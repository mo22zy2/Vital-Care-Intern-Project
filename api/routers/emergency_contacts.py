from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from api.deps import get_current_user
from core.models.emergency_contacts.models import EmergencyContact

router = APIRouter(prefix="/emergency-contacts", tags=["emergency_contacts"])


class EmergencyContactOut(BaseModel):
    id: str
    full_name: str
    relationship: str
    phone: str
    alternate_phone: str
    email: str
    address: str

    class Config:
        from_attributes = True


class EmergencyContactCreate(BaseModel):
    full_name: str
    relationship: str
    phone: str
    alternate_phone: str = ""
    email: str = ""
    address: str = ""


class EmergencyContactUpdate(BaseModel):
    full_name: str | None = None
    relationship: str | None = None
    phone: str | None = None
    alternate_phone: str | None = None
    email: str | None = None
    address: str | None = None


@router.get("", response_model=list[EmergencyContactOut])
def list_contacts(user=Depends(get_current_user)):
    qs = EmergencyContact.objects.filter(patient=user)
    return [
        EmergencyContactOut(
            id=str(c.id),
            full_name=c.full_name,
            relationship=c.relationship,
            phone=c.phone,
            alternate_phone=c.alternate_phone,
            email=c.email,
            address=c.address,
        )
        for c in qs
    ]


@router.post("", response_model=EmergencyContactOut, status_code=201)
def create_contact(body: EmergencyContactCreate, user=Depends(get_current_user)):
    c = EmergencyContact.objects.create(patient=user, **body.dict())
    return EmergencyContactOut(
        id=str(c.id),
        full_name=c.full_name,
        relationship=c.relationship,
        phone=c.phone,
        alternate_phone=c.alternate_phone,
        email=c.email,
        address=c.address,
    )


@router.get("/{contact_id}", response_model=EmergencyContactOut)
def get_contact(contact_id: str, user=Depends(get_current_user)):
    from django.shortcuts import get_object_or_404
    c = get_object_or_404(EmergencyContact, id=contact_id, patient=user)
    return EmergencyContactOut(
        id=str(c.id),
        full_name=c.full_name,
        relationship=c.relationship,
        phone=c.phone,
        alternate_phone=c.alternate_phone,
        email=c.email,
        address=c.address,
    )


@router.put("/{contact_id}", response_model=EmergencyContactOut)
def update_contact(contact_id: str, body: EmergencyContactUpdate, user=Depends(get_current_user)):
    try:
        c = EmergencyContact.objects.get(id=contact_id, patient=user)
    except EmergencyContact.DoesNotExist:
        raise HTTPException(status_code=404, detail="Contact not found")
    for field, value in body.dict(exclude_unset=True).items():
        setattr(c, field, value)
    c.save()
    return EmergencyContactOut(
        id=str(c.id),
        full_name=c.full_name,
        relationship=c.relationship,
        phone=c.phone,
        alternate_phone=c.alternate_phone,
        email=c.email,
        address=c.address,
    )


@router.delete("/{contact_id}")
def delete_contact(contact_id: str, user=Depends(get_current_user)):
    deleted, _ = EmergencyContact.objects.filter(id=contact_id, patient=user).delete()
    if not deleted:
        raise HTTPException(status_code=404, detail="Contact not found")
    return {"message": "Contact deleted"}
