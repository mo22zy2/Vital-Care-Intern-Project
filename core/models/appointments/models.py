import uuid
from django.conf import settings
from django.db import models


class Appointment(models.Model):
    """
    Appointments: patients book/view/cancel appointments with a doctor,
    date, and time. Also backs the Dashboard "Upcoming Appointments" and
    Analytics "Appointment Trends".
    """

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        CONFIRMED = "CONFIRMED", "Confirmed"
        COMPLETED = "COMPLETED", "Completed"
        CANCELLED = "CANCELLED", "Cancelled"
        NO_SHOW = "NO_SHOW", "No Show"

    class Reason(models.TextChoices):
        CONSULTATION = "CONSULTATION", "Consultation"
        FOLLOW_UP = "FOLLOW_UP", "Follow Up"
        EMERGENCY = "EMERGENCY", "Emergency"
        ROUTINE_CHECKUP = "ROUTINE_CHECKUP", "Routine Checkup"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="appointments"
    )
    doctor = models.ForeignKey(
        "doctors.Doctor", on_delete=models.CASCADE, related_name="appointments"
    )
    appointment_date = models.DateField()
    appointment_time = models.TimeField()
    reason = models.CharField(max_length=20, choices=Reason.choices, default=Reason.CONSULTATION)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    contact_phone = models.CharField(max_length=20, blank=True, default="")
    notes = models.TextField(blank=True)
    cancellation_reason = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["appointment_date", "appointment_time"]
        unique_together = ("doctor", "appointment_date", "appointment_time")

    def __str__(self):
        return f"{self.patient} with {self.doctor} on {self.appointment_date} {self.appointment_time}"
