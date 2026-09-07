import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .schemas import AnalyzeRequest, AnalyzeResponse
from .formulas import FormulaEngine
from .explanation_engine import ExplanationEngine
from .ai_recommendation import AIRecommendationService

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
DEFAULT_CORS_ORIGIN_REGEX = r"https://.*\.vercel\.app"

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


def _analyze_payload(payload: AnalyzeRequest) -> AnalyzeResponse:
    payload_dict = payload.model_dump()
    results, more_needed, general_health_pattern = engine.analyze(payload_dict)
    overall = explainer.overall_risk(results, more_needed)
    disclaimer = explainer.disclaimer()
    ai = ai_recommendation.enhance_response(
        results=results,
        more_needed=more_needed,
        payload=payload_dict,
        overall_risk=overall,
        general_health_pattern=general_health_pattern,
    )
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
    }


@app.get("/health")
def health():
    return {"status": "ok", "service": "VitalMap Backend"}


@app.get("/ai/status")
def ai_status():
    return ai_recommendation.status()


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    return _analyze_payload(payload)


@app.post("/predict", response_model=AnalyzeResponse)
def predict(payload: AnalyzeRequest):
    return _analyze_payload(payload)
