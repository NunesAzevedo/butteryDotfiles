#!/bin/bash

# ==============================================================================
# SWWW CONFIGURATION & UTILS
# Centralized configuration for Hyprland wallpaper management using swww.
# ==============================================================================

# --- 1. Dynamic Path Detection ---
# Assumes the structure: ~/.config/hypr/scripts/swww-config.sh
# So, the parent directory is the main hypr config folder.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HYPR_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# --- 2. File & Directory Paths ---
export WALLPAPER_DIR="$HYPR_DIR/Wallpaper"
export CURRENT_FILE="/tmp/current_wallpaper"
export LAST_WALLPAPER_FILE="$HYPR_DIR/.last_wallpaper"

# Specific default wallpaper to use as fallback or initial setup
export DEFAULT_WALLPAPER="$WALLPAPER_DIR/doom_guy_e_isabelle.jpg"

# --- 3. Transition Settings ---
# Customize the animation when switching wallpapers
TRANSITION_TYPE="fade"      # simple, fade, left, right, top, bottom, wipe, wave, grow, center, outer, random
TRANSITION_FPS="60"         # Frames per second
TRANSITION_DURATION="1.0"   # Duration in seconds (e.g., 0.5, 1, 2)


# --- 4. Function: Apply Wallpaper ---
# Usage: apply_wallpaper "/path/to/image.jpg"
apply_wallpaper() {
    local target_wallpaper="$1"

    # Define common arguments to avoid repetition
    local swww_args=(
        --transition-type "$TRANSITION_TYPE"
        --transition-fps "$TRANSITION_FPS"
        --transition-duration "$TRANSITION_DURATION"
    )

    # Check if the target file actually exists
    if [ -f "$target_wallpaper" ]; then
        echo ":: Setting wallpaper: $target_wallpaper"
        swww img "$target_wallpaper" "${swww_args[@]}"
        
        # Save the successful wallpaper path for next session
        echo "$target_wallpaper" > "$LAST_WALLPAPER_FILE"

    else
        echo "[ERROR]: Wallpaper not found in: $target_wallpaper"
        echo ":: Loading the default wallpaper fallback..."

        # Check if default exists to avoid infinite errors
        if [ -f "$DEFAULT_WALLPAPER" ]; then
             swww img "$DEFAULT_WALLPAPER" "${swww_args[@]}"
             # Optionally save the default as the current one
             echo "$DEFAULT_WALLPAPER" > "$LAST_WALLPAPER_FILE"
        else
             echo "[CRITICAL]: Default wallpaper not found at $DEFAULT_WALLPAPER"
        fi
    fi
}
