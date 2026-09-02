from typing import Optional, Dict, Any, List
from pydantic import BaseModel


class Profile(BaseModel):
    age: Optional[int] = None
    age_unit: Optional[str] = "years"
    sex: Optional[str] = None
    height_cm: Optional[float] = None
    height_unit: Optional[str] = "cm"
    height_input: Optional[float] = None
    height_feet: Optional[float] = None
    height_inches: Optional[float] = None
    weight_kg: Optional[float] = None
    weight_unit: Optional[str] = "kg"
    weight_input: Optional[float] = None
    waist_cm: Optional[float] = None
    waist_unit: Optional[str] = "cm"
    waist_input: Optional[float] = None


class Vitals(BaseModel):
    systolic: Optional[float] = None
    systolic_unit: Optional[str] = "mmHg"
    diastolic: Optional[float] = None
    diastolic_unit: Optional[str] = "mmHg"
    heart_rate: Optional[int] = None
    heart_rate_unit: Optional[str] = "bpm"
    spo2: Optional[float] = None
    spo2_unit: Optional[str] = "%"
    body_temperature: Optional[float] = None
    body_temperature_unit: Optional[str] = "°C"
    body_temperature_input: Optional[float] = None
    respiratory_rate: Optional[int] = None
    respiratory_rate_unit: Optional[str] = "breaths/min"


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
    vldl_unit: Optional[str] = "mg/dL"


class DiabetesProfile(BaseModel):
    fasting_glucose: Optional[float] = None
    fasting_glucose_unit: Optional[str] = "mg/dL"
    hba1c: Optional[float] = None
    ppbs: Optional[float] = None
    ppbs_unit: Optional[str] = "mg/dL"
    random_blood_sugar: Optional[float] = None
    random_blood_sugar_unit: Optional[str] = "mg/dL"
    hba1c_unit: Optional[str] = "%"


class LiverFunction(BaseModel):
    ast: Optional[float] = None
    ast_unit: Optional[str] = "U/L"
    alt: Optional[float] = None
    alt_unit: Optional[str] = "U/L"
    ggt: Optional[float] = None
    ggt_unit: Optional[str] = "U/L"
    alp: Optional[float] = None
    alp_unit: Optional[str] = "U/L"
    bilirubin: Optional[float] = None
    bilirubin_unit: Optional[str] = "mg/dL"
    bilirubin_direct: Optional[float] = None
    bilirubin_direct_unit: Optional[str] = "mg/dL"
    bilirubin_indirect: Optional[float] = None
    bilirubin_indirect_unit: Optional[str] = "mg/dL"
    albumin: Optional[float] = None
    albumin_unit: Optional[str] = "g/dL"
    total_protein: Optional[float] = None
    total_protein_unit: Optional[str] = "g/dL"


class CBC(BaseModel):
    platelets: Optional[float] = None
    platelets_unit: Optional[str] = "10⁹/L"
    wbc: Optional[float] = None
    wbc_unit: Optional[str] = "10⁹/L"
    neutrophils: Optional[float] = None
    neutrophils_unit: Optional[str] = "%"
    lymphocytes: Optional[float] = None
    lymphocytes_unit: Optional[str] = "%"
    hemoglobin: Optional[float] = None
    hemoglobin_unit: Optional[str] = "g/dL"
    rbc: Optional[float] = None
    rbc_unit: Optional[str] = "million/µL"
    esr: Optional[float] = None
    esr_unit: Optional[str] = "mm/hr"


class KidneyFunction(BaseModel):
    creatinine: Optional[float] = None
    creatinine_unit: Optional[str] = "mg/dL"
    blood_urea: Optional[float] = None
    blood_urea_unit: Optional[str] = "mg/dL"
    bun: Optional[float] = None
    bun_unit: Optional[str] = "mg/dL"
    uric_acid: Optional[float] = None
    uric_acid_unit: Optional[str] = "mg/dL"
    sodium: Optional[float] = None
    sodium_unit: Optional[str] = "mmol/L"
    potassium: Optional[float] = None
    potassium_unit: Optional[str] = "mmol/L"
    chloride: Optional[float] = None
    chloride_unit: Optional[str] = "mmol/L"


class TumorMarkers(BaseModel):
    afp: Optional[float] = None
    afp_unit: Optional[str] = "ng/mL"
    ca15_3: Optional[float] = None
    ca15_3_unit: Optional[str] = "U/mL"
    ca27_29: Optional[float] = None
    ca27_29_unit: Optional[str] = "U/mL"


class PancreaticEnzymes(BaseModel):
    lipase: Optional[float] = None
    lipase_unit: Optional[str] = "U/L"
    amylase: Optional[float] = None
    amylase_unit: Optional[str] = "U/L"


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
    formula_used: str
    values_used: Dict[str, Any]
    summary: str
    possible_contributors: List[str]
    suggestions: List[str]
    lifestyle_improvement: List[str]
    food_recommendations: List[str]
    environment_recommendations: List[str]
    doctor_followup: str
    ai_recommendation: Dict[str, Any]
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
    general_health_pattern: List[str]
    disclaimer: str
