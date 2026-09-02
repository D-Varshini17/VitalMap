import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .schemas import AnalyzeRequest, AnalyzeResponse
from .formulas import FormulaEngine
from .explanation_engine import ExplanationEngine
from .ai_recommendation import AIRecommendationService

app = FastAPI(title="VitalMap Backend")

cors_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ALLOW_ORIGINS", "*").split(",")
    if origin.strip()
]
if not cors_origins:
    cors_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
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
    results = ai_recommendation.enhance_results(results, payload_dict)
    overall = explainer.overall_risk(results, more_needed)
    disclaimer = explainer.disclaimer()
    return AnalyzeResponse(
        overall_risk=overall,
        calculated_results=results,
        more_data_needed=more_needed,
        general_health_pattern=general_health_pattern,
        disclaimer=disclaimer,
    )


@app.get("/health")
def health():
    return {"status": "ok", "service": "VitalMap Backend"}


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    return _analyze_payload(payload)


@app.post("/predict", response_model=AnalyzeResponse)
def predict(payload: AnalyzeRequest):
    return _analyze_payload(payload)
