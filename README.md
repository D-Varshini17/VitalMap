# VitalMap

VitalMap is a Flutter health-screening client with a FastAPI analysis service.
It calculates organ-health indicators from user-entered profile, vital, lab,
lifestyle, and environment data. It is an indicator and education tool, not a
diagnostic service or replacement for a clinician.

## Architecture

```text
Flutter Android/Web app
        |-- /analyze, /predict --> FastAPI analysis API
        |-- /login, /register --> Flask mock auth API
        |-- offline fallback --> Flutter local analysis engine
```

The analysis API runs on port `8000`. The Flutter app uses `VITALMAP_BACKEND_URL` to point at the FastAPI backend. Use `http://127.0.0.1:8000` for Flutter Web on the same laptop, and use the laptop LAN IP for a physical Android phone.

## Quick start on Windows

VitalMap is designed to run locally with the deterministic FormulaEngine first, then optional local Ollama recommendations. Ollama is never allowed to change medical scores, thresholds, risk categories, or warning flags.

### First-time setup

Double-click:

```powershell
setup_windows.bat
```

This checks Python 3.11+, creates `.venv` when needed, installs `backend\requirements.txt`, verifies FastAPI/Uvicorn, checks Ollama, and tells you to run `ollama pull qwen3:1.7b` if the model is missing.

### Start VitalMap backend + AI

Double-click:

```powershell
start_vitalmap.bat
```

The launcher checks Ollama, starts FastAPI in a separate terminal, waits for `/health`, and prints the backend URLs.

### Or start the backend manually

From the repository root:

```powershell
.\.venv\Scripts\Activate.ps1
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

For development reload mode:

```powershell
run_backend_dev.bat
```

### Browser checks

Open these after the backend starts:

```text
http://127.0.0.1:8000/
http://127.0.0.1:8000/docs
http://127.0.0.1:8000/health
http://127.0.0.1:8000/ai/status
```

### Flutter Web

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=VITALMAP_BACKEND_URL=http://127.0.0.1:8000
```

The Flutter client never uses `0.0.0.0` as a destination address. If the backend or Ollama is unavailable, the app falls back safely and deterministic calculations still work.

### Android physical phone

`127.0.0.1` on Android means the phone itself. For a phone on the same Wi-Fi network, find your laptop IPv4 address:

```powershell
ipconfig
```

Then launch Flutter with your laptop LAN address:

```powershell
cd frontend
flutter run --dart-define=VITALMAP_BACKEND_URL=http://YOUR_LAPTOP_IP:8000
```

Debug/profile Android builds allow local cleartext HTTP so the phone can reach your laptop during development. Release builds are not weakened for local HTTP.

### Diagnostics

Double-click:

```powershell
diagnose_vitalmap.bat
```

It checks Python, `.venv`, pip, FastAPI, Uvicorn, Ollama, `qwen3:1.7b`, Ollama API, backend health, Local AI status, and Flutter. Failed items print the corrective command.

### Deployed web behavior

Vercel cannot access Ollama running on your laptop at `127.0.0.1:11434`. Deployed builds treat Local AI as unavailable unless the browser can reach a backend you started locally. Deterministic calculations and fallback recommendations continue without a paid/cloud LLM.

## Project map

### Root files and folders

| Path | Purpose |
| --- | --- |
| `README.md` | This project overview, setup guide, architecture reference, and deployment guide. |
| `.dockerignore` | Keeps caches, local environments, build output, and unrelated files out of Docker build contexts. |
| `.gitignore` | Ignores Python, Flutter, Android, IDE, OS, and build artifacts. |
| `.gitattributes` | Marks generated web exports and release APKs as generated/binary repository artifacts. |
| `.github/workflows/` | GitHub Actions automation; see the CI section below. |
| `assets/` | Root-level image assets shared or retained outside Flutter's declared asset paths. |
| `backend/` | Python API, analysis engine, authentication server, and backend checks. |
| `frontend/` | Flutter Android and web application, platform projects, assets, and tests. |
| `releases/` | Distribution files and release notes. |
| `render.yaml` | Render infrastructure definition for the backend. |
| `vercel.json` | Root Vercel configuration for the checked-in Flutter web export. |

The `.git/` directory is Git's local repository metadata and is not application
source.

### CI workflows

| Path | Purpose |
| --- | --- |
| `.github/workflows/backend-ci.yml` | Sets up Python 3.11, installs backend dependencies, and runs `backend/test_unit.py`. |
| `.github/workflows/frontend-ci.yml` | Sets up Flutter, fetches packages, runs `flutter analyze`, and runs Flutter tests. |

### Backend

| Path | Purpose |
| --- | --- |
| `backend/__init__.py` | Marks `backend` as a Python package. |
| `backend/README.md` | Instructions for the optional analysis service. |
| `backend/Dockerfile` | Python 3.11 container image that installs requirements and starts Uvicorn using Render's `$PORT`. |
| `backend/requirements.txt` | Python dependencies for FastAPI, Uvicorn, and Pydantic. |
| `backend/post_test.py` | Manual HTTP smoke test that posts a representative request to `/analyze`. |
| `backend/test_analyze.py` | API-level tests for analysis, units, missing data, lifestyle context, and CBC inputs. |
| `backend/test_sample.py` | Direct sample runner for the formula engine; prints results and missing inputs. |
| `backend/test_unit.py` | Lightweight formula-engine smoke test for supported indicators and summaries. |
| `backend/app/__init__.py` | Marks `backend.app` as a Python package. |
| `backend/app/main.py` | FastAPI entrypoint; configures CORS and exposes `/health`, `/analyze`, and `/predict`. |
| `backend/app/schemas.py` | Pydantic request and response models for profiles, labs, vitals, results, and missing data. |
| `backend/app/formulas.py` | Normalizes inputs and calculates indicators such as AIP, TyG, APRI, FIB-4, FLI, NLR, eGFR, SpO2, and LAR. |
| `backend/app/unit_conversion.py` | Converts supported glucose, lipid, creatinine, blood-count, body-measurement, and other units. |
| `backend/app/risk_rules.py` | Thresholds, statuses, colors, and classifications for calculated indicators. |
| `backend/app/explanation_engine.py` | Produces overall risk wording, contributors, suggestions, follow-up guidance, and safety disclaimers. |
| `backend/app/ai_recommendation.py` | Optional local Ollama recommendation package with safe normalization, status checks, and deterministic fallback. |

### Flutter application source

| Path | Purpose |
| --- | --- |
| `frontend/pubspec.yaml` | Flutter package metadata, dependencies, assets, version, and launcher-icon configuration. |
| `frontend/analysis_options.yaml` | Dart analyzer and lint configuration. |
| `frontend/README.md` | Frontend-specific run and validation notes. |
| `frontend/lib/main.dart` | Starts the app, restores sessions, handles splash/auth gates, and builds the responsive navigation shell. |
| `frontend/lib/styles.dart` | Shared theme, colors, typography, status styles, and status normalization. |
| `frontend/lib/core/local_analysis_engine.dart` | Offline counterpart to the backend analysis flow. |
| `frontend/lib/core/risk_rules.dart` | Client-side thresholds, severity ranking, labels, and overall-risk calculation. |
| `frontend/lib/core/responsive.dart` | Breakpoints, widths, spacing, columns, and responsive page containers. |
| `frontend/lib/core/ui_result_adapter.dart` | Converts API/local responses into UI metrics, organ snapshots, counts, scores, and missing-data messages. |
| `frontend/lib/screens/input_screen.dart` | Collects profile, lifestyle, environment, vital, lab, unit, and report-section inputs. |
| `frontend/lib/screens/results_screen.dart` | Shows the overall result, statuses, organ cards, indicators, recommendations, missing data, and PDF actions. |
| `frontend/lib/screens/insight_screen.dart` | Displays the educational organ overview. |
| `frontend/lib/screens/organ_detail_screen.dart` | Shows one organ's status, indicators, insights, and tips. |
| `frontend/lib/screens/index_detail_screen.dart` | Shows one calculated indicator, its value, contributors, recommendations, and follow-up. |
| `frontend/lib/screens/add_missing_screen.dart` | Lists missing values that can unlock additional indicators. |
| `frontend/lib/screens/login_screen.dart` | Login form and navigation to account creation. |
| `frontend/lib/screens/signup_screen.dart` | Registration form with password confirmation. |
| `frontend/lib/screens/splash_screen.dart` | Animated branded startup screen. |
| `frontend/lib/screens/more_screen.dart` | Profile, exports, safety/privacy information, settings, support, and sign-out actions. |
| `frontend/lib/services/api_service.dart` | Sends analysis requests, selects local/emulator URLs, and invokes offline fallback. |
| `frontend/lib/services/auth_service.dart` | Calls the auth API and provides local fallback behavior for login and registration. |
| `frontend/lib/services/export_summary_service.dart` | Creates and shares a PDF summary of the screening result. |
| `frontend/lib/storage/local_storage.dart` | Persists the latest payload, response, timestamp, and email with `SharedPreferences`. |
| `frontend/lib/utils/unit_conversion.dart` | Dart unit conversions and CBC unit classification helpers. |
| `frontend/lib/widgets/brand_logo.dart` | Reusable logo and app-bar branding. |
| `frontend/lib/widgets/disclaimer.dart` | Reusable medical safety/disclaimer panel. |
| `frontend/lib/widgets/health_dashboard_widgets.dart` | Shared dashboard cards, rings, badges, progress chips, and action controls. |
| `frontend/lib/widgets/organ_visual.dart` | Maps organ names to image assets and fallback visuals. |
| `frontend/lib/widgets/status_card.dart` | Accessible reusable status card with semantic labels. |

### Flutter tests and sample payloads

| Path | Purpose |
| --- | --- |
| `frontend/test/local_analysis_engine_test.dart` | Tests offline formulas, risk rules, severity, and overall status. |
| `frontend/test/auth_service_test.dart` | Tests auth URL selection on Android emulator and other platforms. |
| `frontend/test/widget_test.dart` | Tests responsive breakpoints and splash-to-login rendering. |
| `frontend/payload.json` | Representative complete analysis payload. |
| `frontend/payload_sample.json` | Smaller profile/general-health payload for examples and manual testing. |

### Assets and web files

| Path | Purpose |
| --- | --- |
| `frontend/assets/logo_medid.jpeg` | Main in-app logo declared in `pubspec.yaml`. |
| `frontend/assets/images/logo/` | Source, padded, and foreground launcher artwork. |
| `frontend/assets/images/organs/` | PNG organ artwork declared as Flutter assets. |
| `frontend/assets/organs/images/` | Additional JPEG organ artwork declared as Flutter assets. |
| `assets/images/` | Root-level organ image collection separate from Flutter's declared asset folders. |
| `frontend/web/index.html` | Flutter web host HTML. |
| `frontend/web/manifest.json` | Web app metadata. |
| `frontend/web/icons/` | Web/PWA icons. |
| `frontend/tools/pad_icon.dart` | Creates padded and transparent foreground launcher images. |
| `frontend/generate_icons.sh` | Installs packages and runs launcher icon generation. |

### Android and iOS projects

The platform folders are Flutter's native host projects around the shared Dart
application.

| Path | Purpose |
| --- | --- |
| `frontend/android/settings.gradle.kts` | Loads Flutter, Android, and Kotlin Gradle plugins. |
| `frontend/android/build.gradle.kts` | Shared Android repositories and build-directory configuration. |
| `frontend/android/app/build.gradle.kts` | Android application ID, SDK/version settings, Java/Kotlin settings, signing, and Flutter integration. |
| `frontend/android/gradle.properties` | Gradle memory and AndroidX/Kotlin flags. |
| `frontend/android/gradlew` and `gradlew.bat` | Gradle wrapper launchers for Unix-like shells and Windows. |
| `frontend/android/key.properties.example` | Template for release keystore properties; keep real signing secrets private. |
| `frontend/android/local.properties` | Machine-local Android and Flutter SDK paths; do not copy between machines. |
| `frontend/android/app/src/main/` | Main Android manifest, Kotlin `MainActivity`, resources, themes, and launcher icons. |
| `frontend/android/app/src/debug/` and `profile/` | Debug/profile Android manifests and variant-specific resources. |
| `frontend/ios/Runner/` | iOS app delegate, scene delegate, plist metadata, storyboards, and asset catalogs. |
| `frontend/ios/RunnerTests/` | Native iOS test target. |
| `frontend/ios/Runner.xcodeproj/` and `Runner.xcworkspace/` | Xcode project and workspace metadata. |
| `frontend/ios/Flutter/` | Flutter-generated iOS build configuration and plugin registration support. |

### Release and generated output

| Path | Purpose |
| --- | --- |
| `frontend/export_vercel.ps1` | Builds Flutter web with the deployed API URL and refreshes `frontend/vercel-dist/`. |
| `frontend/build_android_release.ps1` | Cleans, fetches packages, generates icons, builds an ARM64 APK, and copies it to `releases/`. |
| `frontend/vercel-dist/` | Checked-in Flutter web release export published by the root Vercel configuration. |
| `frontend/build/` | Flutter, Android, web, plugin, test, and intermediate build output. |
| `releases/VitalMap-release-arm64.apk` | Generated installable ARM64 Android release. |
| `releases/README.md` | Notes about release artifacts. |
| `frontend/android/.gradle/`, Kotlin caches, and crash logs | Machine-local Android tooling output. |
| `__pycache__/` and `.pytest_cache/` | Python runtime and test caches. |

Generated output is listed by folder or artifact rather than file-by-file
because it is recreated by Flutter, Gradle, Xcode, or Python tooling.

## Deployment

### Render backend

`render.yaml` creates a free Render web service named `vitalmap-backend`, uses
`backend/Dockerfile`, and checks `/health`. The Docker context is the repository
root so the image can import the `backend` package.

1. Push the repository to GitHub.
2. Create a Render Web Service from the repository, or use the `render.yaml` blueprint.
3. Confirm the service responds with `{"status":"ok"}` at `/health`.
4. Set the frontend API URL to the deployed HTTPS service.

### Vercel web frontend

The root `vercel.json` publishes `frontend/vercel-dist/` and rewrites routes to
`index.html`. Leave Vercel's Root Directory empty when importing the repository.
The alternative `frontend/vercel.json` supports deployments where `frontend/`
is selected as the Root Directory.

Refresh the checked-in web export with:

```powershell
.\frontend\export_vercel.ps1
```

### Android release

Build the ARM64 release with:

```powershell
.\frontend\build_android_release.ps1
```

The resulting APK is copied to `releases/VitalMap-release-arm64.apk`.
