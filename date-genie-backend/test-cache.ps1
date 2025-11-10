Write-Host "=== First Call (Cache Miss) ==="
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/search" -Headers @{"Content-Type"="application/json"} -Body '{"city": "San Diego", "radius": 10, "budget": 80, "category": "restaurant"}' |
  ConvertTo-Json -Depth 10 |
  Out-File -FilePath "response1.json" -Encoding utf8

Write-Host "=== Second Call (Should Be Cache Hit) ==="
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/search" -Headers @{"Content-Type"="application/json"} -Body '{"city": "San Diego", "radius": 10, "budget": 80, "category": "restaurant"}' |
  ConvertTo-Json -Depth 10 |
  Out-File -FilePath "response2.json" -Encoding utf8

Write-Host "Done. Check response1.json and response2.json for source field."
