#!/bin/bash
# ==============================================================================
# SCRIPT: install_system.sh
# LOCATION: os/arch/system/install_system.sh
# DESCRIPTION: Applies system-level configurations for Arch Linux.
#              Orchestrates specific configs (Arch) and shared configs (Common).
# ==============================================================================

set -e

# 1. Import Shared Library
#    Locates the library relative to this script.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="$CURRENT_DIR/../../../scripts/lib/utils.sh"

if [ -f "$LIB_PATH" ]; then
    source "$LIB_PATH"
else
    echo "❌ Error: Could not find utils.sh at $LIB_PATH"
    exit 1
fi

# BRANDING: Use Yellow Header
log_header "Applying System Configurations for Arch Linux..."
log_warn "Root permissions are required for these operations."

# 2. Define Source Directories
#    Using REPO_ROOT from utils.sh makes paths absolute and safe.
ARCH_SYS_DIR="$REPO_ROOT/os/arch/system"
COMMON_SYS_DIR="$REPO_ROOT/os/common/system"

# ==============================================================================
# HELPER: apply_config
# ==============================================================================
apply_config() {
    local source_file="$1"
    local dest_file="$2"
    local label="$3"

    if [ -f "$source_file" ]; then
        log_info "Configuring $label..."

        # Backup logic
        if [ -f "$dest_file" ] && [ ! -f "$dest_file.bak" ]; then
            echo "    -> Creating backup at $dest_file.bak"
            sudo cp "$dest_file" "$dest_file.bak"
        fi

        # Copy logic
        sudo mkdir -p "$(dirname "$dest_file")"
        if sudo cp "$source_file" "$dest_file"; then
            log_success "    $label updated."
            return 0
        else
            log_error "    Failed to copy $label."
            return 1
        fi
    else
        log_warn "Source file not found: $source_file. Skipping $label."
        return 1
    fi
}

# ==============================================================================
# 1. COMMON CONFIGURATIONS (Shared)
# ==============================================================================
log_info "--- Applying Shared Configurations ---"

# 1.1 Keyd (Keyboard Remapping)
#     Loaded from os/common/system/etc/keyd/default.conf
if apply_config "$COMMON_SYS_DIR/etc/keyd/default.conf" "/etc/keyd/default.conf" "Keyd Config"; then
    log_info "    Reloading keyd service..."
    
    systemctl daemon-reload &>/dev/null || true
    if systemctl enable --now keyd &>/dev/null; then
        log_success "    Keyd service enabled and started."
    else
        log_warn "    Warning: Could not enable Keyd (systemd not found?)"
    fi
    keyd reload &>/dev/null || true
fi

# ==============================================================================
# 2. ARCH SPECIFIC CONFIGURATIONS
# ==============================================================================
log_info "--- Applying Arch Specific Configurations ---"

# 2.1 Package Management
apply_config "$ARCH_SYS_DIR/etc/pacman.conf" "/etc/pacman.conf" "Pacman Config"
apply_config "$ARCH_SYS_DIR/etc/makepkg.conf" "/etc/makepkg.conf" "Makepkg Config"

# 2.2 Bootloader (GRUB)
if apply_config "$ARCH_SYS_DIR/etc/default/grub" "/etc/default/grub" "GRUB Config"; then
    
    if command -v grub-mkconfig &> /dev/null; then
        log_info "    Updating GRUB configuration..."
        if sudo grub-mkconfig -o /boot/grub/grub.cfg > /dev/null; then
            log_success "    GRUB updated successfully."
        else
            log_error "    Failed to update GRUB."
        fi
    else
        log_warn "    'grub-mkconfig' not found. Skipping update."
    fi
fi

# 2.3 Mkinitcpio (Optional - Commented out)
# if apply_config "$ARCH_SYS_DIR/etc/mkinitcpio.conf" "/etc/mkinitcpio.conf" "Mkinitcpio"; then
#     log_info "    Regenerating initramfs..."
#     sudo mkinitcpio -P
# fi

log_success "System configurations applied successfully!"
