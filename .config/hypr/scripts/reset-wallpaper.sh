#!/bin/bash

source ~/.config/hypr/scripts/swww-config.sh

apply_wallpaper "$DEFAULT_WALLPAPER"

# Reseta o índice escrevendo 0 ao invés de deletar o arquivo
echo "0" > "$CURRENT_FILE"
