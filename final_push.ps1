# Final push script with detailed output
Set-Location "c:\Users\dkisa\Downloads\School\CPE185\Lab\FinalProject\LoveableRepo"

Write-Host "=== Current Git Status ===" -ForegroundColor Cyan
git status --short

Write-Host "`n=== Remote Configuration ===" -ForegroundColor Cyan
git remote -v

Write-Host "`n=== Adding All Changes ===" -ForegroundColor Cyan
git add .

Write-Host "`n=== Committing Changes ===" -ForegroundColor Cyan
$commitOutput = git commit -m "Update STM32 files and repository structure" 2>&1
Write-Host $commitOutput

Write-Host "`n=== Pushing to GitHub ===" -ForegroundColor Cyan
Write-Host "If prompted, use:" -ForegroundColor Yellow
Write-Host "  Username: dkisantear" -ForegroundColor Yellow
Write-Host "  Password: Your Personal Access Token (not your GitHub password)" -ForegroundColor Yellow
Write-Host "  Get token: https://github.com/settings/tokens" -ForegroundColor Yellow
Write-Host ""

$pushOutput = git push origin main 2>&1
Write-Host $pushOutput

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== SUCCESS! ===" -ForegroundColor Green
    Write-Host "Repository pushed to: https://github.com/dkisantear/STM32NetworkRouter" -ForegroundColor Green
} else {
    Write-Host "`n=== PUSH FAILED ===" -ForegroundColor Red
    Write-Host "Error code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "1. Authentication failed - Need Personal Access Token" -ForegroundColor Yellow
    Write-Host "2. Network issue - Check internet connection" -ForegroundColor Yellow
    Write-Host "3. Remote branch conflict - May need to pull first" -ForegroundColor Yellow
}
