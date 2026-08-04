import api.config

from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from api.routers import (
    accounts,
    admin,
    appointments,
    auth,
    billing,
    chat,
    doctors,
    emergency_contacts,
    feedback,
    insurance,
    laboratory,
    medical_records,
    notifications,
    payments,
    pharmacy,
    prescriptions,
    search,
)

app = FastAPI(title="Hospital API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Http404)
async def django_http404_handler(request: Request, exc: Http404):
    return JSONResponse(status_code=404, content={"detail": "Not found"})


@app.exception_handler(DjangoValidationError)
async def django_validation_error_handler(request: Request, exc: DjangoValidationError):
    return JSONResponse(status_code=422, content={"detail": "; ".join(exc.messages) or "Invalid input"})


@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(status_code=422, content={"detail": str(exc) or "Invalid value"})

app.include_router(auth.router)
app.include_router(appointments.router)
app.include_router(doctors.router)
app.include_router(pharmacy.router)
app.include_router(billing.router)
app.include_router(laboratory.router)
app.include_router(medical_records.router)
app.include_router(prescriptions.router)
app.include_router(notifications.router)
app.include_router(feedback.router)
app.include_router(insurance.router)
app.include_router(emergency_contacts.router)
app.include_router(accounts.router)
app.include_router(admin.router)
app.include_router(search.router)
app.include_router(payments.router)
app.include_router(chat.router)


@app.get("/health")
def health():
    return {"status": "ok"}
