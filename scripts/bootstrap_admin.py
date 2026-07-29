"""Create the initial admin account (local only, no Supabase)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "hospital_project.settings")

import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

email = sys.argv[1] if len(sys.argv) > 1 else "admin@hospital.com"
password = sys.argv[2] if len(sys.argv) > 2 else "admin123"

if User.objects.filter(email=email).exists():
    print(f"User {email} already exists")
    sys.exit(0)

user = User.objects.create_superuser(
    username=email.split("@")[0],
    email=email,
    password=password,
    phone="+0000000000",
    first_name="Admin",
    last_name="User",
    role="ADMIN",
)
print(f"Admin created: {email} / {password}")
