import uuid
from django.conf import settings
from django.db import models


class InsuranceProvider(models.Model):
    name = models.CharField(max_length=150, unique=True)
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    api_integration_key = models.CharField(
        max_length=255, blank=True, help_text="Key/token used for claims/verification API integration"
    )
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class HealthInsurance(models.Model):
    """
    Health Insurance: a patient's insurance policy details and coverage,
    enabling verification with the provider.
    """

    class VerificationStatus(models.TextChoices):
        UNVERIFIED = "UNVERIFIED", "Unverified"
        VERIFIED = "VERIFIED", "Verified"
        EXPIRED = "EXPIRED", "Expired"
        REJECTED = "REJECTED", "Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="insurance_policies"
    )
    provider = models.ForeignKey(
        InsuranceProvider, on_delete=models.CASCADE, related_name="policies"
    )
    policy_number = models.CharField(max_length=100)
    group_number = models.CharField(max_length=100, blank=True)
    coverage_details = models.TextField(blank=True)
    coverage_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    valid_from = models.DateField()
    valid_to = models.DateField()
    verification_status = models.CharField(
        max_length=20, choices=VerificationStatus.choices, default=VerificationStatus.UNVERIFIED
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("patient", "provider", "policy_number")

    def __str__(self):
        return f"{self.provider} policy {self.policy_number} - {self.patient}"


class InsuranceClaim(models.Model):
    """
    A claim submitted against an invoice for insurance-covered payment.
    """

    class Status(models.TextChoices):
        SUBMITTED = "SUBMITTED", "Submitted"
        UNDER_REVIEW = "UNDER_REVIEW", "Under Review"
        APPROVED = "APPROVED", "Approved"
        DENIED = "DENIED", "Denied"
        PAID = "PAID", "Paid"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    insurance = models.ForeignKey(
        HealthInsurance, on_delete=models.CASCADE, related_name="claims"
    )
    invoice = models.ForeignKey(
        "billing.Invoice", on_delete=models.CASCADE, related_name="insurance_claims"
    )
    claim_amount = models.DecimalField(max_digits=12, decimal_places=2)
    approved_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SUBMITTED)
    submitted_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Claim {self.id} - {self.status}"
