#!/bin/bash
# ==============================================================================
# SCRIPT: docker/start_test.sh
# DESCRIPTION: Helper to build and run Docker test environments for ButteryDotfiles.
# USAGE: ./docker/start_test.sh [arch|fedora]
# ==============================================================================

set -e

# 1. Navigation & Checks
#    Ensure we are running from the repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Import Utils for colors (optional, but consistent)
if [ -f "scripts/lib/utils.sh" ]; then
    source "scripts/lib/utils.sh"
else
    # Fallback definition if utils not found
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

if [[ "$TARGET" != "arch" && "$TARGET" != "fedora" ]]; then
    log_error "Usage: $0 [arch|fedora]"
    exit 1
fi

DOCKERFILE="docker/Dockerfile.$TARGET"
IMAGE_NAME="buttery_${TARGET}_test"
CONTAINER_HOME="/home/tester/butteryDotfiles"

# 3. Build Image
log_header "Building Docker Image for: $TARGET"
log_info "Using $DOCKERFILE..."

docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" .

# 4. Run Container
log_header "Starting Container..."
log_info "Mounting current directory to: $CONTAINER_HOME"
log_info "Entering interactive shell..."
echo ""

# EXPLANATION OF FLAGS:
# -it: Interactive terminal
# --rm: Remove container after exit (keep things clean)
# --privileged: Needed for some package manager operations (pacman keys/chroot)
# -v: Syncs your actual code with the container (live edits!)
# -w: Sets the working directory inside
docker run -it --rm --privileged \
    -v "$REPO_ROOT:$CONTAINER_HOME" \
    -w "$CONTAINER_HOME" \
    "$IMAGE_NAME"
