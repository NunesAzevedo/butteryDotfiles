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
    # Log to tracker file for final summary
    echo "$1" >> "$ERROR_LOG_TRACKER"
}

# ==============================================================================
# 4. DISTRO DETECTION
# ==============================================================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        log_info "Distro detected: $DISTRO"
    else
        log_error "Cannot detect Linux distribution."
        exit 1
    fi
}

# ==============================================================================
# 5. CONFIGURATION MANAGER (CORE LOGIC)
# ==============================================================================
# Compares source and destination files.
# If different: Creates backup, Overwrites destination, Returns 0 (True).
# If identical: Does nothing, Returns 1 (False).
#
# ARGUMENTS:
#   $1 - target_dest: Destination path (e.g., /etc/keyd/default.conf)
#   $2 - source_file: Source file in the repository
#   $3 - label: Human-readable name for logging
#   $4 - required: (optional) "required" to treat missing source as ERROR
#
# RETURNS:
#   0 - Changes were made (file created or updated)
#   1 - No changes (file identical or source missing)
#   2 - Critical error (required file missing)
#
check_and_update() {
    local target_dest="$1"
    local source_file="$2"
    local label="$3"
    local required="${4:-optional}"  # Default: optional (backward compatible)

    # Helper: Ensures the directory exists
    ensure_dir() {
        local dir=$(dirname "$1")
        if [ ! -d "$dir" ]; then
            log_info "Creating directory: $dir"
            sudo mkdir -p "$dir"
        fi
    }

    # Helper: Creates a backup if the file exists
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

    # 1. Validate Source (IMPROVED: Distinguish required vs optional)
    if [ ! -f "$source_file" ]; then
        if [ "$required" == "required" ]; then
            log_error "$label: REQUIRED source file not found!"
            log_error "    Expected: $source_file"
            log_error "    This is a critical configuration. Please ensure the file exists."
            return 2 # Critical error
        else
            log_warn "$label: Source file not found ($source_file). Skipping."
            return 1 # No changes made (optional file)
        fi
    fi

    ensure_dir "$target_dest"

    # 2. Case: New File (Destination doesn't exist)
    if [ ! -f "$target_dest" ]; then
        log_warn "🆕 $label: File created (did not exist)."
        
        if try_copy "$source_file" "$target_dest"; then
             return 0 # SUCCESS: Changes happened
        else
             log_error "Failed to create $target_dest (Permission denied?)"
             return 1 # FAILURE
        fi
    fi

    # 3. Case: Update Existing (Compare content)
    if cmp -s "$target_dest" "$source_file"; then
        log_success "$label: No changes detected."
        return 1 # NO CHANGE
    else
        log_info "🔄 $label: Changes detected! Updating file..."
        log_info "    (Backup created at ${target_dest}.bak)"
        
        create_backup "$target_dest"
        
        if try_copy "$source_file" "$target_dest"; then
             return 0 # SUCCESS: Changes happened
        else
             log_error "Failed to update $target_dest"
             return 1 # FAILURE
        fi
    fi
}
