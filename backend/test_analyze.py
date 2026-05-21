import math
import os
import sys
from copy import deepcopy

from fastapi.testclient import TestClient

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.main import app  # noqa: E402
from backend.app.unit_conversion import (  # noqa: E402
    albumin_to_gdl,
    bilirubin_to_mgdl,
    cholesterol_to_mgdl,
    creatinine_to_mgdl,
    glucose_to_mgdl,
    height_to_cm,
    platelets_to_10e9_l,
    temperature_to_c,
    triglycerides_to_mgdl,
    waist_to_cm,
    weight_to_kg,
)


client = TestClient(app)


GENERAL_LOW = {
    "smoking": "No",
    "alcohol": "No",
    "physical_activity": "High",
    "sleep_duration": ">7 hrs",
    "stress_level": "Low",
    "family_history": "None",
    "diet_type": "Mixed",
    "high_sugar_intake": "Low",
    "high_salt_intake": "Low",
    "fried_processed_food": "Rare",
    "fruit_veg_intake": "High",
    "sugary_drinks": "No",
    "air_pollution": "Low",
    "occupational_exposure": "No",
    "passive_smoking": "No",
    "cooking_smoke": "No",
    "cooking_fuel_smoke": "No",
    "location_type": "Urban",
}


GENERAL_HIGH = {
    "smoking": "Yes",
    "alcohol": "Frequent",
    "physical_activity": "Low",
    "sleep_duration": "<5 hrs",
    "stress_level": "High",
    "family_history": "Diabetes",
    "diet_type": "Mixed",
    "high_sugar_intake": "High",
    "high_salt_intake": "High",
    "fried_processed_food": "Frequent",
    "fruit_veg_intake": "Low",
    "sugary_drinks": "Frequently",
    "air_pollution": "High",
    "occupational_exposure": "Yes",
    "passive_smoking": "Yes",
    "cooking_smoke": "Yes",
    "cooking_fuel_smoke": "Yes",
    "location_type": "Urban",
}


FULL_HIGH_RISK = {
    "profile": {
        "age": 60,
        "sex": "Female",
        "height_unit": "ft-in",
        "height_feet": 5,
        "height_inches": 3,
        "weight_input": 154,
        "weight_unit": "lb",
        "waist_input": 36,
        "waist_unit": "inch",
    },
    "vitals": {
        "systolic": 150,
        "diastolic": 95,
        "heart_rate": 88,
        "spo2": 89,
        "body_temperature": 98.6,
        "body_temperature_unit": "°F",
        "respiratory_rate": 20,
    },
    "lipid_profile": {
        "triglycerides": 3.0,
        "triglycerides_unit": "mmol/L",
        "hdl": 1.0,
        "hdl_unit": "mmol/L",
        "ldl": 3.4,
        "ldl_unit": "mmol/L",
        "total_cholesterol": 6.0,
        "total_cholesterol_unit": "mmol/L",
        "vldl": 0.9,
        "vldl_unit": "mmol/L",
    },
    "diabetes_profile": {
        "fasting_glucose": 7.0,
        "fasting_glucose_unit": "mmol/L",
        "hba1c": 7.2,
        "ppbs": 11.5,
        "ppbs_unit": "mmol/L",
        "random_blood_sugar": None,
    },
    "liver_function": {
        "ast": 80,
        "alt": 60,
        "ggt": 90,
        "alp": 150,
        "bilirubin": 25.65,
        "bilirubin_unit": "µmol/L",
        "albumin": 35,
        "albumin_unit": "g/L",
        "total_protein": 70,
        "total_protein_unit": "g/L",
    },
    "cbc": {
        "platelets": 1.5,
        "platelets_unit": "lakh/µL",
        "wbc": 8500,
        "wbc_unit": "cells/µL",
        "neutrophils": 70,
        "neutrophils_unit": "%",
        "lymphocytes": 20,
        "lymphocytes_unit": "%",
        "hemoglobin": 12.5,
        "rbc": 4.5,
        "esr": 25,
    },
    "kidney_function": {
        "creatinine": 100,
        "creatinine_unit": "µmol/L",
        "blood_urea": 7,
        "blood_urea_unit": "mmol/L",
        "uric_acid": 360,
        "uric_acid_unit": "µmol/L",
        "sodium": 138,
        "potassium": 4.2,
        "chloride": 101,
    },
    "pancreatic_enzymes": {"lipase": 200, "amylase": 40},
    "tumor_markers": {"afp": 250, "ca15_3": 45, "ca27_29": 50},
    "general_health": GENERAL_HIGH,
}


LIMITED_REPORT = {
    "profile": {"age": 45, "sex": "Male", "height_cm": 172, "weight_kg": 76, "waist_cm": 88},
    "general_health": GENERAL_LOW,
    "lipid_profile": {"triglycerides": None, "hdl": None},
    "diabetes_profile": {},
    "liver_function": {},
    "cbc": {},
    "kidney_function": {},
    "pancreatic_enzymes": {},
    "tumor_markers": {},
}


def post_analyze(payload):
    response = client.post("/analyze", json=payload)
    assert response.status_code == 200, response.text
    body = response.json()
    for key in [
        "overall_risk",
        "calculated_results",
        "more_data_needed",
        "general_health_pattern",
        "disclaimer",
    ]:
        assert key in body, f"Missing response key: {key}"
    return body


def result_by_index(body, index_name):
    for result in body["calculated_results"]:
        if result["index_name"] == index_name:
            return result
    raise AssertionError(f"Missing calculated result: {index_name}")


def assert_close(actual, expected, tolerance=0.02):
    assert abs(actual - expected) <= tolerance, f"{actual} != {expected}"


def test_unit_conversions():
    assert_close(glucose_to_mgdl(7, "mmol/L"), 126)
    assert_close(triglycerides_to_mgdl(3, "mmol/L"), 265.71)
    assert_close(cholesterol_to_mgdl(1, "mmol/L"), 38.67)
    assert_close(creatinine_to_mgdl(88.4, "µmol/L"), 1)
    assert_close(bilirubin_to_mgdl(17.1, "µmol/L"), 1)
    assert_close(albumin_to_gdl(35, "g/L"), 3.5)
    assert_close(height_to_cm(unit="ft-in", feet=5, inches=3), 160.02)
    assert_close(weight_to_kg(154, "lb"), 69.85)
    assert_close(waist_to_cm(36, "inch"), 91.44)
    assert_close(temperature_to_c(98.6, "°F"), 37)
    assert_close(platelets_to_10e9_l(1.5, "lakh/µL"), 150)


def test_full_high_risk_sample():
    body = post_analyze(FULL_HIGH_RISK)
    assert body["overall_risk"] == "High"

    tg = 3.0 * 88.57
    hdl = 1.0 * 38.67
    fasting = 7.0 * 18
    platelets = 1.5 * 100
    age = 60
    ast = 80
    alt = 60

    assert_close(result_by_index(body, "AIP")["score"], math.log10(tg / hdl), 0.002)
    assert_close(result_by_index(body, "TyG")["score"], math.log((tg * fasting) / 2.0), 0.002)
    assert_close(result_by_index(body, "APRI")["score"], ((ast / 40.0) / platelets) * 100, 0.002)
    assert_close(result_by_index(body, "FIB-4")["score"], (age * ast) / (platelets * math.sqrt(alt)), 0.002)
    assert_close(result_by_index(body, "NLR")["score"], 70 / 20, 0.002)
    assert_close(result_by_index(body, "LAR")["score"], 200 / 40, 0.002)

    for index in [
        "SpO2",
        "eGFR",
        "FLI",
        "NAFLD Fibrosis Score",
        "AFP",
        "CA 15-3",
        "CA 27.29",
    ]:
        result_by_index(body, index)

    aip = result_by_index(body, "AIP")
    assert "ai_recommendation" in aip
    assert aip["score"] == result_by_index(body, "AIP")["score"]
    assert aip["risk_level"] == result_by_index(body, "AIP")["risk_level"]


def test_limited_report_sample_more_data_needed():
    body = post_analyze(LIMITED_REPORT)
    assert body["overall_risk"] == "More Data Needed"
    assert body["calculated_results"] == []
    assert len(body["more_data_needed"]) > 0
    assert all("message" in item for item in body["more_data_needed"])


def test_same_labs_different_lifestyle_changes_recommendation_context():
    low_context = deepcopy(FULL_HIGH_RISK)
    high_context = deepcopy(FULL_HIGH_RISK)
    low_context["general_health"] = GENERAL_LOW
    high_context["general_health"] = GENERAL_HIGH

    low_body = post_analyze(low_context)
    high_body = post_analyze(high_context)
    low_aip = result_by_index(low_body, "AIP")
    high_aip = result_by_index(high_body, "AIP")

    assert low_aip["score"] == high_aip["score"]
    assert low_aip["risk_level"] == high_aip["risk_level"]
    assert low_aip["possible_contributors"] != high_aip["possible_contributors"]
    assert (
        low_aip["ai_recommendation"]["possible_contributors"]
        != high_aip["ai_recommendation"]["possible_contributors"]
    )


def test_mixed_nlr_units_are_not_calculated():
    payload = deepcopy(FULL_HIGH_RISK)
    payload["cbc"]["neutrophils_unit"] = "%"
    payload["cbc"]["lymphocytes_unit"] = "cells/µL"
    body = post_analyze(payload)
    assert not any(r["index_name"] == "NLR" for r in body["calculated_results"])
    assert any(item["index_name"] == "NLR" for item in body["more_data_needed"])


if __name__ == "__main__":
    test_unit_conversions()
    test_full_high_risk_sample()
    test_limited_report_sample_more_data_needed()
    test_same_labs_different_lifestyle_changes_recommendation_context()
    test_mixed_nlr_units_are_not_calculated()
    print("All analyze checks passed.")
