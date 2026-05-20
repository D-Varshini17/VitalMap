from typing import List


class ExplanationEngine:
    def disclaimer(self) -> str:
        return (
            "For informational purposes only. This app is not a substitute for clinical diagnosis,"
            " treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions."
        )

    def overall_risk(self, results: List[dict], more_needed: List[dict]) -> str:
        # simple rule: if any high -> High, else if any moderate -> Moderate, else if any low -> Low, else More Data Needed
        has_high = any(r.get("risk_level") == "High" for r in results)
        has_moderate = any(r.get("risk_level") == "Moderate" for r in results)
        has_low = any(r.get("risk_level") == "Low" for r in results)
        if has_high:
            return "High"
        if has_moderate:
            return "Moderate"
        if has_low:
            return "Low"
        return "More Data Needed"

    def contributors(self, general_health: dict) -> List[str]:
        out = []
        if not general_health:
            return out
        if general_health.get("smoking") and general_health.get("smoking") != "No":
            out.append("Smoking may contribute to risk indicators")
        if general_health.get("alcohol") and general_health.get("alcohol") != "No":
            out.append("Alcohol use may influence liver and pancreatic markers")
        return out

    def suggested_next_step(self, index_name: str) -> str:
        return "Clinical review suggested if abnormal values persist. Consult a qualified healthcare professional."
