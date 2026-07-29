import uuid
from django.conf import settings
from django.db import models


class LabTest(models.Model):
    """
    Laboratory Tests: catalog of available tests with description
    and pricing, used for booking.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    preparation_instructions = models.TextField(blank=True)
    turnaround_time_hours = models.PositiveIntegerField(default=24)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class LabTestBooking(models.Model):
    """
    A patient's booking of a lab test, and eventually its result,
    viewable online once ready.
    """

    class Status(models.TextChoices):
        BOOKED = "BOOKED", "Booked"
        SAMPLE_COLLECTED = "SAMPLE_COLLECTED", "Sample Collected"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        RESULT_READY = "RESULT_READY", "Result Ready"
        CANCELLED = "CANCELLED", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="lab_bookings"
    )
    lab_test = models.ForeignKey(LabTest, on_delete=models.PROTECT, related_name="bookings")
    scheduled_date = models.DateField()
    scheduled_time = models.TimeField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.BOOKED)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.lab_test} for {self.patient} on {self.scheduled_date}"


class LabTestResult(models.Model):
    booking = models.OneToOneField(
        LabTestBooking, on_delete=models.CASCADE, related_name="result"
    )
    result_summary = models.TextField()
    result_file = models.FileField(upload_to="lab_results/", null=True, blank=True)
    reviewed_by = models.ForeignKey(
        "doctors.Doctor", on_delete=models.SET_NULL, null=True, blank=True, related_name="reviewed_lab_results"
    )
    released_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Result for {self.booking}"
