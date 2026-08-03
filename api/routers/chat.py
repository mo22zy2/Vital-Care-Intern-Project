import httpx
from fastapi import APIRouter, Depends, HTTPException

from api.deps import get_current_user

router = APIRouter(prefix="/chat", tags=["chat"])

RAG_ENDPOINT = "http://localhost:9000/api/v1/nlp/index/answer/21"


@router.post("/ask")
def chat_ask(payload: dict, user=Depends(get_current_user)):
    text = (payload.get("text") or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")
    try:
        resp = httpx.post(
            RAG_ENDPOINT,
            json={"text": text, "limit": payload.get("limit", 5)},
            timeout=30,
        )
    except Exception:
        raise HTTPException(status_code=502, detail="Assistant service unreachable")
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Assistant service error")
    try:
        data = resp.json()
    except Exception:
        raise HTTPException(status_code=502, detail="Assistant returned invalid data")
    answer = data.get("answer") or data.get("text") or ""
    return {"answer": answer, "sources": data.get("sources") or data.get("documents") or []}
