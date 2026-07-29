from fastapi import APIRouter, Depends
from pydantic import BaseModel

from api.deps import get_current_user
from core.models.notifications.models import HealthTip, Notification

router = APIRouter(prefix="/notifications", tags=["notifications"])


class NotificationOut(BaseModel):
    id: str
    notification_type: str
    channel: str
    title: str
    message: str
    is_read: bool
    created_at: str

    class Config:
        from_attributes = True


class HealthTipOut(BaseModel):
    id: int
    title: str
    content: str
    category: str

    class Config:
        from_attributes = True


@router.get("", response_model=list[NotificationOut])
def list_notifications(user=Depends(get_current_user)):
    qs = Notification.objects.filter(recipient=user)[:50]
    return [
        NotificationOut(
            id=str(n.id),
            notification_type=n.notification_type,
            channel=n.channel,
            title=n.title,
            message=n.message,
            is_read=n.is_read,
            created_at=n.created_at.isoformat(),
        )
        for n in qs
    ]


@router.get("/unread-count")
def unread_count(user=Depends(get_current_user)):
    count = Notification.objects.filter(recipient=user, is_read=False).count()
    return {"unread_count": count}


@router.patch("/{notification_id}/read")
def mark_read(notification_id: str, user=Depends(get_current_user)):
    n = Notification.objects.filter(id=notification_id, recipient=user).first()
    if n:
        n.is_read = True
        n.save()
    return {"message": "Marked as read"}


@router.patch("/read-all")
def mark_all_read(user=Depends(get_current_user)):
    Notification.objects.filter(recipient=user, is_read=False).update(is_read=True)
    return {"message": "All marked as read"}


@router.get("/health-tips", response_model=list[HealthTipOut])
def list_health_tips(user=Depends(get_current_user)):
    tips = HealthTip.objects.filter(is_active=True)[:10]
    return [
        HealthTipOut(id=t.id, title=t.title, content=t.content, category=t.category)
        for t in tips
    ]
