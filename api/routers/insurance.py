from datetime import date
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator, model_validator

from api.deps import get_current_user
from api.validators import coverage_percentage as validate_coverage, positive
from core.models.insurance.models import HealthInsurance, InsuranceClaim, InsuranceProvider

router = APIRouter(prefix="/insurance", tags=["insurance"])


class ProviderOut(BaseModel):
    id: int
    name: str
    contact_email: str
    contact_phone: str

    class Config:
        from_attributes = True


class PolicyOut(BaseModel):
    id: str
    provider_name: str
    policy_number: str
    group_number: str
    coverage_details: str
    coverage_percentage: Decimal
    valid_from: str
    valid_to: str
    verification_status: str

    class Config:
        from_attributes = True


class PolicyCreate(BaseModel):
    provider_id: int
    policy_number: str
    group_number: str = ""
    coverage_details: str = ""
    coverage_percentage: Decimal = 0
    valid_from: date
    valid_to: date

    _coverage = field_validator("coverage_percentage")(validate_coverage)

    @model_validator(mode="after")
    def validate_dates(self):
        if self.valid_to <= self.valid_from:
            raise ValueError("Policy end date must be after start date")
        return self


class ClaimOut(BaseModel):
    id: str
    invoice_number: str
    claim_amount: Decimal
    approved_amount: Decimal | None
    status: str
    submitted_at: str
    resolved_at: str | None
    notes: str

    class Config:
        from_attributes = True


class ClaimCreate(BaseModel):
    policy_id: str
    invoice_id: str
    claim_amount: Decimal
    notes: str = ""

    _claim_amount = field_validator("claim_amount")(positive)


@router.get("/providers", response_model=list[ProviderOut])
def list_providers(user=Depends(get_current_user)):
    return [
        ProviderOut(id=p.id, name=p.name, contact_email=p.contact_email, contact_phone=p.contact_phone)
        for p in InsuranceProvider.objects.filter(is_active=True)
    ]


@router.get("/policies", response_model=list[PolicyOut])
def list_policies(user=Depends(get_current_user)):
    qs = HealthInsurance.objects.filter(patient=user).select_related("provider")
    return [
        PolicyOut(
            id=str(p.id),
            provider_name=p.provider.name,
            policy_number=p.policy_number,
            group_number=p.group_number,
            coverage_details=p.coverage_details,
            coverage_percentage=p.coverage_percentage,
            valid_from=p.valid_from.isoformat(),
            valid_to=p.valid_to.isoformat(),
            verification_status=p.verification_status,
        )
        for p in qs
    ]


@router.post("/policies", status_code=201)
def create_policy(body: PolicyCreate, user=Depends(get_current_user)):
    provider = InsuranceProvider.objects.filter(id=body.provider_id, is_active=True).first()
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")
    p = HealthInsurance.objects.create(
        patient=user,
        provider=provider,
        policy_number=body.policy_number,
        group_number=body.group_number,
        coverage_details=body.coverage_details,
        coverage_percentage=body.coverage_percentage,
        valid_from=body.valid_from,
        valid_to=body.valid_to,
    )
    return {"id": str(p.id)}


@router.get("/claims", response_model=list[ClaimOut])
def list_claims(user=Depends(get_current_user)):
    qs = InsuranceClaim.objects.filter(insurance__patient=user).select_related("invoice", "insurance")
    return [
        ClaimOut(
            id=str(c.id),
            invoice_number=c.invoice.invoice_number,
            claim_amount=c.claim_amount,
            approved_amount=c.approved_amount,
            status=c.status,
            submitted_at=c.submitted_at.isoformat(),
            resolved_at=c.resolved_at.isoformat() if c.resolved_at else None,
            notes=c.notes,
        )
        for c in qs
    ]


@router.post("/claims", status_code=201)
def submit_claim(body: ClaimCreate, user=Depends(get_current_user)):
    policy = HealthInsurance.objects.filter(id=body.policy_id, patient=user).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Insurance policy not found")
    from core.models.billing.models import Invoice
    invoice = Invoice.objects.filter(id=body.invoice_id, patient=user).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    c = InsuranceClaim.objects.create(
        insurance=policy,
        invoice=invoice,
        claim_amount=body.claim_amount,
        notes=body.notes,
    )
    return {"id": str(c.id)}
