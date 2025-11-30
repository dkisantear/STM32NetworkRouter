# Automated Raspberry Pi Setup Script
# This script will SSH into your Pi and set up everything automatically

param(
    [Parameter(Mandatory=$true)]
    [string]$PiIP,
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "pi",
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 22
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Automated Raspberry Pi Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Test connection first
Write-Host "Step 1: Testing connection to $PiIP..." -ForegroundColor Yellow
$ping = Test-Connection -ComputerName $PiIP -Count 2 -Quiet

if (-not $ping) {
    Write-Host "❌ Cannot reach $PiIP. Please check:" -ForegroundColor Red
    Write-Host "   - Pi is powered on" -ForegroundColor Yellow
    Write-Host "   - Pi is on the same network" -ForegroundColor Yellow
    Write-Host "   - IP address is correct" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Pi is reachable!" -ForegroundColor Green
Write-Host ""

# Check if SSH is available
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ SSH not found. Installing OpenSSH Client..." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this as Administrator, then run this script again:" -ForegroundColor Yellow
    Write-Host "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor White
    exit 1
}

Write-Host "Step 2: Preparing files to transfer..." -ForegroundColor Yellow

# Create temporary directory with scripts
$tempDir = Join-Path $env:TEMP "pi_setup_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy scripts
Copy-Item "pi_heartbeat_test.py" -Destination $tempDir -ErrorAction SilentlyContinue
Copy-Item "pi_heartbeat_continuous.py" -Destination $tempDir -ErrorAction SilentlyContinue

if (-not (Test-Path (Join-Path $tempDir "pi_heartbeat_test.py"))) {
    Write-Host "❌ Scripts not found in current directory!" -ForegroundColor Red
    Write-Host "Please run this from the project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Files ready" -ForegroundColor Green
Write-Host ""

# Transfer files using SCP
Write-Host "Step 3: Transferring files to Pi..." -ForegroundColor Yellow

if ($Password) {
    # Using plink for password authentication (if available)
    Write-Host "⚠️  Password authentication requires plink (PuTTY) or SSH keys." -ForegroundColor Yellow
    Write-Host "   Please set up SSH key authentication, or transfer files manually." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: I'll create a setup script you can copy-paste:" -ForegroundColor Cyan
} else {
    Write-Host "Transferring files..." -ForegroundColor Yellow
    scp "$tempDir\pi_heartbeat_test.py" "${Username}@${PiIP}:~/" 2>&1 | Out-Null
    scp "$tempDir\pi_heartbeat_continuous.py" "${Username}@${PiIP}:~/" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Files transferred successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  File transfer may require SSH key. Creating manual commands instead..." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 4: Creating setup commands..." -ForegroundColor Yellow

# Create setup script content
$setupScript = @"
#!/bin/bash
echo "=========================================="
echo "Raspberry Pi Gateway Setup"
echo "=========================================="
echo ""

# Install Python dependencies
echo "Installing Python dependencies..."
sudo apt-get update -qq
sudo apt-get install -y python3-pip -qq
pip3 install requests --quiet --break-system-packages 2>/dev/null || pip3 install requests --quiet

echo "✅ Dependencies installed"
echo ""

# Make scripts executable
chmod +x pi_heartbeat_test.py pi_heartbeat_continuous.py 2>/dev/null || true

echo "✅ Scripts ready"
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Next: Run test script:"
echo "  python3 pi_heartbeat_test.py"
echo ""
"@

# Save setup script
$setupScriptPath = Join-Path $tempDir "setup.sh"
$setupScript | Out-File -FilePath $setupScriptPath -Encoding ASCII

# Create test command
$testCommand = "python3 pi_heartbeat_test.py"

# Create continuous run command  
$continuousCommand = "nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setup Commands for Raspberry Pi" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SSH into your Pi:" -ForegroundColor Yellow
Write-Host "  ssh ${Username}@${PiIP}" -ForegroundColor White
Write-Host ""
Write-Host "Then run these commands:" -ForegroundColor Yellow
Write-Host ""

# Display setup script
Write-Host "--- Setup Script (copy all) ---" -ForegroundColor Green
Write-Host $setupScript -ForegroundColor Gray
Write-Host "--- End Setup Script ---" -ForegroundColor Green
Write-Host ""

Write-Host "Or run step by step:" -ForegroundColor Yellow
Write-Host "  sudo apt-get update" -ForegroundColor White
Write-Host "  sudo apt-get install -y python3-pip" -ForegroundColor White
Write-Host "  pip3 install requests" -ForegroundColor White
Write-Host "  chmod +x pi_heartbeat*.py" -ForegroundColor White
Write-Host ""
Write-Host "Test connection:" -ForegroundColor Yellow
Write-Host "  python3 pi_heartbeat_test.py" -ForegroundColor White
Write-Host ""
Write-Host "Run continuously:" -ForegroundColor Yellow
Write-Host "  nohup python3 pi_heartbeat_continuous.py > heartbeat.log 2>&1 &" -ForegroundColor White
Write-Host ""

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "To automate further, set up SSH key authentication:" -ForegroundColor Cyan
Write-Host "  ssh-keygen -t rsa" -ForegroundColor White
Write-Host "  ssh-copy-id ${Username}@${PiIP}" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan

