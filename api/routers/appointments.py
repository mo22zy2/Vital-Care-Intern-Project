from datetime import date, datetime, time
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from django.contrib.auth import get_user_model
from django.db import transaction

from api.deps import get_current_user
from core.models.appointments.models import Appointment
from core.models.doctors.models import Doctor, DoctorAvailability
from core.telegram import send_telegram
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
        notes=a.notes,
        cancellation_reason=a.cancellation_reason or "",
    )


@router.post("", response_model=AppointmentOut, status_code=201)
def create_appointment(body: AppointmentCreate, user=Depends(get_current_user)):
    try:
        doctor = Doctor.objects.get(id=body.doctor_id, is_active=True)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor not found")

    if body.appointment_date < date.today():
        raise HTTPException(status_code=400, detail="Cannot book in the past")

    weekday = body.appointment_date.weekday()
    slot = DoctorAvailability.objects.filter(
        doctor=doctor, weekday=weekday, is_available=True,
        start_time__lte=body.appointment_time, end_time__gte=body.appointment_time,
    ).first()
    if not slot:
        raise HTTPException(status_code=400, detail="Doctor not available at this time")

    with transaction.atomic():
        if Appointment.objects.filter(
            doctor=doctor, appointment_date=body.appointment_date,
            appointment_time=body.appointment_time,
        ).exclude(status="CANCELLED").exists():
            raise HTTPException(status_code=409, detail="Time slot already booked")
        a = Appointment.objects.create(
            patient=user,
            doctor=doctor,
            appointment_date=body.appointment_date,
            appointment_time=body.appointment_time,
            reason=body.reason,
            notes=body.notes,
        )
    send_telegram(f"📅 Appointment booked (API): {user.email} with Dr. {doctor.user.get_full_name()} on {body.appointment_date}")
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


STATUS_MAP = {
    "accept": "CONFIRMED",
    "confirm": "CONFIRMED",
    "complete": "COMPLETED",
    "no_show": "NO_SHOW",
    "cancel": "CANCELLED",
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
    if a.status in ("COMPLETED", "CANCELLED") and new_status in ("CANCELLED",):
        raise HTTPException(status_code=400, detail=f"Cannot change {a.status} appointment")

    a.status = new_status
    a.save()
    notify_appointment_status_changed(a)
    return {"message": f"Appointment {body.action}ed", "status": a.status}
