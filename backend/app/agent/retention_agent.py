import os
import google.generativeai as genai
from google.generativeai.types import FunctionDeclaration, Tool
from app.tools.churn_tools import TOOL_REGISTRY

_SURVEY_TOOL = FunctionDeclaration(
    name="get_client_survey_results",
    description="Retrieves NPS and satisfaction survey responses for a client.",
    parameters={"type":"object","properties":{"client_id":{"type":"string"}},"required":["client_id"]},
)
_RISK_TOOL = FunctionDeclaration(
    name="get_churn_risk_score",
    description="Returns churn risk score and contributing factors for a client.",
    parameters={"type":"object","properties":{"client_id":{"type":"string"}},"required":["client_id"]},
)
GEMINI_TOOLS = [Tool(function_declarations=[_SURVEY_TOOL, _RISK_TOOL])]

SYSTEM_PROMPT = """Eres el agente principal de Churn Hunters.
Tu objetivo es analizar datos de clientes, detectar el riesgo de fuga (churn)
antes de que suceda y generar estrategias de retención personalizadas.
Reglas:
1. Usa las herramientas para consultar reportes antes de emitir diagnóstico.
2. Explica el razonamiento detrás de tu evaluación.
3. Proporciona entre 3 y 5 acciones de retención concretas y priorizadas.
4. Responde siempre en el idioma del usuario."""

_sessions: dict[str, list] = {}

def clear_session(session_id: str) -> None:
    _sessions.pop(session_id, None)

def run_agent(session_id: str, user_message: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise EnvironmentError("GEMINI_API_KEY is not set.")
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(model_name="gemini-1.5-flash", system_instruction=SYSTEM_PROMPT, tools=GEMINI_TOOLS)
    if session_id not in _sessions:
        _sessions[session_id] = []
    chat = model.start_chat(history=_sessions[session_id])
    response = chat.send_message(user_message)
    while True:
        calls = [p.function_call for c in response.candidates for p in c.content.parts if p.function_call.name]
        if not calls:
            break
        tool_responses = []
        for fc in calls:
            fn = TOOL_REGISTRY.get(fc.name)
            result = fn(**dict(fc.args)) if fn else {"error": f"Tool '{fc.name}' not found."}
            tool_responses.append(genai.protos.Part(function_response=genai.protos.FunctionResponse(name=fc.name, response={"result": result})))
        response = chat.send_message(tool_responses)
    _sessions[session_id] = chat.history
    return "\n".join(p.text for c in response.candidates for p in c.content.parts if hasattr(p,"text") and p.text).strip()
