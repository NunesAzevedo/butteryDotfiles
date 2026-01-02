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
    log_error "GNU Stow is not installed. Skipping dotfiles linking."
    exit 1
fi

# Define folders to ignore (scripts, os, git related, etc)
# Using a space-separated string for easier matching
IGNORE_STRING=" . .. .git .github .gitignore .dotfilesignore scripts os assets docker README.md LICENSE "

log_info "Linking configuration files..."

# Loop through each directory in the repo root
for folder in */; do
    app_name="${folder%/}" # Remove trailing slash

    # Skip ignored directories/files
    if [[ "$IGNORE_STRING" =~ " $app_name " ]]; then
        continue
    fi

    echo -ne "${YELLOW}   Linking $app_name... ${NC}"

    # --------------------------------------------------------------------------
    # CONFLICT RESOLUTION: "The Fresh Install Paradox"
    # Detects if system-generated files (like .bashrc, .zshrc) exist as real files.
    # If so, backs them up to allow Stow to create symlinks.
    # --------------------------------------------------------------------------
    # Scan top-level files in the package to see if they collide with HOME
    find "$app_name" -maxdepth 1 -print0 | while IFS= read -r -d '' source_path; do
        # Skip the directory itself
        if [ "$source_path" == "$app_name" ]; then continue; fi
        
        filename=$(basename "$source_path")
        target="$HOME/$filename"

        # FIX: CRITICAL SAFETY CHECK
        # If the source is a directory (e.g., .config) and target is a directory,
        # DO NOT MOVE IT. Let Stow merge the contents inside.
        # We only backup if it's a file conflict OR a file vs dir conflict.
        if [ -d "$source_path" ] && [ -d "$target" ] && [ ! -L "$target" ]; then
            continue
        fi

        # Check: If Target exists AND is NOT a symlink (i.e., it's a real file/dir)
        # This handles the case where distro creates a default .bashrc
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            # We backup existing file to clear the path for the symlink
            # Using mv ensures we don't lose the original system config
            mv "$target" "$target.bak-$(date +%s)"
        fi
    done
    
    # --------------------------------------------------------------------------
    # EXECUTE STOW
    # --------------------------------------------------------------------------
    # FIX: Added -t "$HOME" to ensure links go to home dir regardless of repo location
    if stow -t "$HOME" -R "$app_name" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        # Log specifically so it appears in the final Red Report
        log_error "Stow conflict detected in package: $app_name. Check manually."
    fi
done

log_success "Dotfiles configuration applied!"
