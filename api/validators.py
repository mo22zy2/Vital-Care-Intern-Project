from datetime import date, datetime, timedelta, time
from decimal import Decimal
import re


def not_in_past(value: date) -> date:
    if value < date.today():
        raise ValueError("Date must not be in the past")
    return value


def not_in_future(value: date) -> date:
    if value > date.today():
        raise ValueError("Date must not be in the future")
    return value


def birthday(value: date) -> date:
    today = date.today()
    if value >= today:
        raise ValueError("Date of birth must be in the past")
    if value < today - timedelta(days=365 * 120):
        raise ValueError("Date of birth is too far in the past")
    return value


def positive(value: int | float | Decimal) -> int | float | Decimal:
    if value <= 0:
        raise ValueError("Value must be greater than zero")
    return value


def non_negative(value: int | float | Decimal) -> int | float | Decimal:
    if value < 0:
        raise ValueError("Value must not be negative")
    return value


def rating_1_to_5(value: int) -> int:
    if not 1 <= value <= 5:
        raise ValueError("Rating must be between 1 and 5")
    return value


def coverage_percentage(value: Decimal) -> Decimal:
    if not 0 <= value <= 100:
        raise ValueError("Coverage percentage must be between 0 and 100")
    return value


def future_slot(booking_date: date, booking_time: time | None) -> None:
    if booking_time is not None and datetime.combine(booking_date, booking_time) <= datetime.now():
        raise ValueError("Booking time must be in the future")


def phone(value: str) -> str:
    digits = re.sub(r"[^0-9]", "", value)
    if len(digits) < 8 or len(digits) > 15:
        raise ValueError("Enter a valid phone number (8 to 15 digits)")
    return value
