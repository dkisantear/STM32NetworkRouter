# PowerShell script to automate Pi setup
# This will handle SSH connection and setup

$PiIP = "192.168.1.160"
$PiUser = "pi"
$PiPass = "raspberry"
$CurrentDir = Get-Location

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Automated Raspberry Pi Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pi: $PiUser@$PiIP" -ForegroundColor Yellow
Write-Host ""

# Test connection
Write-Host "Step 1: Testing connection..." -ForegroundColor Cyan
$ping = Test-Connection -ComputerName $PiIP -Count 1 -Quiet
if ($ping) {
    Write-Host "✅ Pi is reachable!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not ping, but continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Creating setup commands..." -ForegroundColor Cyan

# Create setup script content that will be executed on Pi
$setupCommands = @"
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip -qq
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet
chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py
python3 pi_heartbeat_test.py
"@

# Save setup commands to file
$setupFile = Join-Path $env:TEMP "pi_setup_cmds.sh"
$setupCommands | Out-File -FilePath $setupFile -Encoding ASCII

Write-Host "✅ Setup commands prepared" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Transferring files..." -ForegroundColor Cyan
Write-Host "⚠️  You will be prompted for password: $PiPass" -ForegroundColor Yellow
Write-Host ""

# Transfer files using SCP
Write-Host "Transferring pi_heartbeat_test.py..." -ForegroundColor Yellow
& scp "pi_heartbeat_test.py" "${PiUser}@${PiIP}:~/pi_heartbeat_test.py"

Write-Host "Transferring pi_heartbeat_continuous.py..." -ForegroundColor Yellow
& scp "pi_heartbeat_continuous.py" "${PiUser}@${PiIP}:~/pi_heartbeat_continuous.py"

Write-Host ""
Write-Host "Step 4: Running setup on Pi..." -ForegroundColor Cyan
Write-Host "⚠️  You will be prompted for password again: $PiPass" -ForegroundColor Yellow
Write-Host ""

# SSH and run setup
Write-Host "Connecting and running setup..." -ForegroundColor Yellow
$sshCommand = @"
sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip -qq && pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet && chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py && python3 pi_heartbeat_test.py
"@

# Use SSH to run commands
& ssh "${PiUser}@${PiIP}" $sshCommand

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check your dashboard - it should show 'Connected'!" -ForegroundColor Green
Write-Host ""

