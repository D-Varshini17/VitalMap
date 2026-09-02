Mock auth server

Run locally for frontend testing:

```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
pip install -r requirements.txt
python auth_server.py
```

This exposes `/register` and `/login` endpoints on port 5000.
