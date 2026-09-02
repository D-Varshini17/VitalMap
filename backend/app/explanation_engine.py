from typing import List, Dict, Any


class ExplanationEngine:
    def disclaimer(self) -> str:
        return (
            "For informational purposes only. This app is not a substitute for clinical diagnosis,"
            " treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions."
        )

    def overall_risk(self, results: List[dict], more_needed: List[dict]) -> str:
        has_high = any(self._severity(r.get("risk_level")) == "High" for r in results)
        has_moderate = any(self._severity(r.get("risk_level")) == "Moderate" for r in results)
        has_low = any(self._severity(r.get("risk_level")) == "Low" for r in results)
        if has_high:
            return "High"
        if has_moderate:
            return "Moderate"
        if has_low:
            return "Low"
        return "More Data Needed"

    def _severity(self, risk_level: str | None) -> str:
        if not risk_level:
            return "More Data Needed"
        if risk_level.startswith("High"):
            return "High"
        if risk_level.startswith("Moderate"):
            return "Moderate"
        if risk_level.startswith("Low"):
            return "Low"
        return risk_level

    def general_health_pattern(self, general_health: dict) -> List[str]:
        out: List[str] = []
        if not general_health:
            return out
        if general_health.get("smoking") in ["Former", "Yes"]:
            out.append("Smoking exposure reported")
        if general_health.get("alcohol") == "Frequent":
            out.append("Frequent alcohol intake reported")
        if general_health.get("physical_activity") == "Low":
            out.append("Low physical activity reported")
        if general_health.get("sleep_duration") == "<5 hrs":
            out.append("Short sleep duration reported")
        if general_health.get("stress_level") == "High":
            out.append("High stress level reported")
        if general_health.get("family_history") not in [None, "None"]:
            out.append(f"Family history reported: {general_health.get('family_history')}")
        if general_health.get("high_sugar_intake") == "High":
            out.append("High sugar intake reported")
        if general_health.get("high_salt_intake") == "High":
            out.append("High salt intake reported")
        if general_health.get("fried_processed_food") == "Frequent":
            out.append("Frequent fried or processed food intake reported")
        if general_health.get("fruit_veg_intake") == "Low":
            out.append("Low fruit and vegetable intake reported")
        if general_health.get("sugary_drinks") == "Frequently":
            out.append("Frequent sugary drink intake reported")
        if general_health.get("air_pollution") in ["Moderate", "High"]:
            out.append(f"{general_health.get('air_pollution')} air pollution exposure reported")
        if general_health.get("occupational_exposure") == "Yes":
            out.append("Occupational dust or chemical exposure reported")
        if general_health.get("passive_smoking") == "Yes":
            out.append("Passive smoking exposure reported")
        if general_health.get("cooking_smoke") == "Yes" or general_health.get("cooking_fuel_smoke") == "Yes":
            out.append("Cooking smoke exposure reported")
        return out

    def contributors(self, organ: str, general_health: dict, values: Dict[str, Any]) -> List[str]:
        out: List[str] = []
        if general_health.get("physical_activity") == "Low":
            out.append("Low physical activity")
        if general_health.get("fried_processed_food") == "Frequent":
            out.append("Frequent fried or processed food intake")
        if general_health.get("high_sugar_intake") == "High":
            out.append("High sugar intake")
        if general_health.get("sugary_drinks") == "Frequently":
            out.append("Frequent sugary drinks")
        if general_health.get("high_salt_intake") == "High" and organ in ["Heart", "Kidney", "Diabetes / Metabolic"]:
            out.append("High salt intake")
        if general_health.get("smoking") in ["Former", "Yes"] or general_health.get("passive_smoking") == "Yes":
            out.append("Smoking exposure")
        if general_health.get("stress_level") == "High":
            out.append("High stress level")
        if general_health.get("sleep_duration") == "<5 hrs":
            out.append("Short sleep duration")
        if organ in ["Liver", "Pancreas"] and general_health.get("alcohol") in ["Occasional", "Frequent"]:
            out.append("Alcohol intake")
        if organ == "Lung" and general_health.get("air_pollution") in ["Moderate", "High"]:
            out.append("Air pollution exposure")
        if organ == "Lung" and general_health.get("cooking_smoke") == "Yes":
            out.append("Cooking smoke exposure")
        if organ == "Lung" and general_health.get("cooking_fuel_smoke") == "Yes":
            out.append("Cooking fuel smoke exposure")
        if general_health.get("family_history") not in [None, "None"]:
            out.append("Family history")
        return out[:6]

    def summary(self, index_name: str, organ: str, risk_level: str) -> str:
        labels = {
            "AIP": "The entered triglycerides and HDL values were used to create a lipid-related screening insight for heart and metabolic health.",
            "TyG": "The entered triglycerides and fasting glucose values were used to create a metabolic screening insight.",
            "Metabolic screening insight": "The entered glucose-related values were reviewed as a simple metabolic risk indicator.",
            "APRI": "The entered AST and platelet values were used to create a liver fibrosis screening insight.",
            "FIB-4": "The entered age, AST, ALT, and platelet values were used to create a liver fibrosis screening insight.",
            "FLI": "BMI, waist circumference, GGT, and triglycerides were used to create a fatty liver screening insight.",
            "NAFLD Fibrosis Score": "Age, BMI, AST, ALT, platelets, glucose pattern, and albumin were used to create a liver fibrosis screening insight.",
            "NLR": "Neutrophil and lymphocyte values were used to create an inflammation screening insight.",
            "LAR": "Lipase and amylase values were used to create a pancreatic enzyme ratio screening insight.",
            "SpO2": "Oxygen saturation was interpreted as a lung oxygen screening indicator.",
            "eGFR": "Age, sex, and creatinine were used to estimate a kidney function screening indicator.",
            "AFP": "AFP was interpreted as a cancer awareness marker only.",
            "CA 15-3": "CA 15-3 was interpreted as a cancer awareness marker only.",
            "CA 27.29": "CA 27.29 was interpreted as a cancer awareness marker only.",
        }
        base = labels.get(index_name, f"{index_name} was calculated as a {organ} risk indicator.")
        return f"{base} The current risk indicator is {risk_level.lower()}."

    def suggestions(self, organ: str, index_name: str) -> List[str]:
        common = [
            "Review these values with a qualified healthcare professional if they are outside the expected range.",
            "Track the same report values over time instead of relying on one reading only.",
        ]
        organ_specific = {
            "Heart": [
                "Monitor blood pressure and glucose values if available.",
                "Discuss lipid profile results during a routine clinical review.",
            ],
            "Diabetes / Metabolic": [
                "Review glucose values with a healthcare professional.",
                "Consider repeat testing if values were taken during illness or unusual stress.",
            ],
            "Liver": [
                "Review liver function results with a healthcare professional.",
                "Avoid self-interpreting liver markers in isolation.",
            ],
            "Kidney": [
                "Review creatinine and eGFR trends with a healthcare professional.",
                "Discuss hydration, medicines, and repeat testing if results are unexpected.",
            ],
            "Lung": [
                "Recheck SpO2 with a reliable device if the reading seems unusual.",
                "Seek clinical advice if low oxygen readings persist or symptoms are present.",
            ],
            "Inflammation": [
                "Interpret CBC ratios along with symptoms and the full blood report.",
                "Repeat or review the CBC if values were taken during infection or stress.",
            ],
            "Pancreas": [
                "Review enzyme values with a healthcare professional if abdominal symptoms are present.",
                "Avoid interpreting enzyme ratios without clinical context.",
            ],
            "Cancer Awareness": [
                "Use this marker only as an awareness indicator, not as a cancer screening confirmation.",
                "Discuss abnormal or persistent marker values with a qualified healthcare professional.",
            ],
        }
        return organ_specific.get(organ, []) + common

    def lifestyle_improvement(self, organ: str) -> List[str]:
        base = [
            "Aim for regular walking or moderate physical activity as tolerated.",
            "Prefer vegetables, fruits, whole grains, and lean protein.",
            "Reduce sugary drinks, high-salt foods, and fried or processed foods.",
            "Avoid smoking exposure and limit alcohol intake.",
        ]
        if organ == "Lung":
            base.append("Reduce smoke, dust, and pollution exposure where practical.")
        if organ == "Kidney":
            base.append("Avoid unnecessary over-the-counter pain medicines unless advised by a clinician.")
        return base

    def food_recommendations(self, organ: str) -> List[str]:
        advice = [
            "Prefer vegetables, fruits, whole grains, and fiber-rich foods.",
            "Reduce sugary drinks and frequent fried or processed foods.",
            "Keep high-salt packaged foods occasional where practical.",
        ]
        if organ in ["Heart", "Diabetes / Metabolic", "Liver"]:
            advice.append("Choose lean protein and unsaturated fats more often.")
        if organ == "Kidney":
            advice.append("Discuss any major diet restriction with a qualified healthcare professional.")
        return advice

    def environment_recommendations(self, organ: str) -> List[str]:
        advice = [
            "Avoid smoking and passive smoking exposure where possible.",
            "Reduce dust, chemical, and smoke exposure when practical.",
            "Use ventilation during cooking when smoke exposure is present.",
        ]
        if organ == "Lung":
            advice.append("Consider checking air quality and limiting outdoor exposure during high pollution periods.")
        return advice

    def doctor_followup(self, risk_level: str) -> str:
        severity = self._severity(risk_level)
        if severity == "High":
            return "Clinical review is suggested soon, especially if abnormal values persist or symptoms are present."
        if severity == "Moderate":
            return "Clinical review is suggested if the value persists, increases, or is linked with symptoms."
        if severity == "Low":
            return "Routine follow-up can be considered during regular health checkups."
        return "More report values are needed before this risk indicator can be interpreted."

    def rule_based_ai_recommendation(
        self,
        organ: str,
        index_name: str,
        score,
        risk_level: str,
        values_used: Dict[str, Any],
        general_health: dict,
    ) -> Dict[str, Any]:
        return {
            "simple_summary": self.summary(index_name, organ, risk_level),
            "possible_contributors": self.contributors(organ, general_health, values_used),
            "lifestyle_recommendations": self.lifestyle_improvement(organ),
            "food_recommendations": self.food_recommendations(organ),
            "environment_recommendations": self.environment_recommendations(organ),
            "doctor_followup": self.doctor_followup(risk_level),
            "disclaimer": self.disclaimer(),
        }
