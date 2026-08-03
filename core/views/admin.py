from functools import wraps

from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.db.models import Count, Q, Sum
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_http_methods

from ..telegram import send_telegram
from ..notify import notify_appointment_booked, notify_appointment_status_changed, notify_invoice_generated

User = get_user_model()


def admin_required(view_func=None, *, roles=("ADMIN", "STAFF")):
    def decorator(fn):
        @wraps(fn)
        def _wrapped(request, *args, **kwargs):
            if request.user.role not in roles:
                return redirect("dashboard")
            return fn(request, *args, **kwargs)
        return login_required(_wrapped)

    if view_func is not None:
        return decorator(view_func)
    return decorator


# ──────────────────────────────────────────────
#  DASHBOARD
# ──────────────────────────────────────────────

@admin_required
def dashboard(request):
    from core.models.appointments.models import Appointment
    from core.models.billing.models import Invoice
    from core.models.doctors.models import Doctor
    from core.models.feedback.models import Feedback
    from core.models.laboratory.models import LabTest
    from core.models.pharmacy.models import PharmacyOrder, Medicine

    total_users = User.objects.count()
    total_doctors = Doctor.objects.count()
    total_appointments = Appointment.objects.count()
    total_invoices = Invoice.objects.count()
    total_medicines = Medicine.objects.count()
    total_lab_tests = LabTest.objects.count()
    total_revenue = Invoice.objects.filter(status="PAID").aggregate(s=Sum("total_amount"))["s"] or 0
    pending_feedback = Feedback.objects.count()
    pending_orders = PharmacyOrder.objects.filter(status="PENDING").count()

    recent_users = User.objects.order_by("-date_joined")[:5]
    recent_appointments = Appointment.objects.select_related("patient", "doctor__user").order_by("-created_at")[:5]

    return render(request, "core/admin/dashboard.html", {
        "active_tab": "admin_dashboard",
        "total_users": total_users,
        "total_doctors": total_doctors,
        "total_appointments": total_appointments,
        "total_invoices": total_invoices,
        "total_revenue": int(total_revenue),
        "total_medicines": total_medicines,
        "total_lab_tests": total_lab_tests,
        "pending_feedback": pending_feedback,
        "pending_orders": pending_orders,
        "recent_users": recent_users,
        "recent_appointments": recent_appointments,
    })


# ──────────────────────────────────────────────
#  USERS
# ──────────────────────────────────────────────

@admin_required
def user_list(request):
    q = request.GET.get("q", "")
    role_filter = request.GET.get("role", "")

    users = User.objects.all().order_by("-date_joined")
    if q:
        users = users.filter(
            Q(first_name__icontains=q) | Q(last_name__icontains=q)
            | Q(email__icontains=q) | Q(phone__icontains=q)
        )
    if role_filter:
        users = users.filter(role=role_filter)

    page_num = request.GET.get("page", 1)
    paginator = Paginator(users, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        action = request.POST.get("action")
        user_id = request.POST.get("user_id")
        target = get_object_or_404(User, id=user_id)

        if action == "toggle_active":
            target.is_active = not target.is_active
            target.save()
        elif action == "change_role":
            new_role = request.POST.get("role")
            if new_role in dict(User.Role.choices):
                target.role = new_role
                target.save()
        elif action == "delete_user":
            if target.id != request.user.id:
                target.delete()
        return redirect(request.path)

    return render(request, "core/admin/users.html", {
        "active_tab": "admin_users",
        "page_obj": page_obj, "users": page_obj, "query": q, "selected_role": role_filter,
        "roles": User.Role.choices,
    })


@admin_required
def user_create(request):
    error = None
    if request.method == "POST":
        email = request.POST.get("email", "")
        password = request.POST.get("password", "")
        first_name = request.POST.get("first_name", "")
        last_name = request.POST.get("last_name", "")
        phone = request.POST.get("phone", "")
        role = request.POST.get("role", "PATIENT")

        if not email or not password:
            error = "Email and password are required."
        elif User.objects.filter(email=email).exists():
            error = "Email already in use."
        elif User.objects.filter(phone=phone).exists():
            error = "Phone already in use."
        else:
            user = User.objects.create_user(
                username=email.split("@")[0],
                email=email, password=password,
                first_name=first_name, last_name=last_name,
                phone=phone, role=role,
            )
            send_telegram(f"🆕 Admin created user: {email} (role: {role})")
            return redirect("admin_users")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_users",
        "title": "Create User",
        "entity": "User",
        "fields": [
            {"name": "first_name", "label": "First Name", "type": "text", "required": False},
            {"name": "last_name", "label": "Last Name", "type": "text", "required": False},
            {"name": "email", "label": "Email", "type": "email", "required": True},
            {"name": "phone", "label": "Phone", "type": "text", "required": True},
            {"name": "password", "label": "Password", "type": "password", "required": True},
            {"name": "role", "label": "Role", "type": "select", "required": True,
             "choices": User.Role.choices},
        ],
        "cancel_url": "admin_users",
        "error": error,
    })


# ──────────────────────────────────────────────
#  APPOINTMENTS  (full CRUD)
# ──────────────────────────────────────────────

@admin_required
def appointment_list(request):
    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    from core.models.appointments.models import Appointment

    appointments = Appointment.objects.select_related("patient", "doctor__user")
    if q:
        appointments = appointments.filter(
            Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
            | Q(doctor__user__first_name__icontains=q) | Q(doctor__user__last_name__icontains=q)
        )
    if status_filter:
        appointments = appointments.filter(status=status_filter)
    appointments = appointments.order_by("-appointment_date", "-appointment_time")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(appointments, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        action = request.POST.get("action")
        apt_id = request.POST.get("appointment_id")
        apt = get_object_or_404(Appointment, id=apt_id)
        if action == "change_status":
            ns = request.POST.get("status")
            if ns in dict(Appointment.Status.choices):
                apt.status = ns
                apt.save()
                notify_appointment_status_changed(apt)
        elif action == "delete":
            apt.delete()
        return redirect(request.path)

    return render(request, "core/admin/appointments.html", {
        "active_tab": "admin_appointments",
        "page_obj": page_obj, "appointments": page_obj, "query": q, "selected_status": status_filter,
        "statuses": Appointment.Status.choices,
    })


@admin_required
def appointment_create(request):
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor, DoctorAvailability

    error = None
    if request.method == "POST":
        patient_id = request.POST.get("patient_id")
        doctor_id = request.POST.get("doctor_id")
        appointment_date = request.POST.get("appointment_date")
        appointment_time = request.POST.get("appointment_time")
        reason = request.POST.get("reason", "CONSULTATION")
        notes = request.POST.get("notes", "")

        patient = User.objects.filter(id=patient_id).first()
        doctor = Doctor.objects.filter(id=doctor_id).first()
        if not patient or not doctor:
            error = "Invalid patient or doctor."
        elif not appointment_date or not appointment_time:
            error = "Date and time are required."
        elif appointment_date < str(timezone.now().date()):
            error = "Appointment date cannot be in the past."
        elif appointment_date == str(timezone.localtime().date()) and appointment_time <= timezone.localtime().strftime("%H:%M"):
            error = "Appointment time cannot be in the past."
        else:
            from datetime import datetime
            try:
                apt_date = datetime.strptime(appointment_date, "%Y-%m-%d").date()
                apt_time = datetime.strptime(appointment_time, "%H:%M").time()
                weekday = apt_date.weekday()
                slots = doctor.availabilities.filter(weekday=weekday, is_available=True)
                if slots.exists():
                    in_slot = any(s.covers(apt_time) for s in slots)
                    if not in_slot:
                        error = "The selected time is outside the doctor's working hours."
            except ValueError:
                error = "Invalid date or time format."
        if not error:
            apt = Appointment.objects.create(
                patient=patient, doctor=doctor,
                appointment_date=appointment_date,
                appointment_time=appointment_time,
                reason=reason, notes=notes,
            )
            send_telegram(f"📅 Appointment created: {patient.email} with Dr. {doctor.user.get_full_name()} on {appointment_date}")
            notify_appointment_booked(apt)
            return redirect("admin_appointments")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_appointments",
        "title": "Create Appointment",
        "entity": "Appointment",
        "fields": [
            {"name": "patient_id", "label": "Patient", "type": "select_user", "required": True,
             "queryset": User.objects.filter(role__in=["PATIENT", "ADMIN", "STAFF"]).order_by("first_name")},
            {"name": "doctor_id", "label": "Doctor", "type": "select_doctor", "required": True,
             "queryset": Doctor.objects.filter(is_active=True).select_related("user")},
            {"name": "appointment_date", "label": "Date", "type": "date", "required": True},
            {"name": "appointment_time", "label": "Time", "type": "time", "required": True},
            {"name": "reason", "label": "Reason", "type": "select", "required": True,
             "choices": Appointment.Reason.choices},
            {"name": "notes", "label": "Notes", "type": "textarea", "required": False},
        ],
        "cancel_url": "admin_appointments",
        "error": error,
    })


@admin_required
def appointment_edit(request, appointment_id):
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor

    apt = get_object_or_404(Appointment, id=appointment_id)
    error = None
    if request.method == "POST":
        patient_id = request.POST.get("patient_id")
        doctor_id = request.POST.get("doctor_id")
        appointment_date = request.POST.get("appointment_date")
        appointment_time = request.POST.get("appointment_time")
        reason = request.POST.get("reason", "CONSULTATION")
        notes = request.POST.get("notes", "")

        patient = User.objects.filter(id=patient_id).first()
        doctor = Doctor.objects.filter(id=doctor_id).first()
        if not patient or not doctor:
            error = "Invalid patient or doctor."
        elif not appointment_date or not appointment_time:
            error = "Date and time are required."
        elif appointment_date < str(timezone.now().date()):
            error = "Appointment date cannot be in the past."
        else:
            apt.patient = patient
            apt.doctor = doctor
            apt.appointment_date = appointment_date
            apt.appointment_time = appointment_time
            apt.reason = reason
            apt.notes = notes
            apt.save()
            return redirect("admin_appointments")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_appointments",
        "title": "Edit Appointment",
        "entity": "Appointment",
        "fields": [
            {"name": "patient_id", "label": "Patient", "type": "select_user", "required": True,
             "queryset": User.objects.filter(role__in=["PATIENT", "ADMIN", "STAFF"]).order_by("first_name"),
             "value": str(apt.patient_id)},
            {"name": "doctor_id", "label": "Doctor", "type": "select_doctor", "required": True,
             "queryset": Doctor.objects.filter(is_active=True).select_related("user"),
             "value": str(apt.doctor_id)},
            {"name": "appointment_date", "label": "Date", "type": "date", "required": True,
             "value": apt.appointment_date.isoformat()},
            {"name": "appointment_time", "label": "Time", "type": "time", "required": True,
             "value": apt.appointment_time.strftime("%H:%M")},
            {"name": "reason", "label": "Reason", "type": "select", "required": True,
             "choices": Appointment.Reason.choices, "value": apt.reason},
            {"name": "notes", "label": "Notes", "type": "textarea", "required": False,
             "value": apt.notes},
        ],
        "cancel_url": "admin_appointments",
        "error": error,
    })


# ──────────────────────────────────────────────
#  DOCTORS  (full CRUD)
# ──────────────────────────────────────────────

@admin_required
def doctor_list(request):
    q = request.GET.get("q", "")

    from core.models.doctors.models import Doctor, Specialty

    doctors = Doctor.objects.select_related("user").prefetch_related("specialties").order_by("-created_at")
    if q:
        doctors = doctors.filter(
            Q(user__first_name__icontains=q) | Q(user__last_name__icontains=q)
            | Q(user__email__icontains=q) | Q(license_number__icontains=q)
        )
    specialties = Specialty.objects.all()

    page_num = request.GET.get("page", 1)
    paginator = Paginator(doctors, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        action = request.POST.get("action")
        doc_id = request.POST.get("doctor_id")
        doctor = get_object_or_404(Doctor, id=doc_id)
        if action == "toggle_active":
            doctor.is_active = not doctor.is_active
            doctor.save()
        elif action == "toggle_user_active":
            doctor.user.is_active = not doctor.user.is_active
            doctor.user.save()
        return redirect(request.path)

    return render(request, "core/admin/doctors.html", {
        "active_tab": "admin_doctors",
        "page_obj": page_obj, "doctors": page_obj, "specialties": specialties, "query": q,
    })


@admin_required
def doctor_create(request):
    from core.models.doctors.models import Doctor, Specialty

    error = None
    if request.method == "POST":
        user_id = request.POST.get("user_id")
        license_number = request.POST.get("license_number")
        consultation_fee = request.POST.get("consultation_fee", 0)
        years_of_experience = request.POST.get("years_of_experience", 0)
        office_location = request.POST.get("office_location", "")
        bio = request.POST.get("bio", "")
        specialty_ids = request.POST.getlist("specialties")

        user = User.objects.filter(id=user_id).first()
        if not user:
            error = "Invalid user."
        elif Doctor.objects.filter(license_number=license_number).exists():
            error = "License number already exists."
        else:
            doctor = Doctor.objects.create(
                user=user, license_number=license_number,
                consultation_fee=consultation_fee,
                years_of_experience=years_of_experience,
                office_location=office_location, bio=bio,
            )
            if specialty_ids:
                doctor.specialties.set(Specialty.objects.filter(id__in=specialty_ids))
            user.role = "DOCTOR"
            user.save()
            return redirect("admin_doctors")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_doctors",
        "title": "Create Doctor",
        "entity": "Doctor",
        "fields": [
            {"name": "user_id", "label": "User", "type": "select_user", "required": True,
             "queryset": User.objects.filter(role__in=["PATIENT", "DOCTOR", "STAFF"]).order_by("first_name")},
            {"name": "license_number", "label": "License Number", "type": "text", "required": True},
            {"name": "consultation_fee", "label": "Consultation Fee ($)", "type": "number", "required": False},
            {"name": "years_of_experience", "label": "Years of Experience", "type": "number", "required": False},
            {"name": "office_location", "label": "Office Location", "type": "text", "required": False},
            {"name": "bio", "label": "Bio", "type": "textarea", "required": False},
            {"name": "specialties", "label": "Specialties", "type": "select_multi", "required": False,
             "choices": [(s.id, s.name) for s in Specialty.objects.all()]},
        ],
        "cancel_url": "admin_doctors",
        "error": error,
    })


@admin_required
def doctor_edit(request, doctor_id):
    from core.models.doctors.models import Doctor, Specialty

    doctor = get_object_or_404(Doctor.objects.select_related("user"), id=doctor_id)
    error = None
    if request.method == "POST":
        consultation_fee = request.POST.get("consultation_fee", 0)
        years_of_experience = request.POST.get("years_of_experience", 0)
        office_location = request.POST.get("office_location", "")
        bio = request.POST.get("bio", "")
        specialty_ids = request.POST.getlist("specialties")

        doctor.consultation_fee = consultation_fee
        doctor.years_of_experience = years_of_experience
        doctor.office_location = office_location
        doctor.bio = bio
        doctor.save()
        if specialty_ids:
            doctor.specialties.set(Specialty.objects.filter(id__in=specialty_ids))
        else:
            doctor.specialties.clear()
        return redirect("admin_doctors")

    current_specialties = list(doctor.specialties.values_list("id", flat=True))

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_doctors",
        "title": "Edit Doctor",
        "entity": "Doctor",
        "fields": [
            {"name": "user_id", "label": "User", "type": "readonly",
             "value": f"Dr. {doctor.user.get_full_name()} ({doctor.user.email})"},
            {"name": "license_number", "label": "License Number", "type": "readonly",
             "value": doctor.license_number},
            {"name": "consultation_fee", "label": "Consultation Fee ($)", "type": "number", "required": False,
             "value": str(doctor.consultation_fee)},
            {"name": "years_of_experience", "label": "Years of Experience", "type": "number", "required": False,
             "value": str(doctor.years_of_experience)},
            {"name": "office_location", "label": "Office Location", "type": "text", "required": False,
             "value": doctor.office_location},
            {"name": "bio", "label": "Bio", "type": "textarea", "required": False, "value": doctor.bio},
            {"name": "specialties", "label": "Specialties", "type": "select_multi", "required": False,
             "choices": [(s.id, s.name) for s in Specialty.objects.all()],
             "value": current_specialties},
        ],
        "cancel_url": "admin_doctors",
        "error": error,
    })


# ──────────────────────────────────────────────
#  MEDICINES  (full CRUD)
# ──────────────────────────────────────────────

@admin_required(roles=("ADMIN", "STAFF", "PHARMACIST"))
def medicine_list(request):
    q = request.GET.get("q", "")
    from core.models.pharmacy.models import Medicine

    medicines = Medicine.objects.all().order_by("name")
    if q:
        medicines = medicines.filter(
            Q(name__icontains=q) | Q(generic_name__icontains=q)
        )

    page_num = request.GET.get("page", 1)
    paginator = Paginator(medicines, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST" and request.POST.get("action") == "delete":
        med = get_object_or_404(Medicine, id=request.POST.get("medicine_id"))
        med.delete()
        return redirect(request.path)

    return render(request, "core/admin/medicines.html", {
        "active_tab": "admin_medicines",
        "page_obj": page_obj, "medicines": page_obj, "query": q,
    })


@admin_required(roles=("ADMIN", "STAFF", "PHARMACIST"))
def medicine_create(request):
    from core.models.pharmacy.models import Medicine

    error = None
    if request.method == "POST":
        name = request.POST.get("name")
        generic_name = request.POST.get("generic_name", "")
        dosage_form = request.POST.get("dosage_form", "")
        strength = request.POST.get("strength", "")
        price = request.POST.get("price", 0)
        stock_quantity = request.POST.get("stock_quantity", 0)
        requires_prescription = request.POST.get("requires_prescription") == "on"

        if not name:
            error = "Name is required."
        else:
            Medicine.objects.create(
                name=name, generic_name=generic_name,
                dosage_form=dosage_form, strength=strength,
                price=price, stock_quantity=stock_quantity,
                requires_prescription=requires_prescription,
            )
            return redirect("admin_medicines")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_medicines",
        "title": "Create Medicine",
        "entity": "Medicine",
        "fields": [
            {"name": "name", "label": "Medicine Name", "type": "text", "required": True},
            {"name": "generic_name", "label": "Generic Name", "type": "text", "required": False},
            {"name": "dosage_form", "label": "Dosage Form", "type": "text", "required": False},
            {"name": "strength", "label": "Strength", "type": "text", "required": False},
            {"name": "price", "label": "Price ($)", "type": "number", "required": False},
            {"name": "stock_quantity", "label": "Stock Quantity", "type": "number", "required": False},
            {"name": "requires_prescription", "label": "Requires Prescription", "type": "checkbox", "required": False},
        ],
        "cancel_url": "admin_medicines",
        "error": error,
    })


@admin_required(roles=("ADMIN", "STAFF", "PHARMACIST"))
def medicine_edit(request, medicine_id):
    from core.models.pharmacy.models import Medicine

    med = get_object_or_404(Medicine, id=medicine_id)
    error = None
    if request.method == "POST":
        med.name = request.POST.get("name")
        med.generic_name = request.POST.get("generic_name", "")
        med.dosage_form = request.POST.get("dosage_form", "")
        med.strength = request.POST.get("strength", "")
        med.price = request.POST.get("price", 0)
        med.stock_quantity = request.POST.get("stock_quantity", 0)
        med.requires_prescription = request.POST.get("requires_prescription") == "on"
        if not med.name:
            error = "Name is required."
        else:
            med.save()
            return redirect("admin_medicines")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_medicines",
        "title": "Edit Medicine",
        "entity": "Medicine",
        "fields": [
            {"name": "name", "label": "Medicine Name", "type": "text", "required": True, "value": med.name},
            {"name": "generic_name", "label": "Generic Name", "type": "text", "required": False, "value": med.generic_name},
            {"name": "dosage_form", "label": "Dosage Form", "type": "text", "required": False, "value": med.dosage_form},
            {"name": "strength", "label": "Strength", "type": "text", "required": False, "value": med.strength},
            {"name": "price", "label": "Price ($)", "type": "number", "required": False, "value": str(med.price)},
            {"name": "stock_quantity", "label": "Stock Quantity", "type": "number", "required": False, "value": str(med.stock_quantity)},
            {"name": "requires_prescription", "label": "Requires Prescription", "type": "checkbox", "required": False,
             "checked": med.requires_prescription},
        ],
        "cancel_url": "admin_medicines",
        "error": error,
    })


# ──────────────────────────────────────────────
#  INVOICES  (list + status)
# ──────────────────────────────────────────────

@admin_required
def invoice_list(request):
    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    from core.models.billing.models import Invoice

    invoices = Invoice.objects.select_related("patient")
    if q:
        invoices = invoices.filter(
            Q(invoice_number__icontains=q)
            | Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
        )
    if status_filter:
        invoices = invoices.filter(status=status_filter)
    invoices = invoices.order_by("-issue_date")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(invoices, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        inv_id = request.POST.get("invoice_id")
        action = request.POST.get("action")
        inv = get_object_or_404(Invoice, id=inv_id)
        if action == "change_status":
            ns = request.POST.get("status")
            if ns in dict(Invoice.Status.choices):
                inv.status = ns
                inv.save()
                if ns == "PAID":
                    notify_invoice_generated(inv)
        return redirect(request.path)

    return render(request, "core/admin/invoices.html", {
        "active_tab": "admin_invoices",
        "page_obj": page_obj, "invoices": page_obj, "query": q, "selected_status": status_filter,
        "statuses": Invoice.Status.choices,
    })


# ──────────────────────────────────────────────
#  LAB TESTS  (full CRUD)
# ──────────────────────────────────────────────

@admin_required(roles=("ADMIN", "STAFF", "LAB_TECH"))
def labtest_list(request):
    q = request.GET.get("q", "")

    from core.models.laboratory.models import LabTest

    tests = LabTest.objects.all().order_by("name")
    if q:
        tests = tests.filter(Q(name__icontains=q) | Q(category__icontains=q))

    page_num = request.GET.get("page", 1)
    paginator = Paginator(tests, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST" and request.POST.get("action") == "delete":
        t = get_object_or_404(LabTest, id=request.POST.get("test_id"))
        t.delete()
        return redirect(request.path)

    return render(request, "core/admin/labtests.html", {
        "active_tab": "admin_labtests",
        "page_obj": page_obj, "tests": page_obj, "query": q,
    })


@admin_required(roles=("ADMIN", "STAFF", "LAB_TECH"))
def labtest_create(request):
    from core.models.laboratory.models import LabTest

    error = None
    if request.method == "POST":
        name = request.POST.get("name")
        category = request.POST.get("category", "")
        description = request.POST.get("description", "")
        price = request.POST.get("price", 0)
        if not name:
            error = "Name is required."
        else:
            LabTest.objects.create(name=name, category=category, description=description, price=price)
            return redirect("admin_labtests")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_labtests",
        "title": "Create Lab Test",
        "entity": "Lab Test",
        "fields": [
            {"name": "name", "label": "Test Name", "type": "text", "required": True},
            {"name": "category", "label": "Category", "type": "text", "required": False},
            {"name": "description", "label": "Description", "type": "textarea", "required": False},
            {"name": "price", "label": "Price ($)", "type": "number", "required": False},
        ],
        "cancel_url": "admin_labtests",
        "error": error,
    })


@admin_required(roles=("ADMIN", "STAFF", "LAB_TECH"))
def labtest_edit(request, test_id):
    from core.models.laboratory.models import LabTest

    test = get_object_or_404(LabTest, id=test_id)
    error = None
    if request.method == "POST":
        test.name = request.POST.get("name")
        test.category = request.POST.get("category", "")
        test.description = request.POST.get("description", "")
        test.price = request.POST.get("price", 0)
        if not test.name:
            error = "Name is required."
        else:
            test.save()
            return redirect("admin_labtests")

    return render(request, "core/admin/form.html", {
        "active_tab": "admin_labtests",
        "title": "Edit Lab Test",
        "entity": "Lab Test",
        "fields": [
            {"name": "name", "label": "Test Name", "type": "text", "required": True, "value": test.name},
            {"name": "category", "label": "Category", "type": "text", "required": False, "value": test.category},
            {"name": "description", "label": "Description", "type": "textarea", "required": False, "value": test.description},
            {"name": "price", "label": "Price ($)", "type": "number", "required": False, "value": str(test.price)},
        ],
        "cancel_url": "admin_labtests",
        "error": error,
    })


# ──────────────────────────────────────────────
#  PHARMACY ORDERS  (list + status)
# ──────────────────────────────────────────────

@admin_required(roles=("ADMIN", "STAFF", "PHARMACIST"))
def pharmacy_order_list(request):
    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    from core.models.pharmacy.models import PharmacyOrder

    orders = PharmacyOrder.objects.select_related("patient").prefetch_related("items__medicine")
    if q:
        orders = orders.filter(
            Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
        )
    if status_filter:
        orders = orders.filter(status=status_filter)
    orders = orders.order_by("-ordered_at")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(orders, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        order_id = request.POST.get("order_id")
        action = request.POST.get("action")
        order = get_object_or_404(PharmacyOrder, id=order_id)
        if action == "change_status":
            ns = request.POST.get("status")
            if ns in dict(PharmacyOrder.Status.choices):
                order.status = ns
                if ns in ("DELIVERED", "CANCELLED"):
                    from django.utils import timezone
                    order.fulfilled_at = timezone.now()
                order.save()
        return redirect(request.path)

    return render(request, "core/admin/pharmacy_orders.html", {
        "active_tab": "admin_pharmacy_orders",
        "page_obj": page_obj, "orders": page_obj, "query": q, "selected_status": status_filter,
        "statuses": PharmacyOrder.Status.choices,
    })


# ──────────────────────────────────────────────
#  FEEDBACK
# ──────────────────────────────────────────────

@admin_required
def feedback_list(request):
    from core.models.feedback.models import Feedback

    q = request.GET.get("q", "")
    rating_filter = request.GET.get("rating", "")

    feedbacks = Feedback.objects.select_related("patient", "doctor__user")
    if q:
        feedbacks = feedbacks.filter(
            Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
            | Q(comment__icontains=q)
        )
    if rating_filter:
        feedbacks = feedbacks.filter(rating=rating_filter)
    feedbacks = feedbacks.order_by("-created_at")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(feedbacks, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        fb_id = request.POST.get("feedback_id")
        if request.POST.get("action") == "delete":
            get_object_or_404(Feedback, id=fb_id).delete()
        return redirect(request.path)

    return render(request, "core/admin/feedback.html", {
        "active_tab": "admin_feedback",
        "page_obj": page_obj, "feedbacks": page_obj, "query": q, "selected_rating": rating_filter,
    })


# ──────────────────────────────────────────────
#  LAB BOOKINGS  (list + status + release results)
# ──────────────────────────────────────────────

@admin_required(roles=("ADMIN", "STAFF", "LAB_TECH"))
def lab_booking_list(request):
    from core.models.laboratory.models import LabTestBooking, LabTestResult

    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    bookings = LabTestBooking.objects.select_related("patient", "lab_test")
    if q:
        bookings = bookings.filter(Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q) | Q(lab_test__name__icontains=q))
    if status_filter:
        bookings = bookings.filter(status=status_filter)
    bookings = bookings.order_by("-created_at")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(bookings, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        action = request.POST.get("action")
        bk_id = request.POST.get("booking_id")
        booking = get_object_or_404(LabTestBooking, id=bk_id)
        if action == "change_status":
            ns = request.POST.get("status")
            if ns in dict(LabTestBooking.Status.choices):
                booking.status = ns
                booking.save()
        elif action == "release_result":
            summary = request.POST.get("result_summary", "")
            if summary:
                LabTestResult.objects.update_or_create(
                    booking=booking,
                    defaults={"result_summary": summary},
                )
                booking.status = "RESULT_READY"
                booking.save()
                from ..notify import notify_test_result_available
                notify_test_result_available(booking)
        return redirect(request.path)

    return render(request, "core/admin/lab_bookings.html", {
        "active_tab": "admin_lab_bookings",
        "page_obj": page_obj, "bookings": page_obj, "query": q, "selected_status": status_filter,
        "statuses": LabTestBooking.Status.choices,
    })


# ──────────────────────────────────────────────
#  PRESCRIPTIONS  (list + CRUD)
# ──────────────────────────────────────────────

@admin_required
def admin_prescription_list(request):
    from core.models.prescriptions.models import Prescription

    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    rxs = Prescription.objects.select_related("patient", "doctor__user").prefetch_related("items__medicine")
    if q:
        rxs = rxs.filter(Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q) | Q(doctor__user__first_name__icontains=q))
    if status_filter:
        rxs = rxs.filter(status=status_filter)
    rxs = rxs.order_by("-date_prescribed")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(rxs, 20)
    page_obj = paginator.get_page(page_num)

    return render(request, "core/admin/prescriptions.html", {
        "active_tab": "admin_prescriptions",
        "page_obj": page_obj, "prescriptions": page_obj, "query": q, "selected_status": status_filter,
        "statuses": Prescription.Status.choices,
    })


# ──────────────────────────────────────────────
#  PRESCRIPTION REFILLS  (list + status)
# ──────────────────────────────────────────────

@admin_required
def admin_refill_list(request):
    from core.models.prescriptions.models import PrescriptionRefill

    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    refills = PrescriptionRefill.objects.select_related(
        "prescription_item__medicine",
        "prescription_item__prescription__patient",
        "prescription_item__prescription__doctor__user",
    )
    if q:
        refills = refills.filter(
            Q(prescription_item__prescription__patient__first_name__icontains=q)
            | Q(prescription_item__prescription__patient__last_name__icontains=q)
            | Q(prescription_item__medicine__name__icontains=q)
        )
    if status_filter:
        refills = refills.filter(status=status_filter)
    refills = refills.order_by("-requested_at")

    if request.method == "POST":
        refill_id = request.POST.get("refill_id")
        action = request.POST.get("action")
        refill = get_object_or_404(PrescriptionRefill, id=refill_id)
        if action == "approve" and refill.status == "REQUESTED":
            refill.status = "APPROVED"
            refill.save(update_fields=["status"])
            send_telegram(f"💊 Refill approved: {refill.prescription_item.prescription.patient.email} — {refill.prescription_item.medicine.name if refill.prescription_item.medicine else 'item'}")
        elif action == "deny" and refill.status == "REQUESTED":
            refill.status = "DENIED"
            refill.save(update_fields=["status"])
        elif action == "fulfill" and refill.status == "APPROVED":
            refill.status = "FULFILLED"
            refill.fulfilled_at = timezone.now()
            refill.save(update_fields=["status", "fulfilled_at"])
        return redirect("admin_refills")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(refills, 20)
    page_obj = paginator.get_page(page_num)

    return render(request, "core/admin/refills.html", {
        "active_tab": "admin_refills",
        "page_obj": page_obj, "refills": page_obj, "query": q, "selected_status": status_filter,
        "statuses": PrescriptionRefill.Status.choices,
    })


# ──────────────────────────────────────────────
#  MEDICAL RECORDS  (list + view)
# ──────────────────────────────────────────────

@admin_required
def admin_medical_record_list(request):
    from core.models.medical_records.models import PatientRecord

    q = request.GET.get("q", "")
    records = PatientRecord.objects.select_related("patient", "doctor__user").order_by("-record_date")
    if q:
        records = records.filter(Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q) | Q(diagnosis__icontains=q))

    page_num = request.GET.get("page", 1)
    paginator = Paginator(records, 20)
    page_obj = paginator.get_page(page_num)

    return render(request, "core/admin/medical_records.html", {
        "active_tab": "admin_medical_records",
        "page_obj": page_obj, "records": page_obj, "query": q,
    })


# ──────────────────────────────────────────────
#  NOTIFICATIONS  (list + send)
# ──────────────────────────────────────────────

@admin_required
def admin_notification_list(request):
    from core.models.notifications.models import Notification

    q = request.GET.get("q", "")
    type_filter = request.GET.get("type", "")

    notes = Notification.objects.select_related("recipient")
    if q:
        notes = notes.filter(Q(title__icontains=q) | Q(message__icontains=q) | Q(recipient__email__icontains=q))
    if type_filter:
        notes = notes.filter(notification_type=type_filter)
    notes = notes.order_by("-sent_at")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(notes, 20)
    page_obj = paginator.get_page(page_num)

    if request.method == "POST":
        recipient_id = request.POST.get("recipient_id")
        recipient_email = request.POST.get("recipient_email", "").strip()
        ntype = request.POST.get("notification_type")
        title = request.POST.get("title", "")
        message = request.POST.get("message", "")
        if recipient_id and title and message:
            from ..notify import create_notification
            create_notification(
                get_object_or_404(User, id=recipient_id),
                ntype or "GENERAL", title, message,
            )
        elif recipient_email and title and message:
            from ..notify import create_notification
            recipient = User.objects.filter(email=recipient_email).first()
            if recipient:
                create_notification(recipient, ntype or "GENERAL", title, message)
        return redirect(request.path)

    return render(request, "core/admin/notifications.html", {
        "active_tab": "admin_notifications",
        "page_obj": page_obj, "notifications": page_obj, "query": q, "selected_type": type_filter,
        "notification_types": Notification._meta.get_field("notification_type").choices,
    })


# ──────────────────────────────────────────────
#  HEALTH TIPS  (CRUD)
# ──────────────────────────────────────────────

@admin_required
def admin_health_tip_list(request):
    from core.models.notifications.models import HealthTip

    tips = HealthTip.objects.all().order_by("-created_at")

    if request.method == "POST":
        action = request.POST.get("action")
        if action == "create":
            HealthTip.objects.create(
                title=request.POST.get("title", ""),
                content=request.POST.get("content", ""),
                category=request.POST.get("category", "general"),
                is_active=request.POST.get("is_active") == "on",
            )
        elif action == "toggle":
            tip = get_object_or_404(HealthTip, id=request.POST.get("tip_id"))
            tip.is_active = not tip.is_active
            tip.save()
        elif action == "delete":
            get_object_or_404(HealthTip, id=request.POST.get("tip_id")).delete()
        return redirect(request.path)

    return render(request, "core/admin/health_tips.html", {
        "active_tab": "admin_health_tips",
        "tips": tips,
    })


# ──────────────────────────────────────────────
#  INSURANCE PROVIDERS  (list + CRUD)
# ──────────────────────────────────────────────

@admin_required
def admin_insurance_provider_list(request):
    from core.models.insurance.models import InsuranceProvider

    q = request.GET.get("q", "")
    providers = InsuranceProvider.objects.all().order_by("name")
    if q:
        providers = providers.filter(Q(name__icontains=q) | Q(contact_email__icontains=q))

    if request.method == "POST":
        action = request.POST.get("action")
        if action == "create":
            InsuranceProvider.objects.create(
                name=request.POST.get("name"),
                contact_email=request.POST.get("contact_email", ""),
                contact_phone=request.POST.get("contact_phone", ""),
                is_active=request.POST.get("is_active") == "on",
            )
        elif action == "toggle":
            p = get_object_or_404(InsuranceProvider, id=request.POST.get("provider_id"))
            p.is_active = not p.is_active
            p.save()
        elif action == "delete":
            get_object_or_404(InsuranceProvider, id=request.POST.get("provider_id")).delete()
        return redirect(request.path)

    return render(request, "core/admin/insurance_providers.html", {
        "active_tab": "admin_insurance",
        "providers": providers, "query": q,
    })


# ──────────────────────────────────────────────
#  INSURANCE POLICIES  (list + status)
# ──────────────────────────────────────────────

@admin_required
def admin_insurance_policy_list(request):
    from core.models.insurance.models import HealthInsurance

    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    policies = HealthInsurance.objects.select_related("patient", "provider")
    if q:
        policies = policies.filter(
            Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q)
            | Q(policy_number__icontains=q) | Q(provider__name__icontains=q)
        )
    if status_filter:
        policies = policies.filter(verification_status=status_filter)
    policies = policies.order_by("-created_at")

    if request.method == "POST":
        policy_id = request.POST.get("policy_id")
        action = request.POST.get("action")
        policy = get_object_or_404(HealthInsurance, id=policy_id)
        if action in ("verify", "unverify", "expire", "reject"):
            policy.verification_status = {
                "verify": "VERIFIED", "unverify": "UNVERIFIED",
                "expire": "EXPIRED", "reject": "REJECTED",
            }[action]
            policy.save(update_fields=["verification_status"])
            send_telegram(f"🏥 Policy {policy.policy_number} ({policy.patient.email}) marked {policy.get_verification_status_display()}")
        return redirect("admin_insurance_policies")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(policies, 20)
    page_obj = paginator.get_page(page_num)

    return render(request, "core/admin/insurance_policies.html", {
        "active_tab": "admin_insurance_policies",
        "page_obj": page_obj, "policies": page_obj, "query": q, "selected_status": status_filter,
        "statuses": HealthInsurance.VerificationStatus.choices,
    })


# ──────────────────────────────────────────────
#  INSURANCE CLAIMS  (list + status)
# ──────────────────────────────────────────────

@admin_required
def admin_insurance_claim_list(request):
    from core.models.insurance.models import InsuranceClaim

    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    claims = InsuranceClaim.objects.select_related("insurance__patient", "insurance__provider", "invoice")
    if q:
        claims = claims.filter(
            Q(insurance__patient__first_name__icontains=q) | Q(insurance__patient__last_name__icontains=q)
            | Q(invoice__invoice_number__icontains=q)
        )
    if status_filter:
        claims = claims.filter(status=status_filter)
    claims = claims.order_by("-submitted_at")

    if request.method == "POST":
        claim_id = request.POST.get("claim_id")
        action = request.POST.get("action")
        claim = get_object_or_404(InsuranceClaim, id=claim_id)
        approved_amount = request.POST.get("approved_amount")
        if action == "review" and claim.status == "SUBMITTED":
            claim.status = "UNDER_REVIEW"
            claim.save(update_fields=["status"])
        elif action == "approve" and claim.status == "UNDER_REVIEW":
            claim.status = "APPROVED"
            if approved_amount:
                claim.approved_amount = approved_amount
            claim.resolved_at = timezone.now()
            claim.save(update_fields=["status", "approved_amount", "resolved_at"])
            send_telegram(f"🏥 Claim approved: {claim.insurance.patient.email} — E£{claim.approved_amount} on invoice {claim.invoice.invoice_number}")
        elif action == "deny" and claim.status == "UNDER_REVIEW":
            claim.status = "DENIED"
            claim.resolved_at = timezone.now()
            claim.save(update_fields=["status", "resolved_at"])
        elif action == "paid" and claim.status == "APPROVED":
            claim.status = "PAID"
            claim.save(update_fields=["status"])
        return redirect("admin_insurance_claims")

    page_num = request.GET.get("page", 1)
    paginator = Paginator(claims, 20)
    page_obj = paginator.get_page(page_num)

    return render(request, "core/admin/insurance_claims.html", {
        "active_tab": "admin_insurance_claims",
        "page_obj": page_obj, "claims": page_obj, "query": q, "selected_status": status_filter,
        "statuses": InsuranceClaim.Status.choices,
    })


# ──────────────────────────────────────────────
#  REPORTS
# ──────────────────────────────────────────────

@admin_required
def reports(request):
    from django.db.models import Count, Sum
    from django.db.models.functions import TruncMonth

    from core.models.appointments.models import Appointment
    from core.models.billing.models import Invoice
    from core.models.doctors.models import Doctor
    from core.models.feedback.models import Feedback
    from core.models.laboratory.models import LabTest, LabTestBooking
    from core.models.pharmacy.models import PharmacyOrder, Medicine

    now = timezone.now()
    year_start = now.replace(month=1, day=1)

    # ── Appointment stats ──
    total_appointments = Appointment.objects.count()
    appointments_by_status = {
        s: Appointment.objects.filter(status=s).count()
        for s, _ in Appointment.Status.choices
    }
    appointments_by_month = list(
        Appointment.objects.filter(created_at__gte=year_start)
        .annotate(month=TruncMonth("created_at"))
        .values("month")
        .annotate(count=Count("id"))
        .order_by("month")
    )
    top_doctors = (
        Appointment.objects.values("doctor__user__first_name", "doctor__user__last_name")
        .annotate(count=Count("id"))
        .order_by("-count")[:5]
    )

    # ── Revenue stats ──
    total_revenue = Invoice.objects.filter(status="PAID").aggregate(s=Sum("total_amount"))["s"] or 0
    revenue_by_month = list(
        Invoice.objects.filter(status="PAID", issue_date__gte=year_start)
        .annotate(month=TruncMonth("issue_date"))
        .values("month")
        .annotate(total=Sum("total_amount"))
        .order_by("month")
    )
    invoices_by_status = {
        s: Invoice.objects.filter(status=s).count()
        for s, _ in Invoice.Status.choices
    }

    # ── Doctor stats ──
    total_doctors = Doctor.objects.count()
    active_doctors = Doctor.objects.filter(is_active=True).count()

    # ── Pharmacy stats ──
    total_medicines = Medicine.objects.count()
    low_stock = Medicine.objects.filter(stock_quantity__lt=10).count()
    orders_by_status = {
        s: PharmacyOrder.objects.filter(status=s).count()
        for s, _ in PharmacyOrder.Status.choices
    }

    # ── Lab stats ──
    total_lab_tests = LabTest.objects.count()
    lab_bookings_by_status = {
        s: LabTestBooking.objects.filter(status=s).count()
        for s, _ in LabTestBooking.Status.choices
    }

    # ── Feedback ──
    avg_rating = Feedback.objects.aggregate(avg=Sum("rating") / Count("id"))["avg"] or 0
    feedback_count = Feedback.objects.count()

    # ── Users ──
    users_by_role = {
        r: User.objects.filter(role=r).count()
        for r, _ in User.Role.choices
    }
    total_users = User.objects.count()

    context = {
        "active_tab": "admin_reports",
        "total_appointments": total_appointments,
        "appointments_by_status": appointments_by_status,
        "appointments_by_month": appointments_by_month,
        "top_doctors": top_doctors,
        "total_revenue": int(total_revenue),
        "revenue_by_month": revenue_by_month,
        "invoices_by_status": invoices_by_status,
        "total_doctors": total_doctors,
        "active_doctors": active_doctors,
        "total_medicines": total_medicines,
        "low_stock": low_stock,
        "orders_by_status": orders_by_status,
        "total_lab_tests": total_lab_tests,
        "lab_bookings_by_status": lab_bookings_by_status,
        "avg_rating": round(float(avg_rating), 1),
        "feedback_count": feedback_count,
        "users_by_role": users_by_role,
        "total_users": total_users,
    }
    return render(request, "core/admin/reports.html", context)
