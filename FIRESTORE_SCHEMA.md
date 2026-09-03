# Firestore schema

All application data is scoped below the authenticated Firebase user.

## `users/{uid}`

Stores account metadata only: `uid`, `fullName`, `email`, `createdAt`, `updatedAt`, `emailVerified`, `onboardingCompleted`, `notificationEnabled`, and `profileCompleted`.

## `users/{uid}/health_profile/current`

The latest saved basic profile. `inputData` contains the `profile` section and `fullPayload` contains the complete draft used to restore the form. `updatedAt` is a server timestamp.

## `users/{uid}/lifestyle/current`

The latest `general_health` lifestyle answers, including activity, sleep, diet, smoking, alcohol, and stress fields.

## `users/{uid}/environment/current`

The latest environmental answers extracted from `general_health`: air pollution, occupational exposure, passive smoking, cooking smoke, cooking fuel smoke, and location type.

## `users/{uid}/reports/current`

The selected report sections and their latest entered values, including vitals, lipid, diabetes, liver, CBC, kidney, pancreatic, and tumor-marker data.

## `users/{uid}/screenings/{screeningId}`

Every completed analysis is a new document. It contains the complete `inputData`, complete backend `resultData`/`response`, `calculatedValues`, `organScores`, `riskLevels`, `overallRisk`, `explanations`, `recommendationSummary`, `warningFlags`, `algorithmVersion`, and `createdAt`. The app never overwrites an earlier screening.

## Planned user subcollections

`recommendations`, `symptoms`, `meal_plans`, and `notifications` are reserved for the corresponding user-owned features. `settings/preferences` is reserved for notification preferences. Each must use the same `{uid}` security boundary.

The client never stores passwords or user credentials in Firestore.
