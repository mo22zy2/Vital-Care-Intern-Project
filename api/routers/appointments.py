from datetime import date, datetime, time
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, field_validator, model_validator
from django.contrib.auth import get_user_model
from django.db import transaction, IntegrityError

from api.deps import get_current_user
from api.validators import not_in_past, future_slot, phone
from core.models.appointments.models import Appointment
from core.models.doctors.models import Doctor, DoctorAvailability
from core.notify import notify_appointment_booked, notify_appointment_status_changed

router = APIRouter(prefix="/appointments", tags=["appointments"])
User = get_user_model()


class AppointmentOut(BaseModel):
    id: str
    patient_id: str
    patient_name: str
    doctor_id: str
    doctor_name: str
    appointment_date: date
    appointment_time: time
    reason: str
    status: str
    contact_phone: str
    notes: str
    cancellation_reason: str

    class Config:
        from_attributes = True


class AppointmentCreate(BaseModel):
    doctor_id: str
    appointment_date: date
    appointment_time: time
    reason: str = "CONSULTATION"
    notes: str = ""
    contact_phone: str = ""

    _not_in_past = field_validator("appointment_date")(not_in_past)
    _valid_phone = field_validator("contact_phone")(phone)

    @model_validator(mode="after")
    def validate_slot(self):
        future_slot(self.appointment_date, self.appointment_time)
        return self


class CancelBody(BaseModel):
    reason: str = ""


@router.get("", response_model=list[AppointmentOut])
def list_appointments(user=Depends(get_current_user)):
    if user.role == "DOCTOR":
        try:
            doctor = Doctor.objects.get(user=user)
            qs = Appointment.objects.filter(doctor=doctor).select_related("patient", "doctor__user")
        except Doctor.DoesNotExist:
            qs = Appointment.objects.none()
    else:
        qs = Appointment.objects.filter(patient=user).select_related("doctor__user")
    return [
        AppointmentOut(
            id=str(a.id),
            patient_id=str(a.patient_id),
            patient_name=a.patient.get_full_name() or a.patient.email,
            doctor_id=str(a.doctor_id),
            doctor_name=str(a.doctor),
            appointment_date=a.appointment_date,
            appointment_time=a.appointment_time,
            reason=a.reason,
            status=a.status,
            contact_phone=a.contact_phone,
            notes=a.notes,
            cancellation_reason=a.cancellation_reason or "",
        )
        for a in qs.order_by("-appointment_date", "-appointment_time")
    ]


@router.get("/{appointment_id}", response_model=AppointmentOut)
def get_appointment(appointment_id: str, user=Depends(get_current_user)):
    try:
        if user.role == "DOCTOR":
            doctor = Doctor.objects.get(user=user)
            a = Appointment.objects.select_related("patient", "doctor__user").get(id=appointment_id, doctor=doctor)
        else:
            a = Appointment.objects.select_related("doctor__user").get(id=appointment_id, patient=user)
    except Appointment.DoesNotExist:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return AppointmentOut(
        id=str(a.id),
        patient_id=str(a.patient_id),
        patient_name=a.patient.get_full_name() or a.patient.email,
        doctor_id=str(a.doctor_id),
        doctor_name=str(a.doctor),
        appointment_date=a.appointment_date,
        appointment_time=a.appointment_time,
        reason=a.reason,
        status=a.status,
        contact_phone=a.contact_phone,
        notes=a.notes,
        cancellation_reason=a.cancellation_reason or "",
    )


@router.post("", response_model=AppointmentOut, status_code=201)
def create_appointment(body: AppointmentCreate, user=Depends(get_current_user)):
    if user.role != "PATIENT":
        raise HTTPException(status_code=403, detail="Only patients can book appointments")

    try:
        doctor = Doctor.objects.get(id=body.doctor_id, is_active=True)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor not found")

    if body.appointment_date < date.today():
        raise HTTPException(status_code=400, detail="Cannot book in the past")

    weekday = body.appointment_date.weekday()
    requested_time = body.appointment_time.replace(microsecond=0)
    slot = next(
        (s for s in DoctorAvailability.objects.filter(
            doctor=doctor, weekday=weekday, is_available=True,
        ) if s.covers(requested_time)),
        None,
    )
    if not slot:
        raise HTTPException(status_code=400, detail="Doctor not available at this time")

    with transaction.atomic():
        cancelled = Appointment.objects.filter(
            doctor=doctor, appointment_date=body.appointment_date,
            appointment_time=body.appointment_time, status="CANCELLED",
        )
        cancelled.delete()
        if Appointment.objects.filter(
            doctor=doctor, appointment_date=body.appointment_date,
            appointment_time=body.appointment_time,
        ).exists():
            raise HTTPException(status_code=409, detail="Time slot already booked")
        try:
            a = Appointment.objects.create(
                patient=user,
                doctor=doctor,
                appointment_date=body.appointment_date,
                appointment_time=body.appointment_time,
                reason=body.reason,
                contact_phone=body.contact_phone,
                notes=body.notes,
            )
        except IntegrityError:
            raise HTTPException(status_code=409, detail="Time slot already booked")
    notify_appointment_booked(a)
    return AppointmentOut(
        id=str(a.id),
        patient_id=str(a.patient_id),
        patient_name=a.patient.get_full_name() or a.patient.email,
        doctor_id=str(a.doctor_id),
        doctor_name=str(a.doctor),
        appointment_date=a.appointment_date,
        appointment_time=a.appointment_time,
        reason=a.reason,
        status=a.status,
        contact_phone=a.contact_phone,
        notes=a.notes,
        cancellation_reason="",
    )


@router.patch("/{appointment_id}/cancel")
def cancel_appointment(appointment_id: str, body: CancelBody, user=Depends(get_current_user)):
    try:
        if user.role == "DOCTOR":
            doctor = Doctor.objects.get(user=user)
            a = Appointment.objects.get(id=appointment_id, doctor=doctor)
        else:
            a = Appointment.objects.get(id=appointment_id, patient=user)
    except (Appointment.DoesNotExist, Doctor.DoesNotExist):
        raise HTTPException(status_code=404, detail="Appointment not found")
    if a.status in ("COMPLETED", "CANCELLED"):
        raise HTTPException(status_code=400, detail=f"Cannot cancel {a.status} appointment")
    a.status = "CANCELLED"
    if body.reason:
        a.cancellation_reason = body.reason
    a.save()
    notify_appointment_status_changed(a)
    return {"message": "Appointment cancelled"}


# ── Doctor appointment actions ──

class StatusAction(BaseModel):
    action: str
    reason: str = ""


STATUS_MAP = {
    "accept": "CONFIRMED",
    "confirm": "CONFIRMED",
    "complete": "COMPLETED",
    "no_show": "NO_SHOW",
    "cancel": "CANCELLED",
}

ACTION_MESSAGE = {
    "accept": "Appointment accepted",
    "confirm": "Appointment confirmed",
    "complete": "Appointment completed",
    "no_show": "Appointment marked as no-show",
    "cancel": "Appointment cancelled",
}


@router.patch("/{appointment_id}/status")
def update_appointment_status(appointment_id: str, body: StatusAction, user=Depends(get_current_user)):
    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Only doctors can update appointment status")
    try:
        doctor = Doctor.objects.get(user=user)
        a = Appointment.objects.get(id=appointment_id, doctor=doctor)
    except (Appointment.DoesNotExist, Doctor.DoesNotExist):
        raise HTTPException(status_code=404, detail="Appointment not found")

    new_status = STATUS_MAP.get(body.action)
    if not new_status:
        raise HTTPException(status_code=400, detail=f"Invalid action: {body.action}")
    if a.status in ("COMPLETED", "CANCELLED"):
        raise HTTPException(status_code=400, detail=f"Cannot change {a.status} appointment")

    a.status = new_status
    if new_status == "CANCELLED":
        a.cancellation_reason = body.reason or "Cancelled by doctor"
    a.save()
    notify_appointment_status_changed(a)
    return {"message": ACTION_MESSAGE.get(body.action, f"Appointment updated to {a.status}"), "status": a.status}
