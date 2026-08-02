# 🏥 VitalCare Hospital Management System

[![Django](https://img.shields.io/badge/Django-4.2-092E20?logo=django)](https://www.djangoproject.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com/)
[![Supabase](https://img.shields.io/badge/Supabase-Auth-3ECF8E?logo=supabase)](https://supabase.com/)
[![Flutter](https://img.shields.io/badge/Flutter-ready-02569B?logo=flutter)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python)](https://python.org/)

A full-featured hospital management platform with **Django admin UI** for the web and **FastAPI REST API** for the Flutter app. Built with Supabase Auth, 14 domain models, role-based dashboards, and 85+ API endpoints.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
│              (mobile — consumes JSON API)             │
└────────────────────────┬────────────────────────────┘
                         │ Authorization: Bearer <token>
                         ▼
┌─────────────────────────────────────────────────────┐
│               FastAPI (port 8081)                     │
│  16 routers · 85+ endpoints · Pydantic schemas        │
│  Supabase JWT validation · Django ORM integration     │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              Django ORM (shared database)             │
│  14 sub-apps · 30+ models · Custom migrations         │
└────────────────────────┬────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      ┌──────────────┐    ┌──────────────┐
      │  PostgreSQL   │    │   SQLite     │
      │  (Supabase)   │    │  (local dev) │
      └──────────────┘    └──────────────┘
                         ▲
┌─────────────────────────────────────────────────────┐
│            Django (port 8000)                         │
│  VitalCare Web UI · Admin Dashboard · Template views  │
│  Auth with Supabase + Django fallback                  │
└─────────────────────────────────────────────────────┘
```

**Key insight:** Django and FastAPI are independent processes that share the same database through Django ORM. They never communicate directly — Flutter talks to FastAPI, browsers talk to Django.

---

## Features

### Role-Based Dashboards

| Role | Web UI (Django) | Mobile API (FastAPI) |
|---|---|---|
| **Patient** | Register, book appointments, view records, order pharmacy, lab bookings, timeline | `GET /accounts/me/dashboard`, `GET /accounts/me/timeline` |
| **Doctor** | Accept/complete/cancel appointments, write prescriptions, manage availability | `GET /doctors/me/dashboard`, `PATCH /appointments/{id}/status` |
| **Pharmacist** | Fulfill orders, manage stock, view dashboard | `GET /pharmacy/dashboard`, `PATCH /pharmacy/orders/{id}/status` |
| **Lab Tech** | Process bookings, release results, view dashboard | `GET /laboratory/dashboard`, `POST /laboratory/bookings/{id}/release-result` |
| **Admin / Staff** | Full CRUD on users, doctors, medicines, lab tests, invoices, reports | `GET /admin/*` (25 endpoints), `GET /search` (global) |

> **Flutter note:** the admin screens were removed from the mobile app — admin/STAFF users land on the patient dashboard. Admin operations remain available via the `/admin/*` API (for web/desktop clients) and the Django admin panel at `/admindashboard/`.

### Core Modules

- **User Management** — Registration, login (email/phone), Supabase Auth + Django fallback, role-based access
- **Appointments** — Book, confirm, complete, cancel (with reason), double-booking prevention, working-hours-aware booking (the app shows the doctor's availability and rejects times outside them), patient contact phone required at booking
- **Doctors** — Specialties, availability slots (exposed via the API, weekday 0–6), performance metrics
- **Pharmacy** — Medicine catalog with prices and live stock, order placement with per-item quantity validation (min 1, capped at stock), order history/detail with line totals
- **Laboratory** — Test catalog, booking, sample collection, result release
- **Billing & Insurance** — Invoices, payments (cash/card/insurance), insurance claims
- **Medical Records** — Patient history, diagnoses, treatment plans, test results
- **Prescriptions** — Create, refill requests, fulfillment tracking
- **Notifications** — In-app alerts on key events + per-user Telegram delivery via a bot link token (`/telegram/link` → user presses `t.me/<bot>?start=<token>` → `/telegram/sync` binds their chat)
- **Feedback** — Rate doctors, anonymous option, Telegram notification
- **Emergency Contacts** — CRUD per patient
- **Global Search** — Search doctors, medicines, lab tests, users, invoices

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Web Framework** | Django 4.2.16 |
| **REST API** | FastAPI 0.115 |
| **Auth** | Supabase Auth (JWT) + Django password fallback |
| **Database** | PostgreSQL (Supabase) / SQLite (local) |
| **ORM** | Django ORM (same for both Django & FastAPI) |
| **Mobile** | Flutter (via FastAPI JSON endpoints) |
| **Notifications** | Telegram Bot API |
| **Seed Data** | 14 users, 4 doctors, sample data across all models |

---

## Quick Start

### Prerequisites

- Python 3.10+
- Conda (recommended) or venv
- Supabase project (or skip for local-only mode)

### Setup

```powershell
# 1. Clone and enter the project
git clone https://github.com/mo22zy2/Vital-Care-Intern-project.git
cd hospital_project

# 2. Create conda environment
conda create -n hospital_env python=3.10 -y
conda activate hospital_env

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
copy .env.example .env    # Or create .env from scratch
# Edit .env with your Supabase credentials (optional — app works with SQLite + password auth)

# 5. Run migrations
python manage.py makemigrations
python manage.py migrate

# 6. Seed sample data
python scripts/seed_data.py

# 7. Start servers (in two terminals)

# Terminal 1 — Django Web UI (port 8000)
python manage.py runserver

# Terminal 2 — FastAPI for Flutter (port 8081)
uvicorn api.main:app --reload --port 8081
```

### Default Credentials

| Email | Password | Role |
|---|---|---|
| `sara.farid@clinic.eg` | `password123` | **ADMIN** |
| `khaled.nour@clinic.eg` | `password123` | **DOCTOR** (Cardiology) |
| `hend.zaki@clinic.eg` | `password123` | **DOCTOR** (Pediatrics) |
| `mostafa.salem@clinic.eg` | `password123` | **DOCTOR** (Orthopedics) |
| `rania.gaber@clinic.eg` | `password123` | **DOCTOR** (Dermatology) |
| `islam.shawky@clinic.eg` | `password123` | **PHARMACIST** |
| `amr.fahmy@clinic.eg` | `password123` | **LAB_TECH** |
| `mona.kamel@clinic.eg` | `password123` | **STAFF** |
| `ahmed.hassan@gmail.com` | `password123` | **PATIENT** |
| `fatma.ibrahim@yahoo.com` | `password123` | **PATIENT** |
| `youssef.said@outlook.com` | `password123` | **PATIENT** |
| `mariam.a@gmail.com` | `password123` | **PATIENT** |
| `omar.elsayed@gmail.com` | `password123` | **PATIENT** |
| `nour.fathy@gmail.com` | `password123` | **PATIENT** |

---

## Project Structure

```
hospital_project/
├── api/                        # FastAPI REST layer
│   ├── main.py                 # FastAPI app with CORS, 16 routers
│   ├── config.py               # Django ORM setup for FastAPI
│   ├── deps.py                 # get_current_user (Supabase JWT validation)
│   ├── validators.py           # Shared input validators (phone, slot)
│   └── routers/                # 16 route modules
│       ├── auth.py             # Register + login
│       ├── accounts.py         # Profile, dashboard, timeline, password
│       ├── appointments.py     # CRUD + cancel + doctor actions
│       ├── doctors.py          # List, specialties, dashboard, availability
│       ├── pharmacy.py         # Medicines, orders, pharmacist dashboard
│       ├── billing.py          # Invoices
│       ├── laboratory.py       # Tests, bookings, lab tech dashboard
│       ├── medical_records.py  # Patient records
│       ├── prescriptions.py    # Prescriptions + refills
│       ├── notifications.py    # Notifications + health tips
│       ├── feedback.py         # Submit + list
│       ├── insurance.py        # Providers, policies, claims
│       ├── emergency_contacts.py # CRUD
│       ├── telegram.py         # Per-user Telegram linking (link/sync)
│       ├── admin.py            # 25 admin endpoints
│       └── search.py           # Global search
├── core/                       # Django app
│   ├── auth_backend.py         # Supabase JWT → Django User
│   ├── supabase_client.py      # Supabase client singleton
│   ├── notify.py               # In-app notification engine
│   ├── telegram.py             # Telegram bot alerts
│   ├── urls.py                 # Django URL routing
│   ├── views/
│   │   ├── auth.py             # Django register/login/logout/me
│   │   ├── pages.py            # All page-based views (~1320 lines)
│   │   └── admin.py            # Admin CRUD (~1050 lines)
│   ├── templates/core/         # HTML templates (50+ files)
│   ├── static/core/            # CSS, JS assets
│   └── models/                 # 14 sub-apps
│       ├── accounts/           # User, UserPreference, PasswordResetOTP, TelegramLink
│       ├── appointments/       # Appointment
│       ├── billing/            # Invoice, InvoiceItem
│       ├── core/               # GeneratedReport, AnalyticsSnapshot
│       ├── doctors/            # Doctor, Specialty, Availability, Metrics
│       ├── emergency_contacts/ # EmergencyContact
│       ├── feedback/           # Feedback
│       ├── insurance/          # Provider, HealthInsurance, Claim
│       ├── laboratory/         # LabTest, Booking, Result
│       ├── medical_records/    # PatientRecord, TestResult
│       ├── notifications/      # Notification, HealthTip
│       ├── payments/           # Payment
│       ├── pharmacy/           # Medicine, Order, OrderItem
│       └── prescriptions/      # Prescription, Item, Refill
├── hospital_project/           # Django project config
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py / asgi.py
├── scripts/
│   ├── seed_data.py            # Comprehensive seed data
│   └── bootstrap_admin.py      # Admin setup command
├── .env                        # Environment configuration
├── .gitignore
├── manage.py
└── requirements.txt
```

---

## Flutter Integration Guide

### Auth Flow

```dart
// 1. Register / Login — call FastAPI endpoints
final response = await http.post(
  Uri.parse('http://localhost:8081/auth/login'),
  body: jsonEncode({'email': email, 'password': password}),
);
final data = jsonDecode(response.body);
final token = data['session']['access_token'];

// 2. Use the token for all subsequent requests
final headers = {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};
```

### Key Endpoints

| Purpose | Endpoint |
|---|---|
| Register | `POST /auth/register` |
| Login | `POST /auth/login` |
| Patient Dashboard | `GET /accounts/me/dashboard` |
| Patient Timeline | `GET /accounts/me/timeline` |
| Book Appointment | `POST /appointments` |
| List Doctors | `GET /doctors` (includes `availability: [{weekday, start_time, end_time}]`) |
| Doctor Detail | `GET /doctors/{id}` |
| Pharmacy Orders | `POST /pharmacy/orders` |
| Lab Bookings | `POST /laboratory/bookings` |
| Notifications | `GET /notifications` |
| Feedback | `POST /feedback` |

### Telegram Notifications

Every in-app notification is also delivered to the user's Telegram chat once linked:

1. `POST /telegram/link` → returns `{token, bot_username, link, linked}`
2. The user opens `https://t.me/<bot_username>?start=<token>` and presses **Start**
3. `POST /telegram/sync` → polls the bot's `getUpdates` and binds `telegram_chat_id` to the account
4. From then on `core/notify.py` sends a per-chat copy of every notification

---

## API Documentation

FastAPI auto-generates OpenAPI docs:

- **Swagger UI**: `http://127.0.0.1:8081/docs`
- **ReDoc**: `http://127.0.0.1:8081/redoc`

---

## Development

```powershell
# Run model changes
python manage.py makemigrations <app_label>
python manage.py migrate

# Create new sub-app
python manage.py startapp <name> core/models/<name>/

# Add to settings.py INSTALLED_APPS:
# 'core.models.<name>',
# Set default_auto_field in core/models/<name>/apps.py

# Run tests
python manage.py test
```

---

## License

MIT
