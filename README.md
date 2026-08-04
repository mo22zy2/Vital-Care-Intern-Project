# 🏥 VitalCare Hospital Management System

[![Django](https://img.shields.io/badge/Django-4.2-092E20?logo=django)](https://www.djangoproject.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com/)
[![Supabase](https://img.shields.io/badge/Supabase-Auth-3ECF8E?logo=supabase)](https://supabase.com/)
[![Flutter](https://img.shields.io/badge/Flutter-ready-02569B?logo=flutter)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python)](https://python.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A full-featured hospital management platform with a **Django web UI** for staff/admin and a **FastAPI REST API** powering the **Flutter mobile app**. Built on Supabase Auth, 14 domain models, role-based dashboards, and 100+ API endpoints.

---

## Table of Contents

- [Highlights](#highlights)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Knowledge Graph](#knowledge-graph)
- [Flutter Integration Guide](#flutter-integration-guide)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Development](#development)
- [Deployment](#deployment)
- [Security](#security)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Highlights

- **Two interfaces, one database** — Django (web) and FastAPI (mobile API) share the same data through the Django ORM.
- **Role-based access** — Patient, Doctor, Pharmacist, Lab Tech, Admin/Staff each get dedicated dashboards and permissions.
- **Supabase Auth** — JWT-based authentication with a local Django fallback for offline/dev use.
- **Smart workflows** — Appointment slots that can't be double-booked (and cancelled slots can be re-booked), pharmacy order status transitions, lab sample → result pipelines.
- **Push-style notifications** — In-app notifications plus optional per-user **Telegram** delivery.
- **Interactive knowledge graph** — a browsable visualization of the whole codebase ships in the repo (see [Knowledge Graph](#knowledge-graph)).

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App 8082                 │
│              (mobile — consumes JSON API)           │
└────────────────────────┬────────────────────────────┘
                         │ Authorization: Bearer <token>
                         ▼
┌─────────────────────────────────────────────────────┐
│               FastAPI (port 8081)                   │
│  17 routers · 100+ endpoints · Pydantic schemas     │
│  Supabase JWT validation · Django ORM integration   │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              Django ORM (shared database)           │
│  14 sub-apps · 30+ models · Custom migrations       │
└────────────────────────┬────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      ┌──────────────┐    ┌──────────────┐
      │  PostgreSQL  │    │   SQLite     │
      │  (Supabase)  │    │  (local dev) │
      └──────────────┘    └──────────────┘
                         ▲
┌─────────────────────────────────────────────────────┐
│            Django (port 8080)                       │
│  VitalCare Web UI · Admin Dashboard · Template views│
│  Auth with Supabase + Django fallback               │
└─────────────────────────────────────────────────────┘
```

**Key insight:** Django and FastAPI are independent processes that share the same database through the Django ORM. They never communicate directly — the Flutter app talks to FastAPI, browsers talk to Django.

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
- **Laboratory** — Test catalog, booking, sample collection, result release (with enforced status transitions)
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
| **ORM** | Django ORM (shared by Django & FastAPI) |
| **Mobile** | Flutter (via FastAPI JSON endpoints) |
| **Notifications** | Telegram Bot API |
| **Seed Data** | 14 users, 4 doctors, sample data across all models |

---

## Quick Start

### Prerequisites

- Python 3.10+
- Conda (recommended) or venv
- Supabase project (optional — the app runs fully with SQLite + password auth)

### Setup

```powershell
# 1. Clone and enter the project
git clone https://github.com/mo22zy2/Vital-Care-Intern-Project.git
cd hospital_project

# 2. Create conda environment
conda create -n hospital_env python=3.10 -y
conda activate hospital_env

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
copy .env.example .env    # then edit with your own keys
# Supabase credentials are optional — without them the app uses SQLite + local password auth

# 5. Run migrations
python manage.py makemigrations
python manage.py migrate

# 6. Seed sample data
python scripts/seed_data.py

# 7. Start the servers (three terminals)

# Terminal 1 — Django Web UI (port 8080)
python manage.py runserver 8080

# Terminal 2 — FastAPI for Flutter (port 8081)
uvicorn api.main:app --reload --port 8081

# Terminal 3 — Flutter (port 8082)
flutter run -d edge --web-port 8082
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
│   ├── main.py                 # FastAPI app with CORS, 17 routers
│   ├── config.py               # Django ORM setup for FastAPI
│   ├── deps.py                 # get_current_user (Supabase JWT validation)
│   ├── validators.py           # Shared input validators (phone, slot)
│   └── routers/                # 17 route modules (100+ endpoints)
│       ├── auth.py             # Register + login
│       ├── accounts.py         # Profile, dashboard, timeline, password
│       ├── appointments.py     # CRUD + cancel + doctor actions
│       ├── doctors.py          # List, specialties, dashboard, availability
│       ├── pharmacy.py         # Medicines, orders, pharmacist dashboard
│       ├── billing.py          # Invoices
│       ├── payments.py         # Invoice payments
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
│   ├── supabase_client.py      # Supabase client singletons (anon/service)
│   ├── notify.py               # In-app notification engine
│   ├── telegram.py             # Telegram bot alerts
│   ├── urls.py                 # Django URL routing
│   ├── views/
│   │   ├── auth.py             # Django register/login/logout/me
│   │   ├── pages.py            # All page-based views
│   │   └── admin.py            # Admin CRUD
│   ├── templates/core/         # HTML templates (50+ files)
│   ├── static/core/            # CSS, JS assets
│   └── models/                 # 14 sub-apps
│       ├── accounts/           # User, UserPreference, PasswordResetOTP, TelegramLink
│       │   └── tests.py        # API regression test suite
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
├── graphify-out/
│   └── graph.html              # Interactive knowledge graph (see below)
├── .env.example                # Template for environment configuration
├── .env                        # Your environment configuration (git-ignored)
├── .gitignore
├── manage.py
└── requirements.txt
```

---

## Knowledge Graph

[`graphify-out/graph.html`](graphify-out/graph.html) is an **interactive knowledge graph** of the entire codebase — modules, classes, functions, routes, and how they connect. Open it in any browser:

```
start graphify-out/graph.html
```

Features:

- **Zoom / pan** the graph, click any node for details (file, line, docstring).
- **Search** any symbol from the sidebar.
- **Hyper-edge clusters** highlight related groups (e.g., all Supabase auth files).

It is generated with the [graphify](https://github.com/anomalyco/opencode) skill — regenerate it after significant refactors so it stays current. The folder's generated cache and intermediate files are git-ignored; only `graph.html` is tracked.

---

## Flutter Integration Guide

### Configuring the Base URLs

By default the app targets localhost/emulator hosts. Override them at build time with `--dart-define`:

```bash
# Web — point at your deployed API
flutter run -d edge --web-port 8082 \
  --dart-define=API_BASE_URL=https://api.vitalcare.example.com \
  --dart-define=RAG_BASE_URL=https://rag.vitalcare.example.com
```

Defaults (in `vitalcare_flutter/lib/core/constants/api_constants.dart`): web → `http://localhost:8081`, Android emulator → `http://10.0.2.2:8081` (RAG on port `9000`).

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

## Testing

The repo ships an API regression suite covering auth, role enforcement, input validation, booking conflict handling, payment rules, pharmacy order flow, and the lab pipeline:

```powershell
# Run the API regression suite
python manage.py test core.models.accounts

# Run every test in the project
python manage.py test
```

Tests run against a dedicated test database (`test_db.sqlite3`), so they never touch your dev data. They use FastAPI's ASGI transport directly, so no live server is required.

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
python manage.py test <app_label>
```

**Model conventions** (read before adding models):

- All models use UUID primary keys (`uuid.uuid4`, `editable=False`); `accounts.User` also has `supabase_uid`.
- `BigAutoField` default is set in each sub-app's `apps.py`.
- Cross-app FK references use dotted string paths (e.g. `"doctors.Doctor"`).
- `settings.AUTH_USER_MODEL` is used for patient/user FK fields.

---

## Deployment

### Django (Web)

```powershell
# 1. Production settings
# Set DJANGO_DEBUG=False and a strong DJANGO_SECRET_KEY in .env

# 2. Collect static files into STATIC_ROOT
python manage.py collectstatic

# 3. Run with a production WSGI server
gunicorn hospital_project.wsgi:application
# or on Windows: waitress-serve --port=8080 hospital_project.wsgi:application
```

### FastAPI (Mobile API)

```powershell
# Serve the API with a production ASGI server
uvicorn api.main:app --host 0.0.0.0 --port 8081 --workers 2
```

### Database

The app runs on SQLite by default. To use the Supabase PostgreSQL instance, set `DATABASE_URL` in `.env` (it is already parsed in `hospital_project/settings.py`).

---

## Security

- Passwords are never stored or logged in plain text — Supabase handles auth; local fallback uses Django's password hashers.
- JWT access tokens are validated on every protected endpoint; admin routes require an `ADMIN`/superuser role.
- Login redirects are validated against the current host to prevent open redirects.
- Environment secrets live only in `.env`, which is git-ignored; `.env.example` documents the required keys without values.
- API input is validated with Pydantic (types, ranges, enums) plus explicit state-transition checks, so malformed requests return `400/404/409/422` instead of crashing with `500`.

---

## Roadmap

- [x] Role-based web dashboards and admin panel
- [x] Supabase Auth with local fallback and password reset flow
- [x] Appointment, pharmacy, and laboratory workflow state machines
- [x] API input hardening and regression test suite
- [ ] Telemedicine / video appointments
- [ ] Patient-facing mobile profile & records screen polish
- [ ] CI pipeline (lint, tests, migrations check)
- [ ] Containerization (Docker Compose for local stack)

---

## Contributing

1. Fork the repository and create a feature branch (`git checkout -b feat/my-feature`).
2. Make your changes; keep commits scoped to a single concern.
3. Run the test suite before opening a PR (see [Testing](#testing)).
4. Open a pull request describing the change and any QA performed.

Please keep the README's feature/architecture sections up to date when you add or remove functionality.

---

## License

MIT
