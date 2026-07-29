import uuid
from django.conf import settings
from django.db import models


class PatientRecord(models.Model):
    """
    Patient Records: medical history, diagnoses, treatment plans and
    test results. Supports filtering/sorting (by date, doctor, diagnosis).
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="medical_records"
    )
    doctor = models.ForeignKey(
        "doctors.Doctor", on_delete=models.SET_NULL, null=True, related_name="patient_records"
    )
    appointment = models.ForeignKey(
        "appointments.Appointment",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="medical_records",
    )
    record_date = models.DateField()
    medical_history = models.TextField(blank=True)
    diagnosis = models.CharField(max_length=255)
    treatment_plan = models.TextField(blank=True)
    notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-record_date"]

    def __str__(self):
        return f"Record for {self.patient} on {self.record_date} - {self.diagnosis}"


class TestResult(models.Model):
    """
    Test results attached to a patient record (distinct from Laboratory
    Tests booking/catalog, which lives in the laboratory app).
    """

    record = models.ForeignKey(
        PatientRecord, on_delete=models.CASCADE, related_name="test_results"
    )
    test_name = models.CharField(max_length=150)
    result_summary = models.TextField()
    result_file = models.FileField(upload_to="test_results/", null=True, blank=True)
    recorded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.test_name} for {self.record.patient}"
