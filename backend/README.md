VitalMap analysis service

Run locally for frontend testing:

```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

This exposes the optional `/analyze` and `/predict` endpoints. Authentication and user data are handled by Firebase in the Flutter application.

Local AI recommendations with Ollama:

```bash
ollama pull qwen3:1.7b
ollama serve
```

Create `backend/.env` from `.env.example`, then run the backend with:

```bash
set ENABLE_AI_RECOMMENDATIONS=true
set AI_RECOMMENDATION_PROVIDER=ollama
set OLLAMA_MODEL=qwen3:1.7b
set OLLAMA_BASE_URL=http://127.0.0.1:11434
uvicorn app.main:app --reload --port 8000
```

Run Flutter against the local backend:

```bash
flutter run -d chrome --dart-define=VITALMAP_BACKEND_URL=http://127.0.0.1:8000
```

Check Local AI from the app at More -> Local AI -> Test Local AI, or call `GET /ai/status`. If Ollama is stopped or unavailable, VitalMap keeps deterministic formula results unchanged and returns safe fallback recommendation text.
