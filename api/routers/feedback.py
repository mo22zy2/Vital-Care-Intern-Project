from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from api.deps import get_current_user
from core.models.feedback.models import Feedback
from core.telegram import send_telegram

router = APIRouter(prefix="/feedback", tags=["feedback"])


class FeedbackOut(BaseModel):
    id: str
    target_type: str
    doctor_name: str
    rating: int
    comment: str
    is_anonymous: bool
    created_at: str

    class Config:
        from_attributes = True


class FeedbackCreate(BaseModel):
    target_type: str
    doctor_id: str | None = None
    appointment_id: str | None = None
    rating: int
    comment: str = ""
    is_anonymous: bool = False


@router.get("", response_model=list[FeedbackOut])
def list_feedback(user=Depends(get_current_user)):
    qs = Feedback.objects.filter(patient=user).select_related("doctor__user")
    return [
        FeedbackOut(
            id=str(f.id),
            target_type=f.target_type,
            doctor_name=f"Dr. {f.doctor.user.get_full_name()}" if f.doctor else "",
            rating=f.rating,
            comment=f.comment,
            is_anonymous=f.is_anonymous,
            created_at=f.created_at.isoformat(),
        )
        for f in qs
    ]


@router.post("", status_code=201)
def submit_feedback(body: FeedbackCreate, user=Depends(get_current_user)):
    from core.models.doctors.models import Doctor
    doctor = None
    if body.doctor_id:
        doctor = Doctor.objects.filter(id=body.doctor_id).first()
        if not doctor:
            raise HTTPException(status_code=404, detail="Doctor not found")
    f = Feedback.objects.create(
        patient=user,
        target_type=body.target_type,
        doctor=doctor,
        rating=body.rating,
        comment=body.comment,
        is_anonymous=body.is_anonymous,
    )
    send_telegram(f"💬 Feedback submitted (rating: {body.rating}/5) by {user.email}")
    return {"id": str(f.id)}
