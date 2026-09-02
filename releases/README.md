# VitalMap Android Release

`VitalMap-release-arm64.apk` is the installable Android ARM64 release build.

The packaged app uses the deployed Render API and silently falls back to local
screening calculations if the API is unavailable.

Rebuild the APK from the repository root with:

```powershell
.\frontend\build_android_release.ps1
```
