#!/bin/bash
# ==============================================================================
# SCRIPT: install_dotfiles.sh
# LOCATION: scripts/install_dotfiles.sh
# DESCRIPTION: Links user configurations (dotfiles) using GNU Stow and installs static assets.
#              This script runs from the repository root to ensure Stow works correctly.
# ==============================================================================

set -e

# 1. Import Shared Library
#    Locates the directory where this script is, then sources lib/utils.sh.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

# 2. Change Context to Repository Root
#    Stow must be run from the root where the dotfile folders (nvim, zsh...) are located.
cd "$REPO_ROOT"

# BRANDING: Use Yellow Header
log_header "Starting Dotfiles Setup..."
log_info "📂 Working Directory: $(pwd)"

# ==============================================================================
# 3. ASSETS INSTALLATION (Manual Copy)
# ==============================================================================
# As decided, fonts are copied to avoid Stow issues in system directories.
FONT_SRC="assets/fonts"
FONT_DEST="$HOME/.local/share/fonts"

if [ -d "$FONT_SRC" ]; then
    log_info "Installing fonts from $FONT_SRC..."
    mkdir -p "$FONT_DEST"
    
    # Copy fonts (-n: do not overwrite existing files to be safe)
    cp -rn "$FONT_SRC"/* "$FONT_DEST/" &> /dev/null || true
    
    log_info "Updating font cache..."
    fc-cache -f "$FONT_DEST" &> /dev/null
    log_success "Fonts installed and cache updated."
else
    log_warn "No fonts found in $FONT_SRC. Skipping."
fi

# ==============================================================================
# 4. DOTFILES LINKING (GNU Stow)
# ==============================================================================

# 4.1 Check for Stow
if ! command -v stow &> /dev/null; then
    log_error "GNU Stow is not installed. Please install it first."
    exit 1
fi

# 4.2 Define Ignore List
#    - system/os/scripts: Infrastructure folders
#    - assets: Handled manually above
#    - install.sh: The entry point
#    - .git*: Version control
IGNORE_LIST=" system os scripts assets lib .git .github install.sh README.md LICENSE "

log_info "Linking configuration folders..."

# 4.3 Loop through subdirectories in Repo Root
for folder in */; do
    # Remove trailing slash (e.g., "nvim/" -> "nvim")
    app_name=${folder%/}

    # Check if folder is in the ignore list
    if [[ $IGNORE_LIST =~ " $app_name " ]]; then
        continue
    fi

    # Execute Stow
    # -R (Restow): Prunes old links and creates new ones
    # BRANDING: Action in Yellow
    echo -ne "${YELLOW}   Linking $app_name... ${NC}"
    
    if stow -R "$app_name"; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        log_warn "Conflict detected in $app_name."
        log_warn "Stow cannot overwrite existing files. Please remove the original file in $HOME and retry."
    fi
done

log_success "Dotfiles configuration applied!"
