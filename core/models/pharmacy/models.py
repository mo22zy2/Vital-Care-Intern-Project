import uuid
from django.conf import settings
from django.db import models


class Medicine(models.Model):
    """
    Pharmacy: catalog of available medicines with dosage info,
    pricing and stock, used for direct ordering/refills.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=150)
    generic_name = models.CharField(max_length=150, blank=True)
    description = models.TextField(blank=True)
    dosage_form = models.CharField(
        max_length=50, help_text="e.g. tablet, syrup, injection", blank=True
    )
    strength = models.CharField(max_length=50, help_text="e.g. 500mg", blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock_quantity = models.PositiveIntegerField(default=0)
    requires_prescription = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.strength})"


class PharmacyOrder(models.Model):
    """
    A patient order for medicine (fresh purchase or a refill request).
    """

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        PROCESSING = "PROCESSING", "Processing"
        READY_FOR_PICKUP = "READY_FOR_PICKUP", "Ready for Pickup"
        DELIVERED = "DELIVERED", "Delivered"
        CANCELLED = "CANCELLED", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="pharmacy_orders"
    )
    prescription = models.ForeignKey(
        "prescriptions.Prescription",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="pharmacy_orders",
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    ordered_at = models.DateTimeField(auto_now_add=True)
    fulfilled_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Order #{self.id} for {self.patient}"


class PharmacyOrderItem(models.Model):
    order = models.ForeignKey(PharmacyOrder, on_delete=models.CASCADE, related_name="items")
    medicine = models.ForeignKey(Medicine, on_delete=models.PROTECT, related_name="order_items")
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.quantity} x {self.medicine} ({self.order_id})"
