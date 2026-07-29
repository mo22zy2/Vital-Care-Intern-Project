from decimal import Decimal
from datetime import date, time, datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from api.deps import get_current_user
from core.models.laboratory.models import LabTest, LabTestBooking, LabTestResult
from core.notify import notify_test_result_available

router = APIRouter(prefix="/laboratory", tags=["laboratory"])


class LabTestOut(BaseModel):
    id: str
    name: str
    description: str
    price: Decimal
    preparation_instructions: str
    turnaround_time_hours: int

    class Config:
        from_attributes = True


@router.get("/tests", response_model=list[LabTestOut])
def list_tests(user=Depends(get_current_user)):
    tests = LabTest.objects.filter(is_active=True)
    return [
        LabTestOut(
            id=str(t.id),
            name=t.name,
            description=t.description,
            price=t.price,
            preparation_instructions=t.preparation_instructions,
            turnaround_time_hours=t.turnaround_time_hours,
        )
        for t in tests
    ]


class BookingCreate(BaseModel):
    lab_test_id: str
    scheduled_date: date
    scheduled_time: time


class BookingOut(BaseModel):
    id: str
    test_name: str
    patient_name: str
    scheduled_date: date
    scheduled_time: time
    status: str

    class Config:
        from_attributes = True


@router.post("/bookings", response_model=BookingOut, status_code=201)
def create_booking(body: BookingCreate, user=Depends(get_current_user)):
    test = LabTest.objects.filter(id=body.lab_test_id, is_active=True).first()
    if not test:
        raise HTTPException(status_code=404, detail="Lab test not found")
    booking = LabTestBooking.objects.create(
        patient=user, lab_test=test, scheduled_date=body.scheduled_date, scheduled_time=body.scheduled_time
    )
    return BookingOut(
        id=str(booking.id),
        test_name=test.name,
        patient_name=user.get_full_name() or user.email,
        scheduled_date=booking.scheduled_date,
        scheduled_time=booking.scheduled_time,
        status=booking.status,
    )


@router.get("/bookings", response_model=list[BookingOut])
def list_bookings(user=Depends(get_current_user)):
    if user.role == "LAB_TECH":
        bookings = LabTestBooking.objects.all().select_related("lab_test", "patient").order_by("-scheduled_date")
    else:
        bookings = LabTestBooking.objects.filter(patient=user).select_related("lab_test", "patient").order_by("-scheduled_date")
    return [
        BookingOut(
            id=str(b.id),
            test_name=b.lab_test.name,
            patient_name=b.patient.get_full_name() or b.patient.email,
            scheduled_date=b.scheduled_date,
            scheduled_time=b.scheduled_time,
            status=b.status,
        )
        for b in bookings
    ]


class BookingStatusUpdate(BaseModel):
    action: str


# ── Lab Tech Dashboard ──

class LabTechDashboardOut(BaseModel):
    pending: list[dict]
    in_progress: list[dict]
    total_today: int


@router.get("/dashboard", response_model=LabTechDashboardOut)
def labtech_dashboard(user=Depends(get_current_user)):
    if user.role != "LAB_TECH" and user.role not in ("ADMIN", "STAFF"):
        raise HTTPException(status_code=403, detail="Lab tech access required")

    today = date.today()
    pending = LabTestBooking.objects.filter(status="BOOKED").select_related("lab_test", "patient").order_by("scheduled_date", "scheduled_time")[:20]
    in_progress = LabTestBooking.objects.filter(status__in=("SAMPLE_COLLECTED", "IN_PROGRESS")).select_related("lab_test", "patient").order_by("-scheduled_date")[:20]

    return LabTechDashboardOut(
        pending=[
            {
                "id": str(b.id), "test_name": b.lab_test.name,
                "patient_name": b.patient.get_full_name() or b.patient.email,
                "scheduled_date": b.scheduled_date.isoformat(),
                "scheduled_time": b.scheduled_time.strftime("%H:%M") if b.scheduled_time else None,
            }
            for b in pending
        ],
        in_progress=[
            {
                "id": str(b.id), "test_name": b.lab_test.name,
                "patient_name": b.patient.get_full_name() or b.patient.email,
                "status": b.status,
                "scheduled_date": b.scheduled_date.isoformat(),
            }
            for b in in_progress
        ],
        total_today=LabTestBooking.objects.filter(scheduled_date=today).count(),
    )


ACTION_STATUS_MAP = {
    "collect_sample": "SAMPLE_COLLECTED",
    "start_test": "IN_PROGRESS",
    "complete": "COMPLETED",
}


@router.patch("/bookings/{booking_id}/status")
def update_booking_status(booking_id: str, body: BookingStatusUpdate, user=Depends(get_current_user)):
    if user.role != "LAB_TECH" and user.role not in ("ADMIN", "STAFF"):
        raise HTTPException(status_code=403, detail="Lab tech access required")

    booking = LabTestBooking.objects.filter(id=booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    new_status = ACTION_STATUS_MAP.get(body.action)
    if not new_status:
        raise HTTPException(status_code=400, detail=f"Invalid action: {body.action}")

    booking.status = new_status
    booking.save()
    return {"message": f"Booking status changed to {new_status}"}


class ResultRelease(BaseModel):
    result_summary: str
    result_details: str = ""


@router.post("/bookings/{booking_id}/release-result")
def release_result(booking_id: str, body: ResultRelease, user=Depends(get_current_user)):
    if user.role != "LAB_TECH" and user.role not in ("ADMIN", "STAFF"):
        raise HTTPException(status_code=403, detail="Lab tech access required")

    booking = LabTestBooking.objects.filter(id=booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    booking.status = "RESULT_READY"
    booking.save()

    result = LabTestResult.objects.create(
        booking=booking,
        patient=booking.patient,
        lab_test=booking.lab_test,
        result_summary=body.result_summary,
        result_details=body.result_details,
        released_by=user,
    )
    notify_test_result_available(result)
    return {"message": "Result released", "id": str(result.id)}
