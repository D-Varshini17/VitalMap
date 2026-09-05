# VitalMap frontend

The Flutter client for VitalMap, targeting Android and web.

## Run locally

From this directory:

```powershell
flutter pub get
flutter run -d chrome
```

The client calls `http://127.0.0.1:8000` by default. Android emulators use
`http://10.0.2.2:8000`. Override the backend with:

```powershell
flutter run -d chrome
```

If the backend is unavailable, the app falls back to its local analysis engine.

## Validate

```powershell
flutter analyze
flutter test
```

See the root [README](../README.md) for deployment and release instructions.
