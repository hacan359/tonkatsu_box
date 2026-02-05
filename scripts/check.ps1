# Локальная проверка как в CI
# Запуск: .\scripts\check.ps1

Write-Host "=== Flutter Analyze ===" -ForegroundColor Cyan
flutter analyze --fatal-infos --fatal-warnings
if ($LASTEXITCODE -ne 0) {
    Write-Host "Analyze failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Flutter Test ===" -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== All checks passed! ===" -ForegroundColor Green
