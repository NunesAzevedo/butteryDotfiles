#!/bin/bash
# ==============================================================================
# SCRIPT: install_dotfiles.sh
# LOCATION: scripts/install_dotfiles.sh
# DESCRIPTION: Links user configurations (dotfiles) using GNU Stow.
#              - Reads exclusions from .dotfilesignore.
#              - Automatically backs up conflicting system-generated files.
#              - Explicitly targets $HOME directory.
# ==============================================================================

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

cd "$REPO_ROOT"

log_header "Starting Dotfiles Setup..."
log_info "📂 Working Directory: $(pwd)"

# ==============================================================================
# 3. ASSETS INSTALLATION
# ==============================================================================
FONT_SRC="assets/fonts"
FONT_DEST="$HOME/.local/share/fonts"

if [ -d "$FONT_SRC" ]; then
    log_info "Installing fonts from $FONT_SRC..."
    mkdir -p "$FONT_DEST"
    cp -rn "$FONT_SRC"/* "$FONT_DEST/" &> /dev/null || true
    fc-cache -f "$FONT_DEST" &> /dev/null
    log_success "Fonts installed and cache updated."
else
    log_warn "No fonts found in $FONT_SRC. Skipping."
fi

# ==============================================================================
# 4. DOTFILES LINKING (GNU Stow)
# ==============================================================================

if ! command -v stow &> /dev/null; then
    log_error "GNU Stow is not installed. Please install it first."
    exit 1
fi

# Load ignore list from external file for modularity
IGNORE_FILE=".dotfilesignore"
IGNORE_STRING=""

if [ -f "$IGNORE_FILE" ]; then
    # Reads the file, removes comments/empty lines, and creates a space-separated string
    # grep -vE: Ignores lines starting with # or empty lines
    # tr -d '\r': Removes Windows carriage returns (CR) for cross-platform safety
    # tr '\n' ' ': Replaces newlines with spaces to create the list string
    IGNORE_STRING=" $(grep -vE "^\s*#|^\s*$" "$IGNORE_FILE" | tr -d '\r' | tr '\n' ' ') "
    log_info "Loaded exclusion list from $IGNORE_FILE"
else
    log_warn "No $IGNORE_FILE found. Using defaults."
    # Fallback to critical defaults if file is missing
    IGNORE_STRING=" .git .github install.sh scripts os assets lib docker README.md LICENSE"
fi

log_info "Linking configuration folders..."

for folder in */; do
    app_name=${folder%/}

    # Check if the folder name exists inside the IGNORE_STRING
    if [[ "$IGNORE_STRING" =~ " $app_name " ]]; then
        continue
    fi

    echo -ne "${YELLOW}   Linking $app_name... ${NC}"

    # --------------------------------------------------------------------------
    # CONFLICT RESOLUTION: "The Fresh Install Paradox"
    # Detects if system-generated files (like .bashrc, .zshrc) exist as real files.
    # If so, backs them up to allow Stow to create symlinks.
    # --------------------------------------------------------------------------
    find "$app_name" -maxdepth 1 -type f -name ".*" -print0 | while IFS= read -r -d '' source_file; do
        filename=$(basename "$source_file")
        target="$HOME/$filename"

        # Check: If Target exists AND is NOT a symlink (i.e., real file)
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            # We move (mv) instead of copy because we need to clear the path for the symlink
            mv "$target" "$target.bak"
        fi
    done
    
    # --------------------------------------------------------------------------
    # EXECUTE STOW
    # --------------------------------------------------------------------------
    # FIX: Added -t "$HOME" to ensure links go to home dir regardless of repo location
    if stow -t "$HOME" -R "$app_name"; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        # Log specifically so it appears in the final Red Report
        log_error "Stow conflict detected in package: $app_name"
    fi
done

log_success "Dotfiles configuration applied!"
