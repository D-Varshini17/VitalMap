import os
from pathlib import Path
from typing import Any, Dict

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from starlette.concurrency import run_in_threadpool

from .ai_recommendation import AIRecommendationService
from .explanation_engine import ExplanationEngine
from .formulas import FormulaEngine
from .local_health_tools import LocalHealthToolsError, LocalHealthToolsService
from .schemas import AnalyzeRequest, AnalyzeResponse


def _load_backend_env() -> None:
    env_path = Path(__file__).resolve().parents[1] / ".env"
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_backend_env()

app = FastAPI(title="VitalMap Backend")

DEFAULT_CORS_ORIGINS = (
    "http://localhost:3000,http://127.0.0.1:3000,"
    "http://localhost:5000,http://127.0.0.1:5000,"
    "http://localhost:8000,http://127.0.0.1:8000,"
    "http://localhost:8080,http://127.0.0.1:8080,"
    "http://localhost:8081,http://127.0.0.1:8081"
)
DEFAULT_CORS_ORIGIN_REGEX = r"^(?:http://(?:localhost|127\.0\.0\.1)(?::\d+)?|https://.*\.vercel\.app)$"

cors_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ALLOW_ORIGINS", DEFAULT_CORS_ORIGINS).split(",")
    if origin.strip()
]
if not cors_origins:
    cors_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_origin_regex=os.getenv(
        "CORS_ALLOW_ORIGIN_REGEX",
        DEFAULT_CORS_ORIGIN_REGEX,
    ),
    allow_credentials="*" not in cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = FormulaEngine()
explainer = ExplanationEngine()
ai_recommendation = AIRecommendationService()
local_health_tools = LocalHealthToolsService()


def _analyze_payload(payload: AnalyzeRequest) -> AnalyzeResponse:
    payload_dict = payload.model_dump()
    results, more_needed, general_health_pattern = engine.analyze(payload_dict)
    overall = explainer.overall_risk(results, more_needed)
    disclaimer = explainer.disclaimer()
    # Screening stays fast and deterministic. Generative Ollama guidance is
    # requested on demand from View Details, reviewed report insights, or
    # History comparison; it never blocks or alters the formula result.
    ai = {
        "provider": "ollama",
        "cloud_ai": "Disabled",
        "local_only": True,
        "mode": "on_demand_guidance",
        "message": (
            "Deterministic screening completed. Local Ollama guidance is generated "
            "only when the user opens a supported guidance feature."
        ),
    }
    return AnalyzeResponse(
        overall_risk=overall,
        calculated_results=results,
        more_data_needed=more_needed,
        general_health_pattern=general_health_pattern,
        disclaimer=disclaimer,
        ai=ai,
    )


@app.get("/")
def root():
    return {
        "name": "VitalMap Backend",
        "status": "running",
        "docs": "/docs",
        "health": "/health",
        "ai_status": "/ai/status",
        "local_tools_status": "/tools/status",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "VitalMap Backend",
        "revision": os.getenv("RENDER_GIT_COMMIT", os.getenv("VITALMAP_BUILD_REVISION", "local")),
        "provider": "ollama",
        "cloud_ai": "disabled",
        "local_only": True,
    }


@app.get("/ai/status")
def ai_status():
    return ai_recommendation.status()


@app.get("/tools/status")
def tools_status():
    try:
        return local_health_tools.status()
    except LocalHealthToolsError as exc:
        return {
            "provider": "ollama",
            "local_only": True,
            "cloud_ai": "Disabled",
            "available": False,
            "error": str(exc),
        }


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    return _analyze_payload(payload)


@app.post("/predict", response_model=AnalyzeResponse)
def predict(payload: AnalyzeRequest):
    return _analyze_payload(payload)


@app.post("/tools/lab-report/scan")
async def scan_lab_report(file: UploadFile = File(...)):
    # Keep uploads bounded because reports are processed in-memory and are sent
    # only to the local Ollama process.
    data = await file.read(12 * 1024 * 1024 + 1)
    if len(data) > 12 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Report must be 12 MB or smaller.")
    try:
        return await run_in_threadpool(local_health_tools.scan_report,
            filename=file.filename or "report",
            content_type=file.content_type,
            data=data,
        )
    except LocalHealthToolsError as exc:
        print(f"[LAB SCAN ERROR] {exc}")
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc


@app.post("/tools/changes/explain")
def explain_changes(payload: Dict[str, Any]):
    if not payload:
        raise HTTPException(status_code=400, detail="Comparison payload is required.")
    try:
        return local_health_tools.explain_changes(payload)
    except LocalHealthToolsError as exc:
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc


@app.post("/tools/metric-guidance")
def metric_guidance(payload: Dict[str, Any]):
    try:
        return local_health_tools.metric_guidance(payload)
    except LocalHealthToolsError as exc:
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc


@app.post("/tools/report-guidance")
def report_guidance(payload: Dict[str, Any]):
    try:
        return local_health_tools.report_guidance(payload)
    except LocalHealthToolsError as exc:
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc
