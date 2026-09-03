# Firebase setup

Project: `vitalmap-77d53`

## Firebase Console

1. Enable **Authentication > Sign-in method > Email/Password**.
2. Create a **Cloud Firestore** database in production mode and deploy `frontend/firestore.rules`.
3. Add a Firestore index for `users/{uid}/screenings` on `createdAt` descending if the console requests it.
4. Add the deployed Web app domain to Authentication authorized domains.
5. Configure Android SHA-1/SHA-256 fingerprints for the Android app and download updated `google-services.json` when Firebase requests it.
6. Add the iOS app and download `GoogleService-Info.plist` if iOS builds are required; the current generated options include the iOS app id but the plist is not present in this clone.
7. Enable Cloud Messaging only when push reminders are ready. Browser notifications require a VAPID key and permission; Android requires notification permission on recent versions.
8. Configure App Check reCAPTCHA Enterprise for Web and Play Integrity for Android after registering release fingerprints. Keep debug providers limited to local development.

## Deploy rules

From the Flutter project directory, after installing the Firebase CLI and selecting the project:

```powershell
cd frontend
firebase use vitalmap-77d53
firebase deploy --only firestore:rules
```

The current application uses Firebase Auth and Firestore directly. The existing Python analysis API remains optional while the deterministic Flutter analysis engine is available offline; it is not used for authentication.

Never add Firebase Admin service-account JSON, private keys, or `.env` files to the repository. Server-side credentials belong in Cloud Run/Functions secret configuration.
