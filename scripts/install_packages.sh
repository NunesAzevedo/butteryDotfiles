#!/bin/bash
# ==============================================================================
# SCRIPT: install_packages.sh
# LOCATION: scripts/install_packages.sh
# DESCRIPTION: Installs system packages, flatpaks, and shell environments.
#              - Handles Arch (Pacman/AUR) & Fedora (DNF/COPR)
#              - FEATURES: CRLF Fix & Smart Diff (Only installs missing pkgs)
# ==============================================================================

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

detect_distro
SOURCE_DIR="$REPO_ROOT/os/$DISTRO"

# FIX: Robust User Detection (Crucial for Docker/Sudo contexts)
TARGET_USER="${SUDO_USER:-${USER}}"
if [ -z "$TARGET_USER" ]; then TARGET_USER=$(whoami); fi

log_header "Starting Package Restoration for: $DISTRO"

# ==============================================================================
# HELPER: Smart Install List (Diff Strategy)
# ==============================================================================
# Arguments:
# 1. List File Path
# 2. Install Command (e.g., "sudo dnf install")
# 3. Label (for logging)
# 4. Ignore File (optional)
# 5. Check Command (optional - command to list currently installed pkgs)
install_list() {
    local list_file="$1"
    local install_cmd="$2"
    local label="$3"
    local ignore_file="$4"
    local check_cmd="$5"

    if [ ! -f "$list_file" ]; then
        log_warn "File not found: $(basename "$list_file"). Skipping $label."
        return
    fi

    log_info "Processing $label packages..."

    # 1. Clean the list: Remove comments, empty lines, and FIX WINDOWS CRLF (\r)
    local desired_list=$(grep -vE "^\s*#|^\s*$" "$list_file" | tr -d '\r' | sort -u)

    # 2. Filter out ignored packages
    if [ -n "$ignore_file" ] && [ -f "$ignore_file" ]; then
        log_info "Applying ignore list: $(basename "$ignore_file")..."
        # FIX: Clean ignore file too - remove comments and empty lines before using as filter
        local clean_ignore="/tmp/clean_ignore_$$.tmp"
        grep -vE "^\s*#|^\s*$" "$ignore_file" | tr -d '\r' > "$clean_ignore"
        if [ -s "$clean_ignore" ]; then
            desired_list=$(echo "$desired_list" | grep -vFxf "$clean_ignore" || true)
        fi
        rm -f "$clean_ignore"
    fi

    if [ -z "$desired_list" ]; then
        log_info "No packages found in list for $label."
        return
    fi

    # 3. SMART DIFF: Filter out already installed packages
    local missing_list="$desired_list"
    
    if [ -n "$check_cmd" ]; then
        log_info "Checking installed packages (Diff Strategy)..."
        
        # Create temp files for comparison
        local tmp_installed="/tmp/installed_pkgs_$$.tmp"
        local tmp_desired="/tmp/desired_pkgs_$$.tmp"
        
        # FIX: Execute check command using bash -c to handle special characters properly
        # This ensures rpm -qa --qf '%{NAME}\n' works correctly
        bash -c "$check_cmd" 2>/dev/null | sort -u > "$tmp_installed"
        echo "$desired_list" > "$tmp_desired"
        
        # DEBUG: Log counts for verification
        local installed_count=$(wc -l < "$tmp_installed")
        local desired_count=$(wc -l < "$tmp_desired")
        log_info "    Found $installed_count installed packages, $desired_count desired packages"
        
        # comm -23: Show lines unique to file 1 (Desired but NOT Installed)
        missing_list=$(comm -23 "$tmp_desired" "$tmp_installed")
        
        local missing_count=$(echo "$missing_list" | grep -c . || echo 0)
        log_info "    $missing_count packages need to be installed"
        
        # Cleanup
        rm -f "$tmp_installed" "$tmp_desired"
    fi

    # 4. Install Missing Packages
    # Convert newlines to spaces
    local batch_list=$(echo "$missing_list" | tr '\n' ' ')

    if [ -z "$batch_list" ]; then
        log_success "All packages for $label are already installed! Skipping."
        return
    fi

    log_info "Installing missing packages..."
    
    # =========================================================================
    # TWO-PHASE INSTALLATION STRATEGY
    # Phase 1: Batch install with --skip-broken (fast, installs most packages)
    # Phase 2: Re-check what's still missing and retry one-by-one (thorough)
    # =========================================================================
    
    # Phase 1: Fast batch install
    log_info "Phase 1: Batch installation (with --skip-broken for speed)..."
    $install_cmd -y --skip-broken $batch_list 2>&1 || true
    
    # Phase 2: Check what's still missing and retry individually
    if [ -n "$check_cmd" ]; then
        log_info "Phase 2: Verifying installation and retrying skipped packages..."
        
        # Re-check installed packages
        local tmp_now_installed="/tmp/now_installed_$$.tmp"
        bash -c "$check_cmd" 2>/dev/null | sort -u > "$tmp_now_installed"
        
        # Find what's STILL missing after batch
        local still_missing=$(comm -23 <(echo "$missing_list" | sort) "$tmp_now_installed")
        rm -f "$tmp_now_installed"
        
        local still_count=$(echo "$still_missing" | grep -c . || echo 0)
        
        if [ "$still_count" -gt 0 ]; then
            log_info "    $still_count packages still need attention. Installing one-by-one..."
            echo "$still_missing" | while read -r pkg; do
                [[ -z "$pkg" ]] && continue
                $install_cmd -y "$pkg" 2>&1 || log_error "Failed to install package: $pkg"
            done
        fi
    fi
    
    log_success "$label installation complete."
}

# ==============================================================================
# 3. ARCH LINUX INSTALLATION
# ==============================================================================
if [ "$DISTRO" == "arch" ]; then
    log_info "Initializing Arch Keyring..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -Sy --noconfirm --needed archlinux-keyring

    log_info "Installing base tools..."
    sudo pacman -S --needed --noconfirm base-devel git stow unzip curl

    # Yay Bootstrap
    if ! command -v yay &> /dev/null; then
        log_warn "Yay not found. Bootstrapping..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm && cd -
        rm -rf /tmp/yay
        log_success "Yay installed."
    fi

    # Native Packages (Smart Check: pacman -Qq)
    if [ -f "$SOURCE_DIR/pkglist_native.txt" ]; then
        install_list "$SOURCE_DIR/pkglist_native.txt" \
                     "sudo pacman -S --needed --noconfirm" \
                     "Arch Native" \
                     "" \
                     "pacman -Qq"
    fi

    # AUR Packages (Custom Logic with CRLF fix)
    if [ -f "$SOURCE_DIR/pkglist_aur.txt" ]; then
        log_info "Processing AUR packages..."
        # FIX: Added tr -d '\r'
        grep -vE "^\s*#|^\s*$" "$SOURCE_DIR/pkglist_aur.txt" | tr -d '\r' | grep -vE '^yay$' > /tmp/aur_full.txt
        
        # Filter installed AUR packages manually
        if [ -s "/tmp/aur_full.txt" ]; then
             # Get installed packages
             pacman -Qq > /tmp/installed_aur_check.tmp
             # Find missing
             comm -23 <(sort /tmp/aur_full.txt) <(sort /tmp/installed_aur_check.tmp) > /tmp/aur_missing.txt
             
             if [ -s "/tmp/aur_missing.txt" ]; then
                 log_info "Installing missing AUR packages..."
                 # Try batch first
                 if ! yay -S --needed --noconfirm - < /tmp/aur_missing.txt; then
                     log_error "Batch AUR failed. Trying one-by-one."
                     while read -r pkg; do
                         yay -S --needed --noconfirm "$pkg" || log_error "Failed AUR: $pkg"
                     done < /tmp/aur_missing.txt
                 else
                     log_success "AUR packages updated."
                 fi
             else
                 log_success "All AUR packages already installed."
             fi
        fi
        rm -f /tmp/aur_*.txt /tmp/installed_aur_check.tmp
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

    # 4.1 VS CODE
    log_info "Setting up VS Code Repo..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update || true 
    sudo dnf install -y code || log_error "Failed to install VS Code."

    # 4.2 GITKRAKEN
    if ! command -v gitkraken &> /dev/null; then
        log_info "Installing GitKraken..."
        curl -L https://release.gitkraken.com/linux/gitkraken-amd64.rpm -o /tmp/gitkraken.rpm
        sudo dnf install -y /tmp/gitkraken.rpm || log_error "Failed GitKraken install."
        rm -f /tmp/gitkraken.rpm
    else
        log_success "GitKraken already installed."
    fi

    # 4.3 COPR & NATIVE (With Smart Diff)
    COPR_REPO_LIST="$SOURCE_DIR/repolist_copr.txt"
    if [ -f "$COPR_REPO_LIST" ]; then
        log_info "Enabling COPR repositories..."
        # FIX: Added tr -d '\r'
        while read -r repo || [ -n "$repo" ]; do
            clean_repo=$(echo "$repo" | tr -d '\r')
            [[ -z "$clean_repo" || "$clean_repo" =~ ^# ]] && continue
            sudo dnf copr enable -y "$clean_repo"
        done < "$COPR_REPO_LIST"
        log_success "Fedora COPR update complete."
    fi

    IGNORE_FILE="$SOURCE_DIR/pkglist_ignore.txt"
    
    # Native Packages - Check against: rpm -qa --qf "%{NAME}\n"
    install_list "$SOURCE_DIR/pkglist_dnf.txt" \
                 "sudo dnf install" \
                 "Fedora Native" \
                 "$IGNORE_FILE" \
                 "rpm -qa --qf '%{NAME}\n'"

    # COPR Packages - Same check strategy
    install_list "$SOURCE_DIR/pkglist_copr.txt" \
                 "sudo dnf install" \
                 "Fedora COPR" \
                 "$IGNORE_FILE" \
                 "rpm -qa --qf '%{NAME}\n'"
fi

# ==============================================================================
# 5. FLATPAK INSTALLATION
# ==============================================================================
FLATPAK_LIST="$SOURCE_DIR/pkglist_flatpak.txt"

if command -v flatpak &> /dev/null && [ -f "$FLATPAK_LIST" ]; then
    log_info "Configuring Flatpaks..."
    
    # FIX: Initialize Flatpak system if repo doesn't exist (common in fresh installs/Docker)
    if [ ! -d "/var/lib/flatpak/repo" ]; then
        log_info "Initializing Flatpak system repository..."
        sudo flatpak repair --system 2>/dev/null || true
    fi
    
    # Add Flathub remote if not present (try user first, then system)
    if ! flatpak remote-list 2>/dev/null | grep -q "flathub"; then
        log_info "Adding Flathub repository..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || \
        sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    fi
    
    # Smart Install for Flatpak
    # Check command: flatpak list --app --columns=application
    install_list "$FLATPAK_LIST" \
                 "flatpak install -y --noninteractive flathub" \
                 "Flatpak Apps" \
                 "" \
                 "flatpak list --app --columns=application"
fi

# ==============================================================================
# 6. SHELL CONFIGURATION
# ==============================================================================
log_info "Configuring Shell Environment..."

# Oh My Zsh
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    log_info "Installing Oh My Zsh..."
    rm -rf "$HOME/.oh-my-zsh"
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        [ -f "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
    else
        log_error "Failed to install Oh My Zsh."
    fi
else
    log_success "Oh My Zsh already installed."
fi

# Oh My Posh
mkdir -p "$HOME/.local/bin"
if ! command -v oh-my-posh &> /dev/null && [ ! -f "$HOME/.local/bin/oh-my-posh" ]; then
    log_info "Installing Oh My Posh..."
    # FIX: Use official install method without -s flag before bash (was causing issues)
    if curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"; then
        log_success "Oh My Posh installed successfully."
    else
        log_error "Failed to install Oh My Posh."
    fi
else
    log_success "Oh My Posh already installed."
fi

# Create symlink to /usr/bin for system-wide access (optional)
if [ -f "$HOME/.local/bin/oh-my-posh" ] && [ ! -f "/usr/bin/oh-my-posh" ]; then
    log_info "Creating symlink for oh-my-posh in /usr/bin..."
    sudo ln -sf "$HOME/.local/bin/oh-my-posh" /usr/bin/oh-my-posh 2>/dev/null || true
fi

# Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
install_zsh_plugin() {
    local repo="$1"
    local name="$2"
    local dir="$ZSH_CUSTOM/plugins/$name"
    if [ -d "$HOME/.oh-my-zsh" ] && [ ! -d "$dir" ]; then
        log_info "Cloning $name..."
        git clone "$repo" "$dir" --depth 1 || log_error "Failed clone $name"
    fi
}
install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"

# Shell Change
# FIX: Use absolute path for zsh - 'which' can return wrong paths in some environments
ZSH_PATH=""
if [ -x "/usr/bin/zsh" ]; then
    ZSH_PATH="/usr/bin/zsh"
elif [ -x "/bin/zsh" ]; then
    ZSH_PATH="/bin/zsh"
fi

if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
    # Ensure zsh is in /etc/shells
    if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
        log_info "Adding $ZSH_PATH to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    
    if command -v chsh >/dev/null; then
        log_info "Changing shell to Zsh ($ZSH_PATH) for $TARGET_USER..."
        sudo chsh -s "$ZSH_PATH" "$TARGET_USER" || log_warn "Manual shell change required: chsh -s $ZSH_PATH"
    fi
    
    # Inform user about shell change taking effect on next login
    echo ""
    log_info "💡 Shell changed to Zsh. It will be active on your next login."
    log_info "   To start using Zsh now, run: exec zsh"
fi

log_success "Package installation complete!"
