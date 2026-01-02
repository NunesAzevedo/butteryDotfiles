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
    # Phase 1: Batch install (fast)
    #   - DNF: uses --skip-broken to continue past conflicts
    #   - Pacman: Try batch, parse errors, retry without problematic packages
    # Phase 2: Re-check what's still missing and retry one-by-one (thorough)
    # =========================================================================
    
    # Phase 1: Fast batch install
    # Detect if using DNF (supports --skip-broken) or pacman (does not)
    if [[ "$install_cmd" == *"dnf"* ]]; then
        log_info "Phase 1: Batch installation (DNF with --skip-broken)..."
        $install_cmd -y --skip-broken $batch_list 2>&1 || true
    else
        # Pacman strategy: try batch, if fails parse errors and retry without problematic pkgs
        log_info "Phase 1: Batch installation..."
        local batch_output_file="/tmp/pacman_batch_$$.log"
        local batch_exit_code=0
        
        # Run and show output in real-time, also capture to file for parsing
        # Use set +e temporarily to capture exit code properly
        set +e
        $install_cmd $batch_list 2>&1 | tee "$batch_output_file"
        batch_exit_code=${PIPESTATUS[0]}
        set -e
        
        if [ $batch_exit_code -ne 0 ]; then
            log_info "    Batch failed. Analyzing errors to identify problematic packages..."
            
            # Parse pacman errors to find problematic packages:
            # - "error: target not found: <pkg>" -> package doesn't exist
            # - "<pkg1> and <pkg2> are in conflict" -> conflict between packages
            # - "error: failed to prepare transaction (could not satisfy dependencies)"
            local problematic_pkgs=""
            
            # Extract "target not found" packages
            local not_found=$(grep -oP "target not found: \K\S+" "$batch_output_file" || true)
            if [ -n "$not_found" ]; then
                problematic_pkgs="$not_found"
                log_info "    Packages not found: $(echo $not_found | tr '\n' ' ')"
            fi
            
            # Extract conflict packages (both sides of conflict)
            local conflicts=$(grep -oP ":: \K\S+(?= and .* are in conflict)" "$batch_output_file" || true)
            local conflicts2=$(grep -oP ":: \S+ and \K\S+(?= are in conflict)" "$batch_output_file" || true)
            if [ -n "$conflicts" ] || [ -n "$conflicts2" ]; then
                problematic_pkgs="$problematic_pkgs"$'\n'"$conflicts"$'\n'"$conflicts2"
                log_info "    Conflicting packages detected: $(echo "$conflicts $conflicts2" | tr '\n' ' ')"
            fi
            
            # Cleanup temp file
            rm -f "$batch_output_file"
            
            # Remove problematic packages from batch and retry
            if [ -n "$problematic_pkgs" ]; then
                local clean_batch="$batch_list"
                local bad_count=0
                # Use process substitution to avoid subshell variable scope issue
                while read -r bad_pkg; do
                    [[ -z "$bad_pkg" ]] && continue
                    # Remove package from list (word boundary match)
                    clean_batch=$(echo "$clean_batch" | sed "s/\b${bad_pkg}\b//g")
                    ((bad_count++)) || true
                done <<< "$problematic_pkgs"
                # Trim extra spaces
                clean_batch=$(echo "$clean_batch" | tr -s ' ' | xargs)
                
                if [ -n "$clean_batch" ]; then
                    local remaining_count=$(echo "$clean_batch" | wc -w)
                    log_info "    Excluded $bad_count problematic packages. Retrying $remaining_count packages..."
                    $install_cmd $clean_batch 2>&1 || true
                fi
            fi
        else
            # Batch succeeded, cleanup temp file
            rm -f "$batch_output_file"
        fi
    fi
    
    # Phase 2: Check what's still missing and retry individually
    if [ -n "$check_cmd" ]; then
        # Re-check installed packages
        local tmp_now_installed="/tmp/now_installed_$$.tmp"
        bash -c "$check_cmd" 2>/dev/null | sort -u > "$tmp_now_installed"
        
        # Find what's STILL missing after batch
        local still_missing=$(comm -23 <(echo "$missing_list" | sort) "$tmp_now_installed")
        rm -f "$tmp_now_installed"
        
        # Use wc -l and trim whitespace to get a clean integer
        local still_count=0
        if [ -n "$still_missing" ]; then
            still_count=$(echo "$still_missing" | wc -l | tr -d ' ')
        fi
        
        if [ "$still_count" -gt 0 ]; then
            log_info "Phase 2: $still_count packages still missing. Installing one-by-one..."
            echo "$still_missing" | while read -r pkg; do
                [[ -z "$pkg" ]] && continue
                # DNF uses -y flag, pacman already has --noconfirm in install_cmd
                if [[ "$install_cmd" == *"dnf"* ]]; then
                    $install_cmd -y "$pkg" 2>&1 || log_error "Failed to install package: $pkg"
                else
                    $install_cmd "$pkg" 2>&1 || log_error "Failed to install package: $pkg"
                fi
            done
        else
            log_success "Phase 2: All packages verified installed."
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
                 aur_count=$(wc -l < /tmp/aur_missing.txt)
                 log_info "Installing $aur_count missing AUR packages..."
                 
                 # Convert file to space-separated list for yay
                 aur_batch=$(tr '\n' ' ' < /tmp/aur_missing.txt)
                 
                 # Try batch first (yay accepts packages as arguments)
                 if ! yay -S --needed --noconfirm $aur_batch 2>&1; then
                     log_info "Batch AUR had issues. Trying one-by-one..."
                     while read -r pkg; do
                         [[ -z "$pkg" ]] && continue
                         yay -S --needed --noconfirm "$pkg" 2>&1 || log_error "Failed AUR: $pkg"
                     done < /tmp/aur_missing.txt
                 fi
                 log_success "AUR packages processed."
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

# Cargo packages (installed via cargo to avoid rust vs rustup conflicts)
if command -v cargo &> /dev/null; then
    if ! command -v cargo-install-update &> /dev/null; then
        log_info "Installing cargo-update via cargo..."
        cargo install cargo-update 2>/dev/null || log_warn "Failed to install cargo-update (optional)"
    fi
fi

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
