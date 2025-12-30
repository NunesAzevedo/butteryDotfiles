#!/bin/bash
# ==============================================================================
# SCRIPT: install_system.sh
# LOCATION: os/fedora/system/install_system.sh
# DESCRIPTION: Applies system-level configurations for Fedora Linux.
#              Orchestrates specific configs (Fedora) and shared configs (Common).
# ==============================================================================

set -e

# 1. Import Shared Library
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="$CURRENT_DIR/../../../scripts/lib/utils.sh"

if [ -f "$LIB_PATH" ]; then
    source "$LIB_PATH"
else
    echo "❌ Error: Could not find utils.sh at $LIB_PATH"
    exit 1
fi

# BRANDING: Use Yellow Header
log_header "Applying System Configurations for Fedora Linux..."
log_warn "Root permissions are required for these operations."

# 2. Define Source Directories
FEDORA_SYS_DIR="$REPO_ROOT/os/fedora/system"
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
# 2. FEDORA SPECIFIC CONFIGURATIONS
# ==============================================================================
log_info "--- Applying Fedora Specific Configurations ---"

# 2.1 DNF Configuration
apply_config "$FEDORA_SYS_DIR/etc/dnf/dnf.conf" "/etc/dnf/dnf.conf" "DNF Config"

# 2.2 Bootloader (GRUB)
#     Updates defaults and regenerates the config using grub2-mkconfig (Fedora standard)
if apply_config "$FEDORA_SYS_DIR/etc/default/grub" "/etc/default/grub" "GRUB Config"; then
    
    if command -v grub2-mkconfig &> /dev/null; then
        log_info "    Updating GRUB configuration..."
        # On modern Fedora, this output path handles both BIOS and UEFI correctly.
        if sudo grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null; then
            log_success "    GRUB updated successfully."
        else
            log_error "    Failed to update GRUB."
        fi
    else
        log_warn "    'grub2-mkconfig' not found. Skipping update."
    fi
fi

log_success "System configurations applied successfully!"
