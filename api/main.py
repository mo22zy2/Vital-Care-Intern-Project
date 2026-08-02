import api.config

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routers import (
    accounts,
    admin,
    appointments,
    auth,
    billing,
    doctors,
    emergency_contacts,
    feedback,
    insurance,
    laboratory,
    medical_records,
    notifications,
    pharmacy,
    prescriptions,
    search,
    telegram,
)

app = FastAPI(title="Hospital API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
app.include_router(telegram.router)


@app.get("/health")
def health():
    return {"status": "ok"}
