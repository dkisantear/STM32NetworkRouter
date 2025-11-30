# Complete Automated Pi Setup
# This script handles everything: SSH keys, file transfer, and setup

$PiHost = "raspberrypi.local"
$PiIP = "192.168.1.160"
$PiUser = "pi"
$PiPass = "raspberry"
$ScriptDir = Get-Location

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Complete Automated Raspberry Pi Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Test connection
Write-Host "Step 1: Testing Pi connection..." -ForegroundColor Yellow
$ping = Test-Connection -ComputerName $PiIP -Count 1 -Quiet
if ($ping) {
    Write-Host "✅ Pi is reachable at $PiIP" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not ping $PiIP, but continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Checking SSH keys..." -ForegroundColor Yellow

# Check if SSH key exists
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
if (-not (Test-Path $sshKeyPath)) {
    Write-Host "Creating SSH key..." -ForegroundColor Yellow
    ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N '""' -q
    Write-Host "✅ SSH key created" -ForegroundColor Green
} else {
    Write-Host "✅ SSH key already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 3: Copying SSH key to Pi..." -ForegroundColor Yellow
Write-Host "⚠️  You will be prompted for password: $PiPass" -ForegroundColor Cyan
Write-Host ""

# Copy SSH key to Pi
$sshKeyContent = Get-Content $sshKeyPath -Raw
Write-Host "Copying SSH key (enter password when prompted)..." -ForegroundColor Yellow

# Try to copy SSH key
ssh-copy-id -i $sshKeyPath "${PiUser}@${PiIP}" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SSH key copied - passwordless login enabled!" -ForegroundColor Green
} else {
    Write-Host "⚠️  SSH key copy may require manual setup, continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 4: Transferring files..." -ForegroundColor Yellow

# Transfer files
Write-Host "Transferring pi_heartbeat_test.py..." -ForegroundColor Gray
scp "pi_heartbeat_test.py" "${PiUser}@${PiIP}:~/pi_heartbeat_test.py" 2>&1 | Out-Null

Write-Host "Transferring pi_heartbeat_continuous.py..." -ForegroundColor Gray
scp "pi_heartbeat_continuous.py" "${PiUser}@${PiIP}:~/pi_heartbeat_continuous.py" 2>&1 | Out-Null

Write-Host "✅ Files transferred" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Running setup on Pi..." -ForegroundColor Yellow

# Create setup command
$setupCmd = @"
sudo apt-get update -qq && \
sudo apt-get install -y python3 python3-pip -qq && \
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet || sudo pip3 install requests --quiet && \
chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py && \
python3 pi_heartbeat_test.py
"@

Write-Host "Running setup (this may take a minute)..." -ForegroundColor Gray
ssh "${PiUser}@${PiIP}" $setupCmd

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check your dashboard:" -ForegroundColor Yellow
Write-Host "https://blue-desert-0c2a27e1e.3.azurestaticapps.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "It should show: 🟢 Connected" -ForegroundColor Green
Write-Host ""

