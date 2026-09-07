# X1 installer for Windows.
#
#   irm https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.ps1 | iex
#
# Requires Docker Desktop with the WSL2 backend and Linux containers.

$ErrorActionPreference = 'Stop'

$X1Home = if ($env:X1_HOME) { $env:X1_HOME } else { Join-Path $env:LOCALAPPDATA 'XScaleAI\X1' }
$ReleaseUrl = if ($env:X1_RELEASE_URL) { $env:X1_RELEASE_URL } else { 'https://github.com/X-Scale-AI/x1/releases/download/v0.3.0-beta/x1.tar.gz' }

function Say  { param($m) Write-Host "  $m" }
function Step { param($m) Write-Host ""; Write-Host "  $m" }
function Fail { param($m) Write-Host ""; Write-Error "  $m"; exit 1 }

Write-Host ""
Write-Host "  X1 by XScaleAI"
Write-Host "  Your secure personal AI agent."

Step "Checking Docker..."

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail "Docker is not installed.
  X1 runs in secure containers on your own machine, so Docker is required.
  Install Docker Desktop, then run this command again:
  https://www.docker.com/products/docker-desktop/"
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    $desktop = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (Test-Path $desktop) {
        Say "Starting Docker Desktop..."
        Start-Process $desktop | Out-Null
        $waited = 0
        while ($true) {
            docker info *> $null
            if ($LASTEXITCODE -eq 0) { break }
            if ($waited -ge 180) { Fail "Docker did not start within three minutes. Start it yourself, then re-run." }
            Start-Sleep -Seconds 3
            $waited += 3
            Write-Host "." -NoNewline
        }
        Write-Host ""
    } else {
        Fail "The Docker daemon is not running. Start Docker Desktop, then run this command again."
    }
}

$osType = (docker info --format '{{.OSType}}')
if ($osType -ne 'linux') {
    Fail "Docker must be set to Linux containers. Switch in the Docker Desktop tray menu, then re-run."
}
Say "Docker is ready."

Step "Fetching X1..."

New-Item -ItemType Directory -Force -Path $X1Home | Out-Null

if (Test-Path (Join-Path $X1Home 'docker-compose.yml')) {
    Say "Existing install found at $X1Home. Your data is kept."
} else {
    $archive = Join-Path $env:TEMP 'x1.tar.gz'
    try {
        Invoke-WebRequest -Uri $ReleaseUrl -OutFile $archive -UseBasicParsing
    } catch {
        Fail "Could not download X1 from:
  $ReleaseUrl
  Check your connection, or set X1_RELEASE_URL to a bundle you already have."
    }
    tar -xzf $archive -C $X1Home --strip-components=1
    Remove-Item $archive -ErrorAction SilentlyContinue
    Say "Installed to $X1Home"
}

Set-Location $X1Home

if ((-not (Test-Path '.env')) -and (Test-Path '.env.example')) {
    Copy-Item '.env.example' '.env'
    Say "Created .env"
}

Step "Starting X1. The first run downloads the runtime and takes a few minutes..."

docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Fail "Docker Compose could not start X1. Run 'docker compose logs' in $X1Home to see why."
}

$port = '8787'
if (Test-Path '.env') {
    $line = Select-String -Path '.env' -Pattern '^ONBOARDER_PORT=' -ErrorAction SilentlyContinue
    if ($line) { $port = ($line.Line -split '=')[1] }
}
$url = "http://127.0.0.1:$port"

Write-Host ""
Write-Host "  Waiting for X1 to become healthy" -NoNewline
$waited = 0
while ($true) {
    try {
        Invoke-WebRequest -Uri "$url/api/status" -UseBasicParsing -TimeoutSec 3 | Out-Null
        break
    } catch {
        if ($waited -ge 300) { Fail "X1 did not become healthy in five minutes. Run 'docker compose logs' in $X1Home." }
        Start-Sleep -Seconds 3
        $waited += 3
        Write-Host "." -NoNewline
    }
}
Write-Host " ready."

Write-Host ""
Write-Host "  X1 is running: $url"
Write-Host "  Your data stays in the Docker volume xscaleai-paa-data on this machine."
Write-Host ""

Start-Process $url | Out-Null
