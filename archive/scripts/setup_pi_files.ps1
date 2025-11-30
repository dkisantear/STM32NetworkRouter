# PowerShell script to help transfer files to Raspberry Pi
# Run this from PowerShell on Windows

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Raspberry Pi File Transfer Helper" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get Pi IP address
$piIP = Read-Host "Enter your Raspberry Pi's IP address (e.g., 192.168.1.100)"

if (-not $piIP) {
    Write-Host "❌ No IP address provided. Exiting." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Testing connection to $piIP..." -ForegroundColor Yellow

# Test connection
$ping = Test-Connection -ComputerName $piIP -Count 1 -Quiet
if (-not $ping) {
    Write-Host "❌ Cannot reach $piIP. Please check:" -ForegroundColor Red
    Write-Host "   - Pi is powered on" -ForegroundColor Yellow
    Write-Host "   - Pi is on the same network" -ForegroundColor Yellow
    Write-Host "   - IP address is correct" -ForegroundColor Yellow
    exit
}

Write-Host "✅ Pi is reachable!" -ForegroundColor Green
Write-Host ""

# Files to transfer
$files = @(
    "pi_heartbeat_test.py",
    "pi_heartbeat_continuous.py",
    "pi_setup.sh"
)

Write-Host "Files to transfer:" -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file (not found)" -ForegroundColor Red
    }
}

Write-Host ""
$confirm = Read-Host "Ready to transfer? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Transferring files using SCP..." -ForegroundColor Yellow
Write-Host ""

# Check if SCP is available (needs OpenSSH client)
if (Get-Command scp -ErrorAction SilentlyContinue) {
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "Transferring $file..." -ForegroundColor Yellow
            scp $file "pi@${piIP}:~/" 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ $file transferred successfully" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Failed to transfer $file" -ForegroundColor Red
            }
        }
    }
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Files transferred! Next steps:" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. SSH into your Pi:" -ForegroundColor Yellow
    Write-Host "   ssh pi@$piIP" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Run setup script:" -ForegroundColor Yellow
    Write-Host "   chmod +x pi_setup.sh" -ForegroundColor White
    Write-Host "   ./pi_setup.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Test connection:" -ForegroundColor Yellow
    Write-Host "   python3 pi_heartbeat_test.py" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "❌ SCP not found. Installing OpenSSH Client..." -ForegroundColor Red
    Write-Host ""
    Write-Host "Run this in PowerShell as Administrator:" -ForegroundColor Yellow
    Write-Host "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "OR manually copy files to USB and transfer to Pi." -ForegroundColor Yellow
}

