#!/bin/bash
# ==============================================================================
# SCRIPT: install_system.sh (Fedora)
# LOCATION: os/fedora/system/install_system.sh
# DESCRIPTION: Applies system-wide configurations for Fedora.
#              - Keyd (Input Remapping) - Shared
#              - DNF Configuration (Parallel downloads, fast mirrors)
#              - GRUB Configuration (Theming, timeouts)
# ==============================================================================

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Import Shared Library
#    Adjust relative path to reach scripts/lib/utils.sh
UTILS_PATH="$CURRENT_DIR/../../../scripts/lib/utils.sh"

if [ -f "$UTILS_PATH" ]; then
    source "$UTILS_PATH"
else
    echo -e "\033[0;31m❌ Error: utils.sh not found at $UTILS_PATH\033[0m"
    exit 1
fi

SOURCE_DIR="$CURRENT_DIR"
# Define path to Common configurations based on tree structure
COMMON_SYS_DIR="$CURRENT_DIR/../../../os/common/system"

log_header "Configuring Fedora System..."

# ==============================================================================
# 1. COMMON CONFIGURATIONS (Shared)
# ==============================================================================
# Integrating the common keyd config
KEYD_CONF_SRC="$COMMON_SYS_DIR/etc/keyd/default.conf"
KEYD_CONF_DEST="/etc/keyd/default.conf"

if [ -f "$KEYD_CONF_SRC" ]; then
    CHANGES_DETECTED=0 # Reset state
    check_and_update "$KEYD_CONF_DEST" "$KEYD_CONF_SRC" "Keyd Config"
    
    # Reload keyd if changed
    if [ "$CHANGES_DETECTED" -eq 1 ] || ! systemctl is-active --quiet keyd; then
        log_info "    Reloading keyd service..."
        sudo systemctl enable --now keyd &>/dev/null || true
        sudo keyd reload &>/dev/null || true
    fi
fi

# ==============================================================================
# 2. DNF CONFIGURATION
# ==============================================================================
# FIX: Adjusted path to match tree structure (added /etc/dnf/)
DNF_CONF_SRC="$SOURCE_DIR/etc/dnf/dnf.conf"
DNF_CONF_DEST="/etc/dnf/dnf.conf"

if [ -f "$DNF_CONF_SRC" ]; then
    # Reset flag to ensure isolation (prevents false positives from previous steps)
    CHANGES_DETECTED=0
    
    # check_and_update handles backups, sudo, and copy automatically
    check_and_update "$DNF_CONF_DEST" "$DNF_CONF_SRC" "DNF Config"
else
    log_warn "dnf.conf not found in repository ($DNF_CONF_SRC). Skipping."
fi

# ==============================================================================
# 3. GRUB CONFIGURATION
# ==============================================================================
# FIX: Adjusted path to match tree structure (added /etc/default/)
GRUB_CONF_SRC="$SOURCE_DIR/etc/default/grub"
GRUB_CONF_DEST="/etc/default/grub"

if [ -f "$GRUB_CONF_SRC" ]; then
    # FIX: Reset flag so DNF changes don't trigger GRUB regeneration falsely
    CHANGES_DETECTED=0
    
    check_and_update "$GRUB_CONF_DEST" "$GRUB_CONF_SRC" "GRUB Config"

    # Only regenerate GRUB if changes were made specifically to the GRUB file
    if [ "$CHANGES_DETECTED" -eq 1 ]; then
        if command -v grub2-mkconfig &> /dev/null; then
            log_info "Regenerating GRUB bootloader config..."
            # Capture failure in the error report (|| log_error)
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg || log_error "Failed to regenerate GRUB config."
        else
            log_warn "grub2-mkconfig command not found. Skipping bootloader update."
        fi
    fi
else
    log_warn "GRUB config file not found in repository ($GRUB_CONF_SRC). Skipping."
fi

log_success "Fedora system configuration finished."
