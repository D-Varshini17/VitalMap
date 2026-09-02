import json
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '.')))

import urllib.request

payload = {
    "profile": {"age": 45, "sex": "Male", "height_cm": 175, "weight_kg": 80, "waist_cm": 95},
    "vitals": {"systolic": None, "diastolic": None, "heart_rate": None, "spo2": None},
    "lipid_profile": {"triglycerides": 120, "triglycerides_unit": "mg/dL", "hdl": 45, "hdl_unit": "mg/dL", "ldl": None, "total_cholesterol": None, "vldl": None},
    "diabetes_profile": {"fasting_glucose": 95, "fasting_glucose_unit": "mg/dL", "hba1c": None, "ppbs": None, "random_blood_sugar": None},
    "liver_function": {"ast": 25, "alt": 22, "ggt": 30, "alp": None, "bilirubin": None, "albumin": None, "total_protein": None},
    "cbc": {"platelets": 220, "wbc": None, "neutrophils": 55, "lymphocytes": 35, "hemoglobin": None, "rbc": None, "esr": None},
    "kidney_function": {"creatinine": 1.0, "creatinine_unit": "mg/dL", "blood_urea": None, "uric_acid": None, "sodium": None, "potassium": None},
    "pancreatic_enzymes": {"lipase": 40, "amylase": 25},
    "tumor_markers": {"afp": None, "ca15_3": None, "ca27_29": None},
    "general_health": {"smoking": None, "alcohol": None, "physical_activity": None, "sleep_duration": None, "stress_level": None, "family_history": None, "diet_type": None, "high_sugar_intake": None, "high_salt_intake": None, "fried_processed_food": None, "fruit_veg_intake": None, "sugary_drinks": None, "air_pollution": None, "occupational_exposure": None, "passive_smoking": None, "cooking_smoke": None, "cooking_fuel_smoke": None, "location_type": None}
}

url = 'http://127.0.0.1:8000/analyze'
req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req, timeout=10) as f:
        resp = f.read().decode('utf-8')
        print(resp)
except urllib.error.HTTPError as e:
    try:
        body = e.read().decode('utf-8')
    except Exception:
        body = str(e)
    print('HTTP ERROR', e.code, body)
except Exception as e:
    print('ERROR', e)
