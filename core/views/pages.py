import json
import logging

from django.contrib.auth import authenticate, login, logout
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.db.models import Count, Q, Sum
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_http_methods

from ..supabase_client import get_supabase
from ..telegram import send_telegram

logger = logging.getLogger(__name__)
User = get_user_model()


def landing_page(request):
    if request.user.is_authenticated:
        return redirect("dashboard")
    return render(request, "core/landing.html")


@require_http_methods(["GET", "POST"])
def login_page(request):
    if request.user.is_authenticated:
        return redirect("dashboard")

    error = None
    if request.method == "POST":
        identifier = request.POST.get("email", "").strip()
        password = request.POST.get("password")

        if not identifier or not password:
            error = "Email/Phone and password are required."
        else:
            if "@" in identifier:
                email = identifier
            else:
                try:
                    user_by_phone = User.objects.get(phone=identifier)
                    email = user_by_phone.email
                except User.DoesNotExist:
                    email = identifier

            user = User.objects.filter(Q(email=email) | Q(phone=identifier)).first()
            supabase = get_supabase()
            try:
                res = supabase.auth.sign_in_with_password(
                    {"email": email, "password": password}
                )
                if res and res.user:
                    try:
                        user = User.objects.get(supabase_uid=res.user.id)
                    except User.DoesNotExist:
                        error = "Account not found locally."
                    else:
                        user.backend = "django.contrib.auth.backends.ModelBackend"
                        login(request, user)
                        send_telegram(f"🔑 User logged in: {user.email}")
                        next_url = request.GET.get("next", "/")
                        return redirect(next_url)
                else:
                    error = "Invalid email or password."
            except Exception as e:
                logger.exception("Login failed via Supabase, falling back to Django auth")
                if user and user.check_password(password):
                    user.backend = "django.contrib.auth.backends.ModelBackend"
                    login(request, user)
                    send_telegram(f"🔑 User logged in (local): {user.email}")
                    next_url = request.GET.get("next", "/")
                    return redirect(next_url)
                error = "Login failed. Please check your credentials."

    return render(request, "core/auth/login.html", {"error": error})


@require_http_methods(["GET", "POST"])
def register_page(request):
    if request.user.is_authenticated:
        return redirect("dashboard")

    from core.models.emergency_contacts.models import EmergencyContact
    from core.models.accounts.models import UserPreference

    field_errors = {}
    data = {}

    if request.method == "POST":
        data = {
            "email": request.POST.get("email", ""),
            "first_name": request.POST.get("first_name", "").strip(),
            "last_name": request.POST.get("last_name", "").strip(),
            "phone": request.POST.get("phone", "").strip(),
            "address": request.POST.get("address", "").strip(),
            "gender": request.POST.get("gender", ""),
            "date_of_birth": request.POST.get("date_of_birth", ""),
            "ec_name": request.POST.get("ec_name", "").strip(),
            "ec_relationship": request.POST.get("ec_relationship", ""),
            "ec_phone": request.POST.get("ec_phone", "").strip(),
            "ec_alt_phone": request.POST.get("ec_alt_phone", "").strip(),
            "ec_email": request.POST.get("ec_email", "").strip(),
        }
        password = request.POST.get("password", "")

        if not data["email"] or not password or not data["first_name"] or not data["last_name"]:
            msg = "Please fill in all required fields."
            if not data["first_name"]: field_errors["first_name"] = msg
            if not data["last_name"]: field_errors["last_name"] = msg
            if not data["email"]: field_errors["email"] = msg
            if not password: field_errors["password"] = msg
        if not data["phone"]:
            field_errors["phone"] = field_errors.get("phone", "Please fill in all required fields.")
        if password and len(password) < 8:
            field_errors["password"] = "Invalid password."

        if not field_errors:
            supabase = get_supabase()
            try:
                res = supabase.auth.sign_up({"email": data["email"], "password": password})
                if res and res.user:
                    user = User.objects.create_user(
                        username=data["email"].split("@")[0],
                        email=data["email"],
                        password=password,
                        first_name=data["first_name"],
                        last_name=data["last_name"],
                        phone=data["phone"],
                        address=data["address"],
                        gender=data["gender"],
                        date_of_birth=data["date_of_birth"] or None,
                        supabase_uid=res.user.id,
                    )

                    if data["ec_name"] and data["ec_phone"]:
                        ec = EmergencyContact.objects.create(
                            patient=user,
                            full_name=data["ec_name"],
                            relationship=data["ec_relationship"] or "OTHER",
                            phone=data["ec_phone"],
                            alternate_phone=data["ec_alt_phone"],
                            email=data["ec_email"],
                        )
                        user.primary_emergency_contact = ec
                        user.save(update_fields=["primary_emergency_contact"])

                    UserPreference.objects.get_or_create(user=user)

                    user.backend = "django.contrib.auth.backends.ModelBackend"
                    login(request, user)
                    send_telegram(f"🆕 New user registered: {user.email}")
                    return redirect("profile")
                else:
                    field_errors["email"] = "Registration failed. Try again."
            except Exception:
                field_errors["email"] = "Registration failed. Try again."

    from core.models.accounts.models import User as Usr
    return render(request, "core/auth/register.html", {
        "field_errors": field_errors,
        "data": data,
        "gender_choices": Usr.Gender.choices,
        "ec_relationship_choices": EmergencyContact.Relationship.choices,
    })


def logout_page(request):
    supabase = get_supabase()
    try:
        supabase.auth.sign_out()
    except Exception:
        pass
    logout(request)
    return redirect("landing_page")


@login_required
def dashboard(request):
    now = timezone.now()
    today = now.date()
    yesterday = today - timezone.timedelta(days=1)
    month_start = today.replace(day=1)
    last_month_start = (month_start - timezone.timedelta(days=1)).replace(day=1)

    from core.models.appointments.models import Appointment
    from core.models.billing.models import Invoice
    from core.models.pharmacy.models import PharmacyOrder

    user = request.user
    role = user.role
    is_admin = role in ("ADMIN", "STAFF")

    upcoming = Appointment.objects.filter(
        appointment_date__gte=today, status__in=["PENDING", "CONFIRMED"]
    )
    if role == "PATIENT":
        upcoming = upcoming.filter(patient=user)
    elif role == "DOCTOR":
        upcoming = upcoming.filter(doctor__user=user)
    upcoming = upcoming.select_related("patient", "doctor__user")[:5]

    appt_scope = Appointment.objects.all()
    if role == "PATIENT":
        appt_scope = appt_scope.filter(patient=user)
    elif role == "DOCTOR":
        appt_scope = appt_scope.filter(doctor__user=user)

    total_appts_today = appt_scope.filter(appointment_date=today).count()
    total_appts_yesterday = appt_scope.filter(appointment_date=yesterday).count()

    if total_appts_yesterday:
        appointments_change = round(
            (total_appts_today - total_appts_yesterday) / total_appts_yesterday * 100
        )
    else:
        appointments_change = total_appts_today

    total_doctors_active = User.objects.filter(
        role="DOCTOR", is_active=True
    ).count()

    order_scope = PharmacyOrder.objects.all()
    if role == "PATIENT":
        order_scope = order_scope.filter(patient=user)

    total_pending_orders = order_scope.filter(status="PENDING").count()
    pending_orders_last_week = order_scope.filter(
        status="PENDING", ordered_at__gte=now - timezone.timedelta(days=7)
    ).count()
    orders_change = total_pending_orders - pending_orders_last_week

    if is_admin:
        revenue_this_month = (
            Invoice.objects.filter(status="PAID", issue_date__gte=month_start)
            .aggregate(s=Sum("total_amount"))["s"]
            or 0
        )
        revenue_last_month = (
            Invoice.objects.filter(status="PAID", issue_date__gte=last_month_start, issue_date__lt=month_start)
            .aggregate(s=Sum("total_amount"))["s"]
            or 0
        )
    else:
        revenue_this_month = 0
        revenue_last_month = 0

    if revenue_last_month:
        revenue_change = round(
            (revenue_this_month - revenue_last_month) / revenue_last_month * 100
        )
    else:
        revenue_change = 100 if revenue_this_month else 0

    recent_activities = []

    recent_appts = appt_scope.select_related("patient", "doctor__user").order_by("-created_at")[:3]
    for a in recent_appts:
        recent_activities.append({
            "description": f"Appointment booked: {a.patient.get_full_name()} with Dr. {a.doctor.user.get_full_name()}",
            "timestamp": a.created_at,
        })

    recent_orders = order_scope.select_related("patient").order_by("-ordered_at")[:2]
    for o in recent_orders:
        recent_activities.append({
            "description": f"Pharmacy order #{o.id} placed by {o.patient.get_full_name()}",
            "timestamp": o.ordered_at,
        })

    recent_activities.sort(key=lambda x: x["timestamp"], reverse=True)
    recent_activities = recent_activities[:5]

    context = {
        "active_tab": "dashboard",
        "total_appointments": total_appts_today,
        "appointments_change": appointments_change,
        "total_doctors": total_doctors_active,
        "doctors_change": total_doctors_active,
        "pending_orders": total_pending_orders,
        "orders_change": orders_change,
        "total_revenue": int(revenue_this_month),
        "revenue_change": revenue_change,
        "upcoming_appointments": upcoming,
        "recent_activities": recent_activities,
    }
    return render(request, "core/dashboard.html", context)


@login_required
def doctor_detail(request, doctor_id):
    from core.models.doctors.models import Doctor

    doctor = get_object_or_404(
        Doctor.objects.filter(is_active=True).select_related("user").prefetch_related("specialties"),
        id=doctor_id,
    )
    from core.models.appointments.models import Appointment
    from core.models.feedback.models import Feedback

    upcoming = Appointment.objects.filter(doctor=doctor, appointment_date__gte=timezone.now().date())[:5]
    feedbacks = Feedback.objects.filter(doctor=doctor).select_related("patient").order_by("-created_at")[:5]
    return render(request, "core/doctors/detail.html", {
        "active_tab": "doctors",
        "doctor": doctor,
        "upcoming": upcoming,
        "feedbacks": feedbacks,
    })


@login_required
def doctor_list(request):
    query = request.GET.get("q", "")
    specialty_id = request.GET.get("specialty", "")

    from core.models.doctors.models import Doctor, Specialty

    doctors = Doctor.objects.filter(is_active=True).select_related("user").prefetch_related("specialties")

    if query:
        doctors = doctors.filter(
            Q(user__first_name__icontains=query)
            | Q(user__last_name__icontains=query)
            | Q(user__email__icontains=query)
        )

    if specialty_id:
        doctors = doctors.filter(specialties__id=specialty_id)

    specialties = Specialty.objects.all()

    context = {
        "active_tab": "doctors",
        "doctors": doctors,
        "specialties": specialties,
        "query": query,
        "selected_specialty": specialty_id,
    }
    return render(request, "core/doctors/list.html", context)


@login_required
def appointment_list(request):
    query = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    from core.models.appointments.models import Appointment

    user = request.user
    appointments = Appointment.objects.select_related("patient", "doctor__user")

    if user.role == "PATIENT":
        appointments = appointments.filter(patient=user)
    elif user.role == "DOCTOR":
        appointments = appointments.filter(doctor__user=user)

    if query:
        appointments = appointments.filter(
            Q(patient__first_name__icontains=query)
            | Q(patient__last_name__icontains=query)
        )

    if status_filter:
        appointments = appointments.filter(status=status_filter)

    appointments = appointments.order_by("-appointment_date", "-appointment_time")

    from django.core.paginator import Paginator
    page_num = request.GET.get("page", 1)
    paginator = Paginator(appointments, 10)
    page_obj = paginator.get_page(page_num)

    can_cancel = user.role == "PATIENT"

    context = {
        "active_tab": "appointments",
        "appointments": page_obj,
        "page_obj": page_obj,
        "query": query,
        "selected_status": status_filter,
        "can_cancel": can_cancel,
        "is_patient": user.role == "PATIENT",
    }
    return render(request, "core/appointments/list.html", context)


@login_required
def book_appointment(request):
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor, Specialty, DoctorAvailability

    error = None
    specialties = Specialty.objects.all()
    doctors_qs = Doctor.objects.filter(is_active=True).select_related("user").prefetch_related("specialties", "availabilities")
    preselected_doctor = request.GET.get("doctor", "")

    if request.method == "POST":
        doctor_id = request.POST.get("doctor_id")
        appointment_date = request.POST.get("appointment_date")
        appointment_time = request.POST.get("appointment_time")
        reason = request.POST.get("reason", "CONSULTATION")
        notes = request.POST.get("notes", "")

        doctor = Doctor.objects.filter(id=doctor_id, is_active=True).first()
        if not doctor:
            error = "Invalid or inactive doctor."
        elif not appointment_date or not appointment_time:
            error = "Date and time are required."
        elif appointment_date < str(timezone.now().date()):
            error = "Appointment date cannot be in the past."
        else:
            from datetime import datetime
            try:
                apt_date = datetime.strptime(appointment_date, "%Y-%m-%d").date()
                apt_time = datetime.strptime(appointment_time, "%H:%M").time()
                weekday = apt_date.weekday()
                slots = doctor.availabilities.filter(weekday=weekday, is_available=True)
                if not slots.exists():
                    error = "The doctor is not available on this day."
                else:
                    in_slot = any(s.start_time <= apt_time <= s.end_time for s in slots)
                    if not in_slot:
                        error = "The selected time is outside the doctor's working hours."
                    else:
                        try:
                            apt = Appointment.objects.create(
                                patient=request.user,
                                doctor=doctor,
                                appointment_date=appointment_date,
                                appointment_time=appointment_time,
                                reason=reason,
                                notes=notes,
                            )
                            from ..notify import notify_appointment_booked
                            notify_appointment_booked(apt)
                            send_telegram(f"📅 Appointment booked: {request.user.email} with Dr. {doctor.user.get_full_name()} on {appointment_date}")
                            return redirect("appointment_list")
                        except Exception:
                            error = "This time slot is already booked. Please choose another time."
            except ValueError:
                error = "Invalid date or time format."

    return render(request, "core/appointments/book.html", {
        "active_tab": "appointments",
        "error": error,
        "specialties": specialties,
        "doctors": doctors_qs,
        "reasons": Appointment.Reason.choices,
        "preselected_doctor": preselected_doctor,
    })


@login_required
def cancel_appointment(request, appointment_id):
    from core.models.appointments.models import Appointment

    apt = get_object_or_404(Appointment, id=appointment_id, patient=request.user)
    if apt.status in ("COMPLETED", "CANCELLED"):
        return redirect("appointment_list")

    if request.method == "POST":
        reason = request.POST.get("reason", "")
        apt.status = "CANCELLED"
        apt.cancellation_reason = reason
        apt.save()
        from ..notify import notify_appointment_status_changed
        notify_appointment_status_changed(apt)
        send_telegram(f"❌ Appointment cancelled: {request.user.email} — {reason}")
        return redirect("appointment_list")

    return render(request, "core/appointments/cancel.html", {
        "active_tab": "appointments",
        "appointment": apt,
    })


# ──────────────────────────────────────────────
#  DOCTOR UI
# ──────────────────────────────────────────────

@login_required
def doctor_dashboard(request):
    if request.user.role != "DOCTOR":
        return redirect("dashboard")
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor

    doctor = get_object_or_404(Doctor, user=request.user)
    today = timezone.now().date()
    upcoming = Appointment.objects.filter(doctor=doctor, appointment_date__gte=today).exclude(status="CANCELLED").select_related("patient").order_by("appointment_date", "appointment_time")[:10]
    total_pending = Appointment.objects.filter(doctor=doctor, status="PENDING").count()
    total_today = Appointment.objects.filter(doctor=doctor, appointment_date=today).exclude(status="CANCELLED").count()
    total_completed = Appointment.objects.filter(doctor=doctor, status="COMPLETED").count()
    return render(request, "core/doctor/dashboard.html", {
        "active_tab": "doctor_dashboard",
        "doctor": doctor,
        "upcoming": upcoming,
        "total_pending": total_pending,
        "total_today": total_today,
        "total_completed": total_completed,
    })


@login_required
def doctor_appointments(request):
    if request.user.role != "DOCTOR":
        return redirect("dashboard")
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor

    doctor = get_object_or_404(Doctor, user=request.user)
    status_filter = request.GET.get("status", "")
    q = request.GET.get("q", "")
    apts = Appointment.objects.filter(doctor=doctor).select_related("patient")
    if status_filter:
        apts = apts.filter(status=status_filter)
    if q:
        apts = apts.filter(Q(patient__first_name__icontains=q) | Q(patient__last_name__icontains=q))
    apts = apts.order_by("-appointment_date", "-appointment_time")

    if request.method == "POST":
        action = request.POST.get("action")
        apt_id = request.POST.get("appointment_id")
        apt = get_object_or_404(Appointment, id=apt_id, doctor=doctor)
        if action == "accept":
            apt.status = "CONFIRMED"
            apt.save()
            from ..notify import notify_appointment_status_changed
            notify_appointment_status_changed(apt)
            send_telegram(f"✅ Appointment confirmed by Dr. {doctor.user.get_full_name()}")
        elif action == "complete":
            apt.status = "COMPLETED"
            apt.save()
        elif action == "no_show":
            apt.status = "NO_SHOW"
            apt.save()
        elif action == "cancel":
            apt.status = "CANCELLED"
            apt.cancellation_reason = request.POST.get("reason", "")
            apt.save()
            from ..notify import notify_appointment_status_changed
            notify_appointment_status_changed(apt)
        return redirect("doctor_appointments")

    return render(request, "core/doctor/appointments.html", {
        "active_tab": "doctor_appointments",
        "appointments": apts,
        "selected_status": status_filter,
        "query": q,
    })


@login_required
def doctor_availability(request):
    if request.user.role != "DOCTOR":
        return redirect("dashboard")
    from core.models.doctors.models import Doctor, DoctorAvailability

    doctor = get_object_or_404(Doctor, user=request.user)
    slots = doctor.availabilities.order_by("weekday", "start_time")

    if request.method == "POST":
        action = request.POST.get("action")
        if action == "add":
            weekday = int(request.POST.get("weekday"))
            start_time = request.POST.get("start_time")
            end_time = request.POST.get("end_time")
            if start_time and end_time:
                DoctorAvailability.objects.create(
                    doctor=doctor,
                    weekday=weekday,
                    start_time=start_time,
                    end_time=end_time,
                )
        elif action == "remove":
            slot_id = request.POST.get("slot_id")
            DoctorAvailability.objects.filter(id=slot_id, doctor=doctor).delete()
        elif action == "toggle":
            slot_id = request.POST.get("slot_id")
            slot = DoctorAvailability.objects.filter(id=slot_id, doctor=doctor).first()
            if slot:
                slot.is_available = not slot.is_available
                slot.save()
        return redirect("doctor_availability")

    return render(request, "core/doctor/availability.html", {
        "active_tab": "doctor_availability",
        "slots": slots,
        "weekdays": DoctorAvailability.Weekday.choices,
    })


# ──────────────────────────────────────────────
#  LAB TEST PATIENT UI
# ──────────────────────────────────────────────

@login_required
def lab_book_test(request):
    from core.models.laboratory.models import LabTest, LabTestBooking

    error = None
    success = None
    tests = LabTest.objects.filter(is_active=True)

    if request.method == "POST":
        test_id = request.POST.get("test_id")
        scheduled_date = request.POST.get("scheduled_date")
        scheduled_time = request.POST.get("scheduled_time")

        lab_test = LabTest.objects.filter(id=test_id, is_active=True).first()
        if not lab_test:
            error = "Invalid test."
        elif not scheduled_date or not scheduled_time:
            error = "Date and time are required."
        elif scheduled_date < str(timezone.now().date()):
            error = "Date cannot be in the past."
        else:
            booking = LabTestBooking.objects.create(
                patient=request.user,
                lab_test=lab_test,
                scheduled_date=scheduled_date,
                scheduled_time=scheduled_time,
            )
            send_telegram(f"🔬 Lab test booked: {request.user.email} — {lab_test.name}")
            return redirect("lab_booking_history")

    return render(request, "core/laboratory/book.html", {
        "active_tab": "laboratory",
        "tests": tests,
        "error": error,
        "success": success,
    })


@login_required
def lab_booking_history(request):
    from core.models.laboratory.models import LabTestBooking
    from django.core.paginator import Paginator

    bookings = LabTestBooking.objects.filter(patient=request.user).select_related("lab_test", "result").order_by("-created_at")
    page_num = request.GET.get("page", 1)
    paginator = Paginator(bookings, 10)
    page_obj = paginator.get_page(page_num)
    return render(request, "core/laboratory/history.html", {
        "active_tab": "laboratory",
        "bookings": page_obj, "page_obj": page_obj,
    })


@login_required
def create_order(request):
    from core.models.pharmacy.models import Medicine, PharmacyOrder, PharmacyOrderItem
    from decimal import Decimal

    error = None
    success = None
    medicines = Medicine.objects.filter(is_active=True, stock_quantity__gt=0)

    if request.method == "POST":
        medicine_ids = request.POST.getlist("medicine_id")
        quantities = request.POST.getlist("quantity")

        items = []
        for mid, qty in zip(medicine_ids, quantities):
            if not mid or not qty:
                continue
            try:
                med = Medicine.objects.get(id=mid, is_active=True)
                q = int(qty)
                if q < 1:
                    continue
                if q > med.stock_quantity:
                    error = f"Not enough stock for {med.name}. Available: {med.stock_quantity}"
                    break
                items.append((med, q))
            except (Medicine.DoesNotExist, ValueError):
                continue

        if not error and not items:
            error = "Please select at least one medicine with a valid quantity."
        if not error:
            order = PharmacyOrder.objects.create(patient=request.user)
            total = Decimal("0.00")
            for med, qty in items:
                line_total = med.price * qty
                PharmacyOrderItem.objects.create(
                    order=order, medicine=med,
                    quantity=qty, unit_price=med.price,
                )
                med.stock_quantity -= qty
                med.save()
                total += line_total
            from ..notify import notify_order_placed
            notify_order_placed(order)
            send_telegram(f"📦 Order placed: {request.user.email} — {len(items)} items, ${total}")
            return redirect("order_detail", order_id=order.id)

    return render(request, "core/pharmacy/create_order.html", {
        "active_tab": "pharmacy",
        "medicines": medicines,
        "error": error,
        "success": success,
    })


@login_required
def order_detail(request, order_id):
    from core.models.pharmacy.models import PharmacyOrder

    order = get_object_or_404(
        PharmacyOrder.objects.filter(patient=request.user)
        .prefetch_related("items__medicine"),
        id=order_id,
    )
    items = order.items.all()
    total = sum(item.unit_price * item.quantity for item in items)
    return render(request, "core/pharmacy/order_detail.html", {
        "active_tab": "pharmacy",
        "order": order,
        "items": items,
        "total": total,
    })


@login_required
def order_history(request):
    from core.models.pharmacy.models import PharmacyOrder
    from django.core.paginator import Paginator

    orders = PharmacyOrder.objects.filter(patient=request.user).prefetch_related("items__medicine").order_by("-ordered_at")
    page_num = request.GET.get("page", 1)
    paginator = Paginator(orders, 10)
    page_obj = paginator.get_page(page_num)
    return render(request, "core/pharmacy/order_history.html", {
        "active_tab": "pharmacy",
        "orders": page_obj, "page_obj": page_obj,
    })


@login_required
def medicine_list(request):
    query = request.GET.get("q", "")
    rx_filter = request.GET.get("prescription", "")

    from core.models.pharmacy.models import Medicine

    medicines = Medicine.objects.filter(is_active=True)

    if query:
        medicines = medicines.filter(
            Q(name__icontains=query) | Q(generic_name__icontains=query)
        )

    if rx_filter == "required":
        medicines = medicines.filter(requires_prescription=True)
    elif rx_filter == "otc":
        medicines = medicines.filter(requires_prescription=False)

    context = {
        "active_tab": "pharmacy",
        "medicines": medicines,
        "query": query,
        "rx_filter": rx_filter,
    }
    return render(request, "core/pharmacy/medicines.html", context)


@login_required
def invoice_list(request):
    query = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")

    from core.models.billing.models import Invoice

    invoices = Invoice.objects.select_related("patient")

    if request.user.role == "PATIENT":
        invoices = invoices.filter(patient=request.user)

    if query:
        invoices = invoices.filter(
            Q(invoice_number__icontains=query)
            | Q(patient__first_name__icontains=query)
            | Q(patient__last_name__icontains=query)
        )

    if status_filter:
        invoices = invoices.filter(status=status_filter)

    invoices = invoices.order_by("-issue_date")

    context = {
        "active_tab": "billing",
        "invoices": invoices,
        "query": query,
        "selected_status": status_filter,
    }
    return render(request, "core/billing/invoices.html", context)


@login_required
def lab_test_list(request):
    from core.models.laboratory.models import LabTest, LabTestBooking

    lab_tests = LabTest.objects.filter(is_active=True)
    recent_bookings = LabTestBooking.objects.select_related(
        "patient", "lab_test"
    )
    if request.user.role == "PATIENT":
        recent_bookings = recent_bookings.filter(patient=request.user)
    recent_bookings = recent_bookings.order_by("-created_at")[:5]

    context = {
        "active_tab": "laboratory",
        "lab_tests": lab_tests,
        "recent_bookings": recent_bookings,
    }
    return render(request, "core/laboratory/tests.html", context)


@login_required
def medical_record_list(request):
    from core.models.medical_records.models import PatientRecord
    from django.core.paginator import Paginator

    q = request.GET.get("q", "")
    records = (
        PatientRecord.objects.filter(patient=request.user)
        .select_related("doctor__user")
        .prefetch_related("test_results")
    )
    if q:
        records = records.filter(
            Q(diagnosis__icontains=q) | Q(treatment_plan__icontains=q)
            | Q(doctor__user__first_name__icontains=q) | Q(doctor__user__last_name__icontains=q)
        )
    records = records.order_by("-record_date")
    page_num = request.GET.get("page", 1)
    paginator = Paginator(records, 10)
    page_obj = paginator.get_page(page_num)
    return render(request, "core/medical_records/list.html", {
        "active_tab": "medical_records",
        "records": page_obj, "page_obj": page_obj, "query": q,
    })


@login_required
def prescription_list(request):
    from core.models.prescriptions.models import Prescription
    from django.core.paginator import Paginator

    q = request.GET.get("q", "")
    status_filter = request.GET.get("status", "")
    prescriptions = (
        Prescription.objects.filter(patient=request.user)
        .select_related("doctor__user")
        .prefetch_related("items__medicine")
    )
    if q:
        prescriptions = prescriptions.filter(
            Q(doctor__user__first_name__icontains=q) | Q(doctor__user__last_name__icontains=q)
            | Q(notes__icontains=q)
        )
    if status_filter:
        prescriptions = prescriptions.filter(status=status_filter)
    prescriptions = prescriptions.order_by("-date_prescribed")
    page_num = request.GET.get("page", 1)
    paginator = Paginator(prescriptions, 10)
    page_obj = paginator.get_page(page_num)
    return render(request, "core/prescriptions/list.html", {
        "active_tab": "prescriptions",
        "prescriptions": page_obj, "page_obj": page_obj, "query": q,
        "selected_status": status_filter,
    })


@login_required
def notification_list(request):
    from core.models.notifications.models import Notification, HealthTip

    q = request.GET.get("q", "")
    type_filter = request.GET.get("type", "")

    if request.method == "POST":
        nid = request.POST.get("notification_id")
        action = request.POST.get("action")
        if nid and action == "mark_read":
            Notification.objects.filter(id=nid, recipient=request.user).update(is_read=True)
        elif action == "mark_all_read":
            Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        return redirect(request.path)

    notifications = Notification.objects.filter(recipient=request.user)
    if q:
        notifications = notifications.filter(Q(title__icontains=q) | Q(message__icontains=q))
    if type_filter:
        notifications = notifications.filter(notification_type=type_filter)
    notifications = notifications.order_by("-created_at")[:50]
    health_tips = HealthTip.objects.filter(is_active=True)[:6]
    return render(request, "core/notifications/list.html", {
        "active_tab": "notifications",
        "notifications": notifications,
        "health_tips": health_tips,
        "query": q,
        "selected_type": type_filter,
    })


# ──────────────────────────────────────────────
#  DOCTOR — WRITE PRESCRIPTION
# ──────────────────────────────────────────────

@login_required
def doctor_write_prescription(request):
    if request.user.role != "DOCTOR":
        return redirect("dashboard")
    from core.models.doctors.models import Doctor
    from core.models.prescriptions.models import Prescription, PrescriptionItem
    from core.models.appointments.models import Appointment
    from core.models.pharmacy.models import Medicine

    doctor = get_object_or_404(Doctor, user=request.user)
    error = None
    patients = User.objects.filter(role="PATIENT", is_active=True).order_by("first_name")
    medicines = Medicine.objects.filter(is_active=True)

    if request.method == "POST":
        patient_id = request.POST.get("patient_id")
        appointment_id = request.POST.get("appointment_id", "")
        notes = request.POST.get("notes", "")
        med_ids = request.POST.getlist("medicine_id")
        dosages = request.POST.getlist("dosage")
        durations = request.POST.getlist("duration_days")
        quantities = request.POST.getlist("qty")
        instructions = request.POST.getlist("instructions")

        if not patient_id or not med_ids:
            error = "Patient and at least one medicine are required."
        else:
            rx = Prescription.objects.create(
                patient_id=patient_id,
                doctor=doctor,
                appointment_id=appointment_id or None,
                notes=notes,
            )
            for mid, dosage, dur, qty, inst in zip(med_ids, dosages, durations, quantities, instructions):
                if mid and dosage:
                    PrescriptionItem.objects.create(
                        prescription=rx,
                        medicine_id=mid,
                        dosage=dosage,
                        duration_days=int(dur) if dur else 7,
                        quantity=int(qty) if qty else 1,
                        instructions=inst or "",
                    )
            send_telegram(f"💊 Prescription written by Dr. {doctor.user.get_full_name()}")
            return redirect("doctor_dashboard")

    return render(request, "core/doctor/write_prescription.html", {
        "active_tab": "doctor_dashboard",
        "patients": patients,
        "medicines": medicines,
        "error": error,
    })


# ──────────────────────────────────────────────
#  PATIENT — FEEDBACK
# ──────────────────────────────────────────────

@login_required
def submit_feedback(request):
    from core.models.feedback.models import Feedback
    from core.models.doctors.models import Doctor
    from core.models.appointments.models import Appointment

    error = None
    success = None
    doctors = Doctor.objects.filter(is_active=True).select_related("user")
    past_appts = Appointment.objects.filter(patient=request.user, status="COMPLETED").select_related("doctor__user")

    if request.method == "POST":
        target_type = request.POST.get("target_type", "DOCTOR")
        doctor_id = request.POST.get("doctor_id", "")
        appointment_id = request.POST.get("appointment_id", "")
        rating = request.POST.get("rating")
        comment = request.POST.get("comment", "")
        is_anonymous = request.POST.get("is_anonymous") == "on"

        if not rating:
            error = "Please select a rating."
        else:
            Feedback.objects.create(
                patient=request.user,
                target_type=target_type,
                doctor_id=doctor_id or None,
                appointment_id=appointment_id or None,
                rating=int(rating),
                comment=comment,
                is_anonymous=is_anonymous,
            )
            send_telegram(f"💬 Feedback submitted by {request.user.email} — {rating}/5")
            return redirect("dashboard")

    return render(request, "core/feedback/submit.html", {
        "active_tab": "doctors",
        "error": error,
        "success": success,
        "doctors": doctors,
        "past_appts": past_appts,
    })


# ──────────────────────────────────────────────
#  PHARMACIST DASHBOARD
# ──────────────────────────────────────────────

@login_required
def pharmacist_dashboard(request):
    if request.user.role != "PHARMACIST":
        return redirect("dashboard")
    from core.models.pharmacy.models import PharmacyOrder, Medicine

    pending = PharmacyOrder.objects.filter(status="PENDING").select_related("patient").prefetch_related("items__medicine").order_by("-ordered_at")
    low_stock = Medicine.objects.filter(is_active=True, stock_quantity__lt=10)
    total_orders = PharmacyOrder.objects.count()
    total_medicines = Medicine.objects.filter(is_active=True).count()

    if request.method == "POST":
        order_id = request.POST.get("order_id")
        action = request.POST.get("action")
        order = get_object_or_404(PharmacyOrder, id=order_id)
        if action == "process":
            order.status = "PROCESSING"
            order.save()
        elif action == "ready":
            order.status = "READY_FOR_PICKUP"
            order.save()
        elif action == "deliver":
            order.status = "DELIVERED"
            order.fulfilled_at = timezone.now()
            order.save()
        return redirect("pharmacist_dashboard")

    return render(request, "core/pharmacist/dashboard.html", {
        "active_tab": "pharmacist_dashboard",
        "pending_orders": pending,
        "low_stock": low_stock,
        "total_orders": total_orders,
        "total_medicines": total_medicines,
    })


# ──────────────────────────────────────────────
#  LAB TECHNICIAN DASHBOARD
# ──────────────────────────────────────────────

@login_required
def labtech_dashboard(request):
    if request.user.role != "LAB_TECH":
        return redirect("dashboard")
    from core.models.laboratory.models import LabTestBooking, LabTestResult, LabTest

    pending = LabTestBooking.objects.filter(status="BOOKED").select_related("patient", "lab_test").order_by("-scheduled_date")
    in_progress = LabTestBooking.objects.filter(status="SAMPLE_COLLECTED").select_related("patient", "lab_test")
    total_today = LabTestBooking.objects.filter(scheduled_date=timezone.now().date()).count()

    if request.method == "POST":
        action = request.POST.get("action")
        bk_id = request.POST.get("booking_id")
        booking = get_object_or_404(LabTestBooking, id=bk_id)
        if action == "collect_sample":
            booking.status = "SAMPLE_COLLECTED"
            booking.save()
        elif action == "start_test":
            booking.status = "IN_PROGRESS"
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
        return redirect("labtech_dashboard")

    return render(request, "core/labtech/dashboard.html", {
        "active_tab": "labtech_dashboard",
        "pending": pending,
        "in_progress": in_progress,
        "total_today": total_today,
    })


# ──────────────────────────────────────────────
#  PASSWORD CHANGE
# ──────────────────────────────────────────────

@login_required
def password_change(request):
    error = None
    success = None
    if request.method == "POST":
        current = request.POST.get("current_password", "")
        new_pass = request.POST.get("new_password", "")
        confirm = request.POST.get("confirm_password", "")

        if not request.user.check_password(current):
            error = "Current password is incorrect."
        elif not new_pass or len(new_pass) < 8:
            error = "New password must be at least 8 characters."
        elif new_pass != confirm:
            error = "Passwords do not match."
        else:
            request.user.set_password(new_pass)
            request.user.save()
            from django.contrib.auth import update_session_auth_hash
            update_session_auth_hash(request, request.user)
            success = "Password changed successfully."

    return render(request, "core/auth/password_change.html", {
        "active_tab": "profile",
        "error": error, "success": success,
    })


# ──────────────────────────────────────────────
#  PATIENT MEDICAL TIMELINE
# ──────────────────────────────────────────────

@login_required
def patient_timeline(request):
    from core.models.appointments.models import Appointment
    from core.models.medical_records.models import PatientRecord
    from core.models.prescriptions.models import Prescription
    from core.models.laboratory.models import LabTestBooking

    user = request.user
    if user.role not in ("PATIENT", "DOCTOR", "ADMIN", "STAFF"):
        return redirect("dashboard")

    patient_id = request.GET.get("patient") if user.role in ("DOCTOR", "ADMIN", "STAFF") else user.id
    if not patient_id:
        patient_id = user.id

    from django.contrib.auth import get_user_model
    Usr = get_user_model()
    if str(patient_id) != str(user.id) and user.role not in ("DOCTOR", "ADMIN", "STAFF"):
        patient_id = user.id
    patient = get_object_or_404(Usr, id=patient_id)

    events = []

    for apt in Appointment.objects.filter(patient=patient).select_related("doctor__user"):
        events.append({"date": apt.appointment_date, "time": apt.appointment_time, "type": "Appointment", "title": f"Appointment with Dr. {apt.doctor.user.get_full_name()}", "status": apt.status, "obj": apt})

    for rec in PatientRecord.objects.filter(patient=patient).select_related("doctor__user"):
        events.append({"date": rec.record_date, "time": None, "type": "Medical Record", "title": rec.diagnosis[:80] if rec.diagnosis else "Record", "status": "", "obj": rec})

    for rx in Prescription.objects.filter(patient=patient).select_related("doctor__user").prefetch_related("items__medicine"):
        events.append({"date": rx.date_prescribed, "time": None, "type": "Prescription", "title": f"Prescription by Dr. {rx.doctor.user.get_full_name()}", "status": rx.status, "obj": rx})

    for bk in LabTestBooking.objects.filter(patient=patient).select_related("lab_test"):
        events.append({"date": bk.scheduled_date, "time": bk.scheduled_time, "type": "Lab Test", "title": f"Lab test: {bk.lab_test.name}", "status": bk.status, "obj": bk})

    events.sort(key=lambda e: (e["date"] or timezone.now().date(), e["time"] or timezone.now().time()), reverse=True)

    return render(request, "core/timeline.html", {
        "active_tab": "profile",
        "events": events, "patient": patient,
    })


# ──────────────────────────────────────────────
#  GLOBAL SEARCH
# ──────────────────────────────────────────────

@login_required
def global_search(request):
    q = request.GET.get("q", "").strip()
    results = []
    if q:
        from core.models.doctors.models import Doctor
        from core.models.appointments.models import Appointment
        from core.models.pharmacy.models import Medicine
        from core.models.laboratory.models import LabTest
        from core.models.billing.models import Invoice

        if request.user.role in ("ADMIN", "STAFF", "DOCTOR"):
            doctors = Doctor.objects.filter(is_active=True).select_related("user").filter(Q(user__first_name__icontains=q) | Q(user__last_name__icontains=q) | Q(user__email__icontains=q))[:5]
            for d in doctors:
                results.append({"type": "Doctor", "label": f"Dr. {d.user.get_full_name()}", "url": f"/doctors/{d.id}/"})

        medicines = Medicine.objects.filter(is_active=True).filter(Q(name__icontains=q) | Q(generic_name__icontains=q))[:5]
        for m in medicines:
            results.append({"type": "Medicine", "label": m.name, "url": "/pharmacy/"})

        lab_tests = LabTest.objects.filter(is_active=True).filter(name__icontains=q)[:5]
        for t in lab_tests:
            results.append({"type": "Lab Test", "label": t.name, "url": "/laboratory/"})

        if request.user.role in ("ADMIN", "STAFF"):
            users = User.objects.filter(Q(first_name__icontains=q) | Q(last_name__icontains=q) | Q(email__icontains=q))[:5]
            for u in users:
                results.append({"type": "User", "label": f"{u.get_full_name()} ({u.email})", "url": "/admindashboard/users/"})

            invoices = Invoice.objects.filter(Q(invoice_number__icontains=q) | Q(patient__first_name__icontains=q))[:5]
            for inv in invoices:
                results.append({"type": "Invoice", "label": f"Invoice #{inv.invoice_number}", "url": "/admindashboard/invoices/"})

    return render(request, "core/search_results.html", {
        "active_tab": "dashboard",
        "query": q, "results": results,
    })


@login_required
def profile(request):
    from core.models.appointments.models import Appointment
    from core.models.pharmacy.models import PharmacyOrder
    from core.models.billing.models import Invoice
    from core.models.emergency_contacts.models import EmergencyContact

    user = request.user
    error = None
    success = None

    apts = Appointment.objects.filter(patient=user).order_by("-created_at")[:5]
    orders = PharmacyOrder.objects.filter(patient=user).prefetch_related("items__medicine").order_by("-ordered_at")[:5]
    invoices = Invoice.objects.filter(patient=user).order_by("-issue_date")[:5]

    total_apts = Appointment.objects.filter(patient=user).count()
    total_orders = PharmacyOrder.objects.filter(patient=user).count()
    total_invoices = Invoice.objects.filter(patient=user).count()

    ecs = EmergencyContact.objects.filter(patient=user)
    primary_ec = user.primary_emergency_contact

    if request.method == "POST":
        action = request.POST.get("action", "update_profile")

        if action == "update_profile":
            first_name = request.POST.get("first_name", "").strip()
            last_name = request.POST.get("last_name", "").strip()
            phone = request.POST.get("phone", "").strip()
            address = request.POST.get("address", "").strip()
            gender = request.POST.get("gender", "")
            date_of_birth = request.POST.get("date_of_birth", "")

            if not first_name or not last_name:
                error = "First and last name are required."
            else:
                user.first_name = first_name
                user.last_name = last_name
                if phone:
                    user.phone = phone
                user.address = address
                if gender:
                    user.gender = gender
                if date_of_birth:
                    user.date_of_birth = date_of_birth
                user.save()
                success = "Profile updated successfully."

        elif action == "add_ec":
            ec_name = request.POST.get("ec_name", "").strip()
            ec_relationship = request.POST.get("ec_relationship", "")
            ec_phone = request.POST.get("ec_phone", "").strip()
            ec_alt_phone = request.POST.get("ec_alt_phone", "").strip()
            ec_email = request.POST.get("ec_email", "").strip()

            if not ec_name or not ec_phone:
                error = "Emergency contact name and phone are required."
            else:
                ec = EmergencyContact.objects.create(
                    patient=user,
                    full_name=ec_name,
                    relationship=ec_relationship or "OTHER",
                    phone=ec_phone,
                    alternate_phone=ec_alt_phone,
                    email=ec_email,
                )
                if not user.primary_emergency_contact:
                    user.primary_emergency_contact = ec
                    user.save(update_fields=["primary_emergency_contact"])
                success = "Emergency contact added."

        elif action == "delete_ec":
            ec_id = request.POST.get("ec_id")
            ec = EmergencyContact.objects.filter(id=ec_id, patient=user).first()
            if ec:
                if user.primary_emergency_contact_id == ec.id:
                    user.primary_emergency_contact = None
                    user.save(update_fields=["primary_emergency_contact"])
                ec.delete()
                success = "Emergency contact removed."

        elif action == "set_primary_ec":
            ec_id = request.POST.get("ec_id")
            ec = EmergencyContact.objects.filter(id=ec_id, patient=user).first()
            if ec:
                user.primary_emergency_contact = ec
                user.save(update_fields=["primary_emergency_contact"])
                success = "Primary emergency contact updated."

    return render(request, "core/profile.html", {
        "active_tab": "profile",
        "error": error,
        "success": success,
        "apts": apts,
        "orders": orders,
        "invoices": invoices,
        "total_apts": total_apts,
        "total_orders": total_orders,
        "total_invoices": total_invoices,
        "member_since": user.date_joined,
        "gender_choices": User.Gender.choices,
        "ecs": ecs,
        "primary_ec": primary_ec,
        "ec_relationship_choices": EmergencyContact.Relationship.choices,
    })
