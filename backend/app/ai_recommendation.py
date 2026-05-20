import json
import os
import urllib.request
from typing import Any, Dict, List


class AIRecommendationService:
    def __init__(self):
        self.enabled = os.getenv("ENABLE_AI_RECOMMENDATIONS", "false").lower() == "true"
        self.provider = os.getenv("AI_RECOMMENDATION_PROVIDER", "openai").lower()
        self.openai_key = os.getenv("OPENAI_API_KEY")
        self.gemini_key = os.getenv("GEMINI_API_KEY")
        self.openai_model = os.getenv("OPENAI_RECOMMENDATION_MODEL", "gpt-4o-mini")
        self.gemini_model = os.getenv("GEMINI_RECOMMENDATION_MODEL", "gemini-1.5-flash")

    def enhance_results(self, results: List[Dict[str, Any]], payload: Dict[str, Any]):
        if not self.enabled:
            return results
        if self.provider == "openai" and self.openai_key:
            return [self._enhance_with_openai(result, payload) for result in results]
        if self.provider == "gemini" and self.gemini_key:
            return [self._enhance_with_gemini(result, payload) for result in results]
        return results

    def _system_instruction(self) -> str:
        return (
            "You are a health information assistant for an organ health risk indicator app. "
            "You do not diagnose, treat, or confirm disease. You only explain calculated risk "
            "indicators in simple language and provide general lifestyle, food habit, and "
            "environmental recommendations. Always recommend consulting a qualified healthcare "
            "professional for medical decisions. Do not use medication advice."
        )

    def _user_payload(self, result: Dict[str, Any], payload: Dict[str, Any]) -> str:
        safe_input = {
            "organ_system": result.get("organ"),
            "index_name": result.get("index_name"),
            "calculated_score": result.get("score"),
            "risk_indicator": result.get("risk_level"),
            "values_used": result.get("values_used"),
            "general_lifestyle_answers": payload.get("general_health") or {},
            "profile": payload.get("profile") or {},
            "symptoms": payload.get("symptoms") or {},
            "output_format": {
                "simple_summary": "...",
                "possible_contributors": [],
                "lifestyle_recommendations": [],
                "food_recommendations": [],
                "environment_recommendations": [],
                "doctor_followup": "...",
                "disclaimer": "...",
            },
            "forbidden_wording": [
                "diagnosis",
                "disease confirmed",
                "cancer detected",
                "guaranteed prediction",
                "treatment plan",
                "medication advice",
            ],
        }
        return json.dumps(safe_input)

    def _apply_ai_object(self, result: Dict[str, Any], ai_obj: Dict[str, Any]) -> Dict[str, Any]:
        if not ai_obj:
            return result
        updated = dict(result)
        fallback = dict(result.get("ai_recommendation") or {})
        fallback.update(
            {
                "simple_summary": ai_obj.get("simple_summary") or fallback.get("simple_summary"),
                "possible_contributors": ai_obj.get("possible_contributors") or fallback.get("possible_contributors", []),
                "lifestyle_recommendations": ai_obj.get("lifestyle_recommendations") or fallback.get("lifestyle_recommendations", []),
                "food_recommendations": ai_obj.get("food_recommendations") or fallback.get("food_recommendations", []),
                "environment_recommendations": ai_obj.get("environment_recommendations") or fallback.get("environment_recommendations", []),
                "doctor_followup": ai_obj.get("doctor_followup") or fallback.get("doctor_followup"),
                "disclaimer": ai_obj.get("disclaimer") or fallback.get("disclaimer"),
            }
        )
        updated["ai_recommendation"] = fallback
        updated["summary"] = fallback.get("simple_summary") or updated.get("summary")
        updated["possible_contributors"] = fallback.get("possible_contributors") or updated.get("possible_contributors", [])
        updated["lifestyle_improvement"] = fallback.get("lifestyle_recommendations") or updated.get("lifestyle_improvement", [])
        updated["food_recommendations"] = fallback.get("food_recommendations") or updated.get("food_recommendations", [])
        updated["environment_recommendations"] = fallback.get("environment_recommendations") or updated.get("environment_recommendations", [])
        updated["doctor_followup"] = fallback.get("doctor_followup") or updated.get("doctor_followup")
        return updated

    def _parse_json_text(self, text: str) -> Dict[str, Any]:
        try:
            return json.loads(text)
        except Exception:
            start = text.find("{")
            end = text.rfind("}")
            if start >= 0 and end > start:
                try:
                    return json.loads(text[start : end + 1])
                except Exception:
                    return {}
        return {}

    def _enhance_with_openai(self, result: Dict[str, Any], payload: Dict[str, Any]):
        try:
            body = json.dumps(
                {
                    "model": self.openai_model,
                    "messages": [
                        {"role": "system", "content": self._system_instruction()},
                        {"role": "user", "content": self._user_payload(result, payload)},
                    ],
                    "temperature": 0.2,
                    "response_format": {"type": "json_object"},
                }
            ).encode("utf-8")
            request = urllib.request.Request(
                "https://api.openai.com/v1/chat/completions",
                data=body,
                headers={
                    "Authorization": f"Bearer {self.openai_key}",
                    "Content-Type": "application/json",
                },
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=8) as response:
                data = json.loads(response.read().decode("utf-8"))
            text = data["choices"][0]["message"]["content"]
            return self._apply_ai_object(result, self._parse_json_text(text))
        except Exception:
            return result

    def _enhance_with_gemini(self, result: Dict[str, Any], payload: Dict[str, Any]):
        try:
            url = (
                "https://generativelanguage.googleapis.com/v1beta/models/"
                f"{self.gemini_model}:generateContent?key={self.gemini_key}"
            )
            body = json.dumps(
                {
                    "systemInstruction": {"parts": [{"text": self._system_instruction()}]},
                    "contents": [{"role": "user", "parts": [{"text": self._user_payload(result, payload)}]}],
                    "generationConfig": {"temperature": 0.2, "responseMimeType": "application/json"},
                }
            ).encode("utf-8")
            request = urllib.request.Request(
                url,
                data=body,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=8) as response:
                data = json.loads(response.read().decode("utf-8"))
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            return self._apply_ai_object(result, self._parse_json_text(text))
        except Exception:
            return result
