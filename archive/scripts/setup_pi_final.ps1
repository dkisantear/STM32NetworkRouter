# Final Pi Setup Script - Using correct credentials
$PiIP = "192.168.1.160"
$PiUser = "pi5"
$PiPass = "pi5"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Automated Raspberry Pi Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Pi: $PiUser@$PiIP" -ForegroundColor Yellow
Write-Host ""

# Test connection
Write-Host "Testing connection..." -ForegroundColor Yellow
$ping = Test-Connection -ComputerName $PiIP -Count 1 -Quiet
if ($ping) {
    Write-Host "✅ Pi is reachable!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not ping, but continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Since SSH password authentication requires interaction," -ForegroundColor Yellow
Write-Host "here are the exact commands to run:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Transfer files (run these in PowerShell):" -ForegroundColor Cyan
Write-Host "  scp pi_heartbeat_test.py ${PiUser}@${PiIP}:~/" -ForegroundColor White
Write-Host "  scp pi_heartbeat_continuous.py ${PiUser}@${PiIP}:~/" -ForegroundColor White
Write-Host "  (Password: $PiPass)" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 2: SSH into Pi and run setup:" -ForegroundColor Cyan
Write-Host "  ssh ${PiUser}@${PiIP}" -ForegroundColor White
Write-Host "  (Password: $PiPass)" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 3: Once connected, paste this ENTIRE command:" -ForegroundColor Cyan
Write-Host ""

$setupCommand = @"
sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip -qq && pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet && chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py && python3 pi_heartbeat_test.py
"@

Write-Host $setupCommand -ForegroundColor White
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Or use the EXECUTE_THIS_ON_PI.sh file!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

