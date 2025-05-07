# PowerShell script to fix admin page routing issues

Write-Host "Finding client container..."
$clientContainer = docker ps | Select-String -Pattern "rts.*client" | ForEach-Object { $_.ToString().Split()[0] }

if (-not $clientContainer) {
    Write-Host "Client container not found! Make sure it's running." -ForegroundColor Red
    exit 1
}

Write-Host "Client container found: $clientContainer" -ForegroundColor Green

# Create proper serve.json configuration
$serveJson = @"
{
  "public": "/web",
  "rewrites": [
    { "source": "/admin", "destination": "/admin/index.html" },
    { "source": "/admin/*", "destination": "/admin/index.html" }
  ],
  "cleanUrls": true
}
"@

# Save to a temp file
$serveJson | Out-File -Encoding utf8 -FilePath "$env:TEMP\serve.json"

Write-Host "Copying fixed serve.json configuration to container..." -ForegroundColor Yellow
docker cp "$env:TEMP\serve.json" "${clientContainer}:/web/serve.json"

# Make sure admin directory exists
Write-Host "Ensuring admin directory exists..." -ForegroundColor Yellow
docker exec $clientContainer mkdir -p /web/admin

# Copy admin.html to admin/index.html
Write-Host "Copying admin.html to admin/index.html..." -ForegroundColor Yellow
docker exec $clientContainer cp -f /web/admin.html /web/admin/index.html

Write-Host "Restarting serve process..." -ForegroundColor Yellow
docker exec $clientContainer pkill node || Write-Host "No node process to kill"
docker exec -d $clientContainer /start.sh

Write-Host "Fix applied. Wait a moment for the server to restart." -ForegroundColor Green
Write-Host "Then try accessing the admin page at: http://localhost:8000/admin/" -ForegroundColor Cyan
Write-Host "And the main game page at: http://localhost:8000/" -ForegroundColor Cyan

# Clean up
Remove-Item "$env:TEMP\serve.json" -ErrorAction SilentlyContinue
