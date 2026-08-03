from datetime import datetime, timedelta, timezone

import jwt
from django.conf import settings
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from django.contrib.auth import get_user_model

from core.supabase_client import get_supabase

security = HTTPBearer()
User = get_user_model()


def create_local_token(user, days: int = 30) -> str:
    """Mint a local JWT for SQLite-backed users (no Supabase account)."""
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "exp": datetime.now(timezone.utc) + timedelta(days=days),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    if token:
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            return User.objects.get(id=payload["sub"])
        except (jwt.InvalidTokenError, User.DoesNotExist, ValueError):
            pass

    supabase = get_supabase()
    try:
        res = supabase.auth.get_user(token)
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    if not res or not res.user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    supabase_uid = res.user.id
    user, _ = User.objects.get_or_create(
        supabase_uid=supabase_uid,
        defaults={
            "email": res.user.email or "",
            "username": (res.user.email or supabase_uid)[:8],
        },
    )
    return user
