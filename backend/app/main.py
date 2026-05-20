from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .schemas import AnalyzeRequest, AnalyzeResponse
from .formulas import FormulaEngine
from .explanation_engine import ExplanationEngine

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


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    results, more_needed, contributors = engine.analyze(payload.dict())
    overall = explainer.overall_risk(results, more_needed)
    disclaimer = explainer.disclaimer()
    return AnalyzeResponse(
        overall_risk=overall,
        calculated_results=results,
        more_data_needed=more_needed,
        contributors=contributors,
        disclaimer=disclaimer,
    )
