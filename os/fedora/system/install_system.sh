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
# 0. PRE-REQUISITES (CRITICAL FIX)
# ==============================================================================
# Installs 'diffutils' (for 'cmp' command used in utils.sh) and other core tools
# immediately to prevent script failure during check_and_update.
log_info "Installing core system tools..."
sudo dnf install -y git stow util-linux-user unzip curl diffutils

# ==============================================================================
# 1. COMMON CONFIGURATIONS (Shared)
# ==============================================================================
# Integrating the common keyd config
KEYD_CONF_SRC="$COMMON_SYS_DIR/etc/keyd/default.conf"
KEYD_CONF_DEST="/etc/keyd/default.conf"

# check_and_update returns: 0=changed, 1=no change, 2=critical error
check_and_update "$KEYD_CONF_DEST" "$KEYD_CONF_SRC" "Keyd Config" "required"
keyd_result=$?

if [ $keyd_result -eq 2 ]; then
    log_error "Keyd configuration is missing! Check os/common/system/etc/keyd/default.conf"
    # Continue anyway - don't exit, let user see full report
elif [ $keyd_result -eq 0 ]; then
    log_info "    Reloading keyd service..."
    if command -v keyd &> /dev/null; then
        sudo systemctl enable --now keyd &>/dev/null || log_warn "Failed to enable keyd service"
        sudo keyd reload &>/dev/null || log_warn "Failed to reload keyd"
    else
        log_warn "keyd command not found. Install keyd package first."
    fi
fi

# ==============================================================================
# 2. DNF CONFIGURATION
# ==============================================================================
DNF_CONF_SRC="$SOURCE_DIR/etc/dnf/dnf.conf"
DNF_CONF_DEST="/etc/dnf/dnf.conf"

if check_and_update "$DNF_CONF_DEST" "$DNF_CONF_SRC" "DNF Config"; then
    log_success "DNF configuration updated."
fi

# ==============================================================================
# 3. GRUB CONFIGURATION
# ==============================================================================
GRUB_CONF_SRC="$SOURCE_DIR/etc/default/grub"
GRUB_CONF_DEST="/etc/default/grub"

if check_and_update "$GRUB_CONF_DEST" "$GRUB_CONF_SRC" "GRUB Config"; then
    if command -v grub2-mkconfig &> /dev/null; then
        log_info "Backing up current GRUB config..."
        # Create a timestamped backup before regenerating (Fedora uses /boot/grub2)
        sudo cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak-$(date +%s)
        
        log_info "Regenerating GRUB bootloader config..."
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg || log_error "Failed to regenerate GRUB config."
    else
        log_warn "grub2-mkconfig command not found. Skipping bootloader update."
    fi
fi

log_success "Fedora system configuration finished."
