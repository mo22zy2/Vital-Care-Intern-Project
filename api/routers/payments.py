from decimal import Decimal
from datetime import datetime, timezone

from django.utils import timezone as dj_timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from api.deps import get_current_user
from core.models.billing.models import Invoice
from core.models.payments.models import Payment

router = APIRouter(prefix="/payments", tags=["payments"])


class PaymentOut(BaseModel):
    id: str
    invoice_id: str
    invoice_number: str
    method: str
    status: str
    amount: Decimal
    transaction_reference: str
    paid_at: str | None

    class Config:
        from_attributes = True


class PaymentCreate(BaseModel):
    invoice_id: str
    method: str
    amount: Decimal = Field(gt=0)


@router.get("/payments", response_model=list[PaymentOut])
def list_payments(user=Depends(get_current_user)):
    qs = Payment.objects.filter(patient=user).select_related("invoice").order_by("-created_at")
    return [
        PaymentOut(
            id=str(p.id),
            invoice_id=str(p.invoice_id),
            invoice_number=p.invoice.invoice_number,
            method=p.method,
            status=p.status,
            amount=p.amount,
            transaction_reference=p.transaction_reference,
            paid_at=p.paid_at.isoformat() if p.paid_at else None,
        )
        for p in qs
    ]


@router.get("/invoices/{invoice_id}/payments", response_model=list[PaymentOut])
def invoice_payments(invoice_id: str, user=Depends(get_current_user)):
    invoice = Invoice.objects.filter(id=invoice_id, patient=user).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    qs = Payment.objects.filter(invoice=invoice).order_by("-created_at")
    return [
        PaymentOut(
            id=str(p.id),
            invoice_id=str(p.invoice_id),
            invoice_number=p.invoice.invoice_number,
            method=p.method,
            status=p.status,
            amount=p.amount,
            transaction_reference=p.transaction_reference,
            paid_at=p.paid_at.isoformat() if p.paid_at else None,
        )
        for p in qs
    ]


@router.post("/invoices/{invoice_id}/pay", response_model=PaymentOut)
def pay_invoice(invoice_id: str, body: PaymentCreate, user=Depends(get_current_user)):
    from decimal import Decimal as D

    invoice = Invoice.objects.filter(id=invoice_id, patient=user).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    if invoice.status in ("PAID", "CANCELLED"):
        raise HTTPException(status_code=400, detail=f"Invoice already {invoice.status}")

    method = body.method.upper()
    valid_methods = [m[0] for m in Payment.Method.choices]
    if method not in valid_methods:
        raise HTTPException(status_code=400, detail=f"Invalid payment method. Valid: {', '.join(valid_methods)}")

    paid_total = D(0)
    for p in Payment.objects.filter(invoice=invoice, status="SUCCESS"):
        paid_total += p.amount
    remaining = invoice.total_amount - paid_total
    if body.amount > remaining:
        raise HTTPException(status_code=400, detail="Amount exceeds outstanding balance")

    payment = Payment.objects.create(
        invoice=invoice,
        patient=user,
        method=method,
        status="SUCCESS",
        amount=body.amount,
        transaction_reference=f"VC-{datetime.now(timezone.utc):%Y%m%d%H%M%S}-{invoice.invoice_number}",
        paid_at=dj_timezone.now(),
    )

    new_total = paid_total + body.amount
    if new_total >= invoice.total_amount:
        invoice.status = "PAID"
    else:
        invoice.status = "PARTIALLY_PAID"
    invoice.save(update_fields=["status"])

    return PaymentOut(
        id=str(payment.id),
        invoice_id=str(payment.invoice_id),
        invoice_number=invoice.invoice_number,
        method=payment.method,
        status=payment.status,
        amount=payment.amount,
        transaction_reference=payment.transaction_reference,
        paid_at=payment.paid_at.isoformat() if payment.paid_at else None,
    )
