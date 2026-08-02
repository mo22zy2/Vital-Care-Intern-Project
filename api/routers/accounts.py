from datetime import datetime, timedelta, date
import random
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr, Field, field_validator
from django.contrib.auth import get_user_model
from django.utils import timezone

from api.deps import get_current_user
from api.validators import birthday
from core.models.accounts.models import PasswordResetOTP, UserPreference

router = APIRouter(prefix="/accounts", tags=["accounts"])
User = get_user_model()


class ProfileOut(BaseModel):
    id: str
    email: str
    first_name: str
    last_name: str
    phone: str
    address: str
    gender: str
    date_of_birth: str | None
    role: str
    is_email_verified: bool
    is_phone_verified: bool

    class Config:
        from_attributes = True


class ProfileUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    address: str | None = None
    gender: str | None = None
    date_of_birth: date | None = None

    _birthday = field_validator("date_of_birth")(birthday)


@router.get("/me", response_model=ProfileOut)
def get_profile(user=Depends(get_current_user)):
    return ProfileOut(
        id=str(user.id),
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        phone=user.phone,
        address=user.address,
        gender=user.gender,
        date_of_birth=user.date_of_birth.isoformat() if user.date_of_birth else None,
        role=user.role,
        is_email_verified=user.is_email_verified,
        is_phone_verified=user.is_phone_verified,
    )


@router.patch("/me", response_model=ProfileOut)
def update_profile(body: ProfileUpdate, user=Depends(get_current_user)):
    for field, value in body.dict(exclude_unset=True).items():
        if field == "date_of_birth" and value:
            user.date_of_birth = value
        elif value is not None or field == "date_of_birth":
            setattr(user, field, value)
    user.save()
    return ProfileOut(
        id=str(user.id),
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        phone=user.phone,
        address=user.address,
        gender=user.gender,
        date_of_birth=user.date_of_birth.isoformat() if user.date_of_birth else None,
        role=user.role,
        is_email_verified=user.is_email_verified,
        is_phone_verified=user.is_phone_verified,
    )


class DashboardOut(BaseModel):
    upcoming_appointments: list[dict]
    unread_notifications: int
    pending_orders: int
    total_appointments: int
    total_invoices: int
    recent_activities: list[dict]


@router.get("/dashboard", response_model=DashboardOut)
def patient_dashboard(user=Depends(get_current_user)):
    from core.models.appointments.models import Appointment
    from core.models.notifications.models import Notification
    from core.models.pharmacy.models import PharmacyOrder
    from core.models.billing.models import Invoice

    today = timezone.now().date()
    upcoming = Appointment.objects.filter(
        patient=user, appointment_date__gte=today
    ).exclude(status__in=("CANCELLED", "COMPLETED")).select_related("doctor__user").order_by("appointment_date", "appointment_time")[:5]

    activities = []
    for a in Appointment.objects.filter(patient=user).select_related("doctor__user").order_by("-created_at")[:5]:
        activities.append({
            "type": "appointment",
            "date": a.appointment_date.isoformat(),
            "description": f"Appointment with Dr. {a.doctor}" if a.doctor else "Appointment",
            "status": a.status,
            "id": str(a.id),
        })
    for o in PharmacyOrder.objects.filter(patient=user).order_by("-ordered_at")[:5]:
        activities.append({
            "type": "order",
            "date": o.ordered_at.isoformat(),
            "description": "Pharmacy order",
            "status": o.status,
            "id": str(o.id),
        })
    activities.sort(key=lambda x: x["date"], reverse=True)
    activities = activities[:10]

    return DashboardOut(
        upcoming_appointments=[
            {
                "id": str(a.id),
                "doctor_name": str(a.doctor),
                "date": a.appointment_date.isoformat(),
                "time": a.appointment_time.strftime("%H:%M"),
                "status": a.status,
                "reason": a.reason,
            }
            for a in upcoming
        ],
        unread_notifications=Notification.objects.filter(recipient=user, is_read=False).count(),
        pending_orders=PharmacyOrder.objects.filter(patient=user, status="PENDING").count(),
        total_appointments=Appointment.objects.filter(patient=user).count(),
        total_invoices=Invoice.objects.filter(patient=user).count(),
        recent_activities=activities,
    )


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8)


@router.post("/me/password")
def change_password(body: PasswordChange, user=Depends(get_current_user)):
    if not user.check_password(body.current_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    user.set_password(body.new_password)
    user.save()
    return {"message": "Password changed successfully"}


class TimelineEvent(BaseModel):
    type: str
    date: str
    time: str | None
    description: str
    status: str
    id: str

    class Config:
        from_attributes = True


@router.get("/timeline", response_model=list[TimelineEvent])
def patient_timeline(user=Depends(get_current_user)):
    from core.models.appointments.models import Appointment
    from core.models.medical_records.models import PatientRecord
    from core.models.prescriptions.models import Prescription
    from core.models.laboratory.models import LabTestBooking

    events = []
    for a in Appointment.objects.filter(patient=user).select_related("doctor__user"):
        events.append(TimelineEvent(
            type="appointment", date=a.appointment_date.isoformat(),
            time=a.appointment_time.strftime("%H:%M"),
            description=f"Appointment with Dr. {a.doctor}" if a.doctor else "Appointment",
            status=a.status, id=str(a.id),
        ))
    for r in PatientRecord.objects.filter(patient=user):
        events.append(TimelineEvent(
            type="record", date=r.record_date.isoformat(), time=None,
            description=f"Medical record: {r.diagnosis[:50]}" if r.diagnosis else "Medical record",
            status="", id=str(r.id),
        ))
    for p in Prescription.objects.filter(patient=user).select_related("doctor__user"):
        events.append(TimelineEvent(
            type="prescription", date=p.date_prescribed.isoformat(), time=None,
            description=f"Prescription by Dr. {p.doctor}" if p.doctor else "Prescription",
            status=p.status, id=str(p.id),
        ))
    for b in LabTestBooking.objects.filter(patient=user).select_related("lab_test"):
        events.append(TimelineEvent(
            type="lab_test", date=b.scheduled_date.isoformat(),
            time=b.scheduled_time.strftime("%H:%M") if b.scheduled_time else None,
            description=f"Lab test: {b.lab_test.name}",
            status=b.status, id=str(b.id),
        ))

    events.sort(key=lambda e: e.date, reverse=True)
    return events[:50]


# ── Preferences ──

class PreferenceOut(BaseModel):
    theme: str
    language: str

    class Config:
        from_attributes = True


@router.get("/preferences", response_model=PreferenceOut)
def get_preferences(user=Depends(get_current_user)):
    pref, _ = UserPreference.objects.get_or_create(user=user)
    return PreferenceOut(theme=pref.theme, language=pref.language)


class PreferenceUpdate(BaseModel):
    theme: str | None = None
    language: str | None = None


@router.patch("/preferences", response_model=PreferenceOut)
def update_preferences(body: PreferenceUpdate, user=Depends(get_current_user)):
    pref, _ = UserPreference.objects.get_or_create(user=user)
    for field, value in body.dict(exclude_unset=True).items():
        setattr(pref, field, value)
    pref.save()
    return PreferenceOut(theme=pref.theme, language=pref.language)


# ── OTP Password Reset ──

class OTPRequest(BaseModel):
    email: str


class OTPVerify(BaseModel):
    email: str
    code: str
    new_password: str


@router.post("/request-otp")
def request_otp(body: OTPRequest):
    user = User.objects.filter(email=body.email).first()
    if not user:
        return {"message": "If the email exists, an OTP has been sent"}
    code = f"{random.randint(100000, 999999)}"
    PasswordResetOTP.objects.create(
        user=user,
        code=code,
        delivery_method="EMAIL",
        expires_at=timezone.now() + timedelta(minutes=15),
    )
    return {"message": "If the email exists, an OTP has been sent"}


@router.post("/verify-otp")
def verify_otp(body: OTPVerify):
    user = User.objects.filter(email=body.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid request")
    otp = PasswordResetOTP.objects.filter(user=user, code=body.code, is_used=False).first()
    if not otp or not otp.is_valid():
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    user.set_password(body.new_password)
    user.save()
    otp.is_used = True
    otp.save()
    return {"message": "Password reset successfully"}
