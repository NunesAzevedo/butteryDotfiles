#!/bin/bash

# Nome exato da sua mesa digitalizadora Wacom
TABLET_NAME="wacom-one-by-wacom-m-pen"

# Escuta os eventos de troca de monitor via socket do Hyprland
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    
    # Filtra o evento específico de mudança de foco de monitor
    if [[ "$line" == "focusedmon>>"* ]]; then
        
        # Extrai apenas o nome do monitor da string (ex: 'focusedmon>>HDMI-A-1,Workspace1')
        MONITOR=$(echo "$line" | awk -F'>>|,' '{print $2}')
        
        # Altera dinamicamente o limite de área da mesa para o monitor atual
        hyprctl keyword "device[$TABLET_NAME]:output" "$MONITOR" > /dev/null
    fi
done
