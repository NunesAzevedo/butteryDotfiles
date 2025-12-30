#!/bin/bash
# ==============================================================================
# SCRIPT: utils.sh
# LOCATION: scripts/lib/utils.sh
# DESCRIPTION: Shared library for colors, path resolution, and helper functions.
# ==============================================================================

# ==============================================================================
# 1. COLORS
# ==============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m'

# ==============================================================================
# 2. REPOSITORY ROOT RESOLUTION
# ==============================================================================
# Resolves the root directory relative to this script location
export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Temporary file to track errors across all scripts for the final summary.
# Uses ${USER} to avoid permission conflicts on multi-user systems.
export ERROR_LOG_TRACKER="/tmp/buttery_install_errors_${USER}.tmp"

# ==============================================================================
# 3. LOGGING HELPERS
# ==============================================================================
log_header() { 
    echo -e "\n${YELLOW}${BOLD}🧈 $1${NC}" 
}

log_info() { 
    echo -e "${BLUE}-->${NC} $1" 
}

log_success() { 
    echo -e "${GREEN}✅ $1${NC}" 
}

log_warn() { 
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}" 
}

log_error() { 
    echo -e "${RED}❌ ERROR: $1${NC}"
    # Appends the error message to the tracker file for the final summary report
    echo "❌ $1" >> "$ERROR_LOG_TRACKER"
}

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
# 5. SMART INSTALL FUNCTION (With Auto-Sudo, Copy & Backup)
# ==============================================================================
# Global flag to track if any backup/copy operation resulted in changes
export CHANGES_DETECTED=0

check_and_update() {
    local target_dest="$1"  # The destination on the system (e.g., /etc/pacman.conf)
    local source_file="$2"  # The file in your repo
    local label="$3"
    local target_dir
    target_dir=$(dirname "$target_dest")

    # Helper: Tries to create dir as user, falls back to sudo if denied
    ensure_dir() {
        if [ ! -d "$1" ]; then
            mkdir -p "$1" 2>/dev/null || sudo mkdir -p "$1"
        fi
    }

    # Helper: Creates a .bak copy of the existing target before overwriting
    # This prevents data loss if the user had custom configs.
    create_backup() {
        local file="$1"
        if [ -f "$file" ]; then
            # Silent backup: tries user copy, then sudo copy
            cp "$file" "$file.bak" 2>/dev/null || sudo cp "$file" "$file.bak"
        fi
    }

    # Helper: Tries to COPY file as user, falls back to sudo if denied
    try_copy() {
        # cp -f forces overwrite if needed
        cp -f "$1" "$2" 2>/dev/null || sudo cp -f "$1" "$2"
    }

    ensure_dir "$target_dir"

    # Case 1: File doesn't exist (New file)
    if [ ! -f "$target_dest" ]; then
        log_warn "🆕 $label: File created (did not exist)."
        
        if try_copy "$source_file" "$target_dest"; then
             CHANGES_DETECTED=1
        else
             log_error "Failed to create $target_dest (Permission denied?)"
        fi
        return
    fi

    # Case 2: File exists. Check for differences.
    if cmp -s "$target_dest" "$source_file"; then
        log_success "$label: No changes detected."
    else
        log_info "🔄 $label: Changes detected! Updating file..."
        
        # CRITICAL FIX: Backup the original system file before overwriting
        create_backup "$target_dest"
        
        if try_copy "$source_file" "$target_dest"; then
             CHANGES_DETECTED=1
             log_info "    (Backup created at $target_dest.bak)"
        else
             log_error "Failed to update $target_dest (Permission denied?)"
        fi
    fi
}
