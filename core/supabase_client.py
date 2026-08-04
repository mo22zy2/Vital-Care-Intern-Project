import os
from django.conf import settings
from supabase import create_client

_anon_client = None
_service_client = None


def get_supabase():
    global _anon_client
    if _anon_client is None:
        _anon_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_ANON_KEY,
        )
    return _anon_client


def get_supabase_service():
    global _service_client
    if _service_client is None:
        _service_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY,
        )
    return _service_client
