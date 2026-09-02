import json
import sys
import os

# Ensure project root is on sys.path so `backend` package can be imported
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.app.formulas import FormulaEngine

payload = {
    "profile": {
        "age": 55,
        "sex": "Female",
        "height_cm": 160.0,
        "weight_kg": 70.0,
        "waist_cm": 90.0,
    },
    "vitals": {
        "systolic": 130,
        "diastolic": 80,
        "heart_rate": 72,
        "spo2": 96,
    },
    "lipid_profile": {
        "triglycerides": 150,
        "triglycerides_unit": "mg/dL",
        "hdl": 40,
        "hdl_unit": "mg/dL",
    },
    "diabetes_profile": {
        "fasting_glucose": 100,
        "fasting_glucose_unit": "mg/dL",
    },
    "liver_function": {
        "ast": 30,
        "alt": 28,
        "ggt": 40,
    },
    "cbc": {
        "platelets": 250,
        "neutrophils": 60,
        "lymphocytes": 30,
    },
    "kidney_function": {
        "creatinine": 0.9,
        "creatinine_unit": "mg/dL",
    },
    "pancreatic_enzymes": {
        "lipase": 50,
        "amylase": 20,
    },
    "tumor_markers": {
        "afp": 20,
        "ca15_3": 10,
        "ca27_29": 20,
    },
    "general_health": {
        "smoking": "No",
        "alcohol": "Occasional",
    }
}

engine = FormulaEngine()
results, more_needed, general_health_pattern = engine.analyze(payload)

out = {
    "calculated_results": results,
    "more_data_needed": more_needed,
    "general_health_pattern": general_health_pattern,
}

print(json.dumps(out, indent=2))
