import logging
from django.contrib.auth.backends import BaseBackend
from django.contrib.auth import get_user_model

logger = logging.getLogger(__name__)

User = get_user_model()


class SupabaseAuthBackend(BaseBackend):
    def authenticate(self, request, access_token=None, **kwargs):
        if access_token is None:
            return None
        try:
            from .supabase_client import get_supabase
            supabase = get_supabase()
            res = supabase.auth.get_user(access_token)
            if not res or not res.user:
                return None

            supabase_user = res.user
            try:
                user = User.objects.get(supabase_uid=supabase_user.id)
            except User.DoesNotExist:
                email = supabase_user.email or ""
                user = User.objects.create(
                    supabase_uid=supabase_user.id,
                    username=email.split("@")[0] or supabase_user.id[:8],
                    email=email,
                )

            return user
        except Exception as e:
            logger.exception("Supabase auth failed")
            return None

    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None
