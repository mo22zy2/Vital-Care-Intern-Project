from decimal import Decimal
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from api.deps import get_current_user
from core.models.billing.models import Invoice, InvoiceItem

router = APIRouter(prefix="/billing", tags=["billing"])


class InvoiceItemOut(BaseModel):
    description: str
    quantity: int
    unit_price: Decimal
    line_total: Decimal

    class Config:
        from_attributes = True


class InvoiceOut(BaseModel):
    id: str
    invoice_number: str
    issue_date: str
    due_date: str
    status: str
    subtotal: Decimal
    tax_amount: Decimal
    discount_amount: Decimal
    total_amount: Decimal
    items: list[InvoiceItemOut]

    class Config:
        from_attributes = True


@router.get("/invoices", response_model=list[InvoiceOut])
def list_invoices(user=Depends(get_current_user)):
    qs = Invoice.objects.filter(patient=user).prefetch_related("items")
    result = []
    for inv in qs:
        result.append(
            InvoiceOut(
                id=str(inv.id),
                invoice_number=inv.invoice_number,
                issue_date=inv.issue_date.isoformat(),
                due_date=inv.due_date.isoformat(),
                status=inv.status,
                subtotal=inv.subtotal,
                tax_amount=inv.tax_amount,
                discount_amount=inv.discount_amount,
                total_amount=inv.total_amount,
                items=[
                    InvoiceItemOut(
                        description=i.description,
                        quantity=i.quantity,
                        unit_price=i.unit_price,
                        line_total=i.line_total,
                    )
                    for i in inv.items.all()
                ],
            )
        )
    return result


@router.get("/invoices/{invoice_id}", response_model=InvoiceOut)
def get_invoice(invoice_id: str, user=Depends(get_current_user)):
    from django.shortcuts import get_object_or_404
    inv = get_object_or_404(
        Invoice.objects.prefetch_related("items").filter(patient=user), id=invoice_id
    )
    return InvoiceOut(
        id=str(inv.id),
        invoice_number=inv.invoice_number,
        issue_date=inv.issue_date.isoformat(),
        due_date=inv.due_date.isoformat(),
        status=inv.status,
        subtotal=inv.subtotal,
        tax_amount=inv.tax_amount,
        discount_amount=inv.discount_amount,
        total_amount=inv.total_amount,
        items=[
            InvoiceItemOut(
                description=i.description,
                quantity=i.quantity,
                unit_price=i.unit_price,
                line_total=i.line_total,
            )
            for i in inv.items.all()
        ],
    )
