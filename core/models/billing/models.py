import uuid
from django.conf import settings
from django.db import models


class Invoice(models.Model):
    """
    Billing: generates invoices for services (consultations, treatments,
    prescriptions, tests) and provides a summary of charges.
    """

    class Status(models.TextChoices):
        UNPAID = "UNPAID", "Unpaid"
        PARTIALLY_PAID = "PARTIALLY_PAID", "Partially Paid"
        PAID = "PAID", "Paid"
        OVERDUE = "OVERDUE", "Overdue"
        CANCELLED = "CANCELLED", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    invoice_number = models.CharField(max_length=30, unique=True)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="invoices"
    )
    appointment = models.ForeignKey(
        "appointments.Appointment",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="invoices",
    )
    issue_date = models.DateField(auto_now_add=True)
    due_date = models.DateField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.UNPAID)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.patient}"


class InvoiceItem(models.Model):
    """
    Line items on an invoice: consultation fees, prescriptions,
    lab tests, pharmacy orders, etc.
    """

    class ItemType(models.TextChoices):
        CONSULTATION = "CONSULTATION", "Consultation"
        PRESCRIPTION = "PRESCRIPTION", "Prescription"
        LAB_TEST = "LAB_TEST", "Lab Test"
        PHARMACY = "PHARMACY", "Pharmacy Order"
        OTHER = "OTHER", "Other"

    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="items")
    item_type = models.CharField(max_length=20, choices=ItemType.choices)
    description = models.CharField(max_length=255)
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=12, decimal_places=2)

    def __str__(self):
        return f"{self.description} ({self.invoice.invoice_number})"
