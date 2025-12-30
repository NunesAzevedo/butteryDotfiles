#!/bin/bash
# ==============================================================================
# SCRIPT: install_packages.sh
# LOCATION: scripts/install_packages.sh
# DESCRIPTION: Installs system packages, flatpaks, and shell environments.
#              Supports Arch Linux (Pacman/AUR) and Fedora (DNF/COPR).
# ==============================================================================

set -e

# 1. Import Shared Library
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

# 2. Setup & Detection
detect_distro
SOURCE_DIR="$REPO_ROOT/os/$DISTRO"

# BRANDING: Use Yellow Header
log_header "Starting Package Restoration for: $DISTRO"
log_info "📂 Source Directory: $SOURCE_DIR"

# ==============================================================================
# HELPER: Install List
# ==============================================================================
# Generic function to install packages from a file using a given command.
install_list() {
    local list_file="$1"
    local install_cmd="$2"
    local label="$3"

    if [ ! -f "$list_file" ]; then
        log_warn "File not found: $(basename "$list_file"). Skipping $label."
        return
    fi

    log_info "Installing $label packages..."

    # Attempt batch installation first (faster)
    if $install_cmd -y $(grep -vE "^\s*#|^\s*$" "$list_file" | tr '\n' ' '); then
        log_success "All $label packages installed successfully."
    else
        log_error "Batch installation failed. Attempting one-by-one..."
        while read -r pkg; do
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            echo -n "Installing $pkg... "
            if $install_cmd -y "$pkg" &> /dev/null; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}FAIL${NC}"
                # Retry visibly for debugging
                $install_cmd -y "$pkg" || true
            fi
        done < "$list_file"
    fi
}

# ==============================================================================
# 3. ARCH LINUX INSTALLATION
# ==============================================================================
if [ "$DISTRO" == "arch" ]; then
    log_info "Syncing Pacman repositories..."
    sudo pacman -Sy --noconfirm

    # 3.1 Base Tools
    log_info "Installing base tools (git, base-devel, stow)..."
    sudo pacman -S --needed --noconfirm base-devel git stow

    # 3.2 Yay (AUR Helper) Bootstrap
    if ! command -v yay &> /dev/null; then
        log_warn "Yay not found. Bootstrapping..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm && cd -
        rm -rf /tmp/yay
        log_success "Yay installed."
    fi

    # 3.3 Native Packages
    # Note: Pacman syntax differs slightly, so we inline the command here
    if [ -f "$SOURCE_DIR/pkglist_native.txt" ]; then
        log_info "Installing Native Arch packages..."
        sudo pacman -S --needed --noconfirm - < "$SOURCE_DIR/pkglist_native.txt"
    fi

    # 3.4 AUR Packages
    if [ -f "$SOURCE_DIR/pkglist_aur.txt" ]; then
        log_info "Installing AUR packages..."
        # Filter out 'yay' if present to avoid conflicts
        grep -vE '^yay$' "$SOURCE_DIR/pkglist_aur.txt" > /tmp/aur_clean.txt
        yay -S --needed --noconfirm - < /tmp/aur_clean.txt
        rm /tmp/aur_clean.txt
    fi

# ==============================================================================
# 4. FEDORA INSTALLATION
# ==============================================================================
elif [ "$DISTRO" == "fedora" ]; then
    log_info "Configuring DNF..."

    # 4.1 Base Tools
    # 'util-linux-user' provides chsh, which is needed later.
    sudo dnf install -y git stow util-linux-user

    # 4.2 DNF Optimization (Parallel Downloads)
    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    fi

    # 4.3 Enable COPR Repositories
    # Reads repolist_copr.txt and enables them one by one
    COPR_REPO_LIST="$SOURCE_DIR/repolist_copr.txt"
    if [ -f "$COPR_REPO_LIST" ]; then
        log_info "Enabling COPR repositories..."
        while read -r repo; do
            [[ -z "$repo" || "$repo" =~ ^# ]] && continue
            log_info "Enabling $repo..."
            sudo dnf copr enable -y "$repo"
        done < "$COPR_REPO_LIST"
    fi

    # 4.4 Install Native Packages (Official Repos)
    install_list "$SOURCE_DIR/pkglist_dnf.txt" "sudo dnf install" "Fedora Native"

    # 4.5 Install COPR Packages
    install_list "$SOURCE_DIR/pkglist_copr.txt" "sudo dnf install" "Fedora COPR"
fi

# ==============================================================================
# 5. FLATPAK INSTALLATION
# ==============================================================================
FLATPAK_LIST="$SOURCE_DIR/pkglist_flatpak.txt"

if command -v flatpak &> /dev/null && [ -f "$FLATPAK_LIST" ]; then
    log_info "Configuring Flatpaks..."
    
    # Enable Flathub
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Read list and install
    APPS=$(grep -vE "^\s*#|^\s*$" "$FLATPAK_LIST" | tr '\n' ' ')
    if [ -n "$APPS" ]; then
        log_info "Installing Flatpak applications..."
        # --noninteractive ensures no prompts block the script
        flatpak install -y --noninteractive flathub $APPS
    else
        log_warn "Flatpak list is empty."
    fi
elif [ ! -f "$FLATPAK_LIST" ]; then
    log_warn "Flatpak list not found at $FLATPAK_LIST."
fi

# ==============================================================================
# 6. SHELL CONFIGURATION (Zsh & Oh My Posh)
# ==============================================================================
log_info "Configuring Shell Environment..."

# 6.1 Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Remove default .zshrc so Stow can link ours later
    if [ -f "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
    fi
else
    log_success "Oh My Zsh is already installed."
fi

# 6.2 Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
    log_info "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
else
    log_success "Oh My Posh is already installed."
fi

# Ensure OMP is in path (symlink if needed)
if [ -f "$HOME/.local/bin/oh-my-posh" ] && [ ! -f "/usr/bin/oh-my-posh" ]; then
    sudo ln -sf "$HOME/.local/bin/oh-my-posh" /usr/bin/oh-my-posh
fi

# 6.3 Set Default Shell
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
fi

log_success "Package installation complete!"
