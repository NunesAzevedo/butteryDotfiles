#!/bin/bash

# Pega o perfil atual
current=$(powerprofilesctl get)

# Lógica de ciclo: Performance -> Balanced -> Power Saver -> Performance
if [ "$current" == "performance" ]; then
    powerprofilesctl set balanced
    notify-send -u low -t 2000 "Power Profile" "Modo: Balanced"
elif [ "$current" == "balanced" ]; then
    powerprofilesctl set power-saver
    notify-send -u low -t 2000 "Power Profile" "Modo: Power Saver"
else
    powerprofilesctl set performance
    notify-send -u low -t 2000 "Power Profile" "Modo: Performance"
fi
