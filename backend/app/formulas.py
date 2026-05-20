from typing import Tuple, List, Dict, Any
from math import log10, log, sqrt
from .unit_conversion import (
    glucose_to_mgdl,
    triglycerides_to_mgdl,
    cholesterol_to_mgdl,
    creatinine_to_mgdl,
)
from . import risk_rules
from .explanation_engine import ExplanationEngine


class FormulaEngine:
    def __init__(self):
        self.explainer = ExplanationEngine()

    def analyze(self, payload: Dict[str, Any]):
        results = []
        more_needed = []
        contributors = []

        profile = payload.get("profile") or {}
        general = payload.get("general_health") or {}
        contributors = self.explainer.contributors(general)

        # Normalize key values
        lip = payload.get("lipid_profile") or {}
        diab = payload.get("diabetes_profile") or {}
        liver = payload.get("liver_function") or {}
        cbc = payload.get("cbc") or {}
        kidney = payload.get("kidney_function") or {}
        pancreas = payload.get("pancreatic_enzymes") or {}
        tumor = payload.get("tumor_markers") or {}

        tg = triglycerides_to_mgdl(lip.get("triglycerides"), lip.get("triglycerides_unit", "mg/dL"))
        hdl = cholesterol_to_mgdl(lip.get("hdl"), lip.get("hdl_unit", "mg/dL"))
        fasting = glucose_to_mgdl(diab.get("fasting_glucose"), diab.get("fasting_glucose_unit", "mg/dL"))

        # AIP
        if tg is not None and hdl is not None and hdl > 0:
            try:
                aip = log10(tg / hdl)
            except Exception:
                aip = None
            risk, color = risk_rules.aip_risk(aip)
            results.append({
                "organ": "Heart",
                "index_name": "AIP",
                "score": round(aip, 3) if aip is not None else None,
                "risk_level": risk,
                "color": color,
                "formula_used": "AIP = log10(triglycerides / HDL)",
                "values_used": {"triglycerides_mg/dL": tg, "hdl_mg/dL": hdl},
                "interpretation": "Atherogenic Index of Plasma — screening insight for cardiometabolic risk.",
                "suggested_next_step": self.explainer.suggested_next_step("AIP"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "AIP",
                "organ": "Heart",
                "missing_inputs": [x for x, v in [("triglycerides", tg), ("hdl", hdl)] if v is None],
                "message": "AIP needs triglycerides and HDL.",
            })

        # TyG
        if tg is not None and fasting is not None:
            try:
                tyg = log((tg * fasting) / 2.0)
            except Exception:
                tyg = None
            risk, color = risk_rules.tyg_risk(tyg)
            results.append({
                "organ": "Brain / Metabolic",
                "index_name": "TyG",
                "score": round(tyg, 3) if tyg is not None else None,
                "risk_level": risk,
                "color": color,
                "formula_used": "TyG = ln((triglycerides × fasting_glucose) / 2)",
                "values_used": {"triglycerides_mg/dL": tg, "fasting_glucose_mg/dL": fasting},
                "interpretation": "Triglyceride-glucose index — screening insight for insulin resistance.",
                "suggested_next_step": self.explainer.suggested_next_step("TyG"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "TyG",
                "organ": "Brain / Metabolic",
                "missing_inputs": [x for x, v in [("triglycerides", tg), ("fasting_glucose", fasting)] if v is None],
                "message": "TyG needs triglycerides and fasting glucose.",
            })

        # APRI
        ast = liver.get("ast")
        platelets = cbc.get("platelets")
        if ast is not None and platelets is not None and platelets > 0:
            try:
                apri = ((ast / 40.0) / platelets) * 100.0
            except Exception:
                apri = None
            risk, color = risk_rules.apri_risk(apri)
            results.append({
                "organ": "Liver",
                "index_name": "APRI",
                "score": round(apri, 3) if apri is not None else None,
                "risk_level": risk,
                "color": color,
                "formula_used": "APRI = ((AST / 40) / Platelets) × 100",
                "values_used": {"ast": ast, "platelets": platelets},
                "interpretation": "AST to Platelet Ratio Index — screening insight for liver fibrosis.",
                "suggested_next_step": self.explainer.suggested_next_step("APRI"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "APRI",
                "organ": "Liver",
                "missing_inputs": [x for x, v in [("ast", ast), ("platelets", platelets)] if v is None],
                "message": "APRI needs AST and platelets.",
            })

        # FIB-4
        age = profile.get("age")
        alt = liver.get("alt")
        if age is not None and ast is not None and alt is not None and platelets is not None and alt > 0 and platelets > 0:
            try:
                fib4 = (age * ast) / (platelets * sqrt(alt))
            except Exception:
                fib4 = None
            risk, color = risk_rules.fib4_risk(fib4)
            results.append({
                "organ": "Liver",
                "index_name": "FIB-4",
                "score": round(fib4, 3) if fib4 is not None else None,
                "risk_level": risk,
                "color": color,
                "formula_used": "FIB-4 = (Age × AST) / (Platelets × sqrt(ALT))",
                "values_used": {"age": age, "ast": ast, "alt": alt, "platelets": platelets},
                "interpretation": "FIB-4 index — screening insight for liver fibrosis.",
                "suggested_next_step": self.explainer.suggested_next_step("FIB-4"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "FIB-4",
                "organ": "Liver",
                "missing_inputs": [x for x, v in [("age", age), ("ast", ast), ("alt", alt), ("platelets", platelets)] if v is None],
                "message": "FIB-4 needs age, AST, ALT, and platelets.",
            })

        # NLR
        neut = cbc.get("neutrophils")
        lymph = cbc.get("lymphocytes")
        if neut is not None and lymph is not None and lymph > 0:
            try:
                nlr = neut / lymph
            except Exception:
                nlr = None
            risk, color = risk_rules.nlr_risk(nlr)
            results.append({
                "organ": "Inflammation",
                "index_name": "NLR",
                "score": round(nlr, 3) if nlr is not None else None,
                "risk_level": risk,
                "color": color,
                "formula_used": "NLR = Neutrophils / Lymphocytes",
                "values_used": {"neutrophils": neut, "lymphocytes": lymph},
                "interpretation": "Neutrophil-Lymphocyte Ratio — screening insight for inflammation.",
                "suggested_next_step": self.explainer.suggested_next_step("NLR"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "NLR",
                "organ": "Inflammation",
                "missing_inputs": [x for x, v in [("neutrophils", neut), ("lymphocytes", lymph)] if v is None],
                "message": "NLR needs neutrophils and lymphocytes.",
            })

        # LAR
        lip = pancreas.get("lipase")
        amy = pancreas.get("amylase")
        if lip is not None and amy is not None and amy > 0:
            try:
                lar = lip / amy
            except Exception:
                lar = None
            rule_text, color = risk_rules.lar_rule(lar)
            results.append({
                "organ": "Pancreas",
                "index_name": "LAR",
                "score": round(lar, 3) if lar is not None else None,
                "risk_level": "Pattern",
                "color": color,
                "formula_used": "LAR = Lipase / Amylase",
                "values_used": {"lipase": lip, "amylase": amy},
                "interpretation": rule_text,
                "suggested_next_step": self.explainer.suggested_next_step("LAR"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "LAR",
                "organ": "Pancreas",
                "missing_inputs": [x for x, v in [("lipase", lip), ("amylase", amy)] if v is None],
                "message": "LAR needs lipase and amylase.",
            })

        # SpO2
        vit = payload.get("vitals") or {}
        spo2 = vit.get("spo2")
        risk, color = risk_rules.spO2_risk(spo2)
        results.append({
            "organ": "Lung",
            "index_name": "SpO2",
            "score": spo2,
            "risk_level": risk,
            "color": color,
            "formula_used": "SpO2 direct percent",
            "values_used": {"spo2": spo2},
            "interpretation": "Oxygen saturation monitoring indicator.",
            "suggested_next_step": self.explainer.suggested_next_step("SpO2"),
            "disclaimer": self.explainer.disclaimer(),
        })

        # eGFR (placeholder safe function)
        creat = creatinine_to_mgdl(kidney.get("creatinine"), kidney.get("creatinine_unit", "mg/dL"))
        sex = profile.get("sex")
        age = profile.get("age")
        if creat is not None and age is not None and sex is not None:
            # simplified MDRD-like placeholder (NOT for clinical use)
            try:
                egfr = 175 * (creat ** -1.154) * (age ** -0.203) * (0.742 if sex.lower().startswith("f") else 1.0)
            except Exception:
                egfr = None
            rule, color = risk_rules.egfr_rule(egfr)
            results.append({
                "organ": "Kidney",
                "index_name": "eGFR",
                "score": round(egfr, 1) if egfr is not None else None,
                "risk_level": rule,
                "color": color,
                "formula_used": "eGFR (placeholder MDRD-like)",
                "values_used": {"age": age, "sex": sex, "creatinine_mg/dL": creat},
                "interpretation": "Estimated glomerular filtration rate — screening insight for kidney function.",
                "suggested_next_step": self.explainer.suggested_next_step("eGFR"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "eGFR",
                "organ": "Kidney",
                "missing_inputs": [x for x, v in [("age", age), ("sex", sex), ("creatinine", creat)] if v is None],
                "message": "eGFR needs age, sex, and creatinine.",
            })

        # FLI (Fatty Liver Index) - approximate
        bmi = None
        try:
            h = profile.get("height_cm")
            w = profile.get("weight_kg")
            if h and w:
                bmi = w / ((h / 100.0) ** 2)
        except Exception:
            bmi = None

        waist = profile.get("waist_cm")
        ggt = liver.get("ggt")
        if bmi is not None and waist is not None and ggt is not None and tg is not None:
            try:
                # FLI formula
                fl = (0.953 * log(tg) + 0.139 * bmi + 0.718 * log(ggt) + 0.053 * waist - 15.745)
            except Exception:
                fl = None
            results.append({
                "organ": "Liver",
                "index_name": "FLI",
                "score": round(fl, 3) if fl is not None else None,
                "risk_level": "N/A",
                "color": "grey",
                "formula_used": "FLI (approx)",
                "values_used": {"bmi": bmi, "waist_cm": waist, "ggt": ggt, "triglycerides_mg/dL": tg},
                "interpretation": "Fatty Liver Index — screening insight.",
                "suggested_next_step": self.explainer.suggested_next_step("FLI"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "FLI",
                "organ": "Liver",
                "missing_inputs": [x for x, v in [("bmi", bmi), ("waist_cm", waist), ("ggt", ggt), ("triglycerides", tg)] if v is None],
                "message": "FLI needs BMI, waist circumference, GGT, and triglycerides.",
            })

        # Tumor markers direct interpretation
        afp = tumor.get("afp")
        if afp is not None:
            level = "Low" if afp <= 200 else "High"
            color = "green" if afp <= 200 else "red"
            results.append({
                "organ": "Cancer Awareness",
                "index_name": "AFP",
                "score": afp,
                "risk_level": level,
                "color": color,
                "formula_used": "AFP direct value",
                "values_used": {"afp": afp},
                "interpretation": "Awareness indicator only. Abnormal values may occur in benign or serious conditions.",
                "suggested_next_step": self.explainer.suggested_next_step("AFP"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "AFP",
                "organ": "Cancer Awareness",
                "missing_inputs": ["afp"],
                "message": "AFP marker not entered.",
            })

        ca1 = tumor.get("ca15_3")
        if ca1 is not None:
            level = "Low" if ca1 <= 30 else "High"
            color = "green" if ca1 <= 30 else "red"
            results.append({
                "organ": "Cancer Awareness",
                "index_name": "CA 15-3",
                "score": ca1,
                "risk_level": level,
                "color": color,
                "formula_used": "CA 15-3 direct value",
                "values_used": {"ca15_3": ca1},
                "interpretation": "Awareness indicator only. Abnormal values may occur in benign or serious conditions.",
                "suggested_next_step": self.explainer.suggested_next_step("CA 15-3"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "CA 15-3",
                "organ": "Cancer Awareness",
                "missing_inputs": ["ca15_3"],
                "message": "CA 15-3 marker not entered.",
            })

        ca2 = tumor.get("ca27_29")
        if ca2 is not None:
            level = "Low" if ca2 <= 38 else "High"
            color = "green" if ca2 <= 38 else "red"
            results.append({
                "organ": "Cancer Awareness",
                "index_name": "CA 27.29",
                "score": ca2,
                "risk_level": level,
                "color": color,
                "formula_used": "CA 27.29 direct value",
                "values_used": {"ca27_29": ca2},
                "interpretation": "Awareness indicator only. Abnormal values may occur in benign or serious conditions.",
                "suggested_next_step": self.explainer.suggested_next_step("CA 27.29"),
                "disclaimer": self.explainer.disclaimer(),
            })
        else:
            more_needed.append({
                "index_name": "CA 27.29",
                "organ": "Cancer Awareness",
                "missing_inputs": ["ca27_29"],
                "message": "CA 27.29 marker not entered.",
            })

        return results, more_needed, contributors
