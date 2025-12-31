#!/bin/bash
# ==============================================================================
# SCRIPT: install_system.sh (Arch Linux)
# LOCATION: os/arch/system/install_system.sh
# DESCRIPTION: Applies system-wide configurations for Arch Linux.
#              - Keyd (Input Remapping) - Shared
#              - Pacman Configuration (Parallel downloads, colors, multilib)
#              - GRUB Configuration (Theming, timeouts)
# ==============================================================================

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Import Shared Library
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

log_header "Configuring Arch Linux System..."

# ==============================================================================
# 1. COMMON CONFIGURATIONS (Shared)
# ==============================================================================
# Integrating the 'ghost file' found in tree.txt
KEYD_CONF_SRC="$COMMON_SYS_DIR/etc/keyd/default.conf"
KEYD_CONF_DEST="/etc/keyd/default.conf"

if [ -f "$KEYD_CONF_SRC" ]; then
    CHANGES_DETECTED=0 # Reset state
    check_and_update "$KEYD_CONF_DEST" "$KEYD_CONF_SRC" "Keyd Config"
    
    # Reload keyd if changed
    if [ "$CHANGES_DETECTED" -eq 1 ] || ! systemctl is-active --quiet keyd; then
        log_info "    Reloading keyd service..."
        # Try to enable/reload, harmless fail if keyd isn't installed
        sudo systemctl enable --now keyd &>/dev/null || true
        sudo keyd reload &>/dev/null || true
    fi
fi

# ==============================================================================
# 2. PACMAN CONFIGURATION
# ==============================================================================
# FIX: Adjusted path to match tree structure (added /etc/)
PACMAN_CONF_SRC="$SOURCE_DIR/etc/pacman.conf"
PACMAN_CONF_DEST="/etc/pacman.conf"

if [ -f "$PACMAN_CONF_SRC" ]; then
    CHANGES_DETECTED=0 # Reset state
    check_and_update "$PACMAN_CONF_DEST" "$PACMAN_CONF_SRC" "Pacman Config"
    
    # FIX: Force sync if config changed to enable multilib immediately
    # This prevents "target not found: steam" errors later
    if [ "$CHANGES_DETECTED" -eq 1 ]; then
        log_info "Pacman config updated. Syncing repositories..."
        sudo pacman -Sy
    fi
else
    log_warn "pacman.conf not found in repository ($PACMAN_CONF_SRC). Skipping."
fi

# ==============================================================================
# 3. GRUB CONFIGURATION
# ==============================================================================
# FIX: Adjusted path to match tree structure (added /etc/default/)
GRUB_CONF_SRC="$SOURCE_DIR/etc/default/grub"
GRUB_CONF_DEST="/etc/default/grub"

if [ -f "$GRUB_CONF_SRC" ]; then
    CHANGES_DETECTED=0

    check_and_update "$GRUB_CONF_DEST" "$GRUB_CONF_SRC" "GRUB Config"

    # Only regenerate GRUB if changes were made specifically to the GRUB file
    if [ "$CHANGES_DETECTED" -eq 1 ]; then
        if command -v grub-mkconfig &> /dev/null; then
            log_info "Regenerating GRUB bootloader config..."
            sudo grub-mkconfig -o /boot/grub/grub.cfg || log_error "Failed to regenerate GRUB config."
        else
            log_warn "grub-mkconfig command not found. Skipping bootloader update."
        fi
    fi
else
    log_warn "GRUB config file not found in repository ($GRUB_CONF_SRC). Skipping."
fi

log_success "Arch system configuration finished."
