# Push to GitHub using HTTPS
Set-Location "c:\Users\dkisa\Downloads\School\CPE185\Lab\FinalProject\LoveableRepo"

Write-Host "=== Changing Remote to HTTPS ===" -ForegroundColor Cyan
git remote set-url origin https://github.com/dkisantear/STM32NetworkRouter.git
git remote -v

Write-Host "`n=== Adding All Files ===" -ForegroundColor Cyan
git add .

Write-Host "`n=== Committing ===" -ForegroundColor Cyan
git commit -m "Organize repository structure - STM32NetworkRouter"

Write-Host "`n=== Pushing to GitHub ===" -ForegroundColor Cyan
Write-Host "You will be prompted for GitHub credentials:" -ForegroundColor Yellow
Write-Host "- Username: dkisantear" -ForegroundColor Yellow
Write-Host "- Password: Use a Personal Access Token (not your GitHub password)" -ForegroundColor Yellow
Write-Host "Get token from: https://github.com/settings/tokens" -ForegroundColor Yellow
Write-Host ""

git push -u origin main --force

Write-Host "`n=== Done! ===" -ForegroundColor Green
