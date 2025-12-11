#!/bin/bash

# Configurações centralizadas do swww
WALLPAPER_DIR="/home/manteiguinha/Pictures/Wallpaper"
DEFAULT_WALLPAPER="/home/manteiguinha/Pictures/Wallpaper/doom_guy_e_isabelle.jpg"
CURRENT_FILE="/tmp/current_wallpaper"
LAST_WALLPAPER_FILE="$HOME/.config/hypr/.last_wallpaper"

# Configurações de transição
TRANSITION_TYPE="fade"
TRANSITION_FPS="60"
TRANSITION_DURATION="1"

# Função para aplicar wallpaper com as configurações
apply_wallpaper() {
    swww img "$1" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-fps "$TRANSITION_FPS" \
        --transition-duration "$TRANSITION_DURATION"
    
    # Salva o wallpaper atual
    echo "$1" > "$LAST_WALLPAPER_FILE"
}
