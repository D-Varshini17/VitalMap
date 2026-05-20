import json
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.app.formulas import FormulaEngine

def run():
    payload = {
        "profile": {"age": 60, "sex": "Female", "height_cm": 160, "weight_kg": 68, "waist_cm": 88},
        "lipid_profile": {"triglycerides": 140, "triglycerides_unit": "mg/dL", "hdl": 42, "hdl_unit": "mg/dL", "ldl": None, "total_cholesterol": None, "vldl": None},
        "diabetes_profile": {"fasting_glucose": 110, "fasting_glucose_unit": "mg/dL", "hba1c": None, "ppbs": None, "random_blood_sugar": None},
        "liver_function": {"ast": 35, "alt": 30, "ggt": 38, "alp": None, "bilirubin": None, "albumin": None, "total_protein": None},
        "cbc": {"platelets": 230, "wbc": None, "neutrophils": 55, "lymphocytes": 30, "hemoglobin": None, "rbc": None, "esr": None},
        "kidney_function": {"creatinine": 1.1, "creatinine_unit": "mg/dL", "blood_urea": None, "uric_acid": None, "sodium": None, "potassium": None},
        "pancreatic_enzymes": {"lipase": 60, "amylase": 20},
        "tumor_markers": {"afp": None, "ca15_3": None, "ca27_29": None},
        "general_health": {
            "physical_activity": "Low",
            "fried_processed_food": "Frequent",
            "high_sugar_intake": "High",
        }
    }
    engine = FormulaEngine()
    results, more_needed, general_health_pattern = engine.analyze(payload)
    assert any(r['index_name'] == 'AIP' for r in results), 'AIP missing'
    assert any(r['index_name'] == 'TyG' for r in results), 'TyG missing'
    assert all('summary' in r for r in results), 'summary missing'
    assert all('suggestions' in r for r in results), 'suggestions missing'
    assert any('Low physical activity' in item for item in general_health_pattern), 'general health pattern missing'
    print('Unit test passed: formulas returned', [r['index_name'] for r in results])

if __name__ == '__main__':
    run()
