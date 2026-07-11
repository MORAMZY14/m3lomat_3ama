$ErrorActionPreference = "Stop"

Write-Host "Checking Flutter project..." -ForegroundColor Cyan
if (-not (Test-Path ".\pubspec.yaml")) {
  throw "Run this script from the folder that contains pubspec.yaml."
}

if (-not (Test-Path ".\lib\firebase_options.dart")) {
  Write-Warning "lib/firebase_options.dart is missing. The app will use demo data."
} elseif (-not (Select-String -Path ".\lib\firebase_options.dart" -Pattern "static const FirebaseOptions web" -Quiet)) {
  Write-Warning "Firebase Web is not configured. The app will start with demo data."
  Write-Host "Configure it later with:" -ForegroundColor Yellow
  Write-Host "flutterfire configure --yes --project=m3lomat-3ama --platforms=android,web --out=lib/firebase_options.dart"
}

Write-Host "Cleaning old web output..." -ForegroundColor Cyan
flutter clean
if (Test-Path ".\.dart_tool") { Remove-Item ".\.dart_tool" -Recurse -Force }
if (Test-Path ".\build") { Remove-Item ".\build" -Recurse -Force }

Write-Host "Downloading packages..." -ForegroundColor Cyan
flutter pub get

Write-Host "Starting Chrome with local Flutter web resources..." -ForegroundColor Green
flutter run -d chrome --no-web-resources-cdn
