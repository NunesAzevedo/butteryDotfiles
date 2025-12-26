#!/bin/bash

# ==============================================================================
# SCRIPT: install_packages.sh
# DESCRIPTION:
#   Automates the installation of system packages on a new Arch Linux setup.
#   1. Ensures 'base-devel' is installed (required for compiling AUR packages).
#   2. Checks for 'yay' (AUR Helper). If missing, installs it manually from AUR.
#   3. Installs official repository packages from 'pkglist_native.txt'.
#   4. Installs AUR packages from 'pkglist_aur.txt'.
#
# USAGE:
#   ./install_packages.sh
#
# NOTES:
#   - Run this script from the root of your dotfiles repository.
#   - Requires sudo privileges.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

echo "🧈 Starting butteryDotfiles package restoration..."

# 1. Ensure base-devel is installed
# Even if 'base' is installed, 'base-devel' might be missing. It's required for 'makepkg'.
echo "--> Checking/Installing base-devel..."
sudo pacman -S --needed --noconfirm base-devel

# 2. Bootstrapping Yay (AUR Helper)
# We need Yay to install the AUR packages listed in the text file.
if ! command -v yay &> /dev/null; then
    echo "--> Yay not found. Bootstrapping installation from AUR..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf /tmp/yay
    echo "--> Yay installed successfully."
else
    echo "--> Yay is already installed."
fi

# 3. Install Native Packages (Official Repos)
if [ -f pkglist_native.txt ]; then
    echo "--> Installing native packages from pkglist_native.txt..."
    sudo pacman -S --needed --noconfirm - < pkglist_native.txt
else
    echo "!! pkglist_native.txt not found. Skipping."
fi

# 4. Install AUR Packages
if [ -f pkglist_aur.txt ]; then
    echo "--> Installing AUR packages from pkglist_aur.txt..."
    # Removing 'yay' from the list if present to avoid redundancy/locks
    sed '/^yay$/d' pkglist_aur.txt | yay -S --needed --noconfirm -
else
    echo "!! pkglist_aur.txt not found. Skipping."
fi

echo "✅ All packages installed successfully! Time to butter the toast 🧈."

