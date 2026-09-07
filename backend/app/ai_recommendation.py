import json
import logging
import os
import urllib.request
from datetime import datetime, timezone
from typing import Any, Dict, List

logger = logging.getLogger(__name__)

AI_KEYS = [
    "summary",
    "top_priorities",
    "nutrition_recommendations",
    "hydration_recommendations",
    "physical_activity_recommendations",
    "sleep_recommendations",
    "stress_recommendations",
    "lifestyle_recommendations",
    "environment_recommendations",
    "preventive_recommendations",
    "heart_recommendations",
    "liver_recommendations",
    "kidney_recommendations",
    "lung_recommendations",
    "metabolic_recommendations",
    "missing_data_recommendations",
    "doctor_followup",
    "questions_for_doctor",
]

LIST_KEYS = [key for key in AI_KEYS if key not in {"summary", "doctor_followup"}]
DEFAULT_DOCTOR_FOLLOWUP = (
    "No immediate follow-up is indicated by this screening alone. Continue routine health check-ups and seek "
    "professional advice if you develop symptoms or have health concerns."
)
UNAVAILABLE_SUMMARY = "AI recommendations are temporarily unavailable. Your calculated screening results are unaffected."


class AIRecommendationService:
    def __init__(self):
        self.enabled = os.getenv("ENABLE_AI_RECOMMENDATIONS", "false").lower() == "true"
        self.provider = os.getenv("AI_RECOMMENDATION_PROVIDER", "ollama").lower()
        self.ollama_model = os.getenv("OLLAMA_MODEL", "qwen3:1.7b")
        self.ollama_base_url = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434").rstrip("/")
        self.timeout = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "20"))

    def enhance_results(self, results: List[Dict[str, Any]], payload: Dict[str, Any]):
        # Backward-compatible hook: per-result cloud enhancement is intentionally no longer used.
        return results

    def enhance_response(
        self,
        *,
        results: List[Dict[str, Any]],
        more_needed: List[Dict[str, Any]],
        payload: Dict[str, Any],
        overall_risk: str,
        general_health_pattern: List[str],
    ) -> Dict[str, Any]:
        fallback = self._with_context(
            self._fallback_package(results, more_needed, payload, overall_risk, general_health_pattern),
            results,
            more_needed,
        )
        if not self.enabled:
            return self._envelope(False, "disabled", fallback, None)
        if self.provider != "ollama":
            return self._envelope(False, f"unsupported provider: {self.provider}", fallback, None)
        try:
            ai = self._generate_with_ollama(results, more_needed, payload, overall_risk, general_health_pattern)
            normalized = self._with_context(self._normalize_package(ai, fallback), results, more_needed)
            return self._envelope(True, "connected", normalized, None)
        except Exception as exc:  # noqa: BLE001 - service must not break screening
            logger.exception("Ollama recommendation generation failed: %s", exc)
            return self._envelope(False, "unavailable", fallback, str(exc))

    def status(self) -> Dict[str, Any]:
        base = {
            "enabled": self.enabled,
            "provider": self.provider,
            "model": self.ollama_model,
            "base_url": self.ollama_base_url,
            "processing": "Local Device / Local Computer",
            "cloud_ai": "Disabled",
        }
        if not self.enabled or self.provider != "ollama":
            return {**base, "connected": False, "status": "disabled" if not self.enabled else "unsupported provider"}
        try:
            request = urllib.request.Request(f"{self.ollama_base_url}/api/tags", method="GET")
            with urllib.request.urlopen(request, timeout=5) as response:
                data = json.loads(response.read().decode("utf-8"))
            models = [item.get("name") for item in data.get("models", [])]
            return {**base, "connected": self.ollama_model in models, "status": "connected" if self.ollama_model in models else "model missing", "models": models}
        except Exception as exc:  # noqa: BLE001
            logger.warning("Ollama status check failed: %s", exc)
            return {**base, "connected": False, "status": "unavailable", "error": str(exc)}

    def _generate_with_ollama(
        self,
        results: List[Dict[str, Any]],
        more_needed: List[Dict[str, Any]],
        payload: Dict[str, Any],
        overall_risk: str,
        general_health_pattern: List[str],
    ) -> Dict[str, Any]:
        body = json.dumps(
            {
                "model": self.ollama_model,
                "messages": [
                    {"role": "system", "content": self._system_instruction()},
                    {"role": "user", "content": json.dumps(self._context(results, more_needed, payload, overall_risk, general_health_pattern))},
                ],
                "stream": False,
                "format": "json",
                "options": {"temperature": 0.2},
            }
        ).encode("utf-8")
        request = urllib.request.Request(
            f"{self.ollama_base_url}/api/chat",
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            data = json.loads(response.read().decode("utf-8"))
        text = (data.get("message") or {}).get("content", "")
        parsed = self._parse_json_text(text)
        if not parsed:
            raise ValueError("Ollama returned invalid or empty JSON")
        if not self._is_safe_ai_object(parsed):
            raise ValueError("Ollama response failed safety validation")
        return parsed

    def _context(
        self,
        results: List[Dict[str, Any]],
        more_needed: List[Dict[str, Any]],
        payload: Dict[str, Any],
        overall_risk: str,
        general_health_pattern: List[str],
    ) -> Dict[str, Any]:
        profile = payload.get("profile") or {}
        general = payload.get("general_health") or {}
        calculated = [
            {
                "organ": result.get("organ"),
                "index_name": result.get("index_name"),
                "score": result.get("score"),
                "risk_level": result.get("risk_level"),
                "values_used": result.get("values_used"),
                "summary": result.get("summary"),
                "doctor_followup": result.get("doctor_followup"),
            }
            for result in results
        ]
        return {
            "application": "VitalMap",
            "rule": "Deterministic formula results below are already final. Do not recalculate or change them.",
            "overall_risk": overall_risk,
            "profile": {key: profile.get(key) for key in ["age", "sex", "height_cm", "height_input", "height_unit", "weight_kg", "weight_input", "weight_unit", "waist_cm", "waist_input", "waist_unit"] if profile.get(key) is not None},
            "lifestyle": {key: value for key, value in general.items() if value not in [None, ""]},
            "general_health_pattern": general_health_pattern,
            "calculated_results": calculated,
            "more_data_needed": more_needed,
            "required_json_keys": AI_KEYS,
        }

    def _system_instruction(self) -> str:
        return """
You are VitalMap Local AI.
VitalMap has already calculated health screening indicators using deterministic formulas.
You are NOT responsible for diagnosis or medical calculations.
Never diagnose a disease, claim the user has a disease, prescribe medication, provide medication dosage, recommend starting or stopping medication, change an existing risk category, modify calculated scores, recalculate health formulas, invent laboratory values, invent symptoms, invent medical history, claim certainty, or replace professional medical evaluation.
You may explain calculated results in simple language and provide general lifestyle, nutrition, hydration, activity, sleep, stress, preventive, missing-data, and doctor-question guidance using only supplied VitalMap information.
For organs marked Monitor or Needs Attention, provide slightly more targeted general guidance. For lower-concern organs, provide short maintenance-oriented advice.
Doctor follow-up must never be empty. Return valid JSON only. Do not output Markdown. Do not add text before or after the JSON.
""".strip()

    def _fallback_package(
        self,
        results: List[Dict[str, Any]],
        more_needed: List[Dict[str, Any]],
        payload: Dict[str, Any],
        overall_risk: str,
        general_health_pattern: List[str],
    ) -> Dict[str, Any]:
        organs = self._organ_groups(results)
        missing = [item.get("index_name", "this indicator") for item in more_needed[:5]]
        summary = self._summary(results, more_needed, overall_risk)
        doctor = self._doctor_followup(results)
        return self._normalize_package(
            {
                "summary": summary,
                "top_priorities": self._priorities(results, more_needed, general_health_pattern),
                "nutrition_recommendations": self._nutrition(payload),
                "hydration_recommendations": ["Keep hydration habits steady and adjust fluid intake based on thirst, activity, climate, and professional guidance when relevant."],
                "physical_activity_recommendations": self._activity(payload),
                "sleep_recommendations": self._sleep(payload),
                "stress_recommendations": self._stress(payload),
                "lifestyle_recommendations": self._lifestyle(payload),
                "environment_recommendations": self._environment(payload),
                "preventive_recommendations": ["Keep routine health check-ups and compare screening values over time when repeated reports are available."],
                "heart_recommendations": self._organ_advice("Heart", organs),
                "liver_recommendations": self._organ_advice("Liver", organs),
                "kidney_recommendations": self._organ_advice("Kidney", organs),
                "lung_recommendations": self._organ_advice("Lung", organs),
                "metabolic_recommendations": self._organ_advice("Diabetes / Metabolic", organs),
                "missing_data_recommendations": [f"Adding the missing inputs for {name} may improve screening completeness." for name in missing],
                "doctor_followup": doctor if doctor else DEFAULT_DOCTOR_FOLLOWUP,
                "questions_for_doctor": [
                    "What does this calculated indicator mean in the context of my overall health?",
                    "Should this value be monitored over time?",
                    "Would any additional information help interpret this screening result?",
                ],
            },
            None,
        )

    def _normalize_package(self, raw: Dict[str, Any], fallback: Dict[str, Any] | None) -> Dict[str, Any]:
        normalized: Dict[str, Any] = {}
        fallback = fallback or {}
        for key in AI_KEYS:
            if key in LIST_KEYS:
                values = raw.get(key)
                if isinstance(values, list):
                    cleaned = [str(item).strip() for item in values if str(item).strip()]
                elif isinstance(values, str) and values.strip():
                    cleaned = [values.strip()]
                else:
                    cleaned = []
                normalized[key] = cleaned or list(fallback.get(key, []))
            else:
                value = raw.get(key)
                text = str(value).strip() if value is not None else ""
                normalized[key] = text or str(fallback.get(key, "")).strip()
        if not normalized["summary"]:
            normalized["summary"] = UNAVAILABLE_SUMMARY
        if not normalized["doctor_followup"]:
            normalized["doctor_followup"] = DEFAULT_DOCTOR_FOLLOWUP
        return normalized

    def _with_context(
        self,
        package: Dict[str, Any],
        results: List[Dict[str, Any]],
        more_needed: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        package = dict(package)
        calculated = len(results)
        missing = len(more_needed)
        total = calculated + missing
        percent = round((calculated / total) * 100) if total else 0
        if total == 0:
            label = "No screening indicators available"
        elif percent >= 75:
            label = "Strong screening context"
        elif percent >= 40:
            label = "Partial screening context"
        else:
            label = "Limited screening context"
        package["data_completeness"] = {
            "percent": percent,
            "calculated_indicators": calculated,
            "missing_indicators": missing,
            "label": label,
        }
        package["health_trend"] = {
            "status": "Insufficient history",
            "message": "Trend comparison needs saved repeat screenings over time. This result is interpreted as a single screening snapshot.",
        }
        return package

    def _envelope(self, connected: bool, status: str, package: Dict[str, Any], error: str | None) -> Dict[str, Any]:
        return {
            "enabled": self.enabled,
            "provider": "ollama",
            "model": self.ollama_model,
            "base_url": self.ollama_base_url,
            "connected": connected,
            "status": status,
            "processing": "Local Device / Local Computer",
            "cloud_ai": "Disabled",
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "error": error,
            **package,
        }

    def _parse_json_text(self, text: str) -> Dict[str, Any]:
        try:
            return json.loads(text)
        except Exception:
            cleaned = text.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
            start = cleaned.find("{")
            end = cleaned.rfind("}")
            if start >= 0 and end > start:
                try:
                    return json.loads(cleaned[start : end + 1])
                except Exception:
                    return {}
        return {}

    def _is_safe_ai_object(self, ai_obj: Dict[str, Any]) -> bool:
        text = json.dumps(ai_obj, ensure_ascii=False).lower()
        forbidden = ["disease confirmed", "cancer detected", "guaranteed prediction", "treatment plan", "medication dosage", "prescribe"]
        return not any(term in text for term in forbidden)

    def _organ_groups(self, results: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
        out: Dict[str, List[Dict[str, Any]]] = {}
        for result in results:
            out.setdefault(str(result.get("organ", "General")), []).append(result)
        return out

    def _summary(self, results: List[Dict[str, Any]], more_needed: List[Dict[str, Any]], overall: str) -> str:
        if not results:
            return "VitalMap needs additional report values before it can calculate the selected screening indicators. Your current result is based only on available information."
        names = ", ".join(str(r.get("index_name")) for r in results[:4])
        extra = " Missing inputs can improve screening completeness." if more_needed else ""
        return f"VitalMap calculated {len(results)} screening indicator(s), including {names}. The overall screening label is {overall}.{extra}"

    def _priorities(self, results: List[Dict[str, Any]], more_needed: List[Dict[str, Any]], patterns: List[str]) -> List[str]:
        out = []
        attention = [r for r in results if "attention" in str(r.get("risk_level", "")).lower() or "high" in str(r.get("risk_level", "")).lower()]
        monitor = [r for r in results if "monitor" in str(r.get("risk_level", "")).lower() or "moderate" in str(r.get("risk_level", "")).lower()]
        if attention:
            out.append(f"Discuss the {attention[0].get('index_name')} screening result with a qualified healthcare professional if it persists or relates to symptoms.")
        if monitor:
            out.append(f"Track the {monitor[0].get('index_name')} result over time and review related source values.")
        if more_needed:
            out.append(f"Add missing inputs for {more_needed[0].get('index_name')} to improve screening completeness.")
        if not out and patterns:
            out.append(patterns[0])
        if not out:
            out.append("Continue routine health monitoring and maintain healthy daily habits.")
        return out[:3]

    def _doctor_followup(self, results: List[Dict[str, Any]]) -> str:
        if any("attention" in str(r.get("risk_level", "")).lower() or "high" in str(r.get("risk_level", "")).lower() for r in results):
            return "Consider discussing these screening results with a qualified healthcare professional, particularly if values persist, symptoms are present, or you have relevant medical history."
        if any("monitor" in str(r.get("risk_level", "")).lower() or "moderate" in str(r.get("risk_level", "")).lower() for r in results):
            return "Consider discussing monitored screening values during your next routine healthcare visit, especially if they persist or increase."
        return DEFAULT_DOCTOR_FOLLOWUP

    def _nutrition(self, payload: Dict[str, Any]) -> List[str]:
        general = payload.get("general_health") or {}
        out = ["Build meals around vegetables, fruits, whole grains, fiber-rich foods, and appropriate protein."]
        if general.get("sugary_drinks") == "Frequently" or general.get("high_sugar_intake") == "High":
            out.append("Limit frequent sugary drinks and high-added-sugar foods where practical.")
        if general.get("high_salt_intake") == "High":
            out.append("Reduce heavily salted packaged foods where practical.")
        return out

    def _activity(self, payload: Dict[str, Any]) -> List[str]:
        general = payload.get("general_health") or {}
        if general.get("physical_activity") == "Low":
            return ["Gradually increase regular movement, such as walking, within your comfort and health limits."]
        return ["Maintain regular physical activity appropriate for your health, schedule, and abilities."]

    def _sleep(self, payload: Dict[str, Any]) -> List[str]:
        general = payload.get("general_health") or {}
        if general.get("sleep_duration") == "<5 hrs":
            return ["Work toward a consistent sleep schedule and discuss persistent short sleep with a healthcare professional if it affects daily life."]
        return ["Keep a regular sleep routine and allow enough recovery time when possible."]

    def _stress(self, payload: Dict[str, Any]) -> List[str]:
        general = payload.get("general_health") or {}
        if general.get("stress_level") == "High":
            return ["Use simple stress-management routines such as short breaks, breathing exercises, regular sleep, and appropriate support."]
        return ["Maintain regular routines and short recovery breaks to support overall wellness."]

    def _lifestyle(self, payload: Dict[str, Any]) -> List[str]:
        general = payload.get("general_health") or {}
        out = []
        if general.get("smoking") in ["Yes", "Former"] or general.get("passive_smoking") == "Yes":
            out.append("Avoid tobacco, nicotine, and second-hand smoke exposure where possible.")
        if general.get("alcohol") == "Frequent":
            out.append("Consider reducing frequent alcohol intake and discuss safe limits with a healthcare professional.")
        return out or ["Continue healthy routines and track screening values over time when repeat reports are available."]

    def _environment(self, payload: Dict[str, Any]) -> List[str]:
        general = payload.get("general_health") or {}
        out = []
        if general.get("air_pollution") in ["Moderate", "High"]:
            out.append("Reduce avoidable exposure during high-pollution periods when practical.")
        if general.get("cooking_smoke") == "Yes" or general.get("cooking_fuel_smoke") == "Yes":
            out.append("Improve cooking ventilation where practical to reduce smoke exposure.")
        return out

    def _organ_advice(self, organ: str, organs: Dict[str, List[Dict[str, Any]]]) -> List[str]:
        items = organs.get(organ, [])
        if not items:
            return []
        top = items[0]
        return [f"{organ} screening includes {top.get('index_name')} with VitalMap label {top.get('risk_level')}. Use the calculated label as screening context, not a diagnosis."]
