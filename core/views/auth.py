import json
import logging
from django.contrib.auth import login, logout
from django.contrib.auth import get_user_model
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from ..supabase_client import get_supabase
from ..telegram import send_telegram

logger = logging.getLogger(__name__)
User = get_user_model()


@csrf_exempt
@require_http_methods(["POST"])
def register(request):
    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    email = body.get("email")
    password = body.get("password")
    if not email or not password:
        return JsonResponse({"error": "email and password required"}, status=400)

    supabase = get_supabase()
    res = supabase.auth.sign_up({"email": email, "password": password})
    if not res or not res.user:
        return JsonResponse({"error": "Supabase signup failed"}, status=400)

    supabase_id = res.user.id
    user, created = User.objects.get_or_create(
        supabase_uid=supabase_id,
        defaults={
            "username": email.split("@")[0],
            "email": email,
        },
    )
    if created:
        send_telegram(f"🆕 New user registered: {email}")
    return JsonResponse({
        "user": {"id": str(user.id), "email": user.email, "role": user.role},
        "session": {"access_token": res.session.access_token, "refresh_token": res.session.refresh_token},
    }, status=201)


@csrf_exempt
@require_http_methods(["POST"])
def login_view(request):
    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    email = body.get("email")
    password = body.get("password")
    if not email or not password:
        return JsonResponse({"error": "email and password required"}, status=400)

    supabase = get_supabase()
    res = supabase.auth.sign_in_with_password({"email": email, "password": password})
    if not res or not res.user:
        return JsonResponse({"error": "Invalid credentials"}, status=401)

    try:
        user = User.objects.get(supabase_uid=res.user.id)
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found locally"}, status=401)

    login(request, user)
    send_telegram(f"🔑 User logged in: {user.email}")
    return JsonResponse({
        "user": {"id": str(user.id), "email": user.email, "role": user.role},
        "session": {"access_token": res.session.access_token, "refresh_token": res.session.refresh_token},
    })


@require_http_methods(["POST"])
def logout_view(request):
    supabase = get_supabase()
    try:
        supabase.auth.sign_out()
    except Exception:
        pass
    logout(request)
    return JsonResponse({"message": "Logged out"})


@require_http_methods(["GET"])
def me(request):
    auth_header = request.META.get("HTTP_AUTHORIZATION", "")
    if not auth_header.startswith("Bearer "):
        return JsonResponse({"error": "Missing Authorization header"}, status=401)

    token = auth_header.split(" ", 1)[1]
    supabase = get_supabase()
    try:
        res = supabase.auth.get_user(token)
    except Exception:
        return JsonResponse({"error": "Invalid token"}, status=401)

    if not res or not res.user:
        return JsonResponse({"error": "Invalid token"}, status=401)

    try:
        user = User.objects.get(supabase_uid=res.user.id)
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)

    return JsonResponse({
        "id": str(user.id),
        "email": user.email,
        "role": user.role,
        "first_name": user.first_name,
        "last_name": user.last_name,
    })
