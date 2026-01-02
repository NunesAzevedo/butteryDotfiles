#!/bin/bash
# ==============================================================================
# SCRIPT: docker/start_test.sh
# DESCRIPTION: Helper to build and run Docker test environments for ButteryDotfiles.
# USAGE: ./docker/start_test.sh [arch|fedora] [clean]
#        'clean' argument forces a rebuild without cache.
# ==============================================================================

set -e

# 1. Navigation & Checks
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Import Utils for colors
if [ -f "scripts/lib/utils.sh" ]; then
    source "scripts/lib/utils.sh"
else
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'
    log_header() { echo -e "${YELLOW}🧈 $1${NC}"; }
    log_error() { echo -e "${RED}❌ $1${NC}"; }
    log_info() { echo -e "   $1"; }
fi

# 2. Argument Parsing
TARGET="$1"
MODE="$2" # Optional: "clean" to disable cache

if [[ "$TARGET" != "arch" && "$TARGET" != "fedora" ]]; then
    log_error "Usage: $0 [arch|fedora] [clean]"
    exit 1
fi

DOCKERFILE="docker/Dockerfile.$TARGET"
IMAGE_NAME="buttery_${TARGET}_test"
CONTAINER_HOME="/home/tester/butteryDotfiles"

# 3. Configure Build Options
BUILD_FLAGS=""
if [ "$MODE" == "clean" ]; then
    log_header "🧹 Clean build requested (No Cache)..."
    BUILD_FLAGS="--no-cache"
fi

# 4. Build Image (MODERN BUILDKIT ENABLED)
log_header "Building Docker Image for: $TARGET"
log_info "Using $DOCKERFILE with BuildKit..."

# FIX: Added BUILD_FLAGS variable to inject --no-cache when requested
DOCKER_BUILDKIT=1 docker build $BUILD_FLAGS -t "$IMAGE_NAME" -f "$DOCKERFILE" .

# 5. Run Container
log_header "Starting Container..."

# FIX: Detect Host Timezone to sync log timestamps
if command -v timedatectl &> /dev/null; then
    HOST_TZ=$(timedatectl show --value -p Timezone 2>/dev/null)
elif [ -f /etc/timezone ]; then
    HOST_TZ=$(cat /etc/timezone)
else
    HOST_TZ="UTC"
fi

# Fallback if detection returned empty
if [ -z "$HOST_TZ" ]; then HOST_TZ="UTC"; fi

log_info "Timezone detected: $HOST_TZ"
log_info "Mounting current directory to: $CONTAINER_HOME"
log_info "Entering interactive shell..."
echo ""

# FIX: Added -e TZ="$HOST_TZ" to pass the timezone to the container
docker run -it --rm --privileged \
    -e TZ="$HOST_TZ" \
    -v "$REPO_ROOT:$CONTAINER_HOME" \
    -w "$CONTAINER_HOME" \
    "$IMAGE_NAME"
