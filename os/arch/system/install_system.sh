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
# 2. PACMAN CONFIGURATION
# ==============================================================================
PACMAN_CONF_SRC="$SOURCE_DIR/etc/pacman.conf"
PACMAN_CONF_DEST="/etc/pacman.conf"

if check_and_update "$PACMAN_CONF_DEST" "$PACMAN_CONF_SRC" "Pacman Config"; then
    log_info "Pacman config updated. Syncing repositories..."
    # Force sync to enable multilib immediately
    sudo pacman -Sy
fi

# ==============================================================================
# 3. GRUB CONFIGURATION
# ==============================================================================
GRUB_CONF_SRC="$SOURCE_DIR/etc/default/grub"
GRUB_CONF_DEST="/etc/default/grub"

if check_and_update "$GRUB_CONF_DEST" "$GRUB_CONF_SRC" "GRUB Config"; then
    if command -v grub-mkconfig &> /dev/null; then
        log_info "Backing up current GRUB config..."
        # Create a timestamped backup before regenerating
        sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak-$(date +%s)
        
        log_info "Regenerating GRUB bootloader config..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg || log_error "Failed to regenerate GRUB config."
    else
        log_warn "grub-mkconfig command not found. Skipping bootloader update."
    fi
fi

# ==============================================================================
# 4. rEFInd BOOT MANAGER CONFIGURATION
# ==============================================================================
REFIND_SRC_DIR="$COMMON_SYS_DIR/boot/efi/EFI/refind"
REFIND_DEST_DIR="/boot/efi/EFI/refind"

if [ -d "$REFIND_DEST_DIR" ]; then
    log_info "rEFInd detected. Applying configuration..."
    
    # Update refind.conf
    if check_and_update "$REFIND_DEST_DIR/refind.conf" "$REFIND_SRC_DIR/refind.conf" "rEFInd Config"; then
        log_success "rEFInd configuration updated."
    fi
    
    # Sync themes directory
    if [ -d "$REFIND_SRC_DIR/themes" ]; then
        log_info "Syncing rEFInd themes..."
        sudo cp -r "$REFIND_SRC_DIR/themes/"* "$REFIND_DEST_DIR/themes/" 2>/dev/null || true
        log_success "rEFInd themes synced."
    fi
else
    log_info "rEFInd not installed at $REFIND_DEST_DIR. Skipping."
fi

log_success "Arch system configuration finished."
