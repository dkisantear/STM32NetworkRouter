# PowerShell script to update bridge script on Pi
# Make sure you have SSH access set up

$PI_USER = "pi5"
$PI_IP = "192.168.1.160"  # Update this if your Pi IP is different
$SCRIPT_FILE = "pi_stm32_bridge.py"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Updating STM32 Bridge Script on Pi" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $SCRIPT_FILE)) {
    Write-Host "❌ Error: $SCRIPT_FILE not found in current directory" -ForegroundColor Red
    Write-Host "Make sure you're in the repo directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Copying $SCRIPT_FILE to Pi..." -ForegroundColor Yellow

# Copy file to Pi
scp "$SCRIPT_FILE" "${PI_USER}@${PI_IP}:~/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ File copied successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. SSH into your Pi: ssh ${PI_USER}@${PI_IP}" -ForegroundColor White
    Write-Host "2. Stop old bridge: pkill -f pi_stm32_bridge.py" -ForegroundColor White
    Write-Host "3. Start new bridge: python3 pi_stm32_bridge.py" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to connect now
    $connect = Read-Host "Do you want to SSH into Pi now? (y/n)"
    if ($connect -eq "y" -or $connect -eq "Y") {
        Write-Host "Connecting to Pi..." -ForegroundColor Yellow
        ssh "${PI_USER}@${PI_IP}"
    }
} else {
    Write-Host "❌ Failed to copy file. Check your Pi IP address and SSH connection." -ForegroundColor Red
}

