# VitalMap — Effective Redesign

## Product purpose
VitalMap turns reviewed health inputs and supported laboratory values into deterministic screening indicators, then organizes those results into an understandable health map, history, and optional local-AI wellness guidance.

## One job per screen
- **Home:** a concise answer to “what matters now?” — current score, top priority systems, data completeness, next action, and shortcuts.
- **Input:** the only health-data entry area. Users can type values manually or import a report. Imported values must be reviewed before they enter the same existing VitalMap fields.
- **Result:** the current deterministic screening snapshot. It contains organ cards, calculated indicators, and one central Data Needed section instead of repeating missing-data messages in multiple formats.
- **View Details:** the formula result remains first and final. Live local Ollama adds structured Food, Lifestyle, Activity, Risk factors to review, and What to monitor next guidance.
- **Health Map:** uses the supplied body image as a status/navigation layer. Hotspots show supported system status, related indicators, recent change when available, and data gaps; indicator details open the normal result-detail flow.
- **History:** timeline and Compare are one feature. Timeline shows saved screenings and optional Daily Check-ins; Compare lets the user choose two screenings and can ask local Ollama to explain already-computed changes without claiming causation.
- **Daily Check-in:** optional context between screenings. It tracks energy, sleep quality, selected symptoms and notes. It never changes formula scores. Recent check-ins can be included as context when local guidance is generated.
- **Insight:** educational content.
- **More:** settings and account utilities only. Light mode is the default; Dark mode is a direct toggle.

## Lab-report workflow
1. Choose PDF/image/text report.
2. Process locally through FastAPI and Ollama.
3. Show supported extracted values, printed units, printed reference ranges and extraction confidence.
4. High-confidence values are preselected; medium-confidence values require explicit selection.
5. User reviews/edits values and units.
6. Only selected, valid, mappable rows are merged into the existing Input draft.
7. VitalMap deterministic formulas run.
8. Local Ollama may generate a separate wellness explanation from the finalized analysis.

Normal text PDFs are read locally; scanned PDFs are rendered locally and sent to the local vision model. Report uploads are capped at 12 MB.

## Local AI architecture
- **qwen3:1.7b:** View Details guidance, report guidance, and History comparison explanations.
- **qwen2.5vl:3b:** image/scanned-report transcription.
- **No cloud AI API.** No OpenAI/Gemini/Claude/Groq endpoint or cloud OCR is used.

Deterministic analysis no longer waits for generative AI. The `/analyze` path completes the formula screening and stores only an on-demand-local-guidance marker. Generative calls happen only when the user requests a guidance feature.

## Appearance
New users start in **Light** mode. More → Settings contains a direct **Dark mode** switch. Dark mode uses charcoal/slate surfaces, subdued green accents, softer borders and status containers designed for contrast rather than simple color inversion.

## Validation notes
The package includes `CHECK_PROJECT.bat`, which runs backend compilation/tests and, when Flutter is installed, `flutter pub get`, `flutter analyze`, and `flutter test` on the target Windows machine.
