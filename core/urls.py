from django.urls import path
from .views import auth, pages, admin as admin_views

urlpatterns = [
    # API auth endpoints (JSON)
    path("api/auth/register/", auth.register, name="auth_register"),
    path("api/auth/login/", auth.login_view, name="auth_login"),
    path("api/auth/logout/", auth.logout_view, name="auth_logout"),
    path("api/auth/me/", auth.me, name="auth_me"),

    # Page-based auth (HTML templates)
    path("login/", pages.login_page, name="account_login"),
    path("register/", pages.register_page, name="account_register"),
    path("logout/", pages.logout_page, name="account_logout"),
    path("forgot-password/", pages.forgot_password, name="account_forgot"),
    path("forgot-password/verify/", pages.forgot_password_verify, name="account_forgot_verify"),

    # Application pages
    path("", pages.landing_page, name="landing_page"),
    path("dashboard/", pages.dashboard, name="dashboard"),
    path("doctors/", pages.doctor_list, name="doctor_list"),
    path("doctors/<uuid:doctor_id>/", pages.doctor_detail, name="doctor_detail"),
    path("appointments/", pages.appointment_list, name="appointment_list"),
    path("appointments/book/", pages.book_appointment, name="book_appointment"),
    path("appointments/<uuid:appointment_id>/cancel/", pages.cancel_appointment, name="cancel_appointment"),
    path("pharmacy/", pages.medicine_list, name="medicine_list"),
    path("pharmacy/order/new/", pages.create_order, name="create_order"),
    path("pharmacy/order/<uuid:order_id>/", pages.order_detail, name="order_detail"),
    path("pharmacy/orders/", pages.order_history, name="order_history"),
    path("billing/", pages.invoice_list, name="invoice_list"),
    path("billing/<uuid:invoice_id>/", pages.invoice_detail, name="invoice_detail"),
    path("laboratory/", pages.lab_test_list, name="lab_test_list"),
    path("laboratory/book/", pages.lab_book_test, name="lab_book_test"),
    path("laboratory/history/", pages.lab_booking_history, name="lab_booking_history"),
    path("laboratory/results/<uuid:booking_id>/", pages.lab_result_detail, name="lab_result_detail"),
    path("medical-records/", pages.medical_record_list, name="medical_record_list"),
    path("prescriptions/", pages.prescription_list, name="prescription_list"),
    path("prescriptions/refill/request/", pages.prescription_refill_request, name="prescription_refill_request"),
    path("notifications/", pages.notification_list, name="notification_list"),
    path("profile/", pages.profile, name="profile"),
    path("profile/password/", pages.password_change, name="password_change"),
    path("timeline/", pages.patient_timeline, name="patient_timeline"),
    path("feedback/", pages.submit_feedback, name="submit_feedback"),
    path("insurance/", pages.insurance_list, name="insurance_list"),
    path("insurance/policies/add/", pages.insurance_policy_add, name="insurance_policy_add"),
    path("insurance/claims/new/", pages.insurance_claim_new, name="insurance_claim_new"),
    path("search/", pages.global_search, name="global_search"),
    path("chat-proxy/", pages.chat_proxy, name="chat_proxy"),

    # Doctor UI
    path("doctor/dashboard/", pages.doctor_dashboard, name="doctor_dashboard"),
    path("doctor/appointments/", pages.doctor_appointments, name="doctor_appointments"),
    path("doctor/availability/", pages.doctor_availability, name="doctor_availability"),
    path("doctor/prescriptions/write/", pages.doctor_write_prescription, name="doctor_write_prescription"),

    # Pharmacist UI
    path("pharmacist/", pages.pharmacist_dashboard, name="pharmacist_dashboard"),

    # Lab Tech UI
    path("labtech/", pages.labtech_dashboard, name="labtech_dashboard"),

    # Admin pages
    path("admindashboard/", admin_views.dashboard, name="admin_dashboard"),
    path("admindashboard/reports/", admin_views.reports, name="admin_reports"),
    path("admindashboard/users/", admin_views.user_list, name="admin_users"),
    path("admindashboard/users/create/", admin_views.user_create, name="admin_user_create"),
    path("admindashboard/appointments/", admin_views.appointment_list, name="admin_appointments"),
    path("admindashboard/appointments/create/", admin_views.appointment_create, name="admin_appointment_create"),
    path("admindashboard/appointments/<uuid:appointment_id>/edit/", admin_views.appointment_edit, name="admin_appointment_edit"),
    path("admindashboard/doctors/", admin_views.doctor_list, name="admin_doctors"),
    path("admindashboard/doctors/create/", admin_views.doctor_create, name="admin_doctor_create"),
    path("admindashboard/doctors/<uuid:doctor_id>/edit/", admin_views.doctor_edit, name="admin_doctor_edit"),
    path("admindashboard/medicines/", admin_views.medicine_list, name="admin_medicines"),
    path("admindashboard/medicines/create/", admin_views.medicine_create, name="admin_medicine_create"),
    path("admindashboard/medicines/<uuid:medicine_id>/edit/", admin_views.medicine_edit, name="admin_medicine_edit"),
    path("admindashboard/invoices/", admin_views.invoice_list, name="admin_invoices"),
    path("admindashboard/lab-tests/", admin_views.labtest_list, name="admin_labtests"),
    path("admindashboard/lab-tests/create/", admin_views.labtest_create, name="admin_labtest_create"),
    path("admindashboard/lab-tests/<uuid:test_id>/edit/", admin_views.labtest_edit, name="admin_labtest_edit"),
    path("admindashboard/pharmacy-orders/", admin_views.pharmacy_order_list, name="admin_pharmacy_orders"),
    path("admindashboard/feedback/", admin_views.feedback_list, name="admin_feedback"),
    path("admindashboard/lab-bookings/", admin_views.lab_booking_list, name="admin_lab_bookings"),
    path("admindashboard/prescriptions/", admin_views.admin_prescription_list, name="admin_prescriptions"),
    path("admindashboard/refills/", admin_views.admin_refill_list, name="admin_refills"),
    path("admindashboard/medical-records/", admin_views.admin_medical_record_list, name="admin_medical_records"),
    path("admindashboard/notifications/", admin_views.admin_notification_list, name="admin_notifications"),
    path("admindashboard/health-tips/", admin_views.admin_health_tip_list, name="admin_health_tips"),
    path("admindashboard/insurance/", admin_views.admin_insurance_provider_list, name="admin_insurance"),
    path("admindashboard/insurance/policies/", admin_views.admin_insurance_policy_list, name="admin_insurance_policies"),
    path("admindashboard/insurance/claims/", admin_views.admin_insurance_claim_list, name="admin_insurance_claims"),
]
