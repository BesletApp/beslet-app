param([string]$Target = "apk")

$ErrorActionPreference = "Stop"

# Stop Gradle daemon + kill stale cmake to release file locks on build\jni
if (Test-Path "android\gradlew.bat") {
  & ".\android\gradlew.bat" --stop 2>$null
}
Get-Process -Name "cmake" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
if (Test-Path "build\jni") {
  Remove-Item -Recurse -Force "build\jni"
  Write-Host "Cleaned stale cmake build/jni" -ForegroundColor Green
}

# Run flutter build
Write-Host "Building release $Target for arm64..." -ForegroundColor Cyan
flutter build $Target --release --target-platform android-arm64 --split-debug-info=debug-info/ --obfuscate
if ($LASTEXITCODE -ne 0) { throw "Build failed" }

# Install if device connected
$device = flutter devices --machine 2>$null | ConvertFrom-Json | Where-Object { $_.platform -eq "android" -and $_.id -ne "windows" -and $_.id -ne "chrome" -and $_.id -ne "edge" }
if ($device) {
  Write-Host "Installing on $($device.name)..." -ForegroundColor Cyan
  flutter install
} else {
  Write-Host "No Android device found. Build ready at build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
}
