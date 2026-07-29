import uuid
from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Feedback(models.Model):
    """
    Feedback & Reviews: patients leave feedback on doctors, services,
    and hospital facilities.
    """

    class TargetType(models.TextChoices):
        DOCTOR = "DOCTOR", "Doctor"
        SERVICE = "SERVICE", "Service"
        FACILITY = "FACILITY", "Facility"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="feedback_submitted"
    )
    target_type = models.CharField(max_length=20, choices=TargetType.choices)
    doctor = models.ForeignKey(
        "doctors.Doctor",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="feedback_received",
    )
    appointment = models.ForeignKey(
        "appointments.Appointment",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="feedback",
    )
    rating = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True)
    is_anonymous = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        target = self.doctor if self.doctor else self.target_type
        return f"Feedback ({self.rating}/5) on {target}"
