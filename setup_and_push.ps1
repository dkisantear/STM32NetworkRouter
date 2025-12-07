# Complete setup and push script for STM32NetworkRouter
Set-Location "c:\Users\dkisa\Downloads\School\CPE185\Lab\FinalProject\LoveableRepo"

Write-Host "=== Initializing Git Repository ===" -ForegroundColor Cyan
if (Test-Path .git) {
    Write-Host "Repository already initialized" -ForegroundColor Yellow
} else {
    git init
    Write-Host "Repository initialized" -ForegroundColor Green
}

Write-Host "`n=== Setting Remote ===" -ForegroundColor Cyan
git remote remove origin 2>$null
git remote add origin https://github.com/dkisantear/STM32NetworkRouter.git
git remote -v

Write-Host "`n=== Adding All Files ===" -ForegroundColor Cyan
git add .

Write-Host "`n=== Committing ===" -ForegroundColor Cyan
git commit -m "Organize repository structure - STM32NetworkRouter" 2>&1 | ForEach-Object { Write-Host $_ }

Write-Host "`n=== Setting Branch to Main ===" -ForegroundColor Cyan
git branch -M main

Write-Host "`n=== Pushing to GitHub ===" -ForegroundColor Cyan
Write-Host "This may prompt for GitHub credentials..." -ForegroundColor Yellow
git push -u origin main --force 2>&1 | ForEach-Object { Write-Host $_ }

Write-Host "`n=== Verification ===" -ForegroundColor Cyan
git log --oneline -1
git remote -v

Write-Host "`n=== Done! ===" -ForegroundColor Green
Write-Host "Check your repository at: https://github.com/dkisantear/STM32NetworkRouter" -ForegroundColor Yellow
Write-Host "If you see authentication errors, you may need to:" -ForegroundColor Yellow
Write-Host "1. Use a Personal Access Token instead of password" -ForegroundColor Yellow
Write-Host "2. Or set up SSH keys" -ForegroundColor Yellow

