import asyncio
import uuid
from datetime import date, time, timedelta
from decimal import Decimal
from unittest.mock import patch

import httpx
from django.test import TransactionTestCase
from django.utils import timezone

from gotrue.errors import AuthApiError


def _supabase_down():
    """Mock client that fails every Supabase call (drives local fallbacks)."""
    client = object.__new__(type("FakeClient", (), {}))
    import unittest.mock as um

    client.auth = um.MagicMock()
    client.auth.sign_in_with_password.side_effect = AuthApiError("network down", 400, "bad_request")
    client.auth.sign_up.side_effect = AuthApiError("network down", 400, "bad_request")
    client.auth.reset_password_for_email.side_effect = AuthApiError("network down", 400, "bad_request")
    return client


class QARegressionTests(TransactionTestCase):
    def setUp(self):
        from django.contrib.auth import get_user_model

        from core.models.accounts.models import UserPreference
        from core.models.billing.models import Invoice
        from core.models.doctors.models import Doctor, DoctorAvailability
        from core.models.laboratory.models import LabTest
        from core.models.pharmacy.models import Medicine

        User = get_user_model()

        def make_user(email, role, username=None):
            u = User.objects.create_user(
                username=username or email.split("@")[0] + str(uuid.uuid4().hex[:6]),
                email=email,
                password="test-pass-123",
                phone=email.split("@")[0].replace(".", "")[:15] + str(uuid.uuid4().hex[:2]),
                first_name="Test",
                last_name="User",
            )
            u.role = role
            u.save(update_fields=["role"])
            UserPreference.objects.get_or_create(user=u)
            return u

        self.patient = make_user("patient.qa@test.local", "PATIENT")
        self.doctor_user = make_user("doctor.qa@test.local", "DOCTOR")
        self.admin = make_user("admin.qa@test.local", "ADMIN")
        self.pharmacist = make_user("pharmacist.qa@test.local", "PHARMACIST")
        self.labtech = make_user("labtech.qa@test.local", "LAB_TECH")

        self.doctor = Doctor.objects.create(
            user=self.doctor_user,
            license_number=f"LIC-{uuid.uuid4().hex[:8]}",
            years_of_experience=5,
            consultation_fee=Decimal("100.00"),
        )
        for wd in range(7):
            DoctorAvailability.objects.create(
                doctor=self.doctor, weekday=wd, start_time=time(8, 0), end_time=time(17, 0),
            )

        self.invoice = Invoice.objects.create(
            patient=self.patient,
            invoice_number=f"TST-{uuid.uuid4().hex[:10]}",
            due_date=date.today() + timedelta(days=30),
            total_amount=Decimal("570.00"),
        )
        self.medicine = Medicine.objects.create(
            name=f"TestMed-{uuid.uuid4().hex[:6]}",
            price=Decimal("10.00"),
            stock_quantity=100,
        )
        self.labtest = LabTest.objects.create(
            name=f"TestLab-{uuid.uuid4().hex[:6]}",
            price=Decimal("50.00"),
        )

        from api.deps import create_local_token

        self.h = {
            "patient": {"Authorization": f"Bearer {create_local_token(self.patient)}"},
            "doctor": {"Authorization": f"Bearer {create_local_token(self.doctor_user)}"},
            "admin": {"Authorization": f"Bearer {create_local_token(self.admin)}"},
            "pharmacist": {"Authorization": f"Bearer {create_local_token(self.pharmacist)}"},
            "labtech": {"Authorization": f"Bearer {create_local_token(self.labtech)}"},
        }

        import api.main  # noqa: F401  (django.setup + route registration)
        from api.main import app

        self._app = app
        self._tg1 = patch("core.telegram.send_telegram", return_value=True)
        self._tg2 = patch("api.routers.auth.send_telegram", return_value=True)
        self._tg1.start()
        self._tg2.start()

    def tearDown(self):
        self._tg1.stop()
        self._tg2.stop()

    def api(self, method, url, **kwargs):
        """Run a request via the ASGI app so status-code behaviour is exercised."""
        transport = httpx.ASGITransport(app=self._app)

        async def _send():
            async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
                return await client.request(method, url, **kwargs)

        return asyncio.run(_send())

    # ── Auth ──
    def test_local_token_auth_works(self):
        import jwt as pyjwt
        from django.conf import settings
        from django.contrib.auth import get_user_model as gum

        u = gum().objects.get(email="patient.qa@test.local")
        tok = self.h["patient"]["Authorization"].split(" ")[1]
        payload = pyjwt.decode(tok, settings.SECRET_KEY, algorithms=["HS256"])
        self.assertEqual(payload["sub"], str(u.id), "token sub mismatch")
        found = gum().objects.get(id=payload["sub"])
        self.assertEqual(found.email, u.email)
        r = self.api("GET", "/doctors", headers={"Authorization": f"Bearer {tok}"})
        self.assertEqual(r.status_code, 200, f"endpoint: {r.status_code} {r.text[:200]}")

    def test_login_wrong_password_401(self):
        with patch("api.routers.auth.get_supabase", return_value=_supabase_down()):
            r = self.api("POST","/auth/login", json={"email": "patient.qa@test.local", "password": "nope"})
        self.assertEqual(r.status_code, 401)

    def test_login_local_fallback_200(self):
        with patch("api.routers.auth.get_supabase", return_value=_supabase_down()):
            r = self.api("POST","/auth/login", json={"email": "patient.qa@test.local", "password": "test-pass-123"})
        self.assertEqual(r.status_code, 200)
        self.assertIn("access_token", r.json()["session"])

    def test_register_invalid_email_422(self):
        with patch("api.routers.auth.get_supabase", return_value=_supabase_down()):
            r = self.api("POST","/auth/register", json={"email": "not-an-email", "password": "12345678"})
        self.assertEqual(r.status_code, 422)

    # ── Appointments ──
    def _book_payload(self, on=date.today() + timedelta(days=30), at="09:00"):
        return {
            "doctor_id": str(self.doctor.id),
            "appointment_date": on.isoformat(),
            "appointment_time": at,
            "reason": "CONSULTATION",
        }

    def test_doctor_cannot_book_403(self):
        r = self.api("POST","/appointments", json=self._book_payload(), headers=self.h["doctor"])
        self.assertEqual(r.status_code, 403)

    def test_non_uuid_ids_never_500(self):
        r = self.api("POST",
            "/appointments",
            json={"doctor_id": "not-a-uuid", "appointment_date": (date.today() + timedelta(days=30)).isoformat(),
                  "appointment_time": "09:00"},
            headers=self.h["patient"],
        )
        self.assertNotEqual(r.status_code, 500)
        r = self.api("GET","/doctors/not-a-uuid", headers=self.h["patient"])
        self.assertNotEqual(r.status_code, 500)

    def test_duplicate_cancel_rebook(self):
        payload = self._book_payload()
        r = self.api("POST","/appointments", json=payload, headers=self.h["patient"])
        self.assertEqual(r.status_code, 201)
        appt_id = r.json()["id"]

        r = self.api("POST","/appointments", json=payload, headers=self.h["patient"])
        self.assertEqual(r.status_code, 409)

        r = self.api("PATCH",f"/appointments/{appt_id}/cancel", json={"reason": "changed my mind"},
                              headers=self.h["patient"])
        self.assertEqual(r.status_code, 200)

        r = self.api("POST","/appointments", json=payload, headers=self.h["patient"])
        self.assertEqual(r.status_code, 201, r.text)

    # ── Payments ──
    def _pay(self, amount, method="CARD"):
        return self.api("POST",
            f"/payments/invoices/{self.invoice.id}/pay",
            json={"invoice_id": str(self.invoice.id), "method": method, "amount": amount},
            headers=self.h["patient"],
        )

    def test_payment_negative_amount_422(self):
        self.assertEqual(self._pay(-50).status_code, 422)

    def test_payment_invalid_method_400(self):
        self.assertEqual(self._pay(50, method="BITCOIN").status_code, 400)

    def test_payment_over_amount_400(self):
        self.assertEqual(self._pay(999999).status_code, 400)

    # ── Pharmacy ──
    def test_pharmacy_empty_order_422(self):
        r = self.api("POST","/pharmacy/orders", json={"items": []}, headers=self.h["patient"])
        self.assertEqual(r.status_code, 422)

    def test_pharmacy_bad_medicine_id_404(self):
        r = self.api("POST","/pharmacy/orders", json={"items": [{"medicine_id": "bogus", "quantity": 1}]},
                             headers=self.h["patient"])
        self.assertEqual(r.status_code, 404)

    def test_pharmacy_invalid_status_400(self):
        r = self.api("PATCH","/pharmacy/orders/some-order/status", json={"status": "TELEPORTED"},
                              headers=self.h["pharmacist"])
        self.assertEqual(r.status_code, 400, f"got {r.status_code}: {r.text}")

    # ── Admin ──
    def test_admin_lab_tests_200(self):
        r = self.api("GET","/admin/lab-tests", headers=self.h["admin"])
        self.assertEqual(r.status_code, 200)

    def test_admin_feedback_bad_rating_400(self):
        r = self.api("GET","/admin/feedback?rating=abc", headers=self.h["admin"])
        self.assertEqual(r.status_code, 400)

    def test_admin_users_bad_page_400(self):
        r = self.api("GET","/admin/users?page=0", headers=self.h["admin"])
        self.assertEqual(r.status_code, 400)

    def test_admin_users_paginated_200(self):
        r = self.api("GET","/admin/users?page=1&limit=5", headers=self.h["admin"])
        self.assertEqual(r.status_code, 200)
        self.assertLessEqual(len(r.json()), 5)

    # ── Laboratory ──
    def test_lab_booking_and_result_release(self):
        future = (date.today() + timedelta(days=30)).isoformat()
        r = self.api("POST","/laboratory/bookings",
                             json={"lab_test_id": str(self.labtest.id), "scheduled_date": future,
                                   "scheduled_time": "10:00"},
                             headers=self.h["patient"])
        self.assertEqual(r.status_code, 201, r.text)
        booking_id = r.json()["id"]

        r = self.api("PATCH",f"/laboratory/bookings/{booking_id}/status", json={"action": "collect_sample"},
                              headers=self.h["labtech"])
        self.assertEqual(r.status_code, 200)

        r = self.api("POST",f"/laboratory/bookings/{booking_id}/release-result",
                             json={"result_summary": "All clear", "result_details": "regression"},
                             headers=self.h["labtech"])
        self.assertEqual(r.status_code, 200, r.text)

    def test_admin_reports_avg_rating_float(self):
        from core.models.feedback.models import Feedback

        Feedback.objects.create(patient=self.patient, target_type="SERVICE", rating=3, comment="ok")
        Feedback.objects.create(patient=self.patient, target_type="SERVICE", rating=5, comment="great")
        r = self.api("GET", "/admin/reports", headers=self.h["admin"])
        self.assertEqual(r.status_code, 200)
        self.assertIn("avg_rating", r.json())
        self.assertEqual(r.json()["avg_rating"], 4.0, f"expected float avg, got {r.json()['avg_rating']}")

