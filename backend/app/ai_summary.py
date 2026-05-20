import json
import os
import urllib.request
from typing import Any, Dict, List


class AISummaryService:
    def __init__(self):
        self.enabled = os.getenv("ENABLE_AI_SUMMARY", "false").lower() == "true"
        self.provider = os.getenv("AI_SUMMARY_PROVIDER", "openai").lower()
        self.openai_key = os.getenv("OPENAI_API_KEY")
        self.gemini_key = os.getenv("GEMINI_API_KEY")
        self.openai_model = os.getenv("OPENAI_SUMMARY_MODEL", "gpt-4o-mini")
        self.gemini_model = os.getenv("GEMINI_SUMMARY_MODEL", "gemini-1.5-flash")

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
            "You are a health information assistant. You do not diagnose, treat, or confirm disease. "
            "You only explain calculated risk indicators in simple language. Always recommend consulting "
            "a qualified healthcare professional for medical decisions. Do not use diagnostic claims, "
            "guaranteed predictions, cancer detected language, or emergency claims unless severe symptoms "
            "are explicitly provided."
        )

    def _user_payload(self, result: Dict[str, Any], payload: Dict[str, Any]) -> str:
        safe_input = {
            "calculated_result": {
                "index_name": result.get("index_name"),
                "organ": result.get("organ"),
                "score": result.get("score"),
                "risk_indicator": result.get("risk_level"),
                "values_used": result.get("values_used"),
            },
            "lifestyle_details": payload.get("general_health") or {},
            "profile": payload.get("profile") or {},
            "required_output": {
                "simple_summary": "short patient-friendly explanation",
                "possible_contributors": ["safe lifestyle, food, or environment contributors"],
                "lifestyle_suggestions": ["safe general lifestyle suggestions"],
                "food_habit_suggestions": ["safe food habit suggestions"],
                "environment_suggestions": ["safe environment suggestions"],
                "doctor_followup_suggestion": "when to consult a qualified healthcare professional",
            },
        }
        return json.dumps(safe_input)

    def _apply_ai_text(self, result: Dict[str, Any], text: str) -> Dict[str, Any]:
        if not text:
            return result
        updated = dict(result)
        updated["summary"] = text.strip()
        return updated

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
            return self._apply_ai_text(result, text)
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
                    "systemInstruction": {
                        "parts": [{"text": self._system_instruction()}],
                    },
                    "contents": [
                        {
                            "role": "user",
                            "parts": [{"text": self._user_payload(result, payload)}],
                        }
                    ],
                    "generationConfig": {"temperature": 0.2},
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
            return self._apply_ai_text(result, text)
        except Exception:
            return result
