$ErrorActionPreference = "Stop"

$projectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$uiRoot = Join-Path $projectRoot "ui"
$uiAssets = Join-Path $uiRoot "assets"
$logoSource = Join-Path $projectRoot "assets\parman-logo-email.png"
$logoTarget = Join-Path $uiAssets "parman-logo-email.png"
$settingsSource = Join-Path $projectRoot "settings.node-red.js"

if (-not (Test-Path $uiRoot)) {
    throw "UI directory not found: $uiRoot"
}
if (-not (Test-Path $logoSource)) {
    throw "Logo not found: $logoSource"
}
if (-not (Test-Path $settingsSource)) {
    throw "Node-RED settings not found: $settingsSource"
}

New-Item -ItemType Directory -Force $uiAssets | Out-Null
Copy-Item -Force $logoSource $logoTarget

docker exec parman-node-red sh -c "mkdir -p /data/ui/assets" | Out-Null
docker cp "$uiRoot\." parman-node-red:/data/ui/
docker cp $settingsSource parman-node-red:/data/settings.js
docker restart parman-node-red | Out-Null

Start-Sleep -Seconds 4
$response = Invoke-WebRequest -UseBasicParsing http://localhost:1880/app/
if ($response.StatusCode -ne 200) {
    throw "Dashboard verification failed with HTTP $($response.StatusCode)"
}

Write-Output "Checkpoint 8 local UI deployed: http://localhost:1880/app/"
