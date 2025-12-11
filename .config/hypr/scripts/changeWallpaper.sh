#!/bin/bash

source ~/.config/hypr/scripts/swww-config.sh

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    exit 1
fi

if [ -f "$CURRENT_FILE" ]; then
    CURRENT_INDEX=$(cat "$CURRENT_FILE")
else
    CURRENT_INDEX=0
fi

NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#WALLPAPERS[@]} ))
NEXT_WALLPAPER="${WALLPAPERS[$NEXT_INDEX]}"

echo "$NEXT_INDEX" > "$CURRENT_FILE"

apply_wallpaper "$NEXT_WALLPAPER"
