#!/bin/bash

# Pega o nome das redes Wi-Fi disponíveis e joga no Wofi
bssid=$(nmcli -t -f SSID device wifi list | sort -u | grep -v "^$" | wofi --show dmenu --prompt "Selecione a Rede Wi-Fi" --lines 8)

# Se apertar ESC ou fechar, sai do script
if [ -z "$bssid" ]; then
    exit 0
fi

# Verifica se a rede já está salva no sistema
saved_connections=$(nmcli -g NAME connection)

if echo "$saved_connections" | grep -qw "$bssid"; then
    # Conecta direto se já tem a senha salva
    nmcli connection up id "$bssid" | grep "successfully" && notify-send "Wi-Fi" "Conectado a $bssid"
else
    # Pede a senha via Wofi se for uma rede nova
    pass=$(echo "" | wofi --show dmenu --password --prompt "Senha para $bssid" --lines 1)
    
    if [ -n "$pass" ]; then
        nmcli device wifi connect "$bssid" password "$pass" | grep "successfully" && notify-send "Wi-Fi" "Conectado a $bssid"
    fi
fi
