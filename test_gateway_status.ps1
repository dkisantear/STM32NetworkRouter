# Quick Test Script for Gateway Status
# This marks your Pi as "online" in Table Storage

$apiUrl = "https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"
$gatewayId = "pi5-main"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Gateway Status API" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Mark Pi as Online
Write-Host "1. Marking Pi as ONLINE..." -ForegroundColor Yellow
try {
    $body = @{
        gatewayId = $gatewayId
        status = "online"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $apiUrl `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    Write-Host "   ✅ Success!" -ForegroundColor Green
    Write-Host "   Gateway ID: $($response.gatewayId)" -ForegroundColor Gray
    Write-Host "   Status: $($response.status)" -ForegroundColor Gray
    Write-Host "   Last Updated: $($response.lastUpdated)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Test 2: Check Status
Write-Host "2. Checking status..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    $statusUrl = "$apiUrl`?gatewayId=$gatewayId"
    $statusResponse = Invoke-RestMethod -Uri $statusUrl -Method GET

    Write-Host "   ✅ Status Retrieved!" -ForegroundColor Green
    Write-Host "   Gateway ID: $($statusResponse.gatewayId)" -ForegroundColor Gray
    Write-Host "   Status: $($statusResponse.status)" -ForegroundColor Gray
    Write-Host "   Last Updated: $($statusResponse.lastUpdated)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Test Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Now check your dashboard:" -ForegroundColor Yellow
Write-Host "   https://blue-desert-0c2a27e1e.3.azurestaticapps.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Status should show 'Online' within 8 seconds!" -ForegroundColor White
Write-Host ""

