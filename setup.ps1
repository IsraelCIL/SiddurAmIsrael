# Smart Siddur — One-command setup
# Usage: .\setup.ps1
# Prerequisites: Flutter SDK must be installed and on PATH.
# Install Flutter: https://docs.flutter.dev/get-started/install/windows

param(
    [switch]$SkipCreate,   # pass -SkipCreate if flutter create was already run
    [switch]$SkipCodegen   # pass -SkipCodegen to skip build_runner step
)

$ErrorActionPreference = "Stop"

Write-Host "==> Checking Flutter installation..." -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter not found. Install it from https://docs.flutter.dev/get-started/install/windows and add it to PATH, then re-run this script."
    exit 1
}
flutter --version

# Step 1 — Initialize Flutter project files (platform folders, etc.)
if (-not $SkipCreate) {
    Write-Host "`n==> Initializing Flutter project..." -ForegroundColor Cyan
    flutter create . --org com.igintech --project-name smart_siddur --platforms ios,android
}

# Step 2 — Install all dependencies declared in pubspec.yaml
Write-Host "`n==> Installing dependencies (flutter pub get)..." -ForegroundColor Cyan
flutter pub get

# Step 3 — Run code generation (Freezed + Riverpod + JSON)
if (-not $SkipCodegen) {
    Write-Host "`n==> Running code generation (build_runner)..." -ForegroundColor Cyan
    dart run build_runner build --delete-conflicting-outputs
}

# Step 4 — Verify
Write-Host "`n==> Running flutter analyze..." -ForegroundColor Cyan
flutter analyze

Write-Host "`n[OK] Setup complete. Run 'flutter run' to start the app." -ForegroundColor Green
