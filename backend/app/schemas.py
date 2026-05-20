from typing import Optional, Dict, Any, List
from pydantic import BaseModel


class Profile(BaseModel):
    age: Optional[int] = None
    sex: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    waist_cm: Optional[float] = None


class Vitals(BaseModel):
    systolic: Optional[float] = None
    diastolic: Optional[float] = None
    heart_rate: Optional[int] = None
    spo2: Optional[float] = None


class LipidProfile(BaseModel):
    triglycerides: Optional[float] = None
    triglycerides_unit: Optional[str] = "mg/dL"
    hdl: Optional[float] = None
    hdl_unit: Optional[str] = "mg/dL"
    ldl: Optional[float] = None
    ldl_unit: Optional[str] = "mg/dL"
    total_cholesterol: Optional[float] = None
    total_cholesterol_unit: Optional[str] = "mg/dL"
    vldl: Optional[float] = None


class DiabetesProfile(BaseModel):
    fasting_glucose: Optional[float] = None
    fasting_glucose_unit: Optional[str] = "mg/dL"
    hba1c: Optional[float] = None
    ppbs: Optional[float] = None
    ppbs_unit: Optional[str] = "mg/dL"
    random_blood_sugar: Optional[float] = None
    random_blood_sugar_unit: Optional[str] = "mg/dL"


class LiverFunction(BaseModel):
    ast: Optional[float] = None
    alt: Optional[float] = None
    ggt: Optional[float] = None
    alp: Optional[float] = None
    bilirubin: Optional[float] = None
    albumin: Optional[float] = None
    total_protein: Optional[float] = None


class CBC(BaseModel):
    platelets: Optional[float] = None
    wbc: Optional[float] = None
    neutrophils: Optional[float] = None
    lymphocytes: Optional[float] = None
    hemoglobin: Optional[float] = None
    rbc: Optional[float] = None
    esr: Optional[float] = None


class KidneyFunction(BaseModel):
    creatinine: Optional[float] = None
    creatinine_unit: Optional[str] = "mg/dL"
    blood_urea: Optional[float] = None
    uric_acid: Optional[float] = None
    sodium: Optional[float] = None
    potassium: Optional[float] = None


class TumorMarkers(BaseModel):
    afp: Optional[float] = None
    ca15_3: Optional[float] = None
    ca27_29: Optional[float] = None


class PancreaticEnzymes(BaseModel):
    lipase: Optional[float] = None
    amylase: Optional[float] = None


class GeneralHealth(BaseModel):
    smoking: Optional[str] = None
    alcohol: Optional[str] = None
    physical_activity: Optional[str] = None
    sleep_duration: Optional[str] = None
    stress_level: Optional[str] = None
    family_history: Optional[str] = None
    diet_type: Optional[str] = None
    high_sugar_intake: Optional[str] = None
    high_salt_intake: Optional[str] = None
    fried_processed_food: Optional[str] = None
    fruit_veg_intake: Optional[str] = None
    sugary_drinks: Optional[str] = None
    air_pollution: Optional[str] = None
    occupational_exposure: Optional[str] = None
    passive_smoking: Optional[str] = None
    cooking_smoke: Optional[str] = None
    cooking_fuel_smoke: Optional[str] = None
    location_type: Optional[str] = None


class AnalyzeRequest(BaseModel):
    profile: Optional[Profile] = None
    vitals: Optional[Vitals] = None
    lipid_profile: Optional[LipidProfile] = None
    diabetes_profile: Optional[DiabetesProfile] = None
    liver_function: Optional[LiverFunction] = None
    cbc: Optional[CBC] = None
    kidney_function: Optional[KidneyFunction] = None
    tumor_markers: Optional[TumorMarkers] = None
    pancreatic_enzymes: Optional[PancreaticEnzymes] = None
    general_health: Optional[GeneralHealth] = None


class CalculatedResult(BaseModel):
    organ: str
    index_name: str
    score: Optional[float]
    risk_level: str
    color: str
    values_used: Dict[str, Any]
    summary: str
    possible_contributors: List[str]
    suggestions: List[str]
    lifestyle_improvement: List[str]
    doctor_followup: str
    disclaimer: str
    formula_used: Optional[str] = None


class MoreDataNeeded(BaseModel):
    index_name: str
    organ: str
    missing_inputs: List[str]
    message: str


class AnalyzeResponse(BaseModel):
    overall_risk: str
    calculated_results: List[CalculatedResult]
    more_data_needed: List[MoreDataNeeded]
    general_health_pattern: List[str]
    disclaimer: str
