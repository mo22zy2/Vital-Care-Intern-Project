from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

User = get_user_model()


class Command(BaseCommand):
    help = "Create the initial admin account (local only, no Supabase)"

    def add_arguments(self, parser):
        parser.add_argument("--email", default="admin@hospital.com")
        parser.add_argument("--password", default="admin123")
        parser.add_argument("--phone", default="+0000000000")

    def handle(self, *args, **options):
        email = options["email"]
        password = options["password"]
        phone = options["phone"]

        if User.objects.filter(email=email).exists():
            self.stdout.write(self.style.WARNING(f"User {email} already exists"))
            return

        user = User.objects.create_superuser(
            username=email.split("@")[0],
            email=email,
            password=password,
            phone=phone,
            first_name="Admin",
            last_name="User",
            role="ADMIN",
        )
        self.stdout.write(self.style.SUCCESS(f"Admin created: {email} / {password}"))
