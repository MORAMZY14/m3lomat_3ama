# Chrome / Firebase startup fix

## What was wrong

1. The Flutter client still used the old HTTP API at `http://10.0.2.2:3000`.
2. `main.dart` did not initialize Firebase.
3. `firebase_options.dart` was generated only for Android and iOS. It throws
   `UnsupportedError` when used on Chrome.
4. A Firebase/Auth/Firestore request could leave the category screen waiting.

The patched project now:

- initializes Firebase safely;
- reads categories and questions from Cloud Firestore;
- signs players in anonymously;
- calls the `createChallenge` Cloud Function;
- applies request timeouts;
- opens with local demo data instead of showing a blank page when Firebase is
  unavailable or not configured for the selected platform.

## Required command for Chrome

Run from the folder that contains `pubspec.yaml`:

```powershell
flutterfire configure `
  --project=m3lomat-3ama `
  --platforms=android,web `
  --out=lib/firebase_options.dart
```

After the command, open `lib/firebase_options.dart` and confirm that it has:

```dart
if (kIsWeb) {
  return web;
}
```

and a declaration similar to:

```dart
static const FirebaseOptions web = FirebaseOptions(...);
```

Then run:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

## Firebase Console requirements

Enable **Authentication → Sign-in method → Anonymous**.

Create Firestore data by running the seed script or migration script before
expecting live categories. If Firestore is empty, the application uses local
demo categories.
