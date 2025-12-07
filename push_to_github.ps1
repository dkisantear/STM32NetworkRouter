# PowerShell script to push to GitHub
Set-Location "c:\Users\dkisa\Downloads\School\CPE185\Lab\FinalProject\LoveableRepo"

Write-Host "=== Checking Git Status ===" -ForegroundColor Cyan
git status

Write-Host "`n=== Checking Remote ===" -ForegroundColor Cyan
git remote -v

Write-Host "`n=== Setting Remote URL ===" -ForegroundColor Cyan
git remote set-url origin https://github.com/dkisantear/STM32NetworkRouter.git
git remote -v

Write-Host "`n=== Adding All Files ===" -ForegroundColor Cyan
git add .

Write-Host "`n=== Committing ===" -ForegroundColor Cyan
git commit -m "Organize repository structure - STM32NetworkRouter"

Write-Host "`n=== Checking Current Branch ===" -ForegroundColor Cyan
git branch

Write-Host "`n=== Pushing to GitHub (Force) ===" -ForegroundColor Cyan
git push -u origin main --force

Write-Host "`n=== Done! ===" -ForegroundColor Green
Write-Host "Check your repository at: https://github.com/dkisantear/STM32NetworkRouter" -ForegroundColor Yellow

