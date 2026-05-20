from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .schemas import AnalyzeRequest, AnalyzeResponse
from .formulas import FormulaEngine
from .explanation_engine import ExplanationEngine
from .ai_summary import AISummaryService

app = FastAPI(title="NCD Guard - VitalMap Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = FormulaEngine()
explainer = ExplanationEngine()
ai_summary = AISummaryService()


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    payload_dict = payload.model_dump()
    results, more_needed, general_health_pattern = engine.analyze(payload_dict)
    results = ai_summary.enhance_results(results, payload_dict)
    overall = explainer.overall_risk(results, more_needed)
    disclaimer = explainer.disclaimer()
    return AnalyzeResponse(
        overall_risk=overall,
        calculated_results=results,
        more_data_needed=more_needed,
        general_health_pattern=general_health_pattern,
        disclaimer=disclaimer,
    )
