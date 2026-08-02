import re
import requests

from fastapi import APIRouter, Depends, HTTPException
from django.core.cache import cache
from django.utils import timezone

from api.deps import get_current_user
from core.models.accounts.models import TelegramLink
from core.telegram import BOT_TOKEN, get_bot_username, send_telegram_to

router = APIRouter(prefix="/telegram", tags=["telegram"])

OFFSET_KEY = "telegram_update_offset"


def _extract_token(text: str) -> str | None:
    m = re.search(r"([0-9a-f]{32})", text)
    return m.group(1) if m else None


def _fetch_updates() -> list[dict]:
    offset = cache.get(OFFSET_KEY, 0)
    try:
        r = requests.post(
            f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates",
            json={"offset": offset, "timeout": 5},
            timeout=25,
        )
        data = r.json()
    except Exception:
        return []
    result = data.get("result") if data.get("ok") else []
    if result:
        cache.set(OFFSET_KEY, result[-1]["update_id"] + 1)
    return result


@router.post("/link")
def get_link(user=Depends(get_current_user)):
    if not BOT_TOKEN:
        raise HTTPException(status_code=503, detail="Telegram bot is not configured")
    link, _ = TelegramLink.objects.get_or_create(user=user)
    bot = get_bot_username()
    return {
        "token": link.token,
        "bot_username": bot,
        "link": f"https://t.me/{bot}?start={link.token}" if bot else "",
        "linked": bool(link.telegram_chat_id),
    }


@router.post("/sync")
def sync_links(user=Depends(get_current_user)):
    if not BOT_TOKEN:
        raise HTTPException(status_code=503, detail="Telegram bot is not configured")

    before = TelegramLink.objects.filter(user=user).values_list("telegram_chat_id", flat=True).first() or ""

    for up in _fetch_updates():
        message = up.get("message") or {}
        chat_id = str((message.get("chat") or {}).get("id") or "")
        if not chat_id:
            continue
        token = _extract_token(message.get("text") or "")
        if not token:
            continue
        bound = TelegramLink.objects.filter(token=token).first()
        if bound and bound.telegram_chat_id != chat_id:
            bound.telegram_chat_id = chat_id
            bound.linked_at = timezone.now()
            bound.save(update_fields=["telegram_chat_id", "linked_at"])
            send_telegram_to(chat_id, "✅ Telegram linked! You will receive your hospital notifications here.")

    after = TelegramLink.objects.filter(user=user).values_list("telegram_chat_id", flat=True).first() or ""
    linked = bool(after)
    return {
        "linked": linked,
        "just_linked": linked and not bool(before),
        "message": (
            "Telegram linked! You will now get notifications here."
            if linked
            else "Not linked yet. Open the link and press Start, then check again."
        ),
    }
