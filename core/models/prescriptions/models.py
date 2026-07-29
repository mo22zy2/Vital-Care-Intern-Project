import uuid
from django.conf import settings
from django.db import models


class Prescription(models.Model):
    """
    Prescriptions: doctors prescribe medication; patients can view
    prescription history and track refills.
    """

    class Status(models.TextChoices):
        ACTIVE = "ACTIVE", "Active"
        COMPLETED = "COMPLETED", "Completed"
        CANCELLED = "CANCELLED", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="prescriptions"
    )
    doctor = models.ForeignKey(
        "doctors.Doctor", on_delete=models.SET_NULL, null=True, related_name="prescriptions"
    )
    medical_record = models.ForeignKey(
        "medical_records.PatientRecord",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="prescriptions",
    )
    date_prescribed = models.DateField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Prescription #{self.id} for {self.patient}"


class PrescriptionItem(models.Model):
    """
    Individual medication line item within a prescription.
    """

    prescription = models.ForeignKey(
        Prescription, on_delete=models.CASCADE, related_name="items"
    )
    medicine = models.ForeignKey(
        "pharmacy.Medicine", on_delete=models.SET_NULL, null=True, related_name="prescription_items"
    )
    dosage = models.CharField(max_length=100, help_text="e.g. 500mg twice a day")
    duration_days = models.PositiveIntegerField()
    quantity = models.PositiveIntegerField()
    instructions = models.TextField(blank=True)

    def __str__(self):
        return f"{self.medicine} - {self.dosage}"


class PrescriptionRefill(models.Model):
    """
    Tracks refill requests/history for a prescription item.
    """

    class Status(models.TextChoices):
        REQUESTED = "REQUESTED", "Requested"
        APPROVED = "APPROVED", "Approved"
        DENIED = "DENIED", "Denied"
        FULFILLED = "FULFILLED", "Fulfilled"

    prescription_item = models.ForeignKey(
        PrescriptionItem, on_delete=models.CASCADE, related_name="refills"
    )
    requested_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.REQUESTED)
    fulfilled_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Refill for {self.prescription_item} - {self.status}"
