$ErrorActionPreference = "Stop"

$ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $ProjectRoot

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-ContainerExists {
    param([string]$Name)
    $containers = docker ps -a --format "{{.Names}}"
    return $containers -contains $Name
}

function Start-OrCreateContainer {
    param(
        [string]$Name,
        [string]$RunCommand
    )
    if (Test-ContainerExists $Name) {
        docker start $Name | Out-Null
        Write-Host "$Name is running."
    } else {
        Invoke-Expression $RunCommand | Out-Null
        Write-Host "$Name created and started."
    }
}

function Wait-ForHttp {
    param(
        [string]$Url,
        [int]$Seconds = 60
    )
    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        try {
            $response = Invoke-WebRequest -UseBasicParsing $Url -TimeoutSec 4
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for $Url"
}

if (-not (Test-Command docker)) {
    throw "Docker was not found. Install Docker Desktop first, then rerun setup.ps1."
}

Write-Step "Starting Docker containers"
Start-OrCreateContainer `
    -Name "parman-node-red" `
    -RunCommand "docker run -d --name parman-node-red -p 1880:1880 -v parman_nodered_data:/data --restart unless-stopped nodered/node-red:latest"

Start-OrCreateContainer `
    -Name "parman-mailpit" `
    -RunCommand "docker run -d --name parman-mailpit -p 8025:8025 -p 1025:1025 --restart unless-stopped axllent/mailpit:latest"

Write-Step "Waiting for local services"
Wait-ForHttp "http://localhost:1880"
Wait-ForHttp "http://localhost:8025"

$scripts = @(
    "deploy-checkpoint4.ps1",
    "deploy-checkpoint5.ps1",
    "deploy-checkpoint6a.ps1",
    "deploy-checkpoint6b.ps1",
    "deploy-checkpoint6c.ps1",
    "deploy-checkpoint7.ps1",
    "deploy-checkpoint8.ps1",
    "deploy-checkpoint9a.ps1",
    "deploy-checkpoint9b.ps1",
    "deploy-checkpoint10a.ps1",
    "deploy-checkpoint10b.ps1",
    "deploy-checkpoint10c.ps1",
    "deploy-checkpoint11a.ps1",
    "deploy-checkpoint11b.ps1"
)

Write-Step "Deploying Node-RED POC flows and dashboard"
foreach ($script in $scripts) {
    $path = Join-Path $ProjectRoot $script
    if (-not (Test-Path $path)) {
        throw "Missing deployment script: $script"
    }
    Write-Host "Running $script"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $path
}

Write-Step "Verifying dashboard"
Wait-ForHttp "http://localhost:1880/app/"

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Dashboard: http://localhost:1880/app/?v=latest#overview"
Write-Host "Node-RED:   http://localhost:1880"
Write-Host "Mailpit:    http://localhost:8025"
Write-Host ""
Write-Host "If the dashboard looks old, open http://localhost:1880/app/?v=latest#settings and press Ctrl+F5."
