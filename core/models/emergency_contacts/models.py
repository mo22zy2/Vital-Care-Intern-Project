import uuid
from django.conf import settings
from django.db import models


class EmergencyContact(models.Model):
    """
    Emergency Contacts: stored separately so a patient can have
    multiple emergency contacts, quickly accessible by medical staff.
    """

    class Relationship(models.TextChoices):
        PARENT = "PARENT", "Parent"
        SPOUSE = "SPOUSE", "Spouse"
        SIBLING = "SIBLING", "Sibling"
        CHILD = "CHILD", "Child"
        FRIEND = "FRIEND", "Friend"
        GUARDIAN = "GUARDIAN", "Guardian"
        OTHER = "OTHER", "Other"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="emergency_contacts",
    )
    full_name = models.CharField(max_length=150)
    relationship = models.CharField(max_length=20, choices=Relationship.choices)
    phone = models.CharField(max_length=20)
    alternate_phone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    address = models.CharField(max_length=255, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.full_name} ({self.relationship}) - {self.patient}"
