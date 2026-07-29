# AGENTS.md — hospital_project

## Quick start

```powershell
conda activate hospital_env
pip install -r requirements.txt
python manage.py makemigrations; python manage.py migrate
python manage.py runserver      # Django admin on :8000
uvicorn api.main:app --reload   # FastAPI on :8000
```

## Project structure

- `hospital_project/` — Django project config (settings, urls, wsgi, asgi)
- `core/` — Django app (views, admin, supabase client, auth backend)
- `core/models/<domain>/` — **14 sub-apps**, each with own `apps.py`, `models.py`, `migrations/`
- `api/` — FastAPI application (routers, deps, schemas)

## Critical gotchas (fixed)

- **Sub-app layout**: Models live in `core/models/<name>/`. Each is a standalone Django app. `apps.py` `name` must be the full dotted path (`core.models.accounts`, etc.) — this is now fixed.
- **INSTALLED_APPS**: All 14 sub-apps are now registered in `settings.py`.
- **AUTH_USER_MODEL**: Set to `"accounts.User"` in `settings.py`.
- **Supabase Auth**: Auth is handled via Supabase, not Django's built-in auth. The `SupabaseAuthBackend` validates JWT tokens from the `Authorization: Bearer <token>` header. Django `ModelBackend` is kept as fallback for admin.
- **Django 3.1**: Old (2020). Uses `django.urls.path()`, not `url()`.

## Supabase Auth API

All endpoints under `/api/auth/` (in `core/urls.py`):

| Endpoint | Method | Description |
|---|---|---|
| `/api/auth/register/` | POST | Sign up with Supabase Auth + create local User |
| `/api/auth/login/` | POST | Sign in via Supabase, starts Django session |
| `/api/auth/logout/` | POST | Sign out from Supabase + Django |
| `/api/auth/me/` | GET | Get current user from Bearer token |

- **register/login** return `{user, session: {access_token, refresh_token}}`
- The local `User` model has a `supabase_uid` field linking to the Supabase Auth user
- `SupabaseAuthBackend` auto-creates a local User if one doesn't exist for a valid JWT

## Environment configuration (`.env`)

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-role-key
DATABASE_URL=postgres://user:password@host:5432/postgres
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=1143506419
```

- If `DATABASE_URL` starts with `postgres:`, settings.py configures PostgreSQL (Supabase). Falls back to SQLite otherwise.
- Telegram notifications are sent on: user registration, login, admin user creation, appointment booking, feedback submission.

## Django admin panel

Custom admin panel at `/admindashboard/` (not Django's `/admin/`) with 11 pages:
- Dashboard, Reports, Users (CRUD), Appointments (CRUD), Doctors (CRUD), Medicines (CRUD), Lab Tests (CRUD), Invoices (list+status), Pharmacy Orders (list+status), Feedback (list+delete)
- All pages have search/filter, pagination (20 per page), and inline actions
- Admin sidebar in the left nav under "Administration" section (visible for ADMIN/superuser only)

## In-app notifications

`core/notify.py` auto-creates `Notification` records on:
- Appointment booked → patient notified
- Appointment cancelled → patient notified
- Pharmacy order placed → patient notified
- Test result available → patient notified
- Invoice generated → patient notified

Notifications page at `/notifications/` has search, filter by type, and "Mark Read" / "Mark All Read".

## FastAPI API

| File | Purpose |
|---|---|
| `api/main.py` | FastAPI app, CORS, router registration (15 routers, 77 routes) |
| `api/config.py` | `django.setup()` — configures Django ORM for FastAPI |
| `api/deps.py` | `get_current_user` — validates Supabase JWT, returns Django User |
| `api/routers/auth.py` | Register/login (wraps Supabase Auth) |
| `api/routers/appointments.py` | CRUD + cancel, auto-creates in-app notification |
| `api/routers/doctors.py` | List + detail + specialties |
| `api/routers/pharmacy.py` | Medicines + orders, auto-creates in-app notification |
| `api/routers/billing.py` | Invoice list + detail |
| `api/routers/laboratory.py` | Tests + bookings |
| `api/routers/medical_records.py` | Lists + create |
| `api/routers/prescriptions.py` | Lists + create |
| `api/routers/notifications.py` | List + mark read |
| `api/routers/feedback.py` | Create + list, Telegram notify |
| `api/routers/insurance.py` | Providers + policies + claims |
| `api/routers/emergency_contacts.py` | CRUD |
| `api/routers/accounts.py` | Profile + password reset + preferences |
| `api/routers/admin.py` | 25 admin endpoints, gated by `require_admin` |

- All protected endpoints require `Authorization: Bearer <supabase_access_token>`.
- Key events (appointment booking, order placement) auto-create in-app notifications via `core/notify.py`.

## Django auth (admin only)

| File | Purpose |
|---|---|
| `core/supabase_client.py` | Singleton `create_client()` — use `get_supabase()` |
| `core/auth_backend.py` | `SupabaseAuthBackend` — validates JWT, syncs local User |
| `core/views/auth.py` | Register, login, logout, me views (Django JSON) |
| `core/urls.py` | Auth URL routing for Django views |

## Sub-apps (all under `core/models/`)

| App | Key models |
|---|---|
| `accounts` | User (custom, UUID PK, supabase_uid), PasswordResetOTP, UserPreference |
| `appointments` | Appointment |
| `billing` | Invoice, InvoiceItem |
| `core` | GeneratedReport, AnalyticsSnapshot |
| `doctors` | Specialty, Doctor, DoctorAvailability, DoctorPerformanceMetric |
| `emergency_contacts` | EmergencyContact |
| `feedback` | Feedback |
| `insurance` | InsuranceProvider, HealthInsurance, InsuranceClaim |
| `laboratory` | LabTest, LabTestBooking, LabTestResult |
| `medical_records` | PatientRecord, TestResult |
| `notifications` | Notification, HealthTip |
| `payments` | Payment |
| `pharmacy` | Medicine, PharmacyOrder, PharmacyOrderItem |
| `prescriptions` | Prescription, PrescriptionItem, PrescriptionRefill |

## Model conventions

- All use UUID primary keys (`uuid.uuid4`, `editable=False`); `accounts.User` also has `supabase_uid`
- `BigAutoField` default set in each sub-app's `apps.py`
- Cross-app FK refs use dotted string paths (e.g. `"doctors.Doctor"`, `"appointments.Appointment"`)
- `settings.AUTH_USER_MODEL` used for patient/user FK fields

## Common commands

```powershell
python manage.py makemigrations <app_label>
python manage.py migrate
python manage.py test <app_label>
python manage.py createsuperuser
```
