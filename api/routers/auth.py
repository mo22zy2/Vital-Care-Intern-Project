from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr
from django.contrib.auth import get_user_model
from core.supabase_client import get_supabase
from core.telegram import send_telegram

router = APIRouter(prefix="/auth", tags=["auth"])
User = get_user_model()


class RegisterBody(BaseModel):
    email: str
    password: str
    first_name: str = ""
    last_name: str = ""
    phone: str = ""
    address: str = ""
    gender: str = ""
    date_of_birth: str | None = None


class LoginBody(BaseModel):
    email: str
    password: str


class AuthOut(BaseModel):
    user: dict
    session: dict


@router.post("/register", response_model=AuthOut, status_code=201)
def register(body: RegisterBody):
    supabase = get_supabase()
    res = supabase.auth.sign_up({"email": body.email, "password": body.password})
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
                from datetime import datetime
                user.date_of_birth = datetime.strptime(body.date_of_birth, "%Y-%m-%d").date()
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
            from datetime import datetime
            user.date_of_birth = datetime.strptime(body.date_of_birth, "%Y-%m-%d").date()
        user.save()
        from core.models.accounts.models import UserPreference
        UserPreference.objects.get_or_create(user=user)
        send_telegram(f"🆕 New user registered (API - local): {body.email}")
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": "", "refresh_token": ""},
        )

    raise HTTPException(status_code=400, detail="Registration failed")


@router.post("/login", response_model=AuthOut)
def login(body: LoginBody):
    from django.contrib.auth.hashers import check_password

    supabase = get_supabase()
    res = supabase.auth.sign_in_with_password({"email": body.email, "password": body.password})
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
        send_telegram(f"🔑 User logged in (API - local): {body.email}")
        return AuthOut(
            user={"id": str(user.id), "email": user.email, "role": user.role,
                  "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone},
            session={"access_token": "", "refresh_token": ""},
        )

    raise HTTPException(status_code=401, detail="Invalid credentials")
