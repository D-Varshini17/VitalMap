from typing import Optional, Dict, Any, List
from pydantic import BaseModel


class Profile(BaseModel):
    age: Optional[int]
    sex: Optional[str]
    height_cm: Optional[float]
    weight_kg: Optional[float]
    waist_cm: Optional[float]


class Vitals(BaseModel):
    systolic: Optional[float]
    diastolic: Optional[float]
    heart_rate: Optional[int]
    spo2: Optional[float]


class LipidProfile(BaseModel):
    triglycerides: Optional[float]
    triglycerides_unit: Optional[str] = "mg/dL"
    hdl: Optional[float]
    hdl_unit: Optional[str] = "mg/dL"
    ldl: Optional[float]
    total_cholesterol: Optional[float]
    vldl: Optional[float]


class DiabetesProfile(BaseModel):
    fasting_glucose: Optional[float]
    fasting_glucose_unit: Optional[str] = "mg/dL"
    hba1c: Optional[float]
    ppbs: Optional[float]
    random_blood_sugar: Optional[float]


class LiverFunction(BaseModel):
    ast: Optional[float]
    alt: Optional[float]
    ggt: Optional[float]
    alp: Optional[float]
    bilirubin: Optional[float]
    albumin: Optional[float]
    total_protein: Optional[float]


class CBC(BaseModel):
    platelets: Optional[float]
    wbc: Optional[float]
    neutrophils: Optional[float]
    lymphocytes: Optional[float]
    hemoglobin: Optional[float]
    rbc: Optional[float]
    esr: Optional[float]


class KidneyFunction(BaseModel):
    creatinine: Optional[float]
    creatinine_unit: Optional[str] = "mg/dL"
    blood_urea: Optional[float]
    uric_acid: Optional[float]
    sodium: Optional[float]
    potassium: Optional[float]


class TumorMarkers(BaseModel):
    afp: Optional[float]
    ca15_3: Optional[float]
    ca27_29: Optional[float]


class PancreaticEnzymes(BaseModel):
    lipase: Optional[float]
    amylase: Optional[float]


class GeneralHealth(BaseModel):
    smoking: Optional[str]
    alcohol: Optional[str]
    physical_activity: Optional[str]
    sleep_duration: Optional[str]
    stress_level: Optional[str]
    family_history: Optional[str]
    diet_type: Optional[str]
    high_sugar_intake: Optional[str]
    high_salt_intake: Optional[str]
    fried_processed_food: Optional[str]
    fruit_veg_intake: Optional[str]
    sugary_drinks: Optional[str]
    air_pollution: Optional[str]
    occupational_exposure: Optional[str]
    passive_smoking: Optional[str]
    cooking_smoke: Optional[str]
    cooking_fuel_smoke: Optional[str]
    location_type: Optional[str]


class AnalyzeRequest(BaseModel):
    profile: Optional[Profile]
    vitals: Optional[Vitals]
    lipid_profile: Optional[LipidProfile]
    diabetes_profile: Optional[DiabetesProfile]
    liver_function: Optional[LiverFunction]
    cbc: Optional[CBC]
    kidney_function: Optional[KidneyFunction]
    tumor_markers: Optional[TumorMarkers]
    pancreatic_enzymes: Optional[PancreaticEnzymes]
    general_health: Optional[GeneralHealth]


class CalculatedResult(BaseModel):
    organ: str
    index_name: str
    score: Optional[float]
    risk_level: str
    color: str
    formula_used: str
    values_used: Dict[str, Any]
    interpretation: str
    suggested_next_step: str
    disclaimer: str


class MoreDataNeeded(BaseModel):
    index_name: str
    organ: str
    missing_inputs: List[str]
    message: str


class AnalyzeResponse(BaseModel):
    overall_risk: str
    calculated_results: List[CalculatedResult]
    more_data_needed: List[MoreDataNeeded]
    contributors: List[str]
    disclaimer: str
