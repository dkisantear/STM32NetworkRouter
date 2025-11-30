# PowerShell script to help find your Raspberry Pi's IP address
# Run this script to scan your network

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Finding Raspberry Pi on Your Network" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get your local IP address to determine network range
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress

if ($localIP) {
    $networkRange = $localIP -replace '\.\d+$', ''
    Write-Host "Your local network: $networkRange.0/24" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Scanning for Raspberry Pi devices..." -ForegroundColor Yellow
    Write-Host "(This may take a minute)" -ForegroundColor Gray
    Write-Host ""
    
    # Check ARP table for devices
    $arpEntries = arp -a | Select-String "192.168"
    
    Write-Host "Found devices on your network:" -ForegroundColor Green
    Write-Host ""
    
    $foundDevices = @()
    foreach ($entry in $arpEntries) {
        if ($entry -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
            $ip = $matches[1]
            $mac = if ($entry -match '([a-fA-F0-9]{2}-[a-fA-F0-9]{2}-[a-fA-F0-9]{2}-[a-fA-F0-9]{2}-[a-fA-F0-9]{2}-[a-fA-F0-9]{2})') { $matches[1] } else { "Unknown" }
            
            # Try to resolve hostname
            try {
                $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            } catch {
                $hostname = "Unknown"
            }
            
            $foundDevices += [PSCustomObject]@{
                IP = $ip
                MAC = $mac
                Hostname = $hostname
            }
        }
    }
    
    # Display found devices
    $foundDevices | Format-Table -AutoSize
    
    # Look for Raspberry Pi
    Write-Host ""
    Write-Host "Checking for Raspberry Pi..." -ForegroundColor Yellow
    
    $piDevices = $foundDevices | Where-Object { 
        $_.Hostname -like "*raspberry*" -or 
        $_.Hostname -like "*pi*" 
    }
    
    if ($piDevices) {
        Write-Host ""
        Write-Host "🎯 Possible Raspberry Pi devices found:" -ForegroundColor Green
        $piDevices | Format-Table -AutoSize
        Write-Host ""
        Write-Host "Try SSH with one of these IPs:" -ForegroundColor Cyan
        foreach ($pi in $piDevices) {
            Write-Host "  ssh pi@$($pi.IP)" -ForegroundColor White
        }
    } else {
        Write-Host ""
        Write-Host "⚠️  No obvious Raspberry Pi hostname found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Try these common Pi IPs:" -ForegroundColor Cyan
        Write-Host "  ssh pi@192.168.1.100" -ForegroundColor White
        Write-Host "  ssh pi@192.168.1.101" -ForegroundColor White
        Write-Host "  ssh pi@192.168.0.100" -ForegroundColor White
        Write-Host "  ssh pi@192.168.0.101" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Alternative: Check your router admin page" -ForegroundColor Cyan
    Write-Host "Usually at: http://192.168.1.1" -ForegroundColor Yellow
    Write-Host "Look for 'raspberrypi' in connected devices" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    
} else {
    Write-Host "❌ Could not determine your network range." -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual steps:" -ForegroundColor Yellow
    Write-Host "1. Check your router admin page" -ForegroundColor White
    Write-Host "2. Look for 'raspberrypi' in connected devices" -ForegroundColor White
    Write-Host "3. Or check Pi screen: run 'hostname -I'" -ForegroundColor White
}

