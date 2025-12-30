#!/bin/bash
# ==============================================================================
# SCRIPT: utils.sh
# LOCATION: scripts/lib/utils.sh
# DESCRIPTION: Shared library for colors, path resolution, and helper functions.
#              Imported by all automation scripts.
# ==============================================================================

# ==============================================================================
# 1. COLORS
# ==============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export VIOLET='\033[0;35m'
export NC='\033[0m'

# ==============================================================================
# 2. REPOSITORY ROOT RESOLUTION
# ==============================================================================
# Navigates up 2 levels from 'scripts/lib/' to find the project root.
export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ==============================================================================
# 3. LOGGING HELPERS
# ==============================================================================
log_info() { echo -e "${CYAN}--> $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# BRANDING HEADER (Yellow/Buttery)
# Used for main script titles to maintain visual identity.
log_header() { echo -e "${YELLOW}🧈 $1${NC}"; }

# ==============================================================================
# 4. DISTRIBUTION DETECTION
# ==============================================================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        export DISTRO=$ID
        log_info "Distro detected: $DISTRO"
    else
        log_error "Could not detect distribution via /etc/os-release."
        exit 1
    fi
}

# ==============================================================================
# 5. SMART BACKUP FUNCTION (Check & Update)
# ==============================================================================
# Compares a generated temp file with the existing repo file.
# Updates only if content differs (prevents unnecessary git diffs).
export CHANGES_DETECTED=0

check_and_update() {
    local repo_file="$1"
    local temp_file="$2"
    local label="$3"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$repo_file")"

    # Scenario A: File doesn't exist yet
    if [ ! -f "$repo_file" ]; then
        log_warn "🆕 $label: File created (did not exist)."
        mv "$temp_file" "$repo_file"
        CHANGES_DETECTED=1
        return
    fi

    # Scenario B: File exists, check content
    if cmp -s "$repo_file" "$temp_file"; then
        log_success "$label: No changes detected."
        rm "$temp_file" # Clean up temp
    else
        log_info "🔄 $label: Changes detected! Updating file..."
        mv "$temp_file" "$repo_file"
        CHANGES_DETECTED=1
    fi
}
