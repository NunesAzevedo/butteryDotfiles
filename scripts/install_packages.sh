#!/bin/bash
# ==============================================================================
# SCRIPT: install_packages.sh
# LOCATION: scripts/install_packages.sh
# DESCRIPTION: Installs system packages, flatpaks, and shell environments.
# ==============================================================================

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

detect_distro
SOURCE_DIR="$REPO_ROOT/os/$DISTRO"

log_header "Starting Package Restoration for: $DISTRO"

# ==============================================================================
# HELPER: Install List (Enhanced with Ignore Logic)
# ==============================================================================
install_list() {
    local list_file="$1"
    local install_cmd="$2"
    local label="$3"
    local ignore_file="$4" # Optional: Path to an ignore list

    if [ ! -f "$list_file" ]; then
        log_warn "File not found: $(basename "$list_file"). Skipping $label."
        return
    fi

    log_info "Processing $label packages..."

    # 1. Clean the list (remove comments and empty lines)
    local clean_list=$(grep -vE "^\s*#|^\s*$" "$list_file")

    # 2. Filter out ignored packages if ignore file exists
    if [ -n "$ignore_file" ] && [ -f "$ignore_file" ]; then
        log_info "Applying ignore list: $(basename "$ignore_file")..."
        # Grep -vFf uses the file as a list of fixed strings to exclude
        clean_list=$(echo "$clean_list" | grep -vFf "$ignore_file" || true)
    fi

    # 3. Convert to single line for batch install
    local batch_list=$(echo "$clean_list" | tr '\n' ' ')

    if [ -z "$batch_list" ]; then
        log_info "No packages to install for $label (after filtering)."
        return
    fi

    # 4. Attempt Batch Install
    log_info "Installing filtered list..."
    if $install_cmd -y $batch_list; then
        log_success "All $label packages installed successfully."
    else
        log_error "Batch installation failed. Attempting one-by-one..."
        
        # 5. Fallback loop (Iterate over the clean_list variable)
        echo "$clean_list" | while read -r pkg; do
            [[ -z "$pkg" ]] && continue
            $install_cmd -y "$pkg" || log_error "Failed to install package: $pkg"
        done
    fi
}

# ==============================================================================
# 3. ARCH LINUX INSTALLATION
# ==============================================================================
if [ "$DISTRO" == "arch" ]; then
    log_info "Initializing Arch Keyring..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -Sy --noconfirm
    sudo pacman -S --noconfirm archlinux-keyring

    log_info "Installing base tools..."
    sudo pacman -S --needed --noconfirm base-devel git stow unzip curl

    if ! command -v yay &> /dev/null; then
        log_warn "Yay not found. Bootstrapping..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm && cd -
        rm -rf /tmp/yay
        log_success "Yay installed."
    fi

    if [ -f "$SOURCE_DIR/pkglist_native.txt" ]; then
        log_info "Installing Native Arch packages..."
        grep -vE "^\s*#|^\s*$" "$SOURCE_DIR/pkglist_native.txt" | sudo pacman -S --needed --noconfirm -
    fi

    if [ -f "$SOURCE_DIR/pkglist_aur.txt" ]; then
        log_info "Installing AUR packages..."
        grep -vE "^\s*#|^\s*$" "$SOURCE_DIR/pkglist_aur.txt" | grep -vE '^yay$' > /tmp/aur_clean.txt
        if [ -s "/tmp/aur_clean.txt" ]; then
            yay -S --needed --noconfirm - < /tmp/aur_clean.txt
        fi
        rm -f /tmp/aur_clean.txt
    fi

# ==============================================================================
# 4. FEDORA INSTALLATION
# ==============================================================================
elif [ "$DISTRO" == "fedora" ]; then
    log_info "Configuring DNF..."

    sudo dnf install -y git stow util-linux-user unzip curl

    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    fi

    # --------------------------------------------------------------------------
    # 4.1 VS CODE SETUP (Manual Install as requested)
    # --------------------------------------------------------------------------
    log_info "Setting up VS Code Repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    
    # Check updates to refresh repo metadata
    sudo dnf check-update || true 
    
    # Explicitly install 'code' here (since it's ignored in the main list)
    log_info "Installing VS Code..."
    sudo dnf install -y code || log_error "Failed to install VS Code."

    # --------------------------------------------------------------------------
    # 4.2 GITKRAKEN SETUP (Direct RPM Download)
    # --------------------------------------------------------------------------
    if ! command -v gitkraken &> /dev/null; then
        log_info "Installing GitKraken (Latest RPM)..."
        # Download latest RPM to /tmp
        curl -L https://release.gitkraken.com/linux/gitkraken-amd64.rpm -o /tmp/gitkraken.rpm
        
        # Install using DNF (resolves dependencies automatically)
        if sudo dnf install -y /tmp/gitkraken.rpm; then
            log_success "GitKraken installed."
        else
            log_error "Failed to install GitKraken RPM."
        fi
        rm -f /tmp/gitkraken.rpm
    else
        log_success "GitKraken already installed."
    fi

    # --------------------------------------------------------------------------
    # 4.3 COPR & NATIVE PACKAGES
    # --------------------------------------------------------------------------
    COPR_REPO_LIST="$SOURCE_DIR/repolist_copr.txt"
    if [ -f "$COPR_REPO_LIST" ]; then
        log_info "Enabling COPR repositories..."
        while read -r repo || [ -n "$repo" ]; do
            [[ -z "$repo" || "$repo" =~ ^# ]] && continue
            sudo dnf copr enable -y "$repo"
        done < "$COPR_REPO_LIST"
    fi

    # Install packages with ignore logic
    IGNORE_FILE="$SOURCE_DIR/pkglist_ignore.txt"
    install_list "$SOURCE_DIR/pkglist_dnf.txt" "sudo dnf install" "Fedora Native" "$IGNORE_FILE"
    install_list "$SOURCE_DIR/pkglist_copr.txt" "sudo dnf install" "Fedora COPR" "$IGNORE_FILE"
fi

# ==============================================================================
# 5. FLATPAK INSTALLATION
# ==============================================================================
FLATPAK_LIST="$SOURCE_DIR/pkglist_flatpak.txt"

if command -v flatpak &> /dev/null && [ -f "$FLATPAK_LIST" ]; then
    log_info "Configuring Flatpaks..."
    
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        APPS=$(grep -vE "^\s*#|^\s*$" "$FLATPAK_LIST" | tr '\n' ' ')
        if [ -n "$APPS" ]; then
            log_info "Installing Flatpak applications..."
            flatpak install -y --noninteractive flathub $APPS || log_warn "Flatpak install encountered issues, continuing..."
        fi
    else
        log_warn "Failed to add Flathub remote. Skipping Flatpak installation."
    fi
fi

# ==============================================================================
# 6. SHELL CONFIGURATION (Zsh & Oh My Posh)
# ==============================================================================
log_info "Configuring Shell Environment..."

# 6.1 Oh My Zsh
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    log_info "Installing Oh My Zsh..."
    rm -rf "$HOME/.oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    if [ -f "$HOME/.zshrc" ]; then rm "$HOME/.zshrc"; fi
else
    log_success "Oh My Zsh is already installed."
fi

# 6.2 Oh My Posh
mkdir -p "$HOME/.local/bin"

if ! command -v oh-my-posh &> /dev/null; then
    log_info "Installing Oh My Posh..."
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
else
    log_success "Oh My Posh is already installed."
fi

if [ -f "$HOME/.local/bin/oh-my-posh" ] && [ ! -f "/usr/bin/oh-my-posh" ]; then
    sudo ln -sf "$HOME/.local/bin/oh-my-posh" /usr/bin/oh-my-posh || true
fi

# 6.4 Zsh Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_zsh_plugin() {
    local repo_url="$1"
    local plugin_name="$2"
    local target_dir="$ZSH_CUSTOM/plugins/$plugin_name"

    if [ ! -d "$target_dir" ]; then
        log_info "Cloning Zsh plugin: $plugin_name..."
        git clone "$repo_url" "$target_dir" --depth 1 || log_error "Failed to clone $plugin_name"
    else
        log_success "Plugin $plugin_name already exists."
    fi
}

if [ -d "$HOME/.oh-my-zsh" ]; then
    install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
    install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"
fi

# 6.3 Set Default Shell
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Changing default shell to Zsh..."
    sudo chsh -s "$(which zsh)" "$USER" || true
fi

log_success "Package installation complete!"
