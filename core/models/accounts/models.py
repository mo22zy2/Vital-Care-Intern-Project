import uuid
from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    """
    Custom user model used for Sign Up / Sign In.
    Extends Django's AbstractUser so username, password (hashed),
    first_name, last_name, email are already provided.
    """

    class Gender(models.TextChoices):
        MALE = "M", "Male"
        FEMALE = "F", "Female"
        OTHER = "O", "Other"
        PREFER_NOT_TO_SAY = "N", "Prefer not to say"

    class Role(models.TextChoices):
        PATIENT = "PATIENT", "Patient"
        DOCTOR = "DOCTOR", "Doctor"
        ADMIN = "ADMIN", "Admin"
        STAFF = "STAFF", "Staff"
        PHARMACIST = "PHARMACIST", "Pharmacist"
        LAB_TECH = "LAB_TECH", "Lab Technician"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    supabase_uid = models.UUIDField(null=True, blank=True, unique=True)

    # Sign Up fields not already on AbstractUser
    phone = models.CharField(max_length=20, unique=True)
    address = models.CharField(max_length=255, blank=True)
    gender = models.CharField(max_length=1, choices=Gender.choices, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.PATIENT)

    # Emergency contact quick-reference (detailed contacts live in
    # emergency_contacts.EmergencyContact - see that app for full records)
    primary_emergency_contact = models.ForeignKey(
        "emergency_contacts.EmergencyContact",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="primary_for_users",
    )

    is_email_verified = models.BooleanField(default=False)
    is_phone_verified = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    REQUIRED_FIELDS = ["email", "first_name", "last_name", "phone"]

    def __str__(self):
        return f"{self.get_full_name()} ({self.username})"


class PasswordResetOTP(models.Model):
    """
    Forget Password: user requests an OTP via email or SMS,
    then submits it along with a new password.
    """

    class DeliveryMethod(models.TextChoices):
        EMAIL = "EMAIL", "Email"
        SMS = "SMS", "SMS"

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="password_reset_otps")
    code = models.CharField(max_length=6)
    delivery_method = models.CharField(max_length=10, choices=DeliveryMethod.choices)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    def is_valid(self):
        return not self.is_used and timezone.now() < self.expires_at

    def __str__(self):
        return f"OTP for {self.user.username} via {self.delivery_method}"


class UserPreference(models.Model):
    """
    Themes & Languages: per-user UI preferences.
    """

    class Theme(models.TextChoices):
        LIGHT = "LIGHT", "Light"
        DARK = "DARK", "Dark"

    class Language(models.TextChoices):
        ENGLISH = "EN", "English"
        SPANISH = "ES", "Spanish"
        ARABIC = "AR", "Arabic"

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="preference")
    theme = models.CharField(max_length=10, choices=Theme.choices, default=Theme.LIGHT)
    language = models.CharField(max_length=5, choices=Language.choices, default=Language.ENGLISH)

    def __str__(self):
        return f"Preferences for {self.user.username}"


class TelegramLink(models.Model):
    """
    Links a user's account to their Telegram chat so in-app notifications
    are also delivered to their Telegram. `token` is used in the
    t.me/<bot>?start=<token> deep link; `telegram_chat_id` is bound when
    the user presses Start with that token.
    """

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="telegram_link"
    )
    token = models.CharField(max_length=64, unique=True, default=lambda: uuid.uuid4().hex)
    telegram_chat_id = models.CharField(max_length=64, blank=True, default="")
    linked_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Telegram link for {self.user.username}"
