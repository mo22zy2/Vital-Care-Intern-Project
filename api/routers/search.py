from fastapi import APIRouter, Depends
from pydantic import BaseModel
from django.contrib.auth import get_user_model

from api.deps import get_current_user

router = APIRouter(prefix="/search", tags=["search"])
User = get_user_model()


class SearchResult(BaseModel):
    type: str
    label: str
    id: str


class SearchOut(BaseModel):
    results: list[SearchResult]
    total: int


@router.get("", response_model=SearchOut)
def global_search(q: str = "", user=Depends(get_current_user)):
    from django.db.models import Q
    from core.models.doctors.models import Doctor
    from core.models.pharmacy.models import Medicine
    from core.models.laboratory.models import LabTest
    from core.models.billing.models import Invoice

    results = []

    if q:
        doctors = Doctor.objects.filter(
            Q(user__first_name__icontains=q) | Q(user__last_name__icontains=q),
            is_active=True,
        ).select_related("user")[:10]
        for d in doctors:
            results.append(SearchResult(type="doctor", label=f"Dr. {d.user.get_full_name()}", id=str(d.id)))

        meds = Medicine.objects.filter(
            Q(name__icontains=q) | Q(generic_name__icontains=q),
            is_active=True,
        )[:10]
        for m in meds:
            results.append(SearchResult(type="medicine", label=m.name, id=str(m.id)))

        tests = LabTest.objects.filter(name__icontains=q, is_active=True)[:10]
        for t in tests:
            results.append(SearchResult(type="lab_test", label=t.name, id=str(t.id)))

        if user.role in ("ADMIN", "STAFF"):
            users = User.objects.filter(
                Q(first_name__icontains=q) | Q(last_name__icontains=q) | Q(email__icontains=q)
            )[:10]
            for u in users:
                results.append(SearchResult(type="user", label=u.get_full_name() or u.email, id=str(u.id)))

            invoices = Invoice.objects.filter(
                Q(invoice_number__icontains=q) | Q(patient__first_name__icontains=q)
            ).select_related("patient")[:10]
            for i in invoices:
                results.append(SearchResult(type="invoice", label=i.invoice_number, id=str(i.id)))

    return SearchOut(results=results, total=len(results))
