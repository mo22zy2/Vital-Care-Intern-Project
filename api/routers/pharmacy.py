from decimal import Decimal
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from api.deps import get_current_user
from core.models.pharmacy.models import Medicine, PharmacyOrder, PharmacyOrderItem
from core.notify import notify_order_placed

router = APIRouter(prefix="/pharmacy", tags=["pharmacy"])


class MedicineOut(BaseModel):
    id: str
    name: str
    generic_name: str
    dosage_form: str
    strength: str
    price: Decimal
    stock_quantity: int
    requires_prescription: bool

    class Config:
        from_attributes = True


@router.get("/medicines", response_model=list[MedicineOut])
def list_medicines(search: str = "", user=Depends(get_current_user)):
    qs = Medicine.objects.filter(is_active=True)
    if search:
        qs = qs.filter(name__icontains=search)
    return [
        MedicineOut(
            id=str(m.id),
            name=m.name,
            generic_name=m.generic_name,
            dosage_form=m.dosage_form,
            strength=m.strength,
            price=m.price,
            stock_quantity=m.stock_quantity,
            requires_prescription=m.requires_prescription,
        )
        for m in qs
    ]


class OrderItemIn(BaseModel):
    medicine_id: str
    quantity: int = Field(ge=1, description="Quantity must be at least 1")


class OrderCreate(BaseModel):
    items: list[OrderItemIn] = Field(min_length=1, description="At least one item is required")


class OrderOut(BaseModel):
    id: str
    status: str
    total: str
    items: list[dict]

    class Config:
        from_attributes = True


@router.post("/orders", response_model=OrderOut, status_code=201)
def create_order(body: OrderCreate, user=Depends(get_current_user)):
    from django.db import transaction

    with transaction.atomic():
        order = PharmacyOrder.objects.create(patient=user)
        items_out = []
        total = Decimal("0.00")
        for item in body.items:
            try:
                medicine_id = uuid.UUID(item.medicine_id)
            except (ValueError, AttributeError):
                raise HTTPException(status_code=404, detail=f"Medicine {item.medicine_id} not found")
            medicine = Medicine.objects.select_for_update().filter(id=medicine_id, is_active=True).first()
            if not medicine:
                raise HTTPException(status_code=404, detail=f"Medicine {item.medicine_id} not found")
            if medicine.stock_quantity < item.quantity:
                raise HTTPException(status_code=400, detail=f"Insufficient stock for {medicine.name}")
            order_item = PharmacyOrderItem.objects.create(
                order=order, medicine=medicine, quantity=item.quantity, unit_price=medicine.price
            )
            medicine.stock_quantity -= item.quantity
            medicine.save()
            line_total = medicine.price * item.quantity
            total += line_total
            items_out.append({
                "medicine": medicine.name, "quantity": item.quantity,
                "unit_price": str(medicine.price), "line_total": str(line_total),
            })
    notify_order_placed(order)
    return OrderOut(id=str(order.id), status=order.status, total=str(total), items=items_out)


@router.get("/orders", response_model=list[OrderOut])
def list_orders(user=Depends(get_current_user)):
    orders = PharmacyOrder.objects.filter(patient=user).prefetch_related("items__medicine").order_by("-ordered_at")
    return [
        OrderOut(
            id=str(o.id),
            status=o.status,
            total=str(sum(i.unit_price * i.quantity for i in o.items.all())),
            items=[{"medicine": i.medicine.name, "quantity": i.quantity,
                    "unit_price": str(i.unit_price), "line_total": str(i.unit_price * i.quantity)}
                   for i in o.items.all()],
        )
        for o in orders
    ]


@router.get("/orders/{order_id}", response_model=OrderOut)
def get_order(order_id: str, user=Depends(get_current_user)):
    from django.shortcuts import get_object_or_404

    qs = PharmacyOrder.objects.prefetch_related("items__medicine")
    if user.role in ("ADMIN", "STAFF", "PHARMACIST"):
        order = get_object_or_404(qs, id=order_id)
    else:
        order = get_object_or_404(qs, id=order_id, patient=user)
    items = order.items.all()
    total = sum(i.unit_price * i.quantity for i in items)
    return OrderOut(
        id=str(order.id),
        status=order.status,
        total=str(total),
        items=[{"medicine": i.medicine.name, "quantity": i.quantity,
                "unit_price": str(i.unit_price), "line_total": str(i.unit_price * i.quantity)}
               for i in items],
    )


# ── Pharmacist Dashboard ──

class PharmacistDashboardOut(BaseModel):
    pending_orders: list[dict]
    low_stock: list[dict]
    total_orders: int
    total_medicines: int


@router.get("/dashboard", response_model=PharmacistDashboardOut)
def pharmacist_dashboard(user=Depends(get_current_user)):
    if user.role != "PHARMACIST" and user.role not in ("ADMIN", "STAFF"):
        raise HTTPException(status_code=403, detail="Pharmacist access required")

    pending = PharmacyOrder.objects.filter(status="PENDING").select_related("patient").prefetch_related("items__medicine").order_by("-ordered_at")
    low = Medicine.objects.filter(stock_quantity__lt=10, is_active=True).order_by("stock_quantity")[:20]

    return PharmacistDashboardOut(
        pending_orders=[
            {
                "id": str(o.id),
                "patient_name": o.patient.get_full_name() or o.patient.email,
                "ordered_at": o.ordered_at.isoformat(),
                "items": [{"medicine": i.medicine.name, "quantity": i.quantity} for i in o.items.all()],
            }
            for o in pending
        ],
        low_stock=[
            {"id": str(m.id), "name": m.name, "stock": m.stock_quantity}
            for m in low
        ],
        total_orders=PharmacyOrder.objects.count(),
        total_medicines=Medicine.objects.filter(is_active=True).count(),
    )


class OrderStatusUpdate(BaseModel):
    status: str


ALLOWED_STATUS_TRANSITIONS = {
    "PENDING": ("PROCESSING", "CANCELLED"),
    "PROCESSING": ("READY_FOR_PICKUP", "CANCELLED"),
    "READY_FOR_PICKUP": ("DELIVERED", "CANCELLED"),
    "DELIVERED": (),
    "CANCELLED": (),
}


@router.patch("/orders/{order_id}/status")
def update_order_status(order_id: str, body: OrderStatusUpdate, user=Depends(get_current_user)):
    if user.role != "PHARMACIST" and user.role not in ("ADMIN", "STAFF"):
        raise HTTPException(status_code=403, detail="Pharmacist access required")

    from django.utils import timezone

    valid_statuses = [s[0] for s in PharmacyOrder.Status.choices]
    if body.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Valid: {', '.join(valid_statuses)}")

    order = PharmacyOrder.objects.filter(id=order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if body.status not in ALLOWED_STATUS_TRANSITIONS.get(order.status, ()):
        raise HTTPException(
            status_code=400,
            detail=f"Cannot change order from {order.status} to {body.status}",
        )

    order.status = body.status
    if body.status in ("DELIVERED", "CANCELLED"):
        order.fulfilled_at = timezone.now()
    else:
        order.fulfilled_at = None
    order.save()
    return {"message": f"Order status changed to {order.get_status_display()}"}
