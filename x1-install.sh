#!/usr/bin/env bash
#
# X1 installer. Fetches the release bundle, checks the host, and starts the
# stack. Piping this from the site is the one delivery path macOS never
# quarantines, so it works without a signing certificate.
#
#   curl -fsSL https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.sh | bash
#
# Reads, in order of precedence:
#   X1_RELEASE_URL   tarball to install (default: the pinned release below)
#   X1_HOME          install directory (default: ~/.xscaleai/x1)
#   X1_REF           git ref, when installing from a source checkout

set -euo pipefail

X1_HOME="${X1_HOME:-$HOME/.xscaleai/x1}"
X1_RELEASE_URL="${X1_RELEASE_URL:-https://github.com/X-Scale-AI/x1/releases/download/v0.3.0-beta/x1.tar.gz}"

say()  { printf '  %s\n' "$*"; }
step() { printf '\n  %s\n' "$*"; }
fail() { printf '\n  %s\n\n' "$*" >&2; exit 1; }

trap 'fail "Install stopped. Nothing was deleted. Re-run when ready."' INT TERM

printf '\n  X1 by XScaleAI\n  Your secure personal AI agent.\n'

# ---------------------------------------------------------------------------
# 1. Host
# ---------------------------------------------------------------------------
step "Checking this machine..."

case "$(uname -s)" in
    Darwin) host_os="macOS" ;;
    Linux)  host_os="Linux" ;;
    *)      fail "X1 supports macOS and Linux here. On Windows use the PowerShell installer: https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.ps1" ;;
esac

case "$(uname -m)" in
    arm64|aarch64) host_arch="arm64" ;;
    x86_64|amd64)  host_arch="amd64" ;;
    *)             fail "Unsupported architecture: $(uname -m). X1 needs arm64 or amd64." ;;
esac

for tool in curl tar; do
    command -v "$tool" >/dev/null 2>&1 || fail "'$tool' is required but was not found."
done
say "$host_os on $host_arch."

# ---------------------------------------------------------------------------
# 2. Docker
# ---------------------------------------------------------------------------
step "Checking Docker..."

if ! command -v docker >/dev/null 2>&1; then
    fail "Docker is not installed.
  X1 runs in secure containers on your own machine, so Docker is required.
  Install it, then run this command again:
  https://www.docker.com/products/docker-desktop/"
fi

if ! docker info >/dev/null 2>&1; then
    if [ "$host_os" = "macOS" ] && [ -d "/Applications/Docker.app" ]; then
        say "Starting Docker Desktop..."
        open -a Docker >/dev/null 2>&1 || true
        waited=0
        while ! docker info >/dev/null 2>&1; do
            [ "$waited" -ge 120 ] && fail "Docker did not start within two minutes. Start it yourself, then re-run."
            sleep 3; waited=$((waited + 3))
            printf '.'
        done
        printf '\n'
    else
        fail "The Docker daemon is not running. Start Docker, then run this command again."
    fi
fi

docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is required. Update Docker, then re-run."
[ "$(docker info --format '{{.OSType}}' 2>/dev/null)" = "linux" ] || fail "Docker must be running Linux containers."
say "Docker is ready."

# ---------------------------------------------------------------------------
# 3. Fetch
# ---------------------------------------------------------------------------
step "Fetching X1..."

mkdir -p "$X1_HOME"
chmod 700 "$X1_HOME" 2>/dev/null || true

if [ -f "$X1_HOME/docker-compose.yml" ]; then
    say "Existing install found at $X1_HOME. Your data is kept."
else
    staging="$(mktemp -d)"
    trap 'rm -rf "$staging"' EXIT
    if ! curl -fsSL "$X1_RELEASE_URL" -o "$staging/x1.tar.gz"; then
        fail "Could not download X1 from:
  $X1_RELEASE_URL
  Check your connection, or set X1_RELEASE_URL to a bundle you already have."
    fi
    tar -xzf "$staging/x1.tar.gz" -C "$X1_HOME" --strip-components=1
    say "Installed to $X1_HOME"
fi

cd "$X1_HOME"
[ -f docker-compose.yml ] || fail "The bundle is missing docker-compose.yml. Delete $X1_HOME and re-run."

if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    chmod 600 .env 2>/dev/null || true
    say "Created .env with owner-only permissions."
fi

# ---------------------------------------------------------------------------
# 4. Start
# ---------------------------------------------------------------------------
step "Starting X1. The first run downloads the runtime and takes a few minutes..."

if [ -x ./install.sh ] && [ "${X1_BOOTSTRAPPED:-0}" != "1" ]; then
    # The bundle ships the launcher that owns health checks and browser opening.
    X1_BOOTSTRAPPED=1 exec ./install.sh --open
fi

docker compose up -d --build || fail "Docker Compose could not start X1. Run 'docker compose logs' in $X1_HOME to see why."

port="$(grep -E '^ONBOARDER_PORT=' .env 2>/dev/null | cut -d= -f2)"
port="${port:-8787}"
url="http://127.0.0.1:$port"

printf '\n  Waiting for X1 to become healthy'
waited=0
until curl -fsS "$url/api/status" >/dev/null 2>&1; do
    [ "$waited" -ge 300 ] && fail "X1 did not become healthy in five minutes. Run 'docker compose logs' in $X1_HOME."
    sleep 3; waited=$((waited + 3))
    printf '.'
done
printf ' ready.\n'

printf '\n  X1 is running: %s\n' "$url"
printf '  Your data stays in the Docker volume xscaleai-paa-data on this machine.\n\n'

if [ "$host_os" = "macOS" ]; then
    open "$url" >/dev/null 2>&1 || true
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
fi
