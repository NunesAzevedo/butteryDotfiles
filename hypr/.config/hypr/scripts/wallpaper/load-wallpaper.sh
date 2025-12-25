#!/bin/bash
# ==============================================================================
# BOOT LOADER
# Restores the previously used wallpaper on system startup.
# ==============================================================================

source "$(dirname "$0")/swww-config.sh"

# Attempt to restore state from file
if [ -f "$LAST_WALLPAPER_FILE" ]; then
    LAST_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
    
    if [ -f "$LAST_WALLPAPER" ]; then
        apply_wallpaper "$LAST_WALLPAPER"
    else
        apply_wallpaper "$DEFAULT_WALLPAPER"
    fi
else
    # No state file found (fresh install)
    apply_wallpaper "$DEFAULT_WALLPAPER"
fi
