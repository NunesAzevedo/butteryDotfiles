#!/bin/bash
# ==============================================================================
# STATE RESET
# Forces the default wallpaper and resets the rotation index to 0.
# ==============================================================================

source "$(dirname "$0")/swww-config.sh"

apply_wallpaper "$DEFAULT_WALLPAPER"

# Reset the index counter so the next rotation starts from the beginning
echo "0" > "$CURRENT_FILE"
