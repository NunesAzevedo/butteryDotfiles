#!/bin/bash
# ==============================================================================
# WALLPAPER ROTATOR
# Cycles through images in the directory using natural sorting.
# Includes logic to skip the current wallpaper if it matches the target.
# ==============================================================================

# Import core configuration (relative path)
source "$(dirname "$0")/swww-config.sh"

# 1. Build File List
# Uses 'sort -V' to handle numbered files naturally (2 comes before 10)
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | sort -V)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "[ERROR] No images found in: $WALLPAPER_DIR"
    exit 1
fi

# 2. Index Calculation
if [ -f "$CURRENT_FILE" ]; then
    CURRENT_INDEX=$(cat "$CURRENT_FILE")
else
    CURRENT_INDEX=-1
fi

NEXT_INDEX=$((CURRENT_INDEX + 1))

# Cycle back to 0 if we reach the end
if [ "$NEXT_INDEX" -ge "${#WALLPAPERS[@]}" ]; then
    NEXT_INDEX=0
fi

# 3. Redundancy Check
# Prevents applying the same wallpaper again (common on first run after boot)
NEXT_WALLPAPER="${WALLPAPERS[$NEXT_INDEX]}"

if [ -f "$LAST_WALLPAPER_FILE" ]; then
    CURRENT_ON_SCREEN=$(cat "$LAST_WALLPAPER_FILE")
    
    if [ "$NEXT_WALLPAPER" == "$CURRENT_ON_SCREEN" ]; then
        echo ":: Target matches current screen (Index $NEXT_INDEX). Skipping..."
        
        NEXT_INDEX=$((NEXT_INDEX + 1))
        
        # Re-check bounds after skipping
        if [ "$NEXT_INDEX" -ge "${#WALLPAPERS[@]}" ]; then
            NEXT_INDEX=0
        fi
        
        NEXT_WALLPAPER="${WALLPAPERS[$NEXT_INDEX]}"
    fi
fi

# 4. Execution
echo ":: Applying Index: $NEXT_INDEX / ${#WALLPAPERS[@]}"
apply_wallpaper "$NEXT_WALLPAPER"

# Save new index state
echo "$NEXT_INDEX" > "$CURRENT_FILE"
