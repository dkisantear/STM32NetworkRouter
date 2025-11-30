# Automated Pi Setup Script
# This will transfer files and set everything up

$PiHost = "raspberrypi.local"
$PiIP = "192.168.1.160"
$PiUser = "pi"
$PiPass = "raspberry"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Automated Raspberry Pi Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pi Hostname: $PiHost" -ForegroundColor Yellow
Write-Host "Pi IP: $PiIP" -ForegroundColor Yellow
Write-Host "Username: $PiUser" -ForegroundColor Yellow
Write-Host ""

# Test connection
Write-Host "Step 1: Testing connection..." -ForegroundColor Cyan
$ping = Test-Connection -ComputerName $PiIP -Count 1 -Quiet
if ($ping) {
    Write-Host "✅ Pi is reachable!" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot reach Pi. Please check connection." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Preparing files..." -ForegroundColor Cyan

# Read the Python scripts
$testScript = Get-Content "pi_heartbeat_test.py" -Raw
$continuousScript = Get-Content "pi_heartbeat_continuous.py" -Raw

# Create a setup script that will be run on Pi
$setupScript = @"
#!/bin/bash
echo "=========================================="
echo "Raspberry Pi Gateway Setup"
echo "=========================================="
echo ""

# Install dependencies
echo "Installing Python dependencies..."
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip -qq
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet

echo "✅ Dependencies installed"
echo ""

# The Python scripts will be created by the transfer script
chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py 2>/dev/null || true

echo "✅ Setup complete!"
echo ""
"@

Write-Host "✅ Files prepared" -ForegroundColor Green
Write-Host ""

# Instructions for manual execution since SSH password auth is interactive
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Next Steps (Interactive)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Since SSH password authentication requires interaction," -ForegroundColor Yellow
Write-Host "please run these commands:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Transfer files using SCP:" -ForegroundColor Green
Write-Host "   scp pi_heartbeat_test.py pi@$PiHost:~/" -ForegroundColor White
Write-Host "   scp pi_heartbeat_continuous.py pi@$PiHost:~/" -ForegroundColor White
Write-Host "   (Password: raspberry)" -ForegroundColor Gray
Write-Host ""

Write-Host "2. SSH into Pi:" -ForegroundColor Green
Write-Host "   ssh pi@$PiHost" -ForegroundColor White
Write-Host "   (Password: raspberry)" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Run setup (copy and paste this ENTIRE block):" -ForegroundColor Green
Write-Host ""
Write-Host $setupScript -ForegroundColor Gray
Write-Host ""

Write-Host "4. Test connection:" -ForegroundColor Green
Write-Host "   python3 pi_heartbeat_test.py" -ForegroundColor White
Write-Host ""

Write-Host "5. Run continuously in background:" -ForegroundColor Green
Write-Host "   nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &" -ForegroundColor White
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Or, I can provide a single command to copy-paste!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

