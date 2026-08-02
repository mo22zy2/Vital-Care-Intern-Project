from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator

from api.deps import get_current_user
from api.validators import not_in_future
from core.models.medical_records.models import PatientRecord, TestResult

router = APIRouter(prefix="/medical-records", tags=["medical_records"])


class TestResultOut(BaseModel):
    id: str
    test_name: str
    result_summary: str
    recorded_at: str

    class Config:
        from_attributes = True


class PatientRecordOut(BaseModel):
    id: str
    doctor_id: str | None
    doctor_name: str
    record_date: date
    diagnosis: str
    treatment_plan: str
    notes: str
    test_results: list[TestResultOut]

    class Config:
        from_attributes = True


class PatientRecordCreate(BaseModel):
    doctor_id: str | None = None
    appointment_id: str | None = None
    record_date: date
    medical_history: str = ""
    diagnosis: str
    treatment_plan: str = ""

    _record_date = field_validator("record_date")(not_in_future)
    notes: str = ""


@router.get("", response_model=list[PatientRecordOut])
def list_records(user=Depends(get_current_user)):
    qs = PatientRecord.objects.filter(patient=user).select_related("doctor__user").prefetch_related("test_results")
    return [
        PatientRecordOut(
            id=str(r.id),
            doctor_id=str(r.doctor_id) if r.doctor else None,
            doctor_name=f"Dr. {r.doctor.user.get_full_name()}" if r.doctor else "N/A",
            record_date=r.record_date,
            diagnosis=r.diagnosis,
            treatment_plan=r.treatment_plan,
            notes=r.notes,
            test_results=[
                TestResultOut(
                    id=str(t.id),
                    test_name=t.test_name,
                    result_summary=t.result_summary,
                    recorded_at=t.recorded_at.isoformat(),
                )
                for t in r.test_results.all()
            ],
        )
        for r in qs
    ]


@router.get("/{record_id}", response_model=PatientRecordOut)
def get_record(record_id: str, user=Depends(get_current_user)):
    from django.shortcuts import get_object_or_404
    r = get_object_or_404(
        PatientRecord.objects.select_related("doctor__user").prefetch_related("test_results"),
        id=record_id, patient=user,
    )
    return PatientRecordOut(
        id=str(r.id),
        doctor_id=str(r.doctor_id) if r.doctor else None,
        doctor_name=f"Dr. {r.doctor.user.get_full_name()}" if r.doctor else "N/A",
        record_date=r.record_date,
        diagnosis=r.diagnosis,
        treatment_plan=r.treatment_plan,
        notes=r.notes,
        test_results=[
            TestResultOut(
                id=str(t.id),
                test_name=t.test_name,
                result_summary=t.result_summary,
                recorded_at=t.recorded_at.isoformat(),
            )
            for t in r.test_results.all()
        ],
    )


@router.post("", status_code=201)
def create_record(body: PatientRecordCreate, user=Depends(get_current_user)):
    from core.models.doctors.models import Doctor
    doctor = None
    if body.doctor_id:
        doctor = Doctor.objects.filter(id=body.doctor_id).first()
    r = PatientRecord.objects.create(
        patient=user,
        doctor=doctor,
        record_date=body.record_date,
        medical_history=body.medical_history,
        diagnosis=body.diagnosis,
        treatment_plan=body.treatment_plan,
        notes=body.notes,
    )
    return {"id": str(r.id)}
