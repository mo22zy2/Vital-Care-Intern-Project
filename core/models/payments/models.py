import uuid
from django.conf import settings
from django.db import models


class Payment(models.Model):
    """
    Payment Integration: records a payment made against an invoice,
    supporting card, bank transfer, and insurance payment methods.
    """

    class Method(models.TextChoices):
        CREDIT_CARD = "CREDIT_CARD", "Credit Card"
        DEBIT_CARD = "DEBIT_CARD", "Debit Card"
        BANK_TRANSFER = "BANK_TRANSFER", "Bank Transfer"
        INSURANCE = "INSURANCE", "Insurance"
        CASH = "CASH", "Cash"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        SUCCESS = "SUCCESS", "Success"
        FAILED = "FAILED", "Failed"
        REFUNDED = "REFUNDED", "Refunded"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    invoice = models.ForeignKey(
        "billing.Invoice", on_delete=models.CASCADE, related_name="payments"
    )
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="payments"
    )
    insurance_claim = models.ForeignKey(
        "insurance.InsuranceClaim",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    method = models.CharField(max_length=20, choices=Method.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_reference = models.CharField(max_length=100, blank=True)
    gateway_response = models.JSONField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payment {self.id} - {self.amount} ({self.status})"
