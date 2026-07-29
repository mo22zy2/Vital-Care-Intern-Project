import uuid
from django.conf import settings
from django.db import models


class GeneratedReport(models.Model):
    """
    Reports For Admin: logs each generated/downloadable report
    (Patient Admissions, Discharges, Inventory, Staff Attendance, Financials).
    The actual report file is generated and stored; this model tracks
    who generated it, when, the date range covered, and where to download it.
    """

    class ReportType(models.TextChoices):
        PATIENT_ADMISSIONS = "PATIENT_ADMISSIONS", "Patient Admissions"
        DISCHARGES = "DISCHARGES", "Discharges"
        INVENTORY = "INVENTORY", "Inventory"
        STAFF_ATTENDANCE = "STAFF_ATTENDANCE", "Staff Attendance"
        FINANCIALS = "FINANCIALS", "Financials"

    class Format(models.TextChoices):
        PDF = "PDF", "PDF"
        CSV = "CSV", "CSV"
        XLSX = "XLSX", "XLSX"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report_type = models.CharField(max_length=30, choices=ReportType.choices)
    file_format = models.CharField(max_length=10, choices=Format.choices, default=Format.PDF)
    generated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="generated_reports"
    )
    period_start = models.DateField(null=True, blank=True)
    period_end = models.DateField(null=True, blank=True)
    file = models.FileField(upload_to="reports/")
    generated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-generated_at"]

    def __str__(self):
        return f"{self.report_type} report ({self.generated_at:%Y-%m-%d})"


class AnalyticsSnapshot(models.Model):
    """
    Periodic aggregated data backing the Analytics dashboard charts
    (Patient Demographics, Appointment Trends, Doctor Performance,
    Health Outcomes) so heavy aggregation isn't recomputed on every
    dashboard load. Doctor Performance itself has a dedicated model
    at doctors.DoctorPerformanceMetric; this model covers the
    hospital-wide metrics.
    """

    class MetricType(models.TextChoices):
        PATIENT_DEMOGRAPHICS = "PATIENT_DEMOGRAPHICS", "Patient Demographics"
        APPOINTMENT_TRENDS = "APPOINTMENT_TRENDS", "Appointment Trends"
        HEALTH_OUTCOMES = "HEALTH_OUTCOMES", "Health Outcomes"

    metric_type = models.CharField(max_length=30, choices=MetricType.choices)
    period_start = models.DateField()
    period_end = models.DateField()
    data = models.JSONField(help_text="Chart-ready aggregated data, e.g. series/labels/values")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("metric_type", "period_start", "period_end")

    def __str__(self):
        return f"{self.metric_type} ({self.period_start} - {self.period_end})"
