#!/bin/bash

# ==============================================================================
# SCRIPT: install_system.sh
# DESCRIPTION:
#   Applies system-level configurations (root owned files) from the repository
#   to the host machine (/etc/...).
#
# ACTIONS:
#   1. Backs up existing system files to .bak
#   2. Copies new configs from ./etc/ to /etc/ using sudo
#   3. Reloads necessary services (keyd) or updates bootloader (grub)
#
# USAGE:
#   ./install_system.sh
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Determine the absolute path of the script directory to locate config files correctly
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}🧈 Applying System Configurations (Root Permissions Required)...${NC}"

# ==============================================================================
# HELPER FUNCTION
# ==============================================================================
apply_config() {
    local source_file="$1"
    local dest_file="$2"
    local label="$3"

    # Check if the source file exists in the repository
    if [ -f "$source_file" ]; then
        echo -e "${YELLOW}--> Configuring $label...${NC}"

        # Create a backup of the existing system file if it exists
        if [ -f "$dest_file" ] && [ ! -f "$dest_file.bak" ]; then
            echo "    Creating backup at $dest_file.bak"
            sudo cp "$dest_file" "$dest_file.bak"
        fi

        # Ensure destination directory exists
        sudo mkdir -p "$(dirname "$dest_file")"

        # Copy the file
        if sudo cp "$source_file" "$dest_file"; then
            echo -e "${GREEN}    $label updated successfully.${NC}"
            return 0
        else
            echo -e "${RED}    Failed to copy $label.${NC}"
            return 1
        fi
    else
        echo -e "${RED}!! Source file not found: $source_file (Skipping $label)${NC}"
        return 1
    fi
}

# ==============================================================================
# 1. PACKAGE MANAGEMENT (Pacman & Makepkg)
# ==============================================================================
# Applies optimizations (parallel downloads, colors) and build flags (nproc)
apply_config "$BASE_DIR/etc/pacman.conf" "/etc/pacman.conf" "Pacman Config"
apply_config "$BASE_DIR/etc/makepkg.conf" "/etc/makepkg.conf" "Makepkg Config"

# ==============================================================================
# 2. KEYBOARD REMAPPING (Keyd)
# ==============================================================================
# Applies CapsLock remapping. Service needs restart to take effect.
if apply_config "$BASE_DIR/etc/keyd/default.conf" "/etc/keyd/default.conf" "Keyd Config"; then
    echo "    Reloading keyd service..."
    # Try to enable and restart; ignore errors if keyd isn't installed
    sudo systemctl enable keyd &>/dev/null || true
    sudo systemctl restart keyd &>/dev/null || true
fi

# ==============================================================================
# 3. BOOTLOADER (GRUB)
# ==============================================================================
# Applies timeout and visual settings. Grub must be updated afterwards.
if apply_config "$BASE_DIR/etc/default/grub" "/etc/default/grub" "GRUB Config"; then
    
    if command -v grub-mkconfig &> /dev/null; then
        echo -e "${YELLOW}    Updating GRUB configuration (this may take a moment)...${NC}"
        if sudo grub-mkconfig -o /boot/grub/grub.cfg > /dev/null; then
            echo -e "${GREEN}    GRUB updated successfully.${NC}"
        else
            echo -e "${RED}    Failed to update GRUB.${NC}"
        fi
    else
        echo -e "${YELLOW}    ⚠️  'grub-mkconfig' not found. Skipping bootloader update (Expected in Docker/Chroot).${NC}"
    fi
    # ======================
    
fi

# ==============================================================================
# 4. MKINITCPIO (Optional / Commented)
# ==============================================================================
# Uncomment if you add gpu drivers or modules to your config in the future.
# if apply_config "$BASE_DIR/etc/mkinitcpio.conf" "/etc/mkinitcpio.conf" "Mkinitcpio"; then
#     echo -e "${YELLOW}    Regenerating initramfs...${NC}"
#     sudo mkinitcpio -P
# fi

echo -e "${GREEN}✅ All system configurations applied!${NC}"
