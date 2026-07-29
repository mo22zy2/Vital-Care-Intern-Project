from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from api.deps import get_current_user
from core.models.prescriptions.models import Prescription, PrescriptionItem, PrescriptionRefill

router = APIRouter(prefix="/prescriptions", tags=["prescriptions"])


class PrescriptionItemOut(BaseModel):
    id: str
    medicine_name: str
    dosage: str
    duration_days: int
    quantity: int
    instructions: str

    class Config:
        from_attributes = True


class PrescriptionOut(BaseModel):
    id: str
    doctor_name: str
    date_prescribed: str
    status: str
    notes: str
    items: list[PrescriptionItemOut]

    class Config:
        from_attributes = True


class RefillOut(BaseModel):
    id: str
    status: str
    requested_at: str
    fulfilled_at: str | None

    class Config:
        from_attributes = True


@router.get("", response_model=list[PrescriptionOut])
def list_prescriptions(user=Depends(get_current_user)):
    qs = Prescription.objects.filter(patient=user).select_related("doctor__user").prefetch_related("items__medicine")
    return [
        PrescriptionOut(
            id=str(p.id),
            doctor_name=f"Dr. {p.doctor.user.get_full_name()}" if p.doctor else "N/A",
            date_prescribed=p.date_prescribed.isoformat(),
            status=p.status,
            notes=p.notes,
            items=[
                PrescriptionItemOut(
                    id=str(i.id),
                    medicine_name=i.medicine.name if i.medicine else "Unknown",
                    dosage=i.dosage,
                    duration_days=i.duration_days,
                    quantity=i.quantity,
                    instructions=i.instructions,
                )
                for i in p.items.all()
            ],
        )
        for p in qs
    ]


@router.get("/{prescription_id}", response_model=PrescriptionOut)
def get_prescription(prescription_id: str, user=Depends(get_current_user)):
    from django.shortcuts import get_object_or_404
    p = get_object_or_404(
        Prescription.objects.select_related("doctor__user").prefetch_related("items__medicine"),
        id=prescription_id, patient=user,
    )
    return PrescriptionOut(
        id=str(p.id),
        doctor_name=f"Dr. {p.doctor.user.get_full_name()}" if p.doctor else "N/A",
        date_prescribed=p.date_prescribed.isoformat(),
        status=p.status,
        notes=p.notes,
        items=[
            PrescriptionItemOut(
                id=str(i.id),
                medicine_name=i.medicine.name if i.medicine else "Unknown",
                dosage=i.dosage,
                duration_days=i.duration_days,
                quantity=i.quantity,
                instructions=i.instructions,
            )
            for i in p.items.all()
        ],
    )


class RefillRequest(BaseModel):
    prescription_item_id: str


@router.post("/refills", response_model=RefillOut, status_code=201)
def request_refill(body: RefillRequest, user=Depends(get_current_user)):
    item = PrescriptionItem.objects.filter(
        id=body.prescription_item_id,
        prescription__patient=user,
        prescription__status="ACTIVE",
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Prescription item not found or not active")
    refill = PrescriptionRefill.objects.create(prescription_item=item)
    return RefillOut(
        id=str(refill.id),
        status=refill.status,
        requested_at=refill.requested_at.isoformat(),
        fulfilled_at=None,
    )


@router.get("/refills", response_model=list[RefillOut])
def list_refills(user=Depends(get_current_user)):
    refills = PrescriptionRefill.objects.filter(
        prescription_item__prescription__patient=user
    ).select_related("prescription_item")
    return [
        RefillOut(
            id=str(r.id),
            status=r.status,
            requested_at=r.requested_at.isoformat(),
            fulfilled_at=r.fulfilled_at.isoformat() if r.fulfilled_at else None,
        )
        for r in refills
    ]
