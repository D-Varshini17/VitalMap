# VitalMap (NCD_Guard)

This workspace contains a Flutter frontend and a FastAPI backend for a Play Store-friendly organ health risk indicator app (VitalMap).

Structure:
- frontend/: Flutter app (Android + Web)
- backend/: FastAPI backend

Quick start (backend):

1. Create a virtual environment and install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r backend/requirements.txt
```

2. Run the backend:

```powershell
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

Quick start (frontend):

1. Ensure Flutter SDK is installed.
2. From `frontend/` run:

```bash
flutter pub get
flutter run -d chrome   # for web
flutter run -d emulator-5554  # for android emulator (use 10.0.2.2 backend address)
```

Notes:
- The frontend posts to `http://127.0.0.1:8000/analyze` by default. For Android emulator use `10.0.2.2`.
- The backend implements formula engine, unit conversion, risk rules, and safe wording/disclaimer.
- This is a minimal, launch-ready scaffold. Extend UI/fields and tests as needed.

UI polish:
- The Flutter app uses a clean medical light theme with `teal` accents, rounded cards, and a `StatusCard` widget for consistent visuals and improved accessibility. Styles are in `frontend/lib/styles.dart`.

Set app logo:
- Place the supplied image file into `frontend/assets/logo.png` (create the `assets` folder if missing). The app will load this image into the AppBar on all screens. If you prefer another filename, update `assets:` in `frontend/pubspec.yaml` and the `Image.asset` paths in `lib/screens`.

Generate app launcher icons:
- After placing `frontend/assets/logo.png`, from the `frontend/` folder run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

I added a helper script `frontend/generate_icons.sh` to run these commands.

Notes:
- The `flutter_launcher_icons` package will generate Android and iOS launcher icons and adaptive icons using `assets/logo.png` as configured in `frontend/pubspec.yaml`.
- If you want me to add the actual `logo.png` into the repository, reply with "Embed logo" and I'll add it for you.

Deploying the backend to Render (quick guide)
-------------------------------------------

1. Ensure your repo is pushed to GitHub.
2. The repo includes `backend/Dockerfile` and `render.yaml` which Render can use to build and deploy the service.
3. Using the Render dashboard:
	- Create a new "Web Service" and connect your GitHub repo.
	- If using `render.yaml`, select the option to use the manifest or just allow Render to detect the service.
	- Render will build the Docker image using `backend/Dockerfile` and deploy to a public URL.

Alternatively, use the Render CLI to create the service from `render.yaml`:

```bash
# Install render CLI: https://render.com/docs/cli
render login
render services create --file render.yaml
```

Notes:
- The Dockerfile exposes port 8000 and runs `uvicorn backend.app.main:app` using the `$PORT` env var Render provides.
- After deployment, update the Flutter frontend API base URL to point to the Render service domain (HTTPS).



