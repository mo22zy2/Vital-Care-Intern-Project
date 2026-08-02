from datetime import date, time
from decimal import Decimal
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, model_validator

from api.deps import get_current_user
from core.models.doctors.models import Doctor, Specialty, DoctorAvailability

router = APIRouter(prefix="/doctors", tags=["doctors"])

WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


class DoctorOut(BaseModel):
    id: str
    full_name: str
    specialties: list[str]
    license_number: str
    years_of_experience: int
    consultation_fee: Decimal
    office_location: str
    bio: str
    is_active: bool
    availability: list[dict] = []

    class Config:
        from_attributes = True


def _availability_slots(d: Doctor) -> list[dict]:
    slots = []
    for s in d.availabilities.filter(is_available=True).order_by("weekday", "start_time"):
        slots.append({
            "weekday": s.weekday,
            "weekday_name": WEEKDAYS[s.weekday] if s.weekday < 7 else "",
            "start_time": s.start_time.strftime("%H:%M"),
            "end_time": s.end_time.strftime("%H:%M"),
        })
    return slots


@router.get("", response_model=list[DoctorOut])
def list_doctors(specialty_id: str = None, user=Depends(get_current_user)):
    qs = Doctor.objects.filter(is_active=True).select_related("user").prefetch_related("specialties", "availabilities")
    if specialty_id:
        qs = qs.filter(specialties__id=specialty_id)
    return [
        DoctorOut(
            id=str(d.id),
            full_name=d.user.get_full_name(),
            specialties=[s.name for s in d.specialties.all()],
            license_number=d.license_number,
            years_of_experience=d.years_of_experience,
            consultation_fee=d.consultation_fee,
            office_location=d.office_location,
            bio=d.bio,
            is_active=d.is_active,
            availability=_availability_slots(d),
        )
        for d in qs
    ]


class SpecialtyOut(BaseModel):
    id: int
    name: str
    description: str


@router.get("/specialties", response_model=list[SpecialtyOut])
def list_specialties(user=Depends(get_current_user)):
    return [SpecialtyOut(id=s.id, name=s.name, description=s.description) for s in Specialty.objects.all()]


@router.get("/{doctor_id}", response_model=DoctorOut)
def get_doctor(doctor_id: uuid.UUID, user=Depends(get_current_user)):
    from django.shortcuts import get_object_or_404
    d = get_object_or_404(
        Doctor.objects.select_related("user").prefetch_related("specialties", "availabilities"),
        id=doctor_id,
    )
    return DoctorOut(
        id=str(d.id),
        full_name=d.user.get_full_name(),
        specialties=[s.name for s in d.specialties.all()],
        license_number=d.license_number,
        years_of_experience=d.years_of_experience,
        consultation_fee=d.consultation_fee,
        office_location=d.office_location,
        bio=d.bio,
        is_active=d.is_active,
        availability=_availability_slots(d),
    )


# ── Doctor Dashboard ──

class DoctorDashboardOut(BaseModel):
    upcoming: list[dict]
    total_pending: int
    total_today: int
    total_completed: int


@router.get("/me/dashboard", response_model=DoctorDashboardOut)
def doctor_dashboard(user=Depends(get_current_user)):
    from core.models.appointments.models import Appointment

    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Doctor access required")
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    today = date.today()
    upcoming = Appointment.objects.filter(
        doctor=doctor, appointment_date__gte=today,
    ).exclude(status__in=("CANCELLED", "COMPLETED")).select_related("patient").order_by("appointment_date", "appointment_time")[:10]

    return DoctorDashboardOut(
        upcoming=[
            {
                "id": str(a.id),
                "patient_name": a.patient.get_full_name() or a.patient.email,
                "date": a.appointment_date.isoformat(),
                "time": a.appointment_time.strftime("%H:%M"),
                "reason": a.reason,
                "status": a.status,
            }
            for a in upcoming
        ],
        total_pending=Appointment.objects.filter(doctor=doctor, status="PENDING").count(),
        total_today=Appointment.objects.filter(doctor=doctor, appointment_date=today).exclude(status="CANCELLED").count(),
        total_completed=Appointment.objects.filter(doctor=doctor, status="COMPLETED").count(),
    )


# ── Doctor Appointments ──

@router.get("/me/appointments", response_model=list)
def doctor_list_appointments(status: str = "", q: str = "", user=Depends(get_current_user)):
    from core.models.appointments.models import Appointment
    from django.db.models import Q

    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Doctor access required")
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    qs = Appointment.objects.filter(doctor=doctor).select_related("patient").order_by("-appointment_date", "-appointment_time")
    if status:
        qs = qs.filter(status=status)
    if q:
        qs = qs.filter(Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q))

    return [
        {
            "id": str(a.id),
            "patient_name": a.patient.get_full_name() or a.patient.email,
            "patient_id": str(a.patient.id),
            "patient_phone": a.patient.phone,
            "contact_phone": a.contact_phone or a.patient.phone,
            "date": a.appointment_date.isoformat(),
            "time": a.appointment_time.strftime("%H:%M"),
            "reason": a.reason,
            "status": a.status,
            "notes": a.notes,
            "cancellation_reason": a.cancellation_reason or "",
        }
        for a in qs
    ]


# ── Doctor Availability ──

class AvailabilityOut(BaseModel):
    id: str
    weekday: int
    weekday_name: str
    start_time: str
    end_time: str
    is_available: bool

    class Config:
        from_attributes = True


class AvailabilityCreate(BaseModel):
    weekday: int = Field(ge=0, le=6)
    start_time: str
    end_time: str

    @model_validator(mode="after")
    def validate_range(self):
        start = time.fromisoformat(self.start_time)
        end = time.fromisoformat(self.end_time)
        if start >= end:
            raise ValueError("Start time must be before end time")
        self.start_time = start.strftime("%H:%M")
        self.end_time = end.strftime("%H:%M")
        return self


class AvailabilityUpdate(BaseModel):
    is_available: bool


@router.get("/me/availability", response_model=list[AvailabilityOut])
def list_availability(user=Depends(get_current_user)):
    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Doctor access required")
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    qs = DoctorAvailability.objects.filter(doctor=doctor).order_by("weekday", "start_time")
    return [
        AvailabilityOut(
            id=str(s.id),
            weekday=s.weekday,
            weekday_name=WEEKDAYS[s.weekday] if s.weekday < 7 else "",
            start_time=s.start_time.strftime("%H:%M"),
            end_time=s.end_time.strftime("%H:%M"),
            is_available=s.is_available,
        )
        for s in qs
    ]


@router.post("/me/availability", response_model=AvailabilityOut, status_code=201)
def add_availability(body: AvailabilityCreate, user=Depends(get_current_user)):
    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Doctor access required")
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    start = time.fromisoformat(body.start_time)
    end = time.fromisoformat(body.end_time)
    overlaps = DoctorAvailability.objects.filter(
        doctor=doctor, weekday=body.weekday, is_available=True,
    ).filter(
        start_time__lt=end, end_time__gt=start,
    ).exists()
    if overlaps:
        raise HTTPException(status_code=400, detail="Slot overlaps with an existing availability slot")
    slot = DoctorAvailability.objects.create(
        doctor=doctor, weekday=body.weekday, start_time=start, end_time=end,
    )
    return AvailabilityOut(
        id=str(slot.id),
        weekday=slot.weekday,
        weekday_name=WEEKDAYS[slot.weekday],
        start_time=slot.start_time.strftime("%H:%M"),
        end_time=slot.end_time.strftime("%H:%M"),
        is_available=slot.is_available,
    )


@router.delete("/me/availability/{slot_id}")
def remove_availability(slot_id: str, user=Depends(get_current_user)):
    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Doctor access required")
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    deleted, _ = DoctorAvailability.objects.filter(id=slot_id, doctor=doctor).delete()
    if not deleted:
        raise HTTPException(status_code=404, detail="Slot not found")
    return {"message": "Slot removed"}


@router.patch("/me/availability/{slot_id}/toggle")
def toggle_availability(slot_id: str, user=Depends(get_current_user)):
    if user.role != "DOCTOR":
        raise HTTPException(status_code=403, detail="Doctor access required")
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    slot = DoctorAvailability.objects.filter(id=slot_id, doctor=doctor).first()
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")
    slot.is_available = not slot.is_available
    slot.save()
    return {"message": f"Slot {'enabled' if slot.is_available else 'disabled'}", "is_available": slot.is_available}
