import uuid
from django.conf import settings
from django.db import models


class Specialty(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = "Specialties"

    def __str__(self):
        return self.name


class Doctor(models.Model):
    """
    Doctors: profile linked one-to-one with the User account (role=DOCTOR).
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="doctor_profile"
    )
    specialties = models.ManyToManyField(Specialty, related_name="doctors")
    license_number = models.CharField(max_length=50, unique=True)
    years_of_experience = models.PositiveIntegerField(default=0)
    consultation_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    office_location = models.CharField(max_length=255, blank=True)
    bio = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Dr. {self.user.get_full_name()}"


class DoctorAvailability(models.Model):
    """
    Recurring weekly availability slots used when patients book appointments
    and for the Doctors list sorting/filtering ("availability").
    """

    class Weekday(models.IntegerChoices):
        MONDAY = 0, "Monday"
        TUESDAY = 1, "Tuesday"
        WEDNESDAY = 2, "Wednesday"
        THURSDAY = 3, "Thursday"
        FRIDAY = 4, "Friday"
        SATURDAY = 5, "Saturday"
        SUNDAY = 6, "Sunday"

    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name="availabilities")
    weekday = models.IntegerField(choices=Weekday.choices)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_available = models.BooleanField(default=True)

    class Meta:
        unique_together = ("doctor", "weekday", "start_time", "end_time")

    def covers(self, t):
        """True if time t falls inside this slot, handling slots that span midnight."""
        st = self.start_time.replace(microsecond=0)
        et = self.end_time.replace(microsecond=0)
        if et <= st:
            return t >= st or t <= et
        return st <= t <= et

    def __str__(self):
        return f"{self.doctor} - {self.get_weekday_display()} {self.start_time}-{self.end_time}"


class DoctorPerformanceMetric(models.Model):
    """
    Aggregated/periodic performance data backing the Analytics dashboard
    ("Doctor Performance" charts).
    """

    doctor = models.ForeignKey(
        Doctor, on_delete=models.CASCADE, related_name="performance_metrics"
    )
    period_start = models.DateField()
    period_end = models.DateField()
    total_appointments = models.PositiveIntegerField(default=0)
    completed_appointments = models.PositiveIntegerField(default=0)
    cancelled_appointments = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    average_consultation_minutes = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ("doctor", "period_start", "period_end")

    def __str__(self):
        return f"{self.doctor} performance {self.period_start} - {self.period_end}"
