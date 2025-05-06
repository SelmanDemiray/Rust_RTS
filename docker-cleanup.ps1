# PowerShell script to clean up Docker containers and images matching specific patterns

$patterns = @("rts_", "rust_rts-client", "rust_rts-server")

foreach ($pattern in $patterns) {
    Write-Host "Looking for containers using images matching: $pattern"

    # Find all containers (running or stopped) using images matching the pattern
    $containerIds = docker ps -a --format "{{.ID}} {{.Image}}" | Where-Object { $_ -match $pattern } | ForEach-Object { ($_ -split " ")[0] }
    if ($containerIds) {
        Write-Host "Stopping and removing containers: $containerIds"
        $containerIds | ForEach-Object { docker stop $_ }
        $containerIds | ForEach-Object { docker rm $_ }
    }

    # Remove the image(s)
    $imageIds = docker images --format "{{.Repository}} {{.ID}}" | Select-String $pattern | ForEach-Object { ($_ -split " ")[1] }
    if ($imageIds) {
        Write-Host "Removing images: $imageIds"
        $imageIds | ForEach-Object { docker rmi -f $_ }
    }
}

# Remove dangling images
$dangling = docker images -f "dangling=true" -q
if ($dangling) {
    Write-Host "Removing dangling images: $dangling"
    $dangling | ForEach-Object { docker rmi -f $_ }
}

Write-Host "Cleanup complete."
