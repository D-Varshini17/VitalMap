from typing import Dict, Any, List, Optional
from math import exp, log10, log, sqrt

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
        results: List[Dict[str, Any]] = []
        more_needed: List[Dict[str, Any]] = []

        profile = payload.get("profile") or {}
        general = payload.get("general_health") or {}
        vitals = payload.get("vitals") or {}
        lipids = payload.get("lipid_profile") or {}
        diabetes = payload.get("diabetes_profile") or {}
        liver = payload.get("liver_function") or {}
        cbc = payload.get("cbc") or {}
        kidney = payload.get("kidney_function") or {}
        pancreas = payload.get("pancreatic_enzymes") or {}
        tumor = payload.get("tumor_markers") or {}

        age = profile.get("age")
        sex = profile.get("sex")
        bmi = self._bmi(profile.get("height_cm"), profile.get("weight_kg"))
        waist = profile.get("waist_cm")

        tg = triglycerides_to_mgdl(
            lipids.get("triglycerides"), lipids.get("triglycerides_unit", "mg/dL")
        )
        hdl = cholesterol_to_mgdl(lipids.get("hdl"), lipids.get("hdl_unit", "mg/dL"))
        ldl = cholesterol_to_mgdl(lipids.get("ldl"), lipids.get("ldl_unit", "mg/dL"))
        total_cholesterol = cholesterol_to_mgdl(
            lipids.get("total_cholesterol"),
            lipids.get("total_cholesterol_unit", "mg/dL"),
        )

        fasting = glucose_to_mgdl(
            diabetes.get("fasting_glucose"),
            diabetes.get("fasting_glucose_unit", "mg/dL"),
        )
        ppbs = glucose_to_mgdl(diabetes.get("ppbs"), diabetes.get("ppbs_unit", "mg/dL"))
        random_glucose = glucose_to_mgdl(
            diabetes.get("random_blood_sugar"),
            diabetes.get("random_blood_sugar_unit", "mg/dL"),
        )
        hba1c = diabetes.get("hba1c")

        ast = liver.get("ast")
        alt = liver.get("alt")
        ggt = liver.get("ggt")
        albumin = liver.get("albumin")
        platelets = cbc.get("platelets")
        neutrophils = cbc.get("neutrophils")
        lymphocytes = cbc.get("lymphocytes")
        creatinine = creatinine_to_mgdl(
            kidney.get("creatinine"), kidney.get("creatinine_unit", "mg/dL")
        )

        self._calculate_aip(results, more_needed, general, tg, hdl, ldl, total_cholesterol)
        self._calculate_tyg(results, more_needed, general, tg, fasting)
        self._calculate_metabolic(results, more_needed, general, fasting, hba1c, ppbs, random_glucose)
        self._calculate_apri(results, more_needed, general, ast, platelets)
        self._calculate_fib4(results, more_needed, general, age, ast, alt, platelets)
        self._calculate_fli(results, more_needed, general, bmi, waist, ggt, tg)
        self._calculate_nafld(
            results,
            more_needed,
            general,
            age,
            bmi,
            ast,
            alt,
            platelets,
            fasting,
            hba1c,
            ppbs,
            random_glucose,
            albumin,
        )
        self._calculate_nlr(results, more_needed, general, neutrophils, lymphocytes)
        self._calculate_egfr(results, more_needed, general, age, sex, creatinine)
        self._calculate_spo2(results, more_needed, general, vitals.get("spo2"))
        self._calculate_lar(
            results,
            more_needed,
            general,
            pancreas.get("lipase"),
            pancreas.get("amylase"),
        )
        self._calculate_tumor_markers(results, more_needed, general, tumor)

        return results, more_needed, self.explainer.general_health_pattern(general)

    def _result(
        self,
        *,
        organ: str,
        index_name: str,
        score: Optional[float],
        risk_level: str,
        color: str,
        values_used: Dict[str, Any],
        formula_used: str,
        general: Dict[str, Any],
    ) -> Dict[str, Any]:
        return {
            "organ": organ,
            "index_name": index_name,
            "score": score,
            "risk_level": risk_level,
            "color": color,
            "summary": self.explainer.summary(index_name, organ, risk_level),
            "possible_contributors": self.explainer.contributors(organ, general, values_used),
            "suggestions": self.explainer.suggestions(organ, index_name),
            "lifestyle_improvement": self.explainer.lifestyle_improvement(organ),
            "doctor_followup": self.explainer.doctor_followup(risk_level),
            "values_used": values_used,
            "disclaimer": self.explainer.disclaimer(),
            "formula_used": formula_used,
        }

    def _more_needed(
        self,
        more_needed: List[Dict[str, Any]],
        index_name: str,
        organ: str,
        fields: Dict[str, Any],
    ) -> None:
        missing = [name for name, value in fields.items() if value is None]
        if not missing:
            missing = list(fields.keys())
        more_needed.append(
            {
                "index_name": index_name,
                "organ": organ,
                "missing_inputs": missing,
                "message": f"{index_name} needs {', '.join(missing)}.",
            }
        )

    def _bmi(self, height_cm, weight_kg):
        if not height_cm or not weight_kg:
            return None
        try:
            return weight_kg / ((height_cm / 100.0) ** 2)
        except Exception:
            return None

    def _calculate_aip(self, results, more_needed, general, tg, hdl, ldl, total_cholesterol):
        if tg is not None and hdl is not None and tg > 0 and hdl > 0:
            score = log10(tg / hdl)
            risk, color = risk_rules.aip_risk(score)
            values = {
                "triglycerides_mg/dL": round(tg, 2),
                "hdl_mg/dL": round(hdl, 2),
            }
            if ldl is not None:
                values["ldl_mg/dL"] = round(ldl, 2)
            if total_cholesterol is not None:
                values["total_cholesterol_mg/dL"] = round(total_cholesterol, 2)
            results.append(
                self._result(
                    organ="Heart",
                    index_name="AIP",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used=values,
                    formula_used="AIP = log10(Triglycerides / HDL)",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "AIP",
                "Heart",
                {"triglycerides": tg, "hdl": hdl},
            )

    def _calculate_tyg(self, results, more_needed, general, tg, fasting):
        if tg is not None and fasting is not None and tg > 0 and fasting > 0:
            score = log((tg * fasting) / 2.0)
            risk, color = risk_rules.tyg_risk(score)
            results.append(
                self._result(
                    organ="Diabetes / Metabolic",
                    index_name="TyG",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used={
                        "triglycerides_mg/dL": round(tg, 2),
                        "fasting_glucose_mg/dL": round(fasting, 2),
                    },
                    formula_used="TyG = ln((Triglycerides x Fasting Glucose) / 2)",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "TyG",
                "Diabetes / Metabolic",
                {"triglycerides": tg, "fasting_glucose": fasting},
            )

    def _calculate_metabolic(self, results, more_needed, general, fasting, hba1c, ppbs, random_glucose):
        if any(value is not None for value in [fasting, hba1c, ppbs, random_glucose]):
            risk, color = risk_rules.metabolic_risk(fasting, hba1c, ppbs, random_glucose)
            values = {}
            if fasting is not None:
                values["fasting_glucose_mg/dL"] = round(fasting, 2)
            if hba1c is not None:
                values["hba1c_%"] = hba1c
            if ppbs is not None:
                values["ppbs_mg/dL"] = round(ppbs, 2)
            if random_glucose is not None:
                values["random_blood_sugar_mg/dL"] = round(random_glucose, 2)
            score = hba1c if hba1c is not None else fasting or ppbs or random_glucose
            results.append(
                self._result(
                    organ="Diabetes / Metabolic",
                    index_name="Metabolic screening insight",
                    score=round(score, 2) if score is not None else None,
                    risk_level=risk,
                    color=color,
                    values_used=values,
                    formula_used="Direct glucose and HbA1c screening interpretation",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "Metabolic screening insight",
                "Diabetes / Metabolic",
                {
                    "fasting_glucose_or_hba1c_or_ppbs_or_random_blood_sugar": None,
                },
            )

    def _calculate_apri(self, results, more_needed, general, ast, platelets):
        if ast is not None and platelets is not None and platelets > 0:
            score = ((ast / 40.0) / platelets) * 100.0
            risk, color = risk_rules.apri_risk(score)
            results.append(
                self._result(
                    organ="Liver",
                    index_name="APRI",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used={"ast": ast, "platelets": platelets},
                    formula_used="APRI = ((AST / 40) / Platelets) x 100",
                    general=general,
                )
            )
        else:
            self._more_needed(more_needed, "APRI", "Liver", {"ast": ast, "platelets": platelets})

    def _calculate_fib4(self, results, more_needed, general, age, ast, alt, platelets):
        if (
            age is not None
            and ast is not None
            and alt is not None
            and platelets is not None
            and alt > 0
            and platelets > 0
        ):
            score = (age * ast) / (platelets * sqrt(alt))
            risk, color = risk_rules.fib4_risk(score)
            results.append(
                self._result(
                    organ="Liver",
                    index_name="FIB-4",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used={"age": age, "ast": ast, "alt": alt, "platelets": platelets},
                    formula_used="FIB-4 = (Age x AST) / (Platelets x sqrt(ALT))",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "FIB-4",
                "Liver",
                {"age": age, "ast": ast, "alt": alt, "platelets": platelets},
            )

    def _calculate_fli(self, results, more_needed, general, bmi, waist, ggt, tg):
        if (
            bmi is not None
            and waist is not None
            and ggt is not None
            and tg is not None
            and ggt > 0
            and tg > 0
        ):
            linear = 0.953 * log(tg) + 0.139 * bmi + 0.718 * log(ggt) + 0.053 * waist - 15.745
            score = (exp(linear) / (1 + exp(linear))) * 100
            risk, color = risk_rules.fli_risk(score)
            results.append(
                self._result(
                    organ="Liver",
                    index_name="FLI",
                    score=round(score, 2),
                    risk_level=risk,
                    color=color,
                    values_used={
                        "bmi": round(bmi, 2),
                        "waist_cm": waist,
                        "ggt": ggt,
                        "triglycerides_mg/dL": round(tg, 2),
                    },
                    formula_used="FLI = logistic BMI + waist + GGT + triglycerides formula",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "FLI",
                "Liver",
                {"bmi": bmi, "waist_cm": waist, "ggt": ggt, "triglycerides": tg},
            )

    def _calculate_nafld(
        self,
        results,
        more_needed,
        general,
        age,
        bmi,
        ast,
        alt,
        platelets,
        fasting,
        hba1c,
        ppbs,
        random_glucose,
        albumin,
    ):
        glucose_available = any(v is not None for v in [fasting, hba1c, ppbs, random_glucose])
        if (
            age is not None
            and bmi is not None
            and ast is not None
            and alt is not None
            and alt > 0
            and platelets is not None
            and albumin is not None
            and glucose_available
        ):
            glucose_flag = 1 if (
                (fasting is not None and fasting >= 100)
                or (hba1c is not None and hba1c >= 5.7)
                or (ppbs is not None and ppbs >= 140)
                or (random_glucose is not None and random_glucose >= 140)
            ) else 0
            ast_alt_ratio = ast / alt
            score = (
                -1.675
                + (0.037 * age)
                + (0.094 * bmi)
                + (1.13 * glucose_flag)
                + (0.99 * ast_alt_ratio)
                - (0.013 * platelets)
                - (0.66 * albumin)
            )
            risk, color = risk_rules.nafld_risk(score)
            results.append(
                self._result(
                    organ="Liver",
                    index_name="NAFLD Fibrosis Score",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used={
                        "age": age,
                        "bmi": round(bmi, 2),
                        "ast": ast,
                        "alt": alt,
                        "platelets": platelets,
                        "glucose_pattern_flag": glucose_flag,
                        "albumin": albumin,
                    },
                    formula_used="NAFLD = age + BMI + AST/ALT + platelets + glucose pattern + albumin formula",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "NAFLD Fibrosis Score",
                "Liver",
                {
                    "age": age,
                    "bmi": bmi,
                    "ast": ast,
                    "alt": alt,
                    "platelets": platelets,
                    "glucose_or_hba1c": 1 if glucose_available else None,
                    "albumin": albumin,
                },
            )

    def _calculate_nlr(self, results, more_needed, general, neutrophils, lymphocytes):
        if neutrophils is not None and lymphocytes is not None and lymphocytes > 0:
            score = neutrophils / lymphocytes
            risk, color = risk_rules.nlr_risk(score)
            results.append(
                self._result(
                    organ="Inflammation",
                    index_name="NLR",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used={"neutrophils": neutrophils, "lymphocytes": lymphocytes},
                    formula_used="NLR = Neutrophils / Lymphocytes",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "NLR",
                "Inflammation",
                {"neutrophils": neutrophils, "lymphocytes": lymphocytes},
            )

    def _calculate_egfr(self, results, more_needed, general, age, sex, creatinine):
        if age is not None and sex is not None and creatinine is not None and creatinine > 0:
            sex_lower = sex.lower()
            is_female = sex_lower.startswith("f")
            k = 0.7 if is_female else 0.9
            alpha = -0.241 if is_female else -0.302
            score = (
                142
                * (min(creatinine / k, 1) ** alpha)
                * (max(creatinine / k, 1) ** -1.200)
                * (0.9938 ** age)
                * (1.012 if is_female else 1)
            )
            risk, color = risk_rules.egfr_rule(score)
            results.append(
                self._result(
                    organ="Kidney",
                    index_name="eGFR",
                    score=round(score, 1),
                    risk_level=risk,
                    color=color,
                    values_used={
                        "age": age,
                        "sex": sex,
                        "creatinine_mg/dL": round(creatinine, 3),
                    },
                    formula_used="eGFR = age + sex + creatinine based CKD-EPI 2021 estimate",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "eGFR",
                "Kidney",
                {"age": age, "sex": sex, "creatinine": creatinine},
            )

    def _calculate_spo2(self, results, more_needed, general, spo2):
        if spo2 is not None:
            risk, color = risk_rules.spO2_risk(spo2)
            results.append(
                self._result(
                    organ="Lung",
                    index_name="SpO2",
                    score=spo2,
                    risk_level=risk,
                    color=color,
                    values_used={"spo2_%": spo2},
                    formula_used="SpO2 direct interpretation",
                    general=general,
                )
            )
        else:
            self._more_needed(more_needed, "SpO2", "Lung", {"spo2": spo2})

    def _calculate_lar(self, results, more_needed, general, lipase, amylase):
        if lipase is not None and amylase is not None and amylase > 0:
            score = lipase / amylase
            risk, color = risk_rules.lar_rule(score)
            results.append(
                self._result(
                    organ="Pancreas",
                    index_name="LAR",
                    score=round(score, 3),
                    risk_level=risk,
                    color=color,
                    values_used={"lipase": lipase, "amylase": amylase},
                    formula_used="LAR = Lipase / Amylase",
                    general=general,
                )
            )
        else:
            self._more_needed(
                more_needed,
                "LAR",
                "Pancreas",
                {"lipase": lipase, "amylase": amylase},
            )

    def _calculate_tumor_markers(self, results, more_needed, general, tumor):
        markers = [
            ("AFP", "afp", 10, 20),
            ("CA 15-3", "ca15_3", 30, 45),
            ("CA 27.29", "ca27_29", 38, 55),
        ]
        for display_name, key, low_cutoff, moderate_cutoff in markers:
            value = tumor.get(key)
            if value is None:
                self._more_needed(more_needed, display_name, "Cancer Awareness", {key: value})
                continue
            risk, color = risk_rules.tumor_marker_risk(value, low_cutoff, moderate_cutoff)
            results.append(
                self._result(
                    organ="Cancer Awareness",
                    index_name=display_name,
                    score=value,
                    risk_level=risk,
                    color=color,
                    values_used={key: value},
                    formula_used=f"{display_name} direct awareness interpretation",
                    general=general,
                )
            )
