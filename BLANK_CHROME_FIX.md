# Blank Chrome startup fix

The uploaded project had two separate problems:

1. `lib/firebase_options.dart` still had no Web configuration.
2. Chrome could remain empty before Dart `main()` was reached, especially when
   the CanvasKit files from the Flutter CDN were blocked by a certificate,
   proxy, antivirus, or network filter.

This patched copy starts the visible Flutter shell before Firebase, adds a
12-second Firebase timeout, and adds a browser startup screen that displays the
exact engine error instead of an empty gray page.

## First test (works with local demo data)

From the project root:

```powershell
.\run_chrome_local.ps1
```

The script uses local Flutter web engine resources:

```powershell
flutter run -d chrome --no-web-resources-cdn
```

## Configure Firebase Web

The uploaded `firebase_options.dart` contains only Android and iOS. Run:

```powershell
flutterfire configure `
  --yes `
  --project=m3lomat-3ama `
  --platforms=android,web `
  --out=lib/firebase_options.dart
```

Verify:

```powershell
Select-String -Path .\lib\firebase_options.dart -Pattern "static const FirebaseOptions web"
```

Then run the local-resources script again.

## If the browser shows a rendering/WebGL error

Open the same localhost URL and append:

```text
?cpu=1
```

Example:

```text
http://localhost:12345/?cpu=1
```

The custom Flutter bootstrap will force CanvasKit CPU rendering for that run.
