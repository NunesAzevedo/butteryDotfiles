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
# HELPER: Install List
# ==============================================================================
install_list() {
    local list_file="$1"
    local install_cmd="$2"
    local label="$3"

    if [ ! -f "$list_file" ]; then
        log_warn "File not found: $(basename "$list_file"). Skipping $label."
        return
    fi

    log_info "Installing $label packages..."
    # Reads the file, ignores comments (#) and empty lines, replaces newlines with spaces
    if $install_cmd -y $(grep -vE "^\s*#|^\s*$" "$list_file" | tr '\n' ' '); then
        log_success "All $label packages installed successfully."
    else
        log_error "Batch installation failed. Attempting one-by-one..."
        
        # Fallback loop: Try installing packages individually
        while read -r pkg || [ -n "$pkg" ]; do
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            
            # Log specific errors to the summary report instead of ignoring them
            $install_cmd -y "$pkg" || log_error "Failed to install package: $pkg"
        done < "$list_file"
    fi
}

# ==============================================================================
# 3. ARCH LINUX INSTALLATION
# ==============================================================================
if [ "$DISTRO" == "arch" ]; then
    log_info "Initializing Arch Keyring..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux

    log_info "Syncing Pacman repositories..."
    sudo pacman -Sy --noconfirm

    log_info "Refreshing Arch Keyring package..."
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
        
        # Check if file is not empty before running yay
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

    COPR_REPO_LIST="$SOURCE_DIR/repolist_copr.txt"
    if [ -f "$COPR_REPO_LIST" ]; then
        log_info "Enabling COPR repositories..."
        while read -r repo || [ -n "$repo" ]; do
            [[ -z "$repo" || "$repo" =~ ^# ]] && continue
            sudo dnf copr enable -y "$repo"
        done < "$COPR_REPO_LIST"
    fi

    install_list "$SOURCE_DIR/pkglist_dnf.txt" "sudo dnf install" "Fedora Native"
    install_list "$SOURCE_DIR/pkglist_copr.txt" "sudo dnf install" "Fedora COPR"
fi

# ==============================================================================
# 5. FLATPAK INSTALLATION (CORREÇÃO DA APOSTA)
# ==============================================================================
FLATPAK_LIST="$SOURCE_DIR/pkglist_flatpak.txt"

if command -v flatpak &> /dev/null && [ -f "$FLATPAK_LIST" ]; then
    log_info "Configuring Flatpaks..."
    
    # 1. TENTA adicionar o repositório.
    # O 'if' captura o código de saída. Se falhar, vai direto para o 'else'.
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        
        # 2. Só entra aqui se o remote-add funcionou.
        APPS=$(grep -vE "^\s*#|^\s*$" "$FLATPAK_LIST" | tr '\n' ' ')
        
        if [ -n "$APPS" ]; then
            log_info "Installing Flatpak applications..."
            # 3. Mesmo aqui dentro, usamos '|| log_warn' para que um erro de pacote não mate o script.
            flatpak install -y --noninteractive flathub $APPS || log_warn "Flatpak install encountered issues, continuing..."
        fi
    else
        # 4. Se o remote-add falhou, avisamos e PULAMOS a instalação.
        # Isso garante que o script continue para a seção 6 (Shell).
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

# Ensure OMP is in path
if [ -f "$HOME/.local/bin/oh-my-posh" ] && [ ! -f "/usr/bin/oh-my-posh" ]; then
    sudo ln -sf "$HOME/.local/bin/oh-my-posh" /usr/bin/oh-my-posh
fi

# 6.4 Zsh Plugins (Auto-Install commonly used plugins)
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
