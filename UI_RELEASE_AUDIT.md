# VitalMap UI and release audit

## Scope and implementation

Improved the existing Flutter application. Medical formulas, risk rules, recommendation engine, result adapter, unit conversion, authentication service, Firestore service and Firebase client configuration are unchanged. Existing user edits were preserved and completed.

Problems found: an invalid mobile-navigation field declaration; light surfaces and fixed dark text throughout shared wrappers and screens; fixed status palettes; unreadable score-ring foreground in dark mode; oversized desktop authentication forms; result header and card overflows on phones; icon-only desktop navigation; draft forms remounted when switching tabs; unguarded Firebase lookup while loading a local draft; missing PDF failure/loading feedback; placeholder support copy; Vercel serving old prebuilt artifacts without a build command.

Theme architecture: MaterialApp listens to AppThemeController. SharedPreferences stores `theme_mode` as system/light/dark. System Mode delegates to Flutter and follows device brightness changes. The controller guards delayed restoration against newer selections and disposal. ThemeData defines inputs, cursor, dialogs, sheets, menus, buttons, cards and typography. VitalMapColors provides paired semantic status colors. Widgets resolve colors through their BuildContext; custom painters receive colors and repaint on changes.

| Palette role | Light | Dark |
| --- | --- | --- |
| Page | #F4F7F6 | #0E1513 |
| Card | #FFFFFF | #151F1C |
| Secondary surface | #EEF5F2 | #1B2925 |
| Primary | #0F6E56 | #62C5A5 |
| Primary text | #15201D | #F2F7F5 |
| Supporting text | #52605C | #B5C5C0 |
| Card border | #D9E4DF | #30423C |
| Success container / text | #E4F1EC / #124D3E | #1B3A30 / #BDEAD9 |
| Monitor container / text | #FFF2CC / #5F4300 | #493817 / #FFE5A3 |
| Information container / text | #E8F0F5 / #243B4A | #20333D / #C5E4F2 |

Attention containers use #FFF1EF / #7A271A in Light and #442520 / #FFDAD6 in Dark, with matching error accents. Summary text uses the full contrasting foreground; card shadows are subtle black rather than opaque border-color glows. Automated tests check normal text, supporting text, buttons and status-container text at a minimum 4.5:1 contrast. Input outlines use the stronger supporting-text color. Decorative card borders remain subtle. The remaining white Flutter surfaces are intentional logo backplates; PDF white belongs to printed pages. Fixed colors in the decorative organ risk bar carry status meaning and have no overlaid text.

## Screen descriptions in both themes

| Screen | Light presentation | Dark presentation |
| --- | --- | --- |
| Splash | Soft green page, brand logo, green animation | Charcoal-green page, mint animation, retained logo artwork |
| Login / signup | Centered form up to 560 px, white card, tinted inputs | Dark card, green-charcoal inputs, light values and labels |
| Home / results | Green summary, distinct status badges, stacked phone cards, organized desktop dashboard | Mint summary with dark foreground, dark semantic containers, readable score ring |
| Input | Tinted section headers and fields, clear selected reports | Dark surfaces, bright labels, units, cursor and selections |
| Insights / education | Separated education cards and information blocks | Dark containers and readable secondary text |
| Index detail | Formula, values and recommendations in separated panels | Themed formula/value panels and semantic badges |
| Organ detail | Wrapping indicator values and badges; summary/indicator/insight/tip tabs | Dark panels and themed status treatments |
| Add Missing Data | Readable guidance and input cards | Themed guidance, fields and actions |
| More | Profile/settings groups, accurate appearance selection, readable sheets | Dark cards and sheets with matching selection state |
| Navigation | Phone bottom bar; desktop sidebar with visible labels | Dark navigation surfaces, mint selection, readable inactive labels |

Responsive architecture retains the project's shared 600 px and 1024 px breakpoints: mobile below 600, tablet 600–1023, desktop from 1024. Tablet content is constrained to 720 px; dashboard content to 1440 px; detail content to 980 px. Phone result and attention cards stack vertically. Tablet and desktop retain multi-column dashboards. IndexedStack preserves form state between navigation tabs. No platform-specific medical implementations were introduced.

## Verification and limits

- `flutter clean` and `flutter pub get`: passed in frontend.
- `dart format .`: completed.
- `flutter analyze`: no issues after UI integration.
- Final unit/widget suite: 48 tests passed, including live System Mode changes, all saved modes, controller disposal and clearing data from preserved shell pages.
- UI tests render the shell and ten major screens in both themes at 360x800, 390x844, 430x932, 768x1024, 1024x768, 1280x720, 1366x768, 1440x900 and 1920x1080. They check initial layout and scrolling for exceptions. They do not substitute for physical-device or authenticated end-to-end testing.
- Appearance test opens the real selection sheet, chooses Dark, observes the app rebuild and restores that choice using a new controller.
- `flutter build web --release`: passed with Flutter 3.47.2.
- `flutter build apk --release`: PASSED in GitHub CI; the APK is available from the workflow artifact and artifacts/android-release/app-release.apk. Local execution is blocked by a missing Android SDK. android/local.properties points at C:\Users\Varshini\AppData\Local\Android\sdk, which does not exist here. No device, emulator or Android Studio installation was detected.
- Live production Chrome verification used a temporary synthetic account: UI signup, Firebase login, Firestore profile read, UI Analyze, AIP score 0.477, recommendations, Firestore screening history, valid PDF download, Dark selection, browser restart/restoration and sign-out all passed. The synthetic saved draft supplied the questionnaire/report fixture; this does not claim every laboratory field was individually typed. Test account, profile and screening documents were deleted successfully. Physical-device share-sheet interactions remain untested.
- PDF export now reports failures instead of leaving More's progress state stuck; its existing printing adapter remains shared across platforms.
- Browser audit artifacts are generated by `node scripts/verify_web.cjs` into `artifacts/ui-audit/`. Consult browser-report.json and the PNG files for actual browser evidence.
- Both Vercel projects deployed successfully through GitHub. The public alias is https://vital-map-91lk.vercel.app. Live revision and final deployment status can be checked using /build-info.json and node scripts/check_release.cjs. The build now rejects unexpected application-source modifications; omitted legacy deployment files do not count as source changes.

| Feature | Evidence | Remaining scope |
| --- | --- | --- |
| Auth UI | Light/Dark screenshots at 390 and 1440 px | Physical device visual review |
| Input/results/details/education | Both themes across nine widget-test viewports | Comprehensive manual exploration of all optional fields |
| Formulas/units/risk/recommendations | Existing unit tests; live AIP 0.477 and recommendations | No medical rules changed |
| Light/Dark/System/persistence | Widget tests; real browser Dark restoration | Device-specific OS variation |
| Firebase signup/login/profile/history/logout | Live temporary-account flow passed | Android authenticated flow not repeated |
| PDF | Real browser file downloaded, %PDF- header confirmed | Native share chooser/save destination |
| Android release | CI build passed; APK retained | Local SDK unavailable |
| Android runtime | CI emulator smoke test configured and running | See final CI status for its outcome |
| Vercel/assets/refresh | Deployment succeeded; live browser checks passed | Final commit is verified after the last push |
## Deployment architecture

Vercel now builds current source with `bash scripts/build_web.sh` and serves only `frontend/build/web`. The script bootstraps Flutter 3.47.2 if Flutter is absent, restores the lockfile, builds release Web and writes build-info.json. The legacy frontend/vercel-dist directory is unused and excluded from uploads; no manual copying into it is required. No files were deleted.

The rewrite covers extensionless SPA paths while excluding assets, renderer resources, icons and filenames with extensions. Static missing assets remain 404s rather than receiving index.html. Responses revalidate to prevent unversioned Flutter JavaScript becoming stale. Configuration follows [Vercel's file-based build and output configuration](https://vercel.com/docs/project-configuration).

Use repository root as the Vercel project root, Other framework, and main as its production branch. Retain the existing GitHub integration. CI pins the same Flutter version and adds Web/APK release builds. A successful deployment must return the expected commit from `/build-info.json`; opening an older site is not evidence of deployment success.

## Exact local commands

Run from the repository root:

```powershell
cd frontend
flutter pub get
# USB phone: enable developer options and USB debugging, connect and authorize.
flutter devices
flutter run -d <android-device-id>
# Emulator: install/configure Android SDK and an AVD first.
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <emulator-device-id>
# Chrome development
flutter run -d chrome
# Release Web
flutter build web --release
# Release Android (requires SDK)
flutter build apk --release
```

To validate the Web output locally, from repository root:

```powershell
node scripts/write-build-info.cjs
node scripts/verify_web.cjs
```

The browser verifier uses installed Windows Chrome, localhost:8765 and debugging port 9437, closes its browser/server afterward, and writes screenshots plus a JSON report. APK output is frontend/build/app/outputs/flutter-apk/app-release.apk. Existing signing falls back to debug signing when release key.properties is absent; a distributable signed release requires the project's signing setup.

GitHub-to-Vercel process, after reviewing and staging the intended changes:

```powershell
git commit -m "Improve responsive themes and build web from source"
git push origin main
```

The existing Vercel GitHub integration then executes the repository build command. Check GitHub deployment status, the production URL, `/build-info.json`, refresh and static assets before declaring success.
## Files changed

- .github/workflows/frontend-ci.yml
- .gitignore
- frontend/lib/core/responsive.dart
- frontend/lib/main.dart
- frontend/lib/screens/add_missing_screen.dart
- frontend/lib/screens/index_detail_screen.dart
- frontend/lib/screens/input_screen.dart
- frontend/lib/screens/insight_screen.dart
- frontend/lib/screens/login_screen.dart
- frontend/lib/screens/more_screen.dart
- frontend/lib/screens/organ_detail_screen.dart
- frontend/lib/screens/results_screen.dart
- frontend/lib/screens/signup_screen.dart
- frontend/lib/screens/splash_screen.dart
- frontend/lib/services/export_summary_service.dart
- frontend/lib/styles.dart
- frontend/lib/theme/app_theme_controller.dart
- frontend/lib/widgets/brand_logo.dart
- frontend/lib/widgets/disclaimer.dart
- frontend/lib/widgets/health_dashboard_widgets.dart
- frontend/lib/widgets/organ_visual.dart
- frontend/lib/widgets/status_card.dart
- frontend/test/widget_test.dart
- frontend/web/index.html
- vercel.json

Added: .vercelignore, scripts/build_web.sh, scripts/write-build-info.cjs, scripts/verify_web.cjs, frontend/test/theme_ui_test.dart, frontend/test/theme_controller_test.dart, UI_RELEASE_AUDIT.md. Removed: none. Generated artifacts and logs are ignored.


Local Chrome verification of production output: login rendered in Light and Dark at 390 and 1440 px; screenshots reviewed; zero asset 404s, zero failed network requests and zero runtime exceptions. Signup navigation screenshots are included in the final browser run. Public production alias discovered: https://vital-map-91lk.vercel.app. This URL still needs verification after the new deployment; its current availability does not establish that it contains these changes.

Additional files: frontend/integration_test/mobile_smoke_test.dart, scripts/check_release.cjs; frontend/pubspec.yaml and pubspec.lock add only the Flutter SDK integration_test development dependency. The Android emulator workflow follows https://github.com/ReactiveCircus/android-emulator-runner and uses an API 35 Pixel 2 test device. The smoke test covers auth presentation/validation, shared local calculation, results, tab switching, retained form values, theme switching and actual device preference restoration. It runs on a dedicated synthetic-data device.
