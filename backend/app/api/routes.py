from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.agent.retention_agent import run_agent, clear_session

router = APIRouter(prefix="/api/v1", tags=["agent"])

class ChatRequest(BaseModel):
    session_id: str = Field(...)
    client_id: str = Field(...)
    message: str = Field(...)

class ChatResponse(BaseModel):
    session_id: str
    client_id: str
    reply: str

class ClearRequest(BaseModel):
    session_id: str

@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    try:
        reply = run_agent(session_id=req.session_id, user_message=f"[Cliente: {req.client_id}]\n{req.message}")
        return ChatResponse(session_id=req.session_id, client_id=req.client_id, reply=reply)
    except EnvironmentError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Agent error: {exc}")

@router.post("/session/clear")
async def clear(req: ClearRequest):
    clear_session(req.session_id)
    return {"message": f"Session '{req.session_id}' cleared."}

@router.get("/health")
async def health():
    return {"status": "ok", "service": "churn-hunters-backend"}
