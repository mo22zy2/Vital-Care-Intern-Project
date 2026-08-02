from datetime import date, datetime
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from django.contrib.auth import get_user_model
from django.db.models import Sum, Count
from django.db.models.functions import TruncMonth
from django.utils import timezone

from api.deps import get_current_user
from core.telegram import send_telegram

router = APIRouter(prefix="/admin", tags=["admin"])
User = get_user_model()


def require_admin(user=Depends(get_current_user)):
    if user.role not in ("ADMIN", "STAFF") and not user.is_superuser:
        raise HTTPException(status_code=403, detail="Admin access required")
    return user


class UserOut(BaseModel):
    id: str
    email: str
    first_name: str
    last_name: str
    phone: str
    role: str
    is_active: bool
    supabase_uid: str | None
    date_joined: str

    class Config:
        from_attributes = True


class DashboardOut(BaseModel):
    total_users: int
    total_doctors: int
    total_appointments: int
    total_invoices: int
    total_revenue: int
    pending_feedback: int
    pending_orders: int


class AppointmentOut(BaseModel):
    id: str
    patient_name: str
    doctor_name: str
    appointment_date: date
    appointment_time: str
    reason: str
    status: str

    class Config:
        from_attributes = True


class DoctorOut(BaseModel):
    id: str
    full_name: str
    email: str
    license_number: str
    specialties: list[str]
    consultation_fee: str
    is_active: bool
    account_active: bool

    class Config:
        from_attributes = True


class FeedbackOut(BaseModel):
    id: str
    patient_name: str
    target: str
    rating: int
    comment: str
    created_at: str

    class Config:
        from_attributes = True


@router.get("/dashboard", response_model=DashboardOut)
def admin_dashboard(admin=Depends(require_admin)):
    from core.models.appointments.models import Appointment
    from core.models.billing.models import Invoice
    from core.models.doctors.models import Doctor
    from core.models.feedback.models import Feedback
    from core.models.pharmacy.models import PharmacyOrder

    return DashboardOut(
        total_users=User.objects.count(),
        total_doctors=Doctor.objects.count(),
        total_appointments=Appointment.objects.count(),
        total_invoices=Invoice.objects.count(),
        total_revenue=int(Invoice.objects.filter(status="PAID").aggregate(s=Sum("total_amount"))["s"] or 0),
        pending_feedback=Feedback.objects.count(),
        pending_orders=PharmacyOrder.objects.filter(status="PENDING").count(),
    )


@router.get("/users", response_model=list[UserOut])
def admin_users(
    q: str = "",
    role: str = "",
    admin=Depends(require_admin),
):
    from django.db.models import Q

    users = User.objects.all().order_by("-date_joined")
    if q:
        users = users.filter(
            Q(first_name__icontains=q) | Q(last_name__icontains=q)
            | Q(email__icontains=q) | Q(phone__icontains=q)
        )
    if role:
        users = users.filter(role=role)

    return [
        UserOut(
            id=str(u.id),
            email=u.email,
            first_name=u.first_name,
            last_name=u.last_name,
            phone=u.phone,
            role=u.role,
            is_active=u.is_active,
            supabase_uid=str(u.supabase_uid) if u.supabase_uid else None,
            date_joined=u.date_joined.isoformat(),
        )
        for u in users
    ]


class RoleUpdate(BaseModel):
    role: str


@router.patch("/users/{user_id}/role")
def admin_update_user_role(user_id: str, body: RoleUpdate, admin=Depends(require_admin)):
    user = User.objects.filter(id=user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if body.role not in dict(User.Role.choices):
        raise HTTPException(status_code=400, detail="Invalid role")
    user.role = body.role
    user.save()
    return {"message": "Role updated"}


@router.patch("/users/{user_id}/toggle-active")
def admin_toggle_user_active(user_id: str, admin=Depends(require_admin)):
    user = User.objects.filter(id=user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = not user.is_active
    user.save()
    return {"message": f"User {'activated' if user.is_active else 'deactivated'}"}


class UserCreateBody(BaseModel):
    first_name: str = ""
    last_name: str = ""
    email: str
    phone: str = ""
    password: str
    role: str = "PATIENT"


@router.post("/users", status_code=201)
def admin_create_user(body: UserCreateBody, admin=Depends(require_admin)):
    if User.objects.filter(email=body.email).exists():
        raise HTTPException(status_code=400, detail="Email already in use.")
    if body.phone and User.objects.filter(phone=body.phone).exists():
        raise HTTPException(status_code=400, detail="Phone already in use.")
    if len(body.password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
    if body.role not in dict(User.Role.choices):
        raise HTTPException(status_code=400, detail="Invalid role")

    user = User.objects.create_user(
        username=body.email.split("@")[0],
        email=body.email,
        password=body.password,
        first_name=body.first_name,
        last_name=body.last_name,
        phone=body.phone or body.email.split("@")[0],
        role=body.role,
    )
    send_telegram(f"🆕 Admin created user (API): {body.email} (role: {body.role})")
    return {"message": "User created", "id": str(user.id)}


class UserUpdateBody(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    role: str | None = None


@router.patch("/users/{user_id}")
def admin_update_user(user_id: str, body: UserUpdateBody, admin=Depends(require_admin)):
    user = User.objects.filter(id=user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if body.role is not None:
        if body.role not in dict(User.Role.choices):
            raise HTTPException(status_code=400, detail="Invalid role")
        user.role = body.role
    if body.first_name is not None:
        user.first_name = body.first_name
    if body.last_name is not None:
        user.last_name = body.last_name
    if body.phone is not None:
        user.phone = body.phone
    user.save()
    return {"message": "User updated"}


@router.delete("/users/{user_id}")
def admin_delete_user(user_id: str, admin=Depends(require_admin)):
    user = User.objects.filter(id=user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="You cannot delete your own account")
    user.delete()
    return {"message": "User deleted"}


@router.get("/appointments", response_model=list[AppointmentOut])
def admin_appointments(
    q: str = "",
    status: str = "",
    admin=Depends(require_admin),
):
    from core.models.appointments.models import Appointment
    from django.db.models import Q

    qs = Appointment.objects.select_related("patient", "doctor__user").order_by("-appointment_date", "-appointment_time")
    if q:
        qs = qs.filter(
            Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
            | Q(doctor__user__first_name__icontains=q) | Q(doctor__user__last_name__icontains=q)
        )
    if status:
        qs = qs.filter(status=status)

    return [
        AppointmentOut(
            id=str(a.id),
            patient_name=a.patient.get_full_name() or a.patient.email,
            doctor_name=str(a.doctor),
            appointment_date=a.appointment_date,
            appointment_time=a.appointment_time.strftime("%H:%M"),
            reason=a.get_reason_display(),
            status=a.status,
        )
        for a in qs
    ]


class StatusUpdate(BaseModel):
    status: str


@router.patch("/appointments/{appointment_id}/status")
def admin_update_appointment_status(
    appointment_id: str, body: StatusUpdate, admin=Depends(require_admin)
):
    from core.models.appointments.models import Appointment

    apt = Appointment.objects.filter(id=appointment_id).first()
    if not apt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if body.status not in dict(Appointment.Status.choices):
        raise HTTPException(status_code=400, detail="Invalid status")
    apt.status = body.status
    apt.save()
    return {"message": f"Status changed to {apt.get_status_display()}"}


@router.delete("/appointments/{appointment_id}")
def admin_delete_appointment(appointment_id: str, admin=Depends(require_admin)):
    from core.models.appointments.models import Appointment

    apt = Appointment.objects.filter(id=appointment_id).first()
    if not apt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    apt.delete()
    return {"message": "Appointment deleted"}


@router.get("/doctors", response_model=list[DoctorOut])
def admin_doctors(q: str = "", admin=Depends(require_admin)):
    from core.models.doctors.models import Doctor
    from django.db.models import Q

    qs = Doctor.objects.select_related("user").prefetch_related("specialties").order_by("-created_at")
    if q:
        qs = qs.filter(
            Q(user__first_name__icontains=q) | Q(user__last_name__icontains=q)
            | Q(user__email__icontains=q) | Q(license_number__icontains=q)
        )

    return [
        DoctorOut(
            id=str(d.id),
            full_name=f"Dr. {d.user.get_full_name()}",
            email=d.user.email,
            license_number=d.license_number,
            specialties=[s.name for s in d.specialties.all()],
            consultation_fee=str(d.consultation_fee),
            is_active=d.is_active,
            account_active=d.user.is_active,
        )
        for d in qs
    ]


@router.patch("/doctors/{doctor_id}/toggle-active")
def admin_toggle_doctor_active(doctor_id: str, admin=Depends(require_admin)):
    from core.models.doctors.models import Doctor

    doctor = Doctor.objects.filter(id=doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    doctor.is_active = not doctor.is_active
    doctor.save()
    return {"message": f"Doctor {'enabled' if doctor.is_active else 'disabled'}"}


@router.patch("/doctors/{doctor_id}/toggle-account")
def admin_toggle_doctor_account(doctor_id: str, admin=Depends(require_admin)):
    from core.models.doctors.models import Doctor

    doctor = Doctor.objects.filter(id=doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    doctor.user.is_active = not doctor.user.is_active
    doctor.user.save()
    return {"message": f"Account {'unlocked' if doctor.user.is_active else 'locked'}"}


class DoctorCreateBody(BaseModel):
    first_name: str = ""
    last_name: str = ""
    email: str
    password: str = Field(min_length=8)
    license_number: str = ""
    specialties: list[str] = []
    consultation_fee: float = Field(default=0, ge=0)
    years_of_experience: int = Field(default=0, ge=0, le=70)
    office_location: str = ""
    bio: str = ""


@router.post("/doctors", status_code=201)
def admin_create_doctor(body: DoctorCreateBody, admin=Depends(require_admin)):
    from core.models.doctors.models import Doctor, Specialty

    if User.objects.filter(email=body.email).exists():
        raise HTTPException(status_code=400, detail="Email already in use.")
    if not body.email or not body.password:
        raise HTTPException(status_code=400, detail="Email and password are required")
    if len(body.password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
    if Doctor.objects.filter(license_number=body.license_number).exists():
        raise HTTPException(status_code=400, detail="License number already in use")

    user = User.objects.create_user(
        username=body.email.split("@")[0],
        email=body.email,
        password=body.password,
        first_name=body.first_name,
        last_name=body.last_name,
        phone=body.email.split("@")[0],
        role="DOCTOR",
    )
    doctor = Doctor.objects.create(
        user=user,
        license_number=body.license_number or f"LIC-{user.id.hex[:8]}",
        years_of_experience=body.years_of_experience,
        consultation_fee=body.consultation_fee,
        office_location=body.office_location,
        bio=body.bio,
    )
    for name in body.specialties:
        spec, _ = Specialty.objects.get_or_create(name=name)
        doctor.specialties.add(spec)
    send_telegram(f"🆕 Admin created doctor (API): {body.email}")
    return {"message": "Doctor created", "id": str(doctor.id)}


class DoctorUpdateBody(BaseModel):
    consultation_fee: float | None = Field(default=None, ge=0)
    office_location: str | None = None
    bio: str | None = None
    years_of_experience: int | None = Field(default=None, ge=0, le=70)
    specialties: list[str] | None = None


@router.patch("/doctors/{doctor_id}")
def admin_update_doctor(doctor_id: str, body: DoctorUpdateBody, admin=Depends(require_admin)):
    from core.models.doctors.models import Doctor, Specialty

    doctor = Doctor.objects.filter(id=doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    if body.consultation_fee is not None:
        doctor.consultation_fee = body.consultation_fee
    if body.office_location is not None:
        doctor.office_location = body.office_location
    if body.bio is not None:
        doctor.bio = body.bio
    if body.years_of_experience is not None:
        doctor.years_of_experience = body.years_of_experience
    if body.specialties is not None:
        doctor.specialties.clear()
        for name in body.specialties:
            spec, _ = Specialty.objects.get_or_create(name=name)
            doctor.specialties.add(spec)
    doctor.save()
    return {"message": "Doctor updated"}


@router.delete("/doctors/{doctor_id}")
def admin_delete_doctor(doctor_id: str, admin=Depends(require_admin)):
    from core.models.doctors.models import Doctor

    doctor = Doctor.objects.filter(id=doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    user = doctor.user
    doctor.delete()
    user.delete()
    return {"message": "Doctor deleted"}


@router.get("/feedback", response_model=list[FeedbackOut])
def admin_feedback(q: str = "", rating: str = "", admin=Depends(require_admin)):
    from core.models.feedback.models import Feedback
    from django.db.models import Q

    qs = Feedback.objects.select_related("patient", "doctor__user").order_by("-created_at")
    if q:
        qs = qs.filter(
            Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
            | Q(comment__icontains=q)
        )
    if rating:
        qs = qs.filter(rating=int(rating))

    return [
        FeedbackOut(
            id=str(f.id),
            patient_name=f.patient.get_full_name() or f.patient.email,
            target=f"Dr. {f.doctor.user.get_full_name()}" if f.doctor else f.get_target_type_display(),
            rating=f.rating,
            comment=f.comment,
            created_at=f.created_at.isoformat(),
        )
        for f in qs
    ]


@router.delete("/feedback/{feedback_id}")
def admin_delete_feedback(feedback_id: str, admin=Depends(require_admin)):
    from core.models.feedback.models import Feedback

    fb = Feedback.objects.filter(id=feedback_id).first()
    if not fb:
        raise HTTPException(status_code=404, detail="Feedback not found")
    fb.delete()
    return {"message": "Feedback deleted"}


# ── Reports ──

class MonthlyStat(BaseModel):
    month: str
    count: int = 0
    total: float = 0


class ReportsOut(BaseModel):
    total_users: int
    total_appointments: int
    total_revenue: float
    active_doctors: int
    total_doctors: int
    total_medicines: int
    low_stock: int
    avg_rating: float
    feedback_count: int
    appointments_by_status: dict
    invoices_by_status: dict
    orders_by_status: dict
    users_by_role: dict
    monthly_appointments: list[MonthlyStat]
    monthly_revenue: list[MonthlyStat]


@router.get("/reports", response_model=ReportsOut)
def admin_reports(admin=Depends(require_admin)):
    from core.models.appointments.models import Appointment
    from core.models.billing.models import Invoice
    from core.models.doctors.models import Doctor
    from core.models.feedback.models import Feedback
    from core.models.laboratory.models import LabTest, LabTestBooking
    from core.models.pharmacy.models import PharmacyOrder, Medicine

    now = timezone.now()
    year_start = now.replace(month=1, day=1)

    total_revenue = Invoice.objects.filter(status="PAID").aggregate(s=Sum("total_amount"))["s"] or 0
    avg_rating = Feedback.objects.aggregate(avg=Sum("rating") / Count("id"))["avg"] or 0

    monthly_appts = Appointment.objects.filter(created_at__gte=year_start).annotate(
        month=TruncMonth("created_at")
    ).values("month").annotate(count=Count("id")).order_by("month")

    monthly_rev = Invoice.objects.filter(status="PAID", issue_date__gte=year_start).annotate(
        month=TruncMonth("issue_date")
    ).values("month").annotate(total=Sum("total_amount")).order_by("month")

    return ReportsOut(
        total_users=User.objects.count(),
        total_appointments=Appointment.objects.count(),
        total_revenue=float(total_revenue),
        active_doctors=Doctor.objects.filter(is_active=True).count(),
        total_doctors=Doctor.objects.count(),
        total_medicines=Medicine.objects.count(),
        low_stock=Medicine.objects.filter(stock_quantity__lt=10).count(),
        avg_rating=round(float(avg_rating), 1),
        feedback_count=Feedback.objects.count(),
        appointments_by_status={s: Appointment.objects.filter(status=s).count() for s, _ in Appointment.Status.choices},
        invoices_by_status={s: Invoice.objects.filter(status=s).count() for s, _ in Invoice.Status.choices},
        orders_by_status={s: PharmacyOrder.objects.filter(status=s).count() for s, _ in PharmacyOrder.Status.choices},
        users_by_role={r: User.objects.filter(role=r).count() for r, _ in User.Role.choices},
        monthly_appointments=[MonthlyStat(month=str(m["month"]), count=m["count"]) for m in monthly_appts],
        monthly_revenue=[MonthlyStat(month=str(m["month"]), total=float(m["total"])) for m in monthly_rev],
    )


# ── Medicines ──

class MedicineOut(BaseModel):
    id: str
    name: str
    generic_name: str
    dosage_form: str
    strength: str
    price: str
    stock_quantity: int
    requires_prescription: bool

    class Config:
        from_attributes = True


class MedicineCreate(BaseModel):
    name: str
    generic_name: str = ""
    dosage_form: str = ""
    strength: str = ""
    price: float = Field(default=0, ge=0)
    stock_quantity: int = Field(default=0, ge=0)
    requires_prescription: bool = True


class MedicineUpdate(BaseModel):
    name: str | None = None
    generic_name: str | None = None
    dosage_form: str | None = None
    strength: str | None = None
    price: float | None = Field(default=None, ge=0)
    stock_quantity: int | None = Field(default=None, ge=0)
    requires_prescription: bool | None = None


@router.get("/medicines", response_model=list[MedicineOut])
def admin_medicines(q: str = "", admin=Depends(require_admin)):
    from core.models.pharmacy.models import Medicine
    from django.db.models import Q

    qs = Medicine.objects.all().order_by("name")
    if q:
        qs = qs.filter(Q(name__icontains=q) | Q(generic_name__icontains=q))
    return [MedicineOut(id=str(m.id), name=m.name, generic_name=m.generic_name,
                        dosage_form=m.dosage_form, strength=m.strength,
                        price=str(m.price), stock_quantity=m.stock_quantity,
                        requires_prescription=m.requires_prescription) for m in qs]


@router.post("/medicines", status_code=201)
def admin_create_medicine(body: MedicineCreate, admin=Depends(require_admin)):
    from core.models.pharmacy.models import Medicine

    m = Medicine.objects.create(
        name=body.name, generic_name=body.generic_name,
        dosage_form=body.dosage_form, strength=body.strength,
        price=body.price, stock_quantity=body.stock_quantity,
        requires_prescription=body.requires_prescription,
    )
    return {"message": "Medicine created", "id": str(m.id)}


@router.patch("/medicines/{medicine_id}")
def admin_update_medicine(medicine_id: str, body: MedicineUpdate, admin=Depends(require_admin)):
    from core.models.pharmacy.models import Medicine

    m = Medicine.objects.filter(id=medicine_id).first()
    if not m:
        raise HTTPException(status_code=404, detail="Medicine not found")
    data = body.dict(exclude_unset=True)
    for field, value in data.items():
        setattr(m, field, value)
    m.save()
    return {"message": "Medicine updated"}


@router.delete("/medicines/{medicine_id}")
def admin_delete_medicine(medicine_id: str, admin=Depends(require_admin)):
    from core.models.pharmacy.models import Medicine

    m = Medicine.objects.filter(id=medicine_id).first()
    if not m:
        raise HTTPException(status_code=404, detail="Medicine not found")
    m.delete()
    return {"message": "Medicine deleted"}


# ── Invoices ──

class InvoiceOut(BaseModel):
    id: str
    invoice_number: str
    patient_name: str
    issue_date: date
    due_date: date
    total_amount: str
    status: str

    class Config:
        from_attributes = True


@router.get("/invoices", response_model=list[InvoiceOut])
def admin_invoices(q: str = "", status: str = "", admin=Depends(require_admin)):
    from core.models.billing.models import Invoice
    from django.db.models import Q

    qs = Invoice.objects.select_related("patient").order_by("-issue_date")
    if q:
        qs = qs.filter(Q(invoice_number__icontains=q) | Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q))
    if status:
        qs = qs.filter(status=status)
    return [
        InvoiceOut(id=str(i.id), invoice_number=i.invoice_number,
                   patient_name=i.patient.get_full_name() or i.patient.email,
                   issue_date=i.issue_date, due_date=i.due_date,
                   total_amount=str(i.total_amount), status=i.status)
        for i in qs
    ]


@router.patch("/invoices/{invoice_id}/status")
def admin_update_invoice_status(invoice_id: str, body: StatusUpdate, admin=Depends(require_admin)):
    from core.models.billing.models import Invoice

    inv = Invoice.objects.filter(id=invoice_id).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found")
    if body.status not in dict(Invoice.Status.choices):
        raise HTTPException(status_code=400, detail="Invalid status")
    inv.status = body.status
    inv.save()
    return {"message": f"Invoice status changed to {inv.get_status_display()}"}


# ── Lab Tests ──

class LabTestOut(BaseModel):
    id: str
    name: str
    category: str
    price: str
    is_active: bool

    class Config:
        from_attributes = True


class LabTestCreate(BaseModel):
    name: str
    category: str = ""
    description: str = ""
    price: float = Field(default=0, ge=0)


class LabTestUpdate(BaseModel):
    name: str | None = None
    category: str | None = None
    description: str | None = None
    price: float | None = Field(default=None, ge=0)
    is_active: bool | None = None


@router.get("/lab-tests", response_model=list[LabTestOut])
def admin_lab_tests(q: str = "", admin=Depends(require_admin)):
    from core.models.laboratory.models import LabTest
    from django.db.models import Q

    qs = LabTest.objects.all().order_by("name")
    if q:
        qs = qs.filter(Q(name__icontains=q) | Q(category__icontains=q))
    return [LabTestOut(id=str(t.id), name=t.name, category=t.category,
                       price=str(t.price), is_active=t.is_active) for t in qs]


@router.post("/lab-tests", status_code=201)
def admin_create_lab_test(body: LabTestCreate, admin=Depends(require_admin)):
    from core.models.laboratory.models import LabTest

    t = LabTest.objects.create(name=body.name, category=body.category,
                               description=body.description, price=body.price)
    return {"message": "Lab test created", "id": str(t.id)}


@router.patch("/lab-tests/{test_id}")
def admin_update_lab_test(test_id: str, body: LabTestUpdate, admin=Depends(require_admin)):
    from core.models.laboratory.models import LabTest

    t = LabTest.objects.filter(id=test_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Lab test not found")
    data = body.dict(exclude_unset=True)
    for field, value in data.items():
        setattr(t, field, value)
    t.save()
    return {"message": "Lab test updated"}


@router.delete("/lab-tests/{test_id}")
def admin_delete_lab_test(test_id: str, admin=Depends(require_admin)):
    from core.models.laboratory.models import LabTest

    t = LabTest.objects.filter(id=test_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Lab test not found")
    t.delete()
    return {"message": "Lab test deleted"}


# ── Pharmacy Orders ──

class PharmacyOrderOut(BaseModel):
    id: str
    patient_name: str
    status: str
    items: list[dict]
    ordered_at: str

    class Config:
        from_attributes = True


@router.get("/pharmacy-orders", response_model=list[PharmacyOrderOut])
def admin_pharmacy_orders(q: str = "", status: str = "", admin=Depends(require_admin)):
    from core.models.pharmacy.models import PharmacyOrder
    from django.db.models import Q

    qs = PharmacyOrder.objects.select_related("patient").prefetch_related("items__medicine").order_by("-ordered_at")
    if q:
        qs = qs.filter(Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q))
    if status:
        qs = qs.filter(status=status)
    return [
        PharmacyOrderOut(
            id=str(o.id),
            patient_name=o.patient.get_full_name() or o.patient.email,
            status=o.status,
            items=[{"medicine": i.medicine.name, "quantity": i.quantity, "price": str(i.unit_price)} for i in o.items.all()],
            ordered_at=o.ordered_at.isoformat(),
        )
        for o in qs
    ]


@router.patch("/pharmacy-orders/{order_id}/status")
def admin_update_pharmacy_order_status(order_id: str, body: StatusUpdate, admin=Depends(require_admin)):
    from core.models.pharmacy.models import PharmacyOrder

    o = PharmacyOrder.objects.filter(id=order_id).first()
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")
    if body.status not in dict(PharmacyOrder.Status.choices):
        raise HTTPException(status_code=400, detail="Invalid status")
    o.status = body.status
    if body.status in ("DELIVERED", "CANCELLED"):
        o.fulfilled_at = timezone.now()
    o.save()
    return {"message": f"Order status changed to {o.get_status_display()}"}
