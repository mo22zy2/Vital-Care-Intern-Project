#!/usr/bin/env python
"""
Seed sample Egyptian mock data using Django ORM.
Usage: python scripts/seed_data.py
"""
import os
import sys
import uuid
from datetime import date, timedelta, datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "hospital_project.settings")

import django
django.setup()

from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction

User = get_user_model()


def main():
    with transaction.atomic():
        seed_specialties()
        seed_insurance_providers()
        seed_medicines()
        seed_lab_tests()
        seed_health_tips()
        users = seed_users()
        seed_user_preferences(users)
        seed_emergency_contacts(users)
        seed_doctors(users)
        seed_appointments(users)
        seed_medical_records(users)
        seed_prescriptions(users)
        seed_pharmacy_orders(users)
        seed_lab_bookings(users)
        seed_invoices(users)
        seed_insurance_policies(users)
        seed_insurance_claims()
        seed_payments()
        seed_notifications(users)
        seed_feedback(users)
        seed_reports(users)
        seed_analytics_snapshots()
        seed_password_reset_otps(users)
    print("Done — all sample data seeded.")


# ── Helper ──
PASSWORD = "password123"


def make_uuid(hex_seed):
    return uuid.UUID(hex=hex_seed)


# ── 1. Specialties ──
def seed_specialties():
    from core.models.doctors.models import Specialty
    specs = [
        (1, "Cardiology", "Diagnosis and treatment of heart and blood vessel conditions"),
        (2, "Pediatrics", "Medical care for infants, children, and adolescents"),
        (3, "Orthopedics", "Treatment of bones, joints, ligaments, and muscles"),
        (4, "Dermatology", "Skin, hair, and nail conditions"),
        (5, "Internal Medicine", "Prevention, diagnosis, and treatment of adult diseases"),
        (6, "ENT", "Ear, nose, and throat disorders"),
    ]
    for sid, name, desc in specs:
        Specialty.objects.update_or_create(id=sid, defaults={"name": name, "description": desc})
    print(f"  OK {len(specs)} specialties")


# ── 2. Insurance Providers ──
def seed_insurance_providers():
    from core.models.insurance.models import InsuranceProvider
    providers = [
        (1, "Misr Insurance", "support@misrinsurance.com.eg", "0223456789"),
        (2, "Allianz Egypt", "care@allianz.com.eg", "0225551234"),
        (3, "AXA Egypt", "help@axa.com.eg", "0227778888"),
        (4, "Bupa Egypt", "info@bupa.com.eg", "0229990001"),
    ]
    for pid, name, email, phone in providers:
        InsuranceProvider.objects.update_or_create(
            id=pid,
            defaults={"name": name, "contact_email": email, "contact_phone": phone, "api_integration_key": f"{name.lower().replace(' ', '_')}_api_key", "is_active": True},
        )
    print(f"  OK {len(providers)} insurance providers")


# ── 3. Medicines ──
def seed_medicines():
    from core.models.pharmacy.models import Medicine
    data = [
        (make_uuid("70000000000000000000000000000001"), "Concor", "Bisoprolol", "Beta-blocker for hypertension and heart conditions", "Tablet", "5mg", 65.00, 500, True),
        (make_uuid("70000000000000000000000000000002"), "Panadol Extra", "Paracetamol/Caffeine", "Pain reliever and fever reducer", "Tablet", "500mg", 15.50, 1000, False),
        (make_uuid("70000000000000000000000000000003"), "Augmentin", "Amoxicillin/Clavulanate", "Broad-spectrum antibiotic", "Tablet", "1g", 85.00, 300, True),
        (make_uuid("70000000000000000000000000000004"), "Glucophage", "Metformin", "Oral medication for type 2 diabetes", "Tablet", "500mg", 30.00, 700, True),
        (make_uuid("70000000000000000000000000000005"), "Ventolin", "Salbutamol", "Bronchodilator inhaler for asthma", "Inhaler", "100mcg", 45.00, 250, True),
        (make_uuid("70000000000000000000000000000006"), "Voltaren", "Diclofenac", "Anti-inflammatory pain relief gel", "Gel", "1%", 40.00, 400, False),
    ]
    for mid, name, generic, desc, form, strength, price, stock, rx in data:
        Medicine.objects.update_or_create(
            id=mid,
            defaults={"name": name, "generic_name": generic, "description": desc, "dosage_form": form, "strength": strength, "price": price, "stock_quantity": stock, "requires_prescription": rx, "is_active": True},
        )
    print(f"  OK {len(data)} medicines")


# ── 4. Lab Tests ──
def seed_lab_tests():
    from core.models.laboratory.models import LabTest
    data = [
        (make_uuid("90000000000000000000000000000001"), "Complete Blood Count (CBC)", "General blood health screening", 120.00, "No special preparation required", 6),
        (make_uuid("90000000000000000000000000000002"), "Liver Function Test", "Assesses liver enzyme levels", 180.00, "Fasting for 8 hours recommended", 12),
        (make_uuid("90000000000000000000000000000003"), "Lipid Profile", "Cholesterol and triglycerides panel", 150.00, "Fasting for 12 hours required", 24),
        (make_uuid("90000000000000000000000000000004"), "Thyroid Function Test", "TSH, T3, T4 levels", 200.00, "No special preparation required", 24),
    ]
    for tid, name, desc, price, prep, turnaround in data:
        LabTest.objects.update_or_create(
            id=tid,
            defaults={"name": name, "description": desc, "price": price, "preparation_instructions": prep, "turnaround_time_hours": turnaround, "is_active": True},
        )
    print(f"  OK {len(data)} lab tests")


# ── 5. Health Tips ──
def seed_health_tips():
    from core.models.notifications.models import HealthTip
    data = [
        ("Stay Hydrated in Summer", "Drink at least 2-3 liters of water daily, especially during hot Egyptian summers, to avoid dehydration.", "GENERAL_WELLNESS"),
        ("Manage Blood Pressure", "Reduce salt intake and monitor your blood pressure regularly if you have hypertension.", "CARDIOLOGY"),
        ("Childhood Vaccination Schedule", "Keep your child's vaccinations up to date according to the Ministry of Health schedule.", "PEDIATRICS"),
    ]
    for title, content, cat in data:
        HealthTip.objects.create(title=title, content=content, category=cat, is_active=True)
    print(f"  OK {len(data)} health tips")


# ── 6. Users ──
def seed_users():
    users = {}
    raw = [
        # Patients
        ("10000000000000000000000000000001", "ahmed.hassan", "Ahmed", "Hassan", "ahmed.hassan@gmail.com", "01012345671", "12 El Nasr St, Nasr City, Cairo", "M", "1990-03-14", "PATIENT"),
        ("10000000000000000000000000000002", "fatma.ibrahim", "Fatma", "Ibrahim", "fatma.ibrahim@yahoo.com", "01123456782", "5 Al Haram St, Giza", "F", "1985-07-22", "PATIENT"),
        ("10000000000000000000000000000003", "youssef.said", "Youssef", "Said", "youssef.said@outlook.com", "01234567893", "20 Corniche Rd, Alexandria", "M", "1998-11-02", "PATIENT"),
        ("10000000000000000000000000000004", "mariam.abdelrahman", "Mariam", "Abdelrahman", "mariam.a@gmail.com", "01512345674", "9 Talaat Harb St, Downtown, Cairo", "F", "1993-01-30", "PATIENT"),
        ("10000000000000000000000000000005", "omar.elsayed", "Omar", "El-Sayed", "omar.elsayed@gmail.com", "01098765435", "3 Gamal Abdel Nasser St, Mansoura", "M", "2001-05-18", "PATIENT"),
        ("10000000000000000000000000000006", "nour.fathy", "Nour", "Fathy", "nour.fathy@gmail.com", "01187654326", "17 El Geish St, Tanta", "F", "1988-09-09", "PATIENT"),
        # Doctors
        ("10000000000000000000000000000011", "dr.khaled.nour", "Khaled", "Nour", "khaled.nour@clinic.eg", "01011112221", "Heliopolis, Cairo", "M", "1978-02-11", "DOCTOR"),
        ("10000000000000000000000000000012", "dr.hend.zaki", "Hend", "Zaki", "hend.zaki@clinic.eg", "01122223332", "Maadi, Cairo", "F", "1982-06-19", "DOCTOR"),
        ("10000000000000000000000000000013", "dr.mostafa.salem", "Mostafa", "Salem", "mostafa.salem@clinic.eg", "01233334443", "Dokki, Giza", "M", "1975-12-05", "DOCTOR"),
        ("10000000000000000000000000000014", "dr.rania.gaber", "Rania", "Gaber", "rania.gaber@clinic.eg", "01544445554", "Mohandessin, Giza", "F", "1987-04-27", "DOCTOR"),
        # Admin, Staff, Pharmacist, Lab Tech
        ("10000000000000000000000000000021", "sara.farid", "Sara", "Farid", "sara.farid@clinic.eg", "01099998881", "Zamalek, Cairo", "F", "1990-08-15", "ADMIN"),
        ("10000000000000000000000000000022", "mona.kamel", "Mona", "Kamel", "mona.kamel@clinic.eg", "01188887772", "6th of October City, Giza", "F", "1995-10-03", "STAFF"),
        ("10000000000000000000000000000023", "islam.shawky", "Islam", "Shawky", "islam.shawky@clinic.eg", "01277776663", "Shubra, Cairo", "M", "1991-01-21", "PHARMACIST"),
        ("10000000000000000000000000000024", "amr.fahmy", "Amr", "Fahmy", "amr.fahmy@clinic.eg", "01566665554", "Nasr City, Cairo", "M", "1993-03-08", "LAB_TECH"),
    ]
    for uid, username, first, last, email, phone, addr, gender, dob, role in raw:
        u = User.objects.create_user(
            id=make_uuid(uid),
            username=username,
            email=email,
            password=PASSWORD,
            first_name=first,
            last_name=last,
            phone=phone,
            address=addr,
            gender=gender,
            date_of_birth=date.fromisoformat(dob),
            role=role,
            is_email_verified=True,
            is_phone_verified=(role == "PATIENT"),
            is_superuser=(role == "ADMIN"),
        )
        users[username] = u
    print(f"  OK {len(raw)} users (password: {PASSWORD})")
    return users


# ── 7. User Preferences ──
def seed_user_preferences(users):
    from core.models.accounts.models import UserPreference
    prefs = [
        ("ahmed.hassan", "LIGHT", "AR"),
        ("fatma.ibrahim", "DARK", "AR"),
        ("youssef.said", "LIGHT", "EN"),
        ("mariam.abdelrahman", "DARK", "AR"),
        ("omar.elsayed", "LIGHT", "AR"),
        ("nour.fathy", "DARK", "EN"),
        ("dr.khaled.nour", "LIGHT", "EN"),
        ("dr.hend.zaki", "LIGHT", "AR"),
        ("sara.farid", "DARK", "AR"),
    ]
    for uname, theme, lang in prefs:
        UserPreference.objects.update_or_create(user=users[uname], defaults={"theme": theme, "language": lang})
    print(f"  OK {len(prefs)} user preferences")


# ── 8. Emergency Contacts ──
def seed_emergency_contacts(users):
    from core.models.emergency_contacts.models import EmergencyContact
    contacts = {}
    raw = [
        (make_uuid("30000000000000000000000000000001"), "ahmed.hassan", "Mohamed Hassan Ali", "PARENT", "01011122233", "", "mohamed.hassan.ali@gmail.com", "Nasr City, Cairo"),
        (make_uuid("30000000000000000000000000000002"), "fatma.ibrahim", "Ali Ibrahim Saad", "SPOUSE", "01122233344", "01233344455", "", "Al Haram, Giza"),
        (make_uuid("30000000000000000000000000000003"), "youssef.said", "Mahmoud Said Aziz", "PARENT", "01233344456", "", "", "Corniche, Alexandria"),
        (make_uuid("30000000000000000000000000000004"), "mariam.abdelrahman", "Khaled Abdelrahman", "SIBLING", "01544455566", "", "khaled.abdelrahman@gmail.com", "Downtown, Cairo"),
        (make_uuid("30000000000000000000000000000005"), "omar.elsayed", "Tarek El-Sayed", "PARENT", "01099988877", "", "", "Mansoura"),
        (make_uuid("30000000000000000000000000000006"), "nour.fathy", "Hany Fathy", "PARENT", "01188877766", "01099911122", "hany.fathy@gmail.com", "Tanta"),
    ]
    for eid, uname, full_name, rel, phone, alt_phone, email, addr in raw:
        c = EmergencyContact.objects.create(
            id=eid,
            patient=users[uname],
            full_name=full_name,
            relationship=rel,
            phone=phone,
            alternate_phone=alt_phone,
            email=email,
            address=addr,
        )
        contacts[uname] = c

    # Link primary emergency contacts
    for uname in ["ahmed.hassan", "fatma.ibrahim", "youssef.said", "mariam.abdelrahman", "omar.elsayed", "nour.fathy"]:
        u = users[uname]
        u.primary_emergency_contact = contacts[uname]
        u.save()
    print(f"  OK {len(raw)} emergency contacts")


# ── 9. Doctors ──
def seed_doctors(users):
    from core.models.doctors.models import Doctor, Specialty
    from core.models.doctors.models import DoctorAvailability, DoctorPerformanceMetric

    doc_data = [
        (make_uuid("20000000000000000000000000000001"), "dr.khaled.nour", "EG-MED-10023", 18, 500, "Building A, Room 201, Heliopolis Clinic", "Consultant cardiologist with 18 years of experience in interventional cardiology.", [1, 5]),
        (make_uuid("20000000000000000000000000000002"), "dr.hend.zaki", "EG-MED-10456", 12, 350, "Building B, Room 105, Maadi Clinic", "Pediatrician specializing in newborn and childhood care.", [2]),
        (make_uuid("20000000000000000000000000000003"), "dr.mostafa.salem", "EG-MED-10789", 22, 450, "Building A, Room 310, Dokki Clinic", "Orthopedic surgeon focused on sports injuries and joint replacement.", [3]),
        (make_uuid("20000000000000000000000000000004"), "dr.rania.gaber", "EG-MED-11023", 9, 300, "Building C, Room 402, Mohandessin Clinic", "Dermatologist specializing in cosmetic and clinical dermatology.", [4, 6]),
    ]
    for did, uname, lic, exp, fee, loc, bio, spec_ids in doc_data:
        doc = Doctor.objects.create(
            id=did,
            user=users[uname],
            license_number=lic,
            years_of_experience=exp,
            consultation_fee=fee,
            office_location=loc,
            bio=bio,
            is_active=True,
        )
        doc.specialties.set(Specialty.objects.filter(id__in=spec_ids))

    # Availabilities
    avail = [
        ("dr.khaled.nour", 0, "09:00", "14:00"),
        ("dr.khaled.nour", 2, "09:00", "14:00"),
        ("dr.hend.zaki", 1, "10:00", "16:00"),
        ("dr.hend.zaki", 3, "10:00", "16:00"),
        ("dr.mostafa.salem", 4, "08:00", "13:00"),
        ("dr.rania.gaber", 6, "12:00", "18:00"),
    ]
    for uname, wd, st, et in avail:
        doc = Doctor.objects.get(user=users[uname])
        h, mi = map(int, st.split(":"))
        start_t = timezone.now().replace(hour=h, minute=mi, second=0, microsecond=0).time()
        h2, mi2 = map(int, et.split(":"))
        end_t = timezone.now().replace(hour=h2, minute=mi2, second=0, microsecond=0).time()
        DoctorAvailability.objects.create(doctor=doc, weekday=wd, start_time=start_t, end_time=end_t)

    # Performance metrics
    perf = [
        ("dr.khaled.nour", "2026-04-01", "2026-06-30", 120, 105, 10, 4.6, 22),
        ("dr.hend.zaki", "2026-04-01", "2026-06-30", 95, 88, 5, 4.8, 18),
        ("dr.mostafa.salem", "2026-04-01", "2026-06-30", 80, 70, 8, 4.4, 30),
        ("dr.rania.gaber", "2026-04-01", "2026-06-30", 60, 55, 3, 4.7, 20),
    ]
    for uname, ps, pe, total, comp, canc, rating, mins in perf:
        doc = Doctor.objects.get(user=users[uname])
        DoctorPerformanceMetric.objects.create(
            doctor=doc,
            period_start=date.fromisoformat(ps),
            period_end=date.fromisoformat(pe),
            total_appointments=total,
            completed_appointments=comp,
            cancelled_appointments=canc,
            average_rating=rating,
            average_consultation_minutes=mins,
        )
    print(f"  OK {len(doc_data)} doctors + availabilities + performance")


# ── 10. Appointments ──
def seed_appointments(users):
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor

    data = [
        (make_uuid("40000000000000000000000000000001"), "ahmed.hassan", "dr.khaled.nour", "2026-07-10", "09:30", "CONSULTATION", "COMPLETED", "Routine cardiac checkup", ""),
        (make_uuid("40000000000000000000000000000002"), "fatma.ibrahim", "dr.hend.zaki", "2026-07-12", "11:00", "ROUTINE_CHECKUP", "COMPLETED", "Child vaccination follow-up", ""),
        (make_uuid("40000000000000000000000000000003"), "youssef.said", "dr.mostafa.salem", "2026-07-20", "08:30", "CONSULTATION", "CONFIRMED", "Knee pain evaluation", ""),
        (make_uuid("40000000000000000000000000000004"), "mariam.abdelrahman", "dr.rania.gaber", "2026-07-22", "13:00", "FOLLOW_UP", "PENDING", "", ""),
        (make_uuid("40000000000000000000000000000005"), "omar.elsayed", "dr.khaled.nour", "2026-06-15", "10:00", "EMERGENCY", "CANCELLED", "", "Patient rescheduled due to travel"),
        (make_uuid("40000000000000000000000000000006"), "nour.fathy", "dr.hend.zaki", "2026-07-25", "12:30", "CONSULTATION", "PENDING", "", ""),
    ]
    for aid, pname, dname, dt, tm, reason, status, notes, cancel_reason in data:
        hh, mm = map(int, tm.split(":"))
        apt_time = timezone.now().replace(hour=hh, minute=mm, second=0, microsecond=0).time()
        Appointment.objects.create(
            id=aid,
            patient=users[pname],
            doctor=Doctor.objects.get(user=users[dname]),
            appointment_date=date.fromisoformat(dt),
            appointment_time=apt_time,
            reason=reason,
            status=status,
            notes=notes,
            cancellation_reason=cancel_reason,
        )
    print(f"  OK {len(data)} appointments")


# ── 11. Medical Records ──
def seed_medical_records(users):
    from core.models.medical_records.models import PatientRecord, TestResult
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor

    records_data = [
        (make_uuid("50000000000000000000000000000001"), "ahmed.hassan", "dr.khaled.nour", "40000000000000000000000000000001", "2026-07-10", "Mild hypertension, no prior surgeries", "Stage 1 Hypertension", "Lifestyle modification and low-dose Concor", "Follow up in 3 months"),
        (make_uuid("50000000000000000000000000000002"), "fatma.ibrahim", "dr.hend.zaki", "40000000000000000000000000000002", "2026-07-12", "Up to date on vaccinations", "Healthy - routine visit", "Continue standard vaccination schedule", "No concerns"),
    ]
    for rid, pname, dname, apt_hex, rd, hist, diag, plan, notes in records_data:
        rec = PatientRecord.objects.create(
            id=rid,
            patient=users[pname],
            doctor=Doctor.objects.get(user=users[dname]),
            appointment=Appointment.objects.get(id=make_uuid(apt_hex)),
            record_date=date.fromisoformat(rd),
            medical_history=hist,
            diagnosis=diag,
            treatment_plan=plan,
            notes=notes,
        )

    TestResult.objects.create(
        record=PatientRecord.objects.get(id=make_uuid("50000000000000000000000000000001")),
        test_name="Blood Pressure Panel",
        result_summary="BP 145/92, borderline elevated cholesterol",
        result_file="/files/results/bp_panel_001.pdf",
    )
    TestResult.objects.create(
        record=PatientRecord.objects.get(id=make_uuid("50000000000000000000000000000001")),
        test_name="ECG",
        result_summary="Normal sinus rhythm, no ischemic changes",
        result_file="/files/results/ecg_001.pdf",
    )
    print(f"  OK {len(records_data)} medical records + test results")


# ── 12. Prescriptions ──
def seed_prescriptions(users):
    from core.models.prescriptions.models import Prescription, PrescriptionItem, PrescriptionRefill
    from core.models.doctors.models import Doctor
    from core.models.medical_records.models import PatientRecord
    from core.models.pharmacy.models import Medicine

    med_concor = Medicine.objects.get(id=make_uuid("70000000000000000000000000000001"))
    med_panadol = Medicine.objects.get(id=make_uuid("70000000000000000000000000000002"))

    rx_data = [
        (make_uuid("60000000000000000000000000000001"), "ahmed.hassan", "dr.khaled.nour", "50000000000000000000000000000001", "2026-07-10", "ACTIVE", "Blood pressure management", [(med_concor, "5mg once daily", 90, 90, "Take every morning with water")]),
        (make_uuid("60000000000000000000000000000002"), "fatma.ibrahim", "dr.hend.zaki", "50000000000000000000000000000002", "2026-07-12", "COMPLETED", "Fever management, short course", [(med_panadol, "500mg every 6 hours as needed", 5, 20, "Take after meals if fever persists")]),
    ]
    for pid, pname, dname, rec_hex, dp, status, notes, items in rx_data:
        presc = Prescription.objects.create(
            id=pid,
            patient=users[pname],
            doctor=Doctor.objects.get(user=users[dname]),
            medical_record=PatientRecord.objects.get(id=make_uuid(rec_hex)),
            date_prescribed=date.fromisoformat(dp),
            status=status,
            notes=notes,
        )
        for med, dosage, dur, qty, instr in items:
            PrescriptionItem.objects.create(
                prescription=presc,
                medicine=med,
                dosage=dosage,
                duration_days=dur,
                quantity=qty,
                instructions=instr,
            )

    # PrescriptionRefill
    presc1 = Prescription.objects.get(id=make_uuid("60000000000000000000000000000001"))
    item1 = presc1.items.first()
    PrescriptionRefill.objects.create(prescription_item=item1, status="FULFILLED", fulfilled_at=timezone.now() - timedelta(days=4))
    PrescriptionRefill.objects.create(prescription_item=item1, status="REQUESTED")
    print(f"  OK {len(rx_data)} prescriptions + items + refills")


# ── 13. Pharmacy Orders ──
def seed_pharmacy_orders(users):
    from core.models.pharmacy.models import PharmacyOrder, PharmacyOrderItem, Medicine
    from core.models.prescriptions.models import Prescription

    order_data = [
        (make_uuid("80000000000000000000000000000001"), "ahmed.hassan", "60000000000000000000000000000001", "DELIVERED", 3, [(make_uuid("70000000000000000000000000000001"), 90, 65.00)]),
        (make_uuid("80000000000000000000000000000002"), "fatma.ibrahim", "60000000000000000000000000000002", "READY_FOR_PICKUP", 1, [(make_uuid("70000000000000000000000000000002"), 20, 15.50)]),
    ]
    for oid, pname, rx_hex, status, days_ago, items in order_data:
        order = PharmacyOrder.objects.create(
            id=oid,
            patient=users[pname],
            prescription=Prescription.objects.get(id=make_uuid(rx_hex)),
            status=status,
            ordered_at=timezone.now() - timedelta(days=days_ago),
            fulfilled_at=(timezone.now() - timedelta(days=1) if status == "DELIVERED" else None),
        )
        for mid, qty, price in items:
            PharmacyOrderItem.objects.create(
                order=order,
                medicine=Medicine.objects.get(id=mid),
                quantity=qty,
                unit_price=price,
            )
    print(f"  OK {len(order_data)} pharmacy orders + items")


# ── 14. Lab Bookings ──
def seed_lab_bookings(users):
    from core.models.laboratory.models import LabTest, LabTestBooking, LabTestResult
    from core.models.doctors.models import Doctor

    booking_data = [
        (make_uuid("a0000000000000000000000000000001"), "ahmed.hassan", "90000000000000000000000000000003", "2026-07-11", "08:00", "RESULT_READY"),
        (make_uuid("a0000000000000000000000000000002"), "youssef.said", "90000000000000000000000000000001", "2026-07-21", "09:00", "BOOKED"),
    ]
    for bid, pname, tid, sd, tm, status in booking_data:
        hh, mm = map(int, tm.split(":"))
        btime = timezone.now().replace(hour=hh, minute=mm, second=0).time()
        booking = LabTestBooking.objects.create(
            id=bid,
            patient=users[pname],
            lab_test=LabTest.objects.get(id=make_uuid(tid)),
            scheduled_date=date.fromisoformat(sd),
            scheduled_time=btime,
            status=status,
        )

    # Lab test result for the first booking
    booking1 = LabTestBooking.objects.get(id=make_uuid("a0000000000000000000000000000001"))
    LabTestResult.objects.create(
        booking=booking1,
        result_summary="LDL slightly elevated, HDL within normal range",
        result_file="/files/results/lipid_001.pdf",
        reviewed_by=Doctor.objects.get(user=users["dr.khaled.nour"]),
    )
    print(f"  OK {len(booking_data)} lab bookings + results")


# ── 15. Invoices ──
def seed_invoices(users):
    from core.models.billing.models import Invoice, InvoiceItem
    from core.models.appointments.models import Appointment

    inv_data = [
        (make_uuid("b0000000000000000000000000000001"), "INV-2026-0001", "ahmed.hassan", "40000000000000000000000000000001", "2026-07-10", "PAID", 500.00, 70.00, 0.00, 570.00, [("CONSULTATION", "Cardiology consultation", 1, 500.00, 500.00)]),
        (make_uuid("b0000000000000000000000000000002"), "INV-2026-0002", "fatma.ibrahim", "40000000000000000000000000000002", "2026-07-12", "UNPAID", 350.00, 49.00, 20.00, 379.00, [("CONSULTATION", "Pediatric consultation", 1, 350.00, 350.00)]),
    ]
    for iid, inv_num, pname, apt_hex, idate, status, sub, tax, disc, total, items in inv_data:
        inv = Invoice.objects.create(
            id=iid,
            invoice_number=inv_num,
            patient=users[pname],
            appointment=Appointment.objects.get(id=make_uuid(apt_hex)),
            issue_date=date.fromisoformat(idate),
            due_date=date.fromisoformat(idate) + timedelta(days=14),
            status=status,
            subtotal=sub,
            tax_amount=tax,
            discount_amount=disc,
            total_amount=total,
        )
        for itype, desc, qty, up, lt in items:
            InvoiceItem.objects.create(invoice=inv, item_type=itype, description=desc, quantity=qty, unit_price=up, line_total=lt)
    print(f"  OK {len(inv_data)} invoices + items")


# ── 16. Insurance Policies ──
def seed_insurance_policies(users):
    from core.models.insurance.models import HealthInsurance, InsuranceProvider

    policy_data = [
        (make_uuid("c0000000000000000000000000000001"), "ahmed.hassan", 1, "MISR-POL-33421", "GRP-100", "Covers consultations and lab tests up to 80%", 80.00, "2026-01-01", "2026-12-31", "VERIFIED"),
        (make_uuid("c0000000000000000000000000000002"), "fatma.ibrahim", 2, "ALZ-POL-88213", "GRP-220", "Covers consultations up to 70%", 70.00, "2026-02-01", "2027-01-31", "VERIFIED"),
    ]
    for hid, pname, pid, policy, group_num, details, pct, vf, vt, vs in policy_data:
        HealthInsurance.objects.create(
            id=hid,
            patient=users[pname],
            provider=InsuranceProvider.objects.get(id=pid),
            policy_number=policy,
            group_number=group_num,
            coverage_details=details,
            coverage_percentage=pct,
            valid_from=date.fromisoformat(vf),
            valid_to=date.fromisoformat(vt),
            verification_status=vs,
        )
    print(f"  OK {len(policy_data)} insurance policies")


# ── 17. Insurance Claims ──
def seed_insurance_claims():
    from core.models.insurance.models import HealthInsurance, InsuranceClaim
    from core.models.billing.models import Invoice

    claim_data = [
        (make_uuid("d0000000000000000000000000000001"), "c0000000000000000000000000000001", "b0000000000000000000000000000001", 456.00, 456.00, "PAID", 10, 5, "Approved in full"),
        (make_uuid("d0000000000000000000000000000002"), "c0000000000000000000000000000002", "b0000000000000000000000000000002", 265.30, None, "UNDER_REVIEW", 2, None, "Awaiting provider response"),
    ]
    for cid, hid, iid, amount, approved, status, sub_days, res_days, notes in claim_data:
        kwargs = {
            "id": cid,
            "insurance": HealthInsurance.objects.get(id=make_uuid(hid)),
            "invoice": Invoice.objects.get(id=make_uuid(iid)),
            "claim_amount": amount,
            "approved_amount": approved,
            "status": status,
            "submitted_at": timezone.now() - timedelta(days=sub_days),
            "notes": notes,
        }
        if res_days:
            kwargs["resolved_at"] = timezone.now() - timedelta(days=res_days)
        InsuranceClaim.objects.create(**kwargs)
    print(f"  OK {len(claim_data)} insurance claims")


# ── 18. Payments ──
def seed_payments():
    from core.models.payments.models import Payment
    from core.models.billing.models import Invoice
    from core.models.insurance.models import InsuranceClaim

    inv1 = Invoice.objects.get(id=make_uuid("b0000000000000000000000000000001"))
    inv2 = Invoice.objects.get(id=make_uuid("b0000000000000000000000000000002"))
    claim1 = InsuranceClaim.objects.get(id=make_uuid("d0000000000000000000000000000001"))

    Payment.objects.create(
        id=make_uuid("e0000000000000000000000000000001"),
        invoice=inv1,
        patient=inv1.patient,
        insurance_claim=claim1,
        method="INSURANCE",
        status="SUCCESS",
        amount=456.00,
        transaction_reference="TXN-EG-88213",
        gateway_response={"status": "approved", "gateway": "misr_insurance"},
        paid_at=timezone.now() - timedelta(days=5),
    )
    Payment.objects.create(
        id=make_uuid("e0000000000000000000000000000002"),
        invoice=inv1,
        patient=inv1.patient,
        method="CREDIT_CARD",
        status="SUCCESS",
        amount=114.00,
        transaction_reference="TXN-EG-44902",
        gateway_response={"status": "success", "gateway": "fawry"},
        paid_at=timezone.now() - timedelta(days=5),
    )
    Payment.objects.create(
        id=make_uuid("e0000000000000000000000000000003"),
        invoice=inv2,
        patient=inv2.patient,
        method="CASH",
        status="PENDING",
        amount=379.00,
        transaction_reference="TXN-EG-PENDING-001",
    )
    print(f"  OK 3 payments")


# ── 19. Notifications ──
def seed_notifications(users):
    from core.models.notifications.models import Notification

    Notification.objects.create(
        id=make_uuid("f0000000000000000000000000000001"),
        recipient=users["ahmed.hassan"],
        notification_type="APPOINTMENT_REMINDER",
        channel="SMS",
        title="Appointment Reminder",
        message="You have an appointment with Dr. Khaled Nour tomorrow at 09:30.",
        scheduled_for=datetime(2026, 7, 9, 9, 30, tzinfo=timezone.utc),
        sent_at=datetime(2026, 7, 9, 9, 30, tzinfo=timezone.utc),
    )
    Notification.objects.create(
        id=make_uuid("f0000000000000000000000000000002"),
        recipient=users["ahmed.hassan"],
        notification_type="TEST_RESULT",
        channel="IN_APP",
        title="Lab Results Ready",
        message="Your Lipid Profile test results are now available.",
        is_read=True,
    )
    Notification.objects.create(
        id=make_uuid("f0000000000000000000000000000003"),
        recipient=users["fatma.ibrahim"],
        notification_type="BILLING",
        channel="EMAIL",
        title="Invoice Due",
        message="Invoice INV-2026-0002 is due on 2026-07-26.",
    )
    print(f"  OK 3 notifications")


# ── 20. Feedback ──
def seed_feedback(users):
    from core.models.feedback.models import Feedback
    from core.models.appointments.models import Appointment
    from core.models.doctors.models import Doctor

    Feedback.objects.create(
        id=make_uuid("11000000000000000000000000000001"),
        patient=users["ahmed.hassan"],
        target_type="DOCTOR",
        doctor=Doctor.objects.get(user=users["dr.khaled.nour"]),
        appointment=Appointment.objects.get(id=make_uuid("40000000000000000000000000000001")),
        rating=5,
        comment="Dr. Khaled was very thorough and explained everything clearly.",
        is_anonymous=False,
    )
    Feedback.objects.create(
        id=make_uuid("11000000000000000000000000000002"),
        patient=users["fatma.ibrahim"],
        target_type="DOCTOR",
        doctor=Doctor.objects.get(user=users["dr.hend.zaki"]),
        appointment=Appointment.objects.get(id=make_uuid("40000000000000000000000000000002")),
        rating=4,
        comment="Great with kids, though the wait time was a bit long.",
        is_anonymous=True,
    )
    print(f"  OK 2 feedback entries")


# ── 21. Reports ──
def seed_reports(users):
    from core.models.core.models import GeneratedReport

    GeneratedReport.objects.create(
        id=make_uuid("12000000000000000000000000000001"),
        report_type="FINANCIALS",
        file_format="PDF",
        period_start=date(2026, 4, 1),
        period_end=date(2026, 6, 30),
        file="/files/reports/financials_q2_2026.pdf",
        generated_by=users["sara.farid"],
    )
    GeneratedReport.objects.create(
        id=make_uuid("12000000000000000000000000000002"),
        report_type="PATIENT_ADMISSIONS",
        file_format="XLSX",
        period_start=date(2026, 6, 1),
        period_end=date(2026, 6, 30),
        file="/files/reports/admissions_june_2026.xlsx",
        generated_by=users["sara.farid"],
    )
    print(f"  OK 2 generated reports")


# ── 22. Analytics Snapshots ──
def seed_analytics_snapshots():
    from core.models.core.models import AnalyticsSnapshot

    AnalyticsSnapshot.objects.create(
        metric_type="APPOINTMENT_TRENDS",
        period_start=date(2026, 6, 1),
        period_end=date(2026, 6, 30),
        data={"total_appointments": 355, "completed": 318, "cancelled": 25, "no_show": 12, "top_specialty": "Cardiology"},
    )
    AnalyticsSnapshot.objects.create(
        metric_type="PATIENT_DEMOGRAPHICS",
        period_start=date(2026, 6, 1),
        period_end=date(2026, 6, 30),
        data={"total_patients": 1240, "male": 590, "female": 650, "avg_age": 34.5, "top_cities": ["Cairo", "Giza", "Alexandria"]},
    )
    print(f"  OK 2 analytics snapshots")


# ── 23. Password Reset OTPs ──
def seed_password_reset_otps(users):
    from core.models.accounts.models import PasswordResetOTP

    PasswordResetOTP.objects.create(
        user=users["ahmed.hassan"],
        code="482913",
        delivery_method="SMS",
        is_used=True,
        expires_at=timezone.now() - timedelta(days=2) + timedelta(minutes=10),
    )
    PasswordResetOTP.objects.create(
        user=users["mariam.abdelrahman"],
        code="117260",
        delivery_method="EMAIL",
        expires_at=timezone.now() + timedelta(minutes=10),
    )
    print(f"  OK 2 password reset OTPs")


if __name__ == "__main__":
    main()