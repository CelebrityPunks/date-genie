# Test Cache Miss and Cache Hit
Write-Host "=== First API Call (Cache Miss) ===" -ForegroundColor Yellow
$body = '{"city": "San Diego", "radius": 10, "budget": 80, "category": "restaurant"}'

try {
    $response1 = Invoke-RestMethod -Uri 'http://localhost:3000/api/search' -Method Post -Body $body -ContentType 'application/json'
    Write-Host "Source: $($response1.source)" -ForegroundColor $(if ($response1.source -eq 'cache') { 'Green' } else { 'Yellow' })
    Write-Host "Latency: $($response1.latency_ms)ms"
    Write-Host "Results: $($response1.data.Count) venues"
    Write-Host ""
    
    Start-Sleep -Seconds 2
    
    Write-Host "=== Second API Call (Should be Cache Hit) ===" -ForegroundColor Cyan
    $response2 = Invoke-RestMethod -Uri 'http://localhost:3000/api/search' -Method Post -Body $body -ContentType 'application/json'
    Write-Host "Source: $($response2.source)" -ForegroundColor $(if ($response2.source -eq 'cache') { 'Green' } else { 'Yellow' })
    Write-Host "Latency: $($response2.latency_ms)ms"
    Write-Host "Results: $($response2.data.Count) venues"
    Write-Host ""
    
    Write-Host "=== Comparison ===" -ForegroundColor Magenta
    Write-Host "First call:  $($response1.source) - $($response1.latency_ms)ms"
    Write-Host "Second call: $($response2.source) - $($response2.latency_ms)ms"
    
    if ($response2.source -eq 'cache') {
        $speedup = [math]::Round(($response1.latency_ms / $response2.latency_ms), 2)
        Write-Host ""
        Write-Host "CACHE IS WORKING! Speedup: ${speedup}x faster" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Cache may not be configured (check Redis credentials in .env.local)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the server is running" -ForegroundColor Yellow
}
