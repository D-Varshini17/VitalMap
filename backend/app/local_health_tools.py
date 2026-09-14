"""Local-only health helper tools for VitalMap.

This module never calls a cloud AI provider. It talks only to an Ollama server
configured through OLLAMA_BASE_URL (default: http://127.0.0.1:11434).
Deterministic VitalMap calculations remain in FormulaEngine and are never
recalculated or overridden here.
"""

from __future__ import annotations

import base64
import io
import json
import math
import os
import re
import urllib.error
import urllib.request
from typing import Any, Dict, Iterable, List

from pypdf import PdfReader
from PIL import Image, ImageOps, UnidentifiedImageError
import pymupdf as fitz


class LocalHealthToolsError(RuntimeError):
    """User-safe error raised by local helper tools."""

    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.status_code = status_code


class LocalHealthToolsService:
    MAX_TEXT_CHARS = 32_000
    MAX_PDF_PAGES = 3

    # Only fields already understood by the existing VitalMap input model are
    # eligible for one-tap draft merge. The scanner may still display other
    # report values, but those are returned as unsupported extras.
    SUPPORTED_FIELDS: Dict[str, Dict[str, Any]] = {
        "triglycerides": {
            "label": "Triglycerides",
            "section": "lipid_profile",
            "canonical_unit": "mg/dL",
            "aliases": ["triglyceride", "tg"],
        },
        "hdl": {
            "label": "HDL cholesterol",
            "section": "lipid_profile",
            "canonical_unit": "mg/dL",
            "aliases": ["hdl-c", "hdl cholesterol"],
        },
        "fasting_glucose": {
            "label": "Fasting glucose",
            "section": "diabetes_profile",
            "canonical_unit": "mg/dL",
            "aliases": ["fasting blood glucose", "fbs", "fasting plasma glucose"],
        },
        "ast": {
            "label": "AST",
            "section": "liver_function",
            "canonical_unit": "U/L",
            "aliases": ["sgot", "aspartate aminotransferase"],
        },
        "alt": {
            "label": "ALT",
            "section": "liver_function",
            "canonical_unit": "U/L",
            "aliases": ["sgpt", "alanine aminotransferase"],
        },
        "ggt": {
            "label": "GGT",
            "section": "liver_function",
            "canonical_unit": "U/L",
            "aliases": ["gamma gt", "gamma-glutamyl transferase"],
        },
        "albumin": {
            "label": "Albumin",
            "section": "liver_function",
            "canonical_unit": "g/dL",
            "aliases": ["serum albumin"],
        },
        "platelets": {
            "label": "Platelets",
            "section": "cbc",
            "canonical_unit": "10^9/L",
            "aliases": ["platelet count", "plt"],
        },
        "neutrophils": {
            "label": "Neutrophils",
            "section": "cbc",
            "canonical_unit": "%",
            "aliases": ["neutrophil", "neut"],
        },
        "lymphocytes": {
            "label": "Lymphocytes",
            "section": "cbc",
            "canonical_unit": "%",
            "aliases": ["lymphocyte", "lymph"],
        },
        "creatinine": {
            "label": "Creatinine",
            "section": "kidney_function",
            "canonical_unit": "mg/dL",
            "aliases": ["serum creatinine"],
        },
        "spo2": {
            "label": "SpO2",
            "section": "vitals",
            "canonical_unit": "%",
            "aliases": ["oxygen saturation", "spo₂", "spo2"],
        },
        "lipase": {
            "label": "Lipase",
            "section": "pancreatic_enzymes",
            "canonical_unit": "U/L",
            "aliases": [],
        },
        "amylase": {
            "label": "Amylase",
            "section": "pancreatic_enzymes",
            "canonical_unit": "U/L",
            "aliases": [],
        },
        "afp": {
            "label": "AFP",
            "section": "tumor_markers",
            "canonical_unit": "ng/mL",
            "aliases": ["alpha fetoprotein", "alpha-fetoprotein"],
        },
        "ca15_3": {
            "label": "CA 15-3",
            "section": "tumor_markers",
            "canonical_unit": "U/mL",
            "aliases": ["ca15-3", "ca 15.3"],
        },
        "ca27_29": {
            "label": "CA 27.29",
            "section": "tumor_markers",
            "canonical_unit": "U/mL",
            "aliases": ["ca27.29", "ca 27-29"],
        },
    }

    def __init__(self) -> None:
        self.base_url = os.getenv(
            "OLLAMA_BASE_URL", "http://127.0.0.1:11434"
        ).rstrip("/")
        self.text_model = os.getenv("OLLAMA_MODEL", "qwen3:1.7b")
        self.vision_model = os.getenv("OLLAMA_VISION_MODEL", "qwen2.5vl:3b")
        self.timeout = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "150"))
        self.vision_timeout = float(os.getenv("OLLAMA_VISION_TIMEOUT_SECONDS", "180"))

    def status(self) -> Dict[str, Any]:
        models = self._installed_models()
        return {
            "provider": "ollama",
            "cloud_ai": "Disabled",
            "local_only": True,
            "base_url": self.base_url,
            "text_model": self.text_model,
            "vision_model": self.vision_model,
            "text_model_installed": self._has_model(models, self.text_model),
            "vision_model_installed": self._has_model(models, self.vision_model),
            "models": models,
            "available": self._has_model(models, self.text_model),
            "text_timeout_seconds": self.timeout,
            "vision_timeout_seconds": self.vision_timeout,
        }

    def scan_report(
        self,
        *,
        filename: str,
        content_type: str | None,
        data: bytes,
    ) -> Dict[str, Any]:
        if not data:
            raise LocalHealthToolsError("The selected report is empty.")

        safe_name = os.path.basename(filename or "report")
        extension = os.path.splitext(safe_name)[1].lower()
        content_type = (content_type or "").lower()

        if extension == ".pdf" or "pdf" in content_type:
            text = self._extract_pdf_text(data)
            if text.strip():
                payload = self._extract_from_text(text)
                mode = "pdf_text"
                preview = self._safe_preview(text)
            else:
                page_images = self._render_pdf_pages(data)
                payload = self._extract_from_images(page_images)
                mode = "pdf_vision"
                preview = (
                    f"{len(page_images)} scanned PDF page(s) processed locally with Ollama vision."
                )
        elif extension in {".txt", ".csv"} or content_type.startswith("text/"):
            text = data.decode("utf-8", errors="replace")
            payload = self._extract_from_text(text)
            mode = "text"
            preview = self._safe_preview(text)
        elif extension in {".png", ".jpg", ".jpeg", ".webp"} or content_type.startswith(
            "image/"
        ):
            payload = self._extract_from_image(data)
            mode = "vision"
            preview = "Image processed locally with Ollama vision."
        else:
            raise LocalHealthToolsError(
                "Unsupported file type. Use PDF, PNG, JPG, JPEG, WEBP, TXT, or CSV."
            )

        transcript = payload.pop('_transcribed_text', None)
        normalized = self._normalize_extraction(payload)
        if transcript:
            text = transcript
        if mode in {"pdf_text", "text"} or transcript:
            # Printed reference ranges must be present in the source, never inferred.
            source_text = re.sub(r"\s+", "", text).lower()
            for field in normalized["fields"] + normalized["extras"]:
                reference = field["reference_range"]
                if reference and re.sub(r"\s+", "", reference).lower() not in source_text:
                    field["reference_range"] = ""
                    field["confidence"] = "low"
                    normalized["warnings"].append("An unverified reference range was removed. Check the original report.")
        return {
            "source_file": safe_name,
            "mode": mode,
            "provider": "ollama",
            "local_only": True,
            "fields": normalized["fields"],
            "extras": normalized["extras"],
            "warnings": normalized["warnings"],
            "text_preview": preview,
            "review_required": True,
            "safety_note": (
                "Review every extracted value and unit against the original report before saving. "
                "VitalMap does not diagnose conditions from scanned reports."
            ),
        }

    def explain_changes(self, comparison: Dict[str, Any]) -> Dict[str, Any]:
        """Explain already-computed changes without recalc or causal claims."""
        prompt = {
            "task": "Explain the supplied VitalMap comparison in plain language.",
            "strict_rules": [
                "Do not calculate or modify any VitalMap score, value, risk label, or formula.",
                "Do not diagnose disease or claim that one change caused another.",
                "Refer to input differences as values that changed alongside the screening result, not proven causes.",
                "Do not prescribe medication or treatment.",
                "Return JSON only.",
            ],
            "required_json": {
                "summary": "string",
                "key_points": ["string"],
                "possible_context": ["string"],
            },
            "comparison": comparison,
        }
        raw = self._chat_json(
            model=self.text_model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are VitalMap Local AI. You only explain deterministic screening comparisons already supplied by VitalMap. "
                        "Never diagnose, prescribe, recalculate, alter labels, or claim medical causation. Return valid JSON only."
                    ),
                },
                {"role": "user", "content": json.dumps(prompt, ensure_ascii=False)},
            ],
            num_predict=550,
        )
        return self._normalize_change_explanation(raw)

    def metric_guidance(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Generate general local-AI wellness suggestions for one existing metric.

        The supplied VitalMap score/status is treated as final. This helper may
        explain and organize suggestions, but it may not diagnose, recalculate,
        or change deterministic risk labels.
        """
        metric = payload.get("metric") if isinstance(payload, dict) else None
        if not isinstance(metric, dict) or not metric:
            raise LocalHealthToolsError("Metric context is required.")
        context = {
            "metric": metric,
            "general_health": payload.get("general_health", {}),
            "profile": payload.get("profile", {}),
            "recent_check_ins": payload.get("recent_check_ins", []),
            "recent_trend": payload.get("recent_trend", []),
        }
        prompt = {
            "task": "Generate detailed but practical wellness guidance for the supplied deterministic VitalMap screening indicator. Tailor each section to the supplied values, contributors, lifestyle context, recent trend and optional Daily Check-ins. Each bullet should be specific and briefly explain why it is relevant, without making causal or diagnostic claims.",
            "strict_rules": [
                "The supplied score, status, formula output, and warning flags are final. Never recalculate or alter them.",
                "Do not diagnose a disease or say the user has a condition.",
                "Do not classify individual biomarker values as normal, high, low, or elevated. Only refer to the supplied finalized indicator status and explanation.",
                "Never infer overall health, normal health, or absence of health risks from a single screening indicator.",
                "Do not prescribe medicines, supplements, or treatment.",
                "Do not recommend calorie restriction, fasting, weight-loss targets, body-shape goals, or extreme exercise.",
                "Food guidance must be ordinary balanced-food ideas, not a restrictive medical diet.",
                "Exercise guidance must be moderate, general, and include a note to follow clinician guidance when symptoms or medical restrictions apply.",
                "Risk factors must only restate contributors or context explicitly supplied by VitalMap; do not invent new causes.",
                "Recent Daily Check-ins and recent trend are context only. Never claim they caused the indicator result.",
                "The monitor_next list should name sensible values or habits to observe next, based only on supplied context.",
                "Return JSON only.",
            ],
            "required_json": {
                "summary": "string",
                "food": ["string"],
                "lifestyle": ["string"],
                "exercise": ["string"],
                "risk_factors": ["string"],
                "monitor_next": ["string"],
            },
            "context": context,
        }
        raw = self._chat_json(
            model=self.text_model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are VitalMap Local AI. Give conservative, non-diagnostic wellness guidance only from supplied deterministic results. "
                        "Never change scores or risk labels, prescribe treatment, encourage restrictive eating, or recommend extreme exercise. Return valid JSON only."
                    ),
                },
                {"role": "user", "content": json.dumps(prompt, ensure_ascii=False)},
            ],
            num_predict=700,
        )
        return self._normalize_guidance(raw)

    def report_guidance(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Explain an already-computed report analysis and organize safe guidance."""
        if not isinstance(payload, dict) or not payload:
            raise LocalHealthToolsError("Report analysis context is required.")
        analysis = payload.get("analysis")
        if not isinstance(analysis, dict) or not analysis:
            raise LocalHealthToolsError("Deterministic VitalMap analysis is required first.")
        context = {
            "overall_risk": analysis.get("overall_risk"),
            "calculated_results": analysis.get("calculated_results"),
            "general_health_pattern": analysis.get("general_health_pattern"),
            "general_health": payload.get("general_health", {}),
        }
        prompt = {
            "task": "Summarize the supplied deterministic VitalMap screening analysis from a reviewed lab report and generate practical wellness guidance that is clearly tied to the supplied screening context. Each bullet should be specific and briefly explain why it is relevant.",
            "strict_rules": [
                "Do not diagnose disease or claim the lab report proves a condition.",
                "Do not calculate, modify, upgrade, or downgrade any supplied VitalMap score, status, risk category, or warning flag.",
                "Risk factors must only restate supplied contributors, entered lifestyle context, or supplied indicator statuses; never invent causes.",
                "Do not prescribe medicines, supplements, or treatment.",
                "Do not recommend calorie restriction, fasting, weight-loss targets, body-shape goals, or extreme exercise.",
                "Food advice must be balanced everyday food suggestions rather than a restrictive medical diet.",
                "Exercise suggestions must be moderate/general and defer to a clinician when symptoms or restrictions are present.",
                "Return JSON only.",
            ],
            "required_json": {
                "summary": "string",
                "food": ["string"],
                "exercise": ["string"],
                "lifestyle": ["string"],
                "risk_factors": ["string"],
                "monitor_next": ["string"],
            },
            "context": context,
        }
        raw = self._chat_json(
            model=self.text_model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are VitalMap Local AI. Explain only the deterministic screening results supplied by VitalMap and provide conservative general wellness suggestions. "
                        "Never diagnose, prescribe, change formulas or labels, encourage restrictive eating, or recommend extreme exercise. Return valid JSON only."
                    ),
                },
                {"role": "user", "content": json.dumps(prompt, ensure_ascii=False)},
            ],
            num_predict=850,
        )
        return self._normalize_guidance(raw)

    @staticmethod
    def _normalize_guidance(raw: Dict[str, Any]) -> Dict[str, Any]:
        def clean(value: Any, limit: int = 5) -> List[str]:
            if not isinstance(value, list):
                return []
            out: List[str] = []
            for item in value:
                text = re.sub(r"\s+", " ", str(item)).strip()
                if text and text not in out:
                    out.append(text[:280])
                if len(out) >= limit:
                    break
            return out

        summary = re.sub(r"\s+", " ", str(raw.get("summary", ""))).strip()[:700]
        if re.search(r"no (?:immediate |significant )?health risks|generally healthy|healthy profile|within normal|normal ranges|general health is within|you (?:have|suffer from) (?:diabetes|cancer|kidney disease)|stop (?:taking|your) medication", json.dumps(raw), re.IGNORECASE):
            raise LocalHealthToolsError("Local AI guidance made an unsupported medical claim. Your screening is unchanged; retry guidance.", 502)
        if not summary or any(not isinstance(raw.get(key), list) for key in ('food', 'exercise', 'lifestyle', 'risk_factors', 'monitor_next')):
            raise LocalHealthToolsError("Ollama returned incomplete guidance. Retry to generate all sections.", 502)
        return {
            "provider": "ollama",
            "local_only": True,
            "cloud_ai": "Disabled",
            "summary": summary,
            "food": clean(raw.get("food")),
            "exercise": clean(raw.get("exercise")),
            "lifestyle": clean(raw.get("lifestyle")),
            "risk_factors": clean(raw.get("risk_factors")),
            "monitor_next": clean(raw.get("monitor_next")),
            "safety_note": (
                "General wellness guidance only. VitalMap does not diagnose conditions or replace a qualified healthcare professional."
            ),
        }

    def _extract_from_text(self, text: str) -> Dict[str, Any]:
        clipped = text[: self.MAX_TEXT_CHARS]
        prompt = self._extraction_prompt()
        return self._chat_json(
            model=self.text_model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a local lab-report transcription helper. Extract only values explicitly present in the supplied report text. "
                        "Do not infer, diagnose, interpret, calculate, or invent values. Return JSON only."
                    ),
                },
                {
                    "role": "user",
                    "content": f"{prompt}\n\nREPORT TEXT:\n{clipped}",
                },
            ],
            num_predict=900,
        )

    def _extract_from_image(self, data: bytes) -> Dict[str, Any]:
        return self._extract_from_images([data])

    def _extract_from_images(self, images: List[bytes]) -> Dict[str, Any]:
        models = self._installed_models()
        if not self._has_model(models, self.vision_model):
            raise LocalHealthToolsError(
                f"Local Ollama vision model '{self.vision_model}' is not installed. Install/configure that local model, then retry the image scan."
            )
        if not images:
            raise LocalHealthToolsError("No readable report pages were found.")
        encoded = [base64.b64encode(self._optimize_image(item)).decode("ascii") for item in images[:3]]
        transcription = self._chat_json(
            model=self.vision_model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a local lab-report transcription helper. Read only visible report text and values. "
                        "Never diagnose, interpret, calculate, or invent missing information. Return JSON only."
                    ),
                },
                {
                    "role": "user",
                    "content": 'Transcribe all visible text in this report image exactly, including test names, numbers and units. Do not interpret it. Return a JSON object with one key, "text", whose value is the exact transcribed text. Do not invent text that is not visible.',
                    "images": encoded,
                },
            ],
            num_predict=1200,
            timeout=self.vision_timeout,
        )
        text = transcription.get('text')
        if not isinstance(text, str) or not text.strip():
            raise LocalHealthToolsError('The vision model could not read report text. Try a clearer, closely cropped image.', 502)
        extracted = self._extract_from_text(text)
        extracted['_transcribed_text'] = text
        return extracted

    @staticmethod
    def _optimize_image(data: bytes) -> bytes:
        try:
            with Image.open(io.BytesIO(data)) as source:
                if source.width * source.height > 40_000_000:
                    raise LocalHealthToolsError("Report image exceeds 40 megapixels. Export a smaller image.")
                image = ImageOps.exif_transpose(source).convert("RGB")
                image.thumbnail((2000, 2000))
                output = io.BytesIO()
                image.save(output, format="JPEG", quality=88, optimize=True)
                return output.getvalue()
        except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
            raise LocalHealthToolsError("The report image is invalid or cannot be decoded.") from exc

    def _extraction_prompt(self) -> str:
        catalogue = [
            {
                "key": key,
                "label": meta["label"],
                "aliases": meta["aliases"],
                "section": meta["section"],
            }
            for key, meta in self.SUPPORTED_FIELDS.items()
        ]
        return (
            "Extract only lab/vital values explicitly shown in the report. Preserve the printed numeric value and printed unit. "
            "For any uncertain value, omit it rather than guessing. Do not calculate derived indicators. "
            "You may also return clearly labelled extra laboratory values not in the supported catalogue.\n"
            "Return exactly this JSON shape:\n"
            '{"fields":[{"key":"supported_key","label":"printed label","value":0.0,"unit":"printed unit","reference_range":"printed reference range or empty","confidence":"high|medium"}],'
            '"extras":[{"label":"printed label","value":0.0,"unit":"printed unit","reference_range":"printed reference range or empty","confidence":"high|medium"}],'
            '"warnings":["string"]}\n'
            "Use an empty reference_range unless it is explicitly printed. Never supply a normal range from memory.\n"
            f"SUPPORTED CATALOGUE: {json.dumps(catalogue, ensure_ascii=False)}"
        )

    def _normalize_extraction(self, raw: Dict[str, Any]) -> Dict[str, Any]:
        if not isinstance(raw.get("fields"), list) or not isinstance(raw.get("extras", []), list) or not isinstance(raw.get("warnings", []), list):
            raise LocalHealthToolsError("Ollama returned an invalid report schema. Retry extraction.", 502)
        fields: List[Dict[str, Any]] = []
        seen: set[str] = set()
        for item in self._iter_dicts(raw.get("fields")):
            key = self._normalize_key(str(item.get("key", "")))
            if key not in self.SUPPORTED_FIELDS or key in seen:
                continue
            value = self._as_number(item.get("value"))
            unit = self._clean_text(item.get("unit"), 24)
            if value is None or not unit:
                continue
            meta = self.SUPPORTED_FIELDS[key]
            fields.append(
                {
                    "key": key,
                    "label": self._clean_text(item.get("label"), 80) or meta["label"],
                    "value": value,
                    "unit": unit,
                    "reference_range": self._clean_text(item.get("reference_range"), 60),
                    "confidence": self._confidence(item.get("confidence")),
                    "section": meta["section"],
                    "canonical_unit": meta["canonical_unit"],
                    "supported": True,
                }
            )
            seen.add(key)

        extras: List[Dict[str, Any]] = []
        for item in self._iter_dicts(raw.get("extras")):
            label = self._clean_text(item.get("label"), 80)
            value = self._as_number(item.get("value"))
            unit = self._clean_text(item.get("unit"), 24)
            if not label or value is None or not unit:
                continue
            extras.append(
                {
                    "label": label,
                    "value": value,
                    "unit": unit,
                    "reference_range": self._clean_text(item.get("reference_range"), 60),
                    "confidence": self._confidence(item.get("confidence")),
                    "supported": False,
                }
            )

        warnings = [
            self._clean_text(value, 180)
            for value in raw.get("warnings", [])
            if self._clean_text(value, 180)
        ][:8]
        if not fields:
            warnings.insert(
                0,
                "No supported VitalMap input values were confidently extracted. Check the report quality and labels.",
            )
        return {"fields": fields, "extras": extras[:20], "warnings": warnings}

    def _normalize_change_explanation(self, raw: Dict[str, Any]) -> Dict[str, Any]:
        def text_list(key: str) -> List[str]:
            value = raw.get(key, [])
            if isinstance(value, str):
                value = [value]
            if not isinstance(value, list):
                return []
            return [self._clean_text(item, 240) for item in value if self._clean_text(item, 240)][:6]

        summary = self._clean_text(raw.get("summary"), 500)
        if not summary:
            summary = "The latest screening can be compared with the previous saved screening using the deterministic changes shown above."
        return {
            "summary": summary,
            "key_points": text_list("key_points"),
            "possible_context": text_list("possible_context"),
            "provider": "ollama",
            "local_only": True,
            "cloud_ai": "Disabled",
        }

    def _chat_json(
        self,
        *,
        model: str,
        messages: List[Dict[str, Any]],
        num_predict: int,
        timeout: float | None = None,
        _retry: bool = True,
    ) -> Dict[str, Any]:
        models = self._installed_models()
        if not self._has_model(models, model):
            raise LocalHealthToolsError(
                f"Local Ollama model '{model}' is not installed or not visible to Ollama.", 503
            )
        body = json.dumps(
            {
                "model": model,
                "messages": messages,
                "stream": False,
                "format": "json",
                "think": False,
                "options": {"temperature": 0.1, "num_predict": num_predict, "num_ctx": 4096},
                "keep_alive": 0,
            }
        ).encode("utf-8")
        request = urllib.request.Request(
            f"{self.base_url}/api/chat",
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout or self.timeout) as response:
                data = json.loads(response.read().decode("utf-8"))
        except TimeoutError as exc:
            raise LocalHealthToolsError(
                f"Local Ollama timed out after {int(timeout or self.timeout)} seconds while processing this request. The model may still be loading; retry once and keep Ollama running.", 504
            ) from exc
        except urllib.error.HTTPError as exc:
            raise LocalHealthToolsError(f"Local Ollama rejected the model request (HTTP {exc.code}). Check the model and retry.", 502) from exc
        except (urllib.error.URLError, OSError) as exc:
            raise LocalHealthToolsError(
                "Local AI is unavailable on this deployment. For local mode, start Ollama on the backend computer.", 503
            ) from exc
        except json.JSONDecodeError as exc:
            raise LocalHealthToolsError("Ollama returned an unreadable response.") from exc

        content = (data.get("message") or {}).get("content", "")
        parsed = self._parse_json_text(str(content))
        if not parsed:
            if _retry:
                return self._chat_json(model=model, messages=messages, num_predict=num_predict, timeout=timeout, _retry=False)
            raise LocalHealthToolsError("Ollama returned invalid or empty JSON after one retry.", 502)
        return parsed

    def _installed_models(self) -> List[str]:
        request = urllib.request.Request(f"{self.base_url}/api/tags", method="GET")
        try:
            with urllib.request.urlopen(request, timeout=4) as response:
                data = json.loads(response.read().decode("utf-8"))
        except Exception as exc:  # noqa: BLE001 - converted to a user-safe local error
            raise LocalHealthToolsError(
                "Local AI is unavailable on this deployment. For local mode, start Ollama on the backend computer.", 503
            ) from exc
        return [
            str(item.get("name", "")).strip()
            for item in data.get("models", [])
            if str(item.get("name", "")).strip()
        ]

    @staticmethod
    def _has_model(models: Iterable[str], requested: str) -> bool:
        requested = requested.strip()
        if not requested:
            return False
        requested_base = requested.split(":", 1)[0]
        for model in models:
            if model == requested:
                return True
            if ":" not in requested and model.split(":", 1)[0] == requested_base:
                return True
        return False

    @staticmethod
    def _extract_pdf_text(data: bytes) -> str:
        try:
            reader = PdfReader(io.BytesIO(data))
            parts: List[str] = []
            if len(reader.pages) > LocalHealthToolsService.MAX_PDF_PAGES:
                raise LocalHealthToolsError("Reports are limited to 3 pages. Choose the relevant lab pages and retry.")
            for page in reader.pages:
                text = page.extract_text() or ""
                if not text.strip():
                    return ""  # Mixed text/image PDFs require vision for all pages.
                if text.strip():
                    parts.append(text)
            return "\n\n".join(parts)
        except LocalHealthToolsError:
            raise
        except Exception as exc:  # noqa: BLE001
            raise LocalHealthToolsError(
                "The PDF could not be read. Try exporting it again or scan a PNG/JPG page."
            ) from exc

    @staticmethod
    def _render_pdf_pages(data: bytes) -> List[bytes]:
        try:
            document = fitz.open(stream=data, filetype="pdf")
            if len(document) > LocalHealthToolsService.MAX_PDF_PAGES:
                document.close()
                raise LocalHealthToolsError("Reports are limited to 3 pages. Choose the relevant lab pages and retry.")
            images: List[bytes] = []
            for page_index in range(min(len(document), 3)):
                page = document.load_page(page_index)
                scale = min(1.6, 2000 / max(page.rect.width, page.rect.height))
                pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
                images.append(pix.tobytes("png"))
            document.close()
            if not images:
                raise LocalHealthToolsError("The PDF did not contain a readable page.")
            return images
        except LocalHealthToolsError:
            raise
        except Exception as exc:  # noqa: BLE001
            raise LocalHealthToolsError(
                "The scanned PDF could not be rendered locally. Try the original PDF or a PNG/JPG image."
            ) from exc

    @staticmethod
    def _parse_json_text(text: str) -> Dict[str, Any]:
        cleaned = text.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)
        try:
            value = json.loads(cleaned)
            return value if isinstance(value, dict) else {}
        except json.JSONDecodeError:
            start = cleaned.find("{")
            end = cleaned.rfind("}")
            if start >= 0 and end > start:
                try:
                    value = json.loads(cleaned[start : end + 1])
                    return value if isinstance(value, dict) else {}
                except json.JSONDecodeError:
                    return {}
        return {}

    def _normalize_key(self, raw: str) -> str:
        key = raw.strip().lower().replace("-", "_").replace(" ", "_")
        key = re.sub(r"[^a-z0-9_]+", "", key)
        if key in self.SUPPORTED_FIELDS:
            return key
        compact = raw.strip().lower()
        for supported, meta in self.SUPPORTED_FIELDS.items():
            candidates = [meta["label"], *meta["aliases"]]
            if any(compact == str(candidate).lower() for candidate in candidates):
                return supported
        return key

    @staticmethod
    def _iter_dicts(value: Any) -> Iterable[Dict[str, Any]]:
        if not isinstance(value, list):
            return []
        return [item for item in value if isinstance(item, dict)]

    @staticmethod
    def _as_number(value: Any) -> float | None:
        if isinstance(value, bool):
            return None
        if isinstance(value, (int, float)):
            return float(value) if math.isfinite(value) else None
        if value is None:
            return None
        match = re.fullmatch(r"[-+]?\d+(?:\.\d+)?", str(value).replace(",", "").strip())
        return float(match.group(0)) if match else None

    @staticmethod
    def _clean_text(value: Any, max_length: int) -> str:
        if value is None:
            return ""
        text = re.sub(r"\s+", " ", str(value)).strip()
        return text[:max_length]

    @staticmethod
    def _confidence(value: Any) -> str:
        text = str(value or "").strip().lower()
        return text if text in {"high", "medium", "low"} else "low"

    @staticmethod
    def _safe_preview(text: str) -> str:
        preview = re.sub(r"\s+", " ", text).strip()
        return preview[:500]
