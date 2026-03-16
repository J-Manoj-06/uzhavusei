# UzhavuSei

Production-oriented Flutter marketplace app for farm equipment rental.

## Prerequisites

- Flutter SDK (stable)
- Firebase project configured for Android package `com.uzhavusei`
- Cloudinary account with an **unsigned upload preset**
- Razorpay key ID (optional for payment flow)

## Environment Setup

Copy `.env.example` to `.env` and fill values:

```env
GEMINI_API_KEY=
RAZORPAY_KEY_ID=
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_UPLOAD_PRESET=
CLOUDINARY_API_SECRET=
```

Important:
- The Flutter app uses `CLOUDINARY_CLOUD_NAME` + `CLOUDINARY_UPLOAD_PRESET` for client uploads.
- `CLOUDINARY_API_SECRET` is backend-only and should never be used directly from Flutter API calls.

## Firebase Setup

1. Place Android config at `android/app/google-services.json`.
2. Ensure `android/app/build.gradle.kts` uses:
	- `applicationId = "com.uzhavusei"`
	- `namespace = "com.uzhavusei"`
3. Publish Firestore rules from `firestore.rules` in Firebase Console.

## Run

```bash
flutter clean
flutter pub get
flutter run
```

## Production Notes

- Keep `.env` private (already gitignored).
- Use Firebase Auth + Firestore rules before opening public access.
- For strict production security, move Cloudinary signed upload generation to backend.
