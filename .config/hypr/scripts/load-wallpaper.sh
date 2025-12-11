#!/bin/bash

source ~/.config/hypr/scripts/swww-config.sh

# Verifica se existe um wallpaper salvo
if [ -f "$LAST_WALLPAPER_FILE" ]; then
    LAST_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
    
    # Verifica se o arquivo ainda existe
    if [ -f "$LAST_WALLPAPER" ]; then
        apply_wallpaper "$LAST_WALLPAPER"
    else
        # Se o arquivo não existe mais, usa o padrão
        apply_wallpaper "$DEFAULT_WALLPAPER"
    fi
else
    # Se não há wallpaper salvo, usa o padrão
    apply_wallpaper "$DEFAULT_WALLPAPER"
fi
