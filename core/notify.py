from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


def create_notification(recipient, notification_type, title, message, channel="IN_APP"):
    from core.models.notifications.models import Notification
    Notification.objects.create(
        recipient=recipient,
        notification_type=notification_type,
        channel=channel,
        title=title,
        message=message,
        sent_at=timezone.now(),
    )


def notify_appointment_booked(appointment):
    from core.telegram import send_telegram
    msg = f"Your appointment with Dr. {appointment.doctor.user.get_full_name()} on {appointment.appointment_date} at {appointment.appointment_time} has been booked."
    create_notification(appointment.patient, "APPOINTMENT_REMINDER", "Appointment Confirmed", msg)
    send_telegram(f"📅 Appointment booked: {appointment.patient.email} with Dr. {appointment.doctor.user.get_full_name()} on {appointment.appointment_date} at {appointment.appointment_time}")


def notify_appointment_status_changed(appointment):
    from core.telegram import send_telegram
    msg = f"Your appointment with Dr. {appointment.doctor.user.get_full_name()} on {appointment.appointment_date} is now {appointment.get_status_display()}."
    create_notification(appointment.patient, "APPOINTMENT_REMINDER", f"Appointment {appointment.get_status_display()}", msg)
    send_telegram(f"📅 Appointment {appointment.get_status_display()}: {appointment.patient.email} with Dr. {appointment.doctor.user.get_full_name()} on {appointment.appointment_date} at {appointment.appointment_time}")


def notify_test_result_available(booking):
    from core.telegram import send_telegram
    msg = f"Your test result for {booking.lab_test.name} is now available."
    create_notification(booking.patient, "TEST_RESULT", "Test Result Available", msg)
    send_telegram(f"🧪 Test result available: {booking.patient.email} — {booking.lab_test.name}")


def notify_order_placed(order):
    from core.telegram import send_telegram
    msg = f"Your pharmacy order has been placed and is being processed."
    create_notification(order.patient, "MEDICATION_REFILL", "Order Placed", msg)
    send_telegram(f"💊 Pharmacy order placed: {order.patient.email} — #{order.id}")


def notify_invoice_generated(invoice):
    from core.telegram import send_telegram
    msg = f"Invoice #{invoice.invoice_number} for E£{invoice.total_amount} has been generated. Due: {invoice.due_date}."
    create_notification(invoice.patient, "BILLING", "New Invoice", msg)
    send_telegram(f"🧾 Invoice #{invoice.invoice_number} generated: {invoice.patient.email} — E£{invoice.total_amount}. Due: {invoice.due_date}")
