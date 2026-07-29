import uuid
from django.conf import settings
from django.db import models


class Notification(models.Model):
    """
    Notifications: reminders/updates about appointments, test results,
    medication refills, and general health alerts. Also feeds the
    Dashboard "Notifications" section.
    """

    class NotificationType(models.TextChoices):
        APPOINTMENT_REMINDER = "APPOINTMENT_REMINDER", "Appointment Reminder"
        TEST_RESULT = "TEST_RESULT", "Test Result"
        MEDICATION_REFILL = "MEDICATION_REFILL", "Medication Refill"
        HEALTH_ALERT = "HEALTH_ALERT", "Health Alert"
        BILLING = "BILLING", "Billing"
        GENERAL = "GENERAL", "General"

    class Channel(models.TextChoices):
        IN_APP = "IN_APP", "In App"
        EMAIL = "EMAIL", "Email"
        SMS = "SMS", "SMS"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications"
    )
    notification_type = models.CharField(max_length=30, choices=NotificationType.choices)
    channel = models.CharField(max_length=10, choices=Channel.choices, default=Channel.IN_APP)
    title = models.CharField(max_length=150)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    scheduled_for = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.notification_type} to {self.recipient} - {self.title}"


class HealthTip(models.Model):
    """
    Health Tips shown on the Dashboard.
    """

    title = models.CharField(max_length=150)
    content = models.TextField()
    category = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
