# ========================================
# Copy Updated Bridge Script to Pi
# ========================================
# Run this from PowerShell in the repo directory

$piHost = "pi5@192.168.1.160"
$scriptFile = "pi_stm32_bridge.py"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📤 Copying Bridge Script to Pi" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $scriptFile)) {
    Write-Host "❌ Error: $scriptFile not found in current directory!" -ForegroundColor Red
    Write-Host "   Make sure you're running this from the repo root." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found $scriptFile" -ForegroundColor Green
Write-Host ""

# Copy to Pi
Write-Host "📡 Copying to $piHost..." -ForegroundColor Yellow
Write-Host "   (You may be prompted for password)" -ForegroundColor Gray
Write-Host ""

try {
    scp $scriptFile "${piHost}:~/"
    Write-Host ""
    Write-Host "✅ File copied successfully!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "📋 Next Steps (run on Pi via SSH):" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Stop old bridge:" -ForegroundColor Yellow
    Write-Host "   pkill -f pi_stm32_bridge" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Test UART first:" -ForegroundColor Yellow
    Write-Host "   python3 pi_uart_test.py" -ForegroundColor White
    Write-Host "   (Should see 'STM32_ALIVE' messages)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Start bridge:" -ForegroundColor Yellow
    Write-Host "   nohup python3 pi_stm32_bridge.py > bridge_output.log 2>&1 &" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Monitor logs:" -ForegroundColor Yellow
    Write-Host "   tail -f ~/stm32-bridge.log" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ Error copying file: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Manual copy via SSH" -ForegroundColor Yellow
    Write-Host "   1. Open pi_stm32_bridge.py in this repo" -ForegroundColor White
    Write-Host "   2. Copy all contents (Ctrl+A, Ctrl+C)" -ForegroundColor White
    Write-Host "   3. SSH to Pi: ssh $piHost" -ForegroundColor White
    Write-Host "   4. Edit file: nano ~/pi_stm32_bridge.py" -ForegroundColor White
    Write-Host "   5. Delete all, paste new, save (Ctrl+O, Enter, Ctrl+X)" -ForegroundColor White
    exit 1
}

