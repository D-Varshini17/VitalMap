VitalMap analysis service

Run locally for frontend testing:

```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

This exposes the optional `/analyze` and `/predict` endpoints. Authentication and user data are handled by Firebase in the Flutter application.
