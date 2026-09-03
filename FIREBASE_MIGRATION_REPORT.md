# Firebase migration report

## Existing architecture

VitalMap used a Flutter UI, a local deterministic analysis engine, an optional FastAPI analysis endpoint, a Flask JSON-file authentication server, and SharedPreferences for one global draft/result.

## Problems discovered

Authentication was not real authentication: a locally saved email could represent a session. Health data and the latest result were device-wide rather than user-scoped, so they did not synchronize across devices and could survive the wrong logout boundary.

## Files modified

- `frontend/pubspec.yaml`
- `frontend/lib/main.dart`
- `frontend/lib/services/auth_service.dart`
- `frontend/lib/services/firestore_service.dart`
- `frontend/lib/screens/login_screen.dart`
- `frontend/lib/screens/signup_screen.dart`
- `frontend/lib/screens/input_screen.dart`
- `frontend/firebase.json`

## Files created

- `frontend/firestore.rules`
- `FIREBASE_SETUP.md`
- `FIRESTORE_SCHEMA.md`
- `FIREBASE_MIGRATION_REPORT.md`

## Firebase services implemented

Firebase Core initialization, Firebase Authentication email/password login, registration, display name updates, password reset, sign-out, user profile creation, separate cloud persistence for basic profile/lifestyle/environment/report inputs, and immutable screening history persistence.

## Old systems removed

The Flutter client no longer calls `auth_server.py`, `users.json`, or accepts locally stored credentials. Those backend files are retained as legacy files for review/removal after deployment verification. SharedPreferences remains only as a non-authoritative offline cache.

## Firestore architecture

Data is scoped under `users/{uid}`. The current profile draft is stored at `health_profile/current`, while every completed analysis is appended under `screenings/{screeningId}` with server timestamps.

## Authentication flow

Splash completes, Firebase initializes, and `AuthGate` listens to `authStateChanges()`. Logged-out users see login/signup; authenticated users see the existing home shell.

## Notification flow

Not implemented yet. FCM and local scheduling still require product-specific reminder preferences and platform setup.

## Analysis flow

The existing backend deterministic calculator remains the preferred online path. The client sends the Firebase ID token to the analysis API, saves the complete input payload and returned result to Firestore, and uses the existing deterministic local engine only when the backend is unavailable. The latest Firestore screening is preferred on dashboard startup.

## Security implementation

`firestore.rules` requires a signed-in user whose UID exactly matches the path UID, including all subcollections. No Admin SDK credentials are in Flutter or the repository.

## Remaining manual Firebase Console steps

Enable Email/Password, create Firestore in production mode, deploy rules, configure authorized domains and Android/iOS app settings, and configure App Check/Cloud Messaging as described in `FIREBASE_SETUP.md`.

## Testing performed

Dependency resolution completed successfully. `flutter analyze` passed with no issues and `flutter test` passed all 8 tests. The Python risk suite was attempted but could not run because this Windows environment has no `python` executable available.

## Known limitations

The optional Python API is still present for analysis compatibility and is not Firebase-token protected. The Flutter deterministic engine remains the production fallback, but a deployed callable/Cloud Run endpoint should verify Firebase ID tokens before using server analysis. Symptom tracking, recommendation documents, meal plans, notifications, typed domain models, emulator tests, and history UI are still follow-up work.
