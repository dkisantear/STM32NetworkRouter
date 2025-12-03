# Test if Master STM32 status is being stored in Azure
$apiUrl = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-master"

Write-Host "Testing Master STM32 status API..." -ForegroundColor Yellow
Write-Host "URL: $apiUrl" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method GET
    
    Write-Host "✅ Response received!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Device ID: $($response.deviceId)" -ForegroundColor Cyan
    Write-Host "Status: $($response.status)" -ForegroundColor Cyan
    Write-Host "Last Updated: $($response.lastUpdated)" -ForegroundColor Cyan
    Write-Host ""
    
    if ($response.status -eq "unknown") {
        Write-Host "⚠️  Status is 'unknown' - bridge script may be using wrong device ID" -ForegroundColor Yellow
        Write-Host "   Check if bridge script uses: DEVICE_ID = 'stm32-master'" -ForegroundColor Yellow
    } elseif ($response.status -eq "online") {
        Write-Host "✅ Master STM32 is ONLINE!" -ForegroundColor Green
    } elseif ($response.status -eq "offline") {
        Write-Host "⚠️  Master STM32 is OFFLINE" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Also test with wrong device ID for comparison:" -ForegroundColor Gray
$wrongUrl = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/stm32-status?deviceId=stm32-main"
try {
    $wrongResponse = Invoke-RestMethod -Uri $wrongUrl -Method GET
    Write-Host "stm32-main status: $($wrongResponse.status)" -ForegroundColor Gray
} catch {
    Write-Host "stm32-main: Error or not found" -ForegroundColor Gray
}

