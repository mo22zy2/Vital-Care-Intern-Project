from datetime import date, datetime

import jwt
from django.conf import settings
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field, field_validator
from django.contrib.auth import get_user_model
from core.supabase_client import get_supabase
from core.telegram import send_telegram
from gotrue.errors import AuthApiError
from api.validators import birthday

router = APIRouter(prefix="/auth", tags=["auth"])
User = get_user_model()


class RegisterBody(BaseModel):
    email: str
    password: str = Field(min_length=8)
    first_name: str = ""
    last_name: str = ""
    phone: str = ""
    address: str = ""
    gender: str = ""
    date_of_birth: date | None = None

    _birthday = field_validator("date_of_birth")(birthday)


class LoginBody(BaseModel):
    email: str
    password: str


class RefreshBody(BaseModel):
    refresh_token: str


class AuthOut(BaseModel):
    user: dict
    session: dict


@router.post("/register", response_model=AuthOut, status_code=201)
def register(body: RegisterBody):
    supabase = get_supabase()
    try:
        res = supabase.auth.sign_up({"email": body.email, "password": body.password})
    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=str(e).split(":")[-1].strip() or "Registration failed")
    if res and res.user:
        user, created = User.objects.get_or_create(
            supabase_uid=res.user.id,
            defaults={
                "username": body.email.split("@")[0],
                "email": body.email,
                "first_name": body.first_name,
                "last_name": body.last_name,
                "phone": body.phone or body.email.split("@")[0],
                "address": body.address,
            },
        )
        if not created:
            user.first_name = body.first_name or user.first_name
            user.last_name = body.last_name or user.last_name
            user.phone = body.phone or user.phone
            user.address = body.address or user.address
            if body.gender:
                user.gender = body.gender
            user.save()
        else:
            if body.gender:
                user.gender = body.gender
            if body.date_of_birth:
                user.date_of_birth = body.date_of_birth
            user.save()
            from core.models.accounts.models import UserPreference
            UserPreference.objects.get_or_create(user=user)

        from core.models.emergency_contacts.models import EmergencyContact
        send_telegram(f"🆕 New user registered (API): {body.email}")
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": res.session.access_token, "refresh_token": res.session.refresh_token},
        )

    if body.password and len(body.password) >= 8:
        user = User.objects.create_user(
            username=body.email.split("@")[0],
            email=body.email,
            password=body.password,
            first_name=body.first_name,
            last_name=body.last_name,
            phone=body.phone or body.email.split("@")[0],
            address=body.address,
        )
        if body.gender:
            user.gender = body.gender
        if body.date_of_birth:
            user.date_of_birth = body.date_of_birth
        user.save()
        from core.models.accounts.models import UserPreference
        UserPreference.objects.get_or_create(user=user)
        from api.deps import create_local_token
        send_telegram(f"🆕 New user registered (API - local): {body.email}")
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": create_local_token(user), "refresh_token": create_local_token(user, days=90)},
        )

    raise HTTPException(status_code=400, detail="Registration failed")


@router.post("/refresh", response_model=AuthOut)
def refresh(body: RefreshBody):
    from api.deps import create_local_token

    try:
        payload = jwt.decode(body.refresh_token, settings.SECRET_KEY, algorithms=["HS256"])
        user = User.objects.get(id=payload["sub"])
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": create_local_token(user), "refresh_token": create_local_token(user, days=90)},
        )
    except (jwt.InvalidTokenError, User.DoesNotExist, ValueError):
        pass

    supabase = get_supabase()
    try:
        res = supabase.auth.refresh_session(body.refresh_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    if not res or not res.session:
        raise HTTPException(status_code=401, detail="Refresh failed")
    try:
        user = User.objects.get(supabase_uid=res.user.id)
    except User.DoesNotExist:
        user = None
    return AuthOut(
        user={
            "id": str(user.id) if user else "",
            "email": user.email if user else (res.user.email or ""),
            "role": user.role if user else "PATIENT",
            "first_name": user.first_name if user else "",
            "last_name": user.last_name if user else "",
            "phone": user.phone if user else "",
        },
        session={"access_token": res.session.access_token, "refresh_token": res.session.refresh_token},
    )


@router.post("/login", response_model=AuthOut)
def login(body: LoginBody):
    from django.contrib.auth.hashers import check_password

    try:
        supabase = get_supabase()
        res = supabase.auth.sign_in_with_password({"email": body.email, "password": body.password})
    except AuthApiError:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if res and res.user:
        try:
            user = User.objects.get(supabase_uid=res.user.id)
        except User.DoesNotExist:
            raise HTTPException(status_code=401, detail="User not found")
        send_telegram(f"🔑 User logged in (API): {body.email}")
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": res.session.access_token, "refresh_token": res.session.refresh_token},
        )

    user = User.objects.filter(email=body.email).first()
    if user and user.is_active and check_password(body.password, user.password):
        from api.deps import create_local_token
        send_telegram(f"🔑 User logged in (API - local): {body.email}")
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": create_local_token(user), "refresh_token": create_local_token(user, days=90)},
        )

    raise HTTPException(status_code=401, detail="Invalid credentials")
