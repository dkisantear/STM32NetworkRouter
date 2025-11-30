# Setup using plink (PuTTY command line) if available
$PiIP = "192.168.1.160"
$PiUser = "pi5"
$PiPass = "pi5"

Write-Host "Checking for plink..." -ForegroundColor Yellow

if (Get-Command plink -ErrorAction SilentlyContinue) {
    Write-Host "✅ plink found!" -ForegroundColor Green
    
    # Transfer files
    Write-Host "Transferring files..." -ForegroundColor Yellow
    echo y | plink -ssh -pw $PiPass "$PiUser@$PiIP" "exit"
    
    plink -ssh -pw $PiPass "$PiUser@$PiIP" "mkdir -p ~/scripts"
    
    # Create setup script on Pi
    $setupScript = Get-Content "EXECUTE_THIS_ON_PI.sh" -Raw
    $setupScript | plink -ssh -pw $PiPass "$PiUser@$PiIP" "cat > ~/setup.sh"
    
    # Run setup
    Write-Host "Running setup..." -ForegroundColor Yellow
    plink -ssh -pw $PiPass "$PiUser@$PiIP" "bash ~/setup.sh"
    
} else {
    Write-Host "plink not found. Please install PuTTY or use manual method." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual steps:" -ForegroundColor Cyan
    Write-Host "1. ssh pi5@192.168.1.160" -ForegroundColor White
    Write-Host "2. Copy-paste EXECUTE_THIS_ON_PI.sh contents" -ForegroundColor White
}

