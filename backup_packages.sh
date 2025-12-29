#!/bin/bash

# ==============================================================================
# SCRIPT: backup_packages.sh
# DESCRIÇÃO:
#   Atualiza as listas de pacotes apenas se houver mudanças reais no sistema.
#   Compara o estado atual com o arquivo salvo, sem depender do git status.
# ==============================================================================

set -e

# Variável para controlar se houve mudanças (0 = não, 1 = sim)
CHANGES_DETECTED=0

echo "📦 Iniciando verificação de pacotes..."

# Função para comparar e atualizar
check_and_update() {
    local repo_file=$1
    local temp_file=$2
    local label=$3

    # Se o arquivo do repo não existir, cria-o direto
    if [ ! -f "$repo_file" ]; then
        echo "🆕 $label: Arquivo criado (não existia)."
        mv "$temp_file" "$repo_file"
        CHANGES_DETECTED=1
        return
    fi

    # Compara o temporário com o original (-s = silencioso)
    if cmp -s "$repo_file" "$temp_file"; then
        echo "✅ $label: Nenhuma alteração."
        rm "$temp_file" # Remove o lixo temporário
    else
        echo "🔄 $label: Mudanças detectadas! Atualizando arquivo..."
        mv "$temp_file" "$repo_file"
        CHANGES_DETECTED=1
    fi
}

# ---------------------------------------------------------
# 1. Processar Pacotes Nativos
# ---------------------------------------------------------
echo "--> Verificando pacotes Nativos..."
TEMP_NATIVE="/tmp/pkglist_native.tmp"
pacman -Qqen > "$TEMP_NATIVE"

check_and_update "pkglist_native.txt" "$TEMP_NATIVE" "Native"

# ---------------------------------------------------------
# 2. Processar Pacotes AUR
# ---------------------------------------------------------
echo "--> Verificando pacotes AUR..."
TEMP_AUR="/tmp/pkglist_aur.tmp"

# Gera lista limpa (sem -debug)
if pacman -Qqm > /dev/null 2>&1; then
    pacman -Qqm | grep -v '\-debug$' > "$TEMP_AUR"
else
    > "$TEMP_AUR"
fi

check_and_update "pkglist_aur.txt" "$TEMP_AUR" "AUR"


# ---------------------------------------------------------
# 3. Processar Pacotes Flatpak 
# ---------------------------------------------------------
if command -v flatpak &> /dev/null; then
    echo "--> Verificando pacotes Flatpak..."
    TEMP_FLATPAK="/tmp/pkglist_flatpak.tmp"

    # Lista apenas APPs (ignora runtimes) e pega apenas a coluna do ID
    flatpak list --app --columns=application > "$TEMP_FLATPAK"

    check_and_update "pkglist_flatpak.txt" "$TEMP_FLATPAK" "Flatpak"
else
    echo "⚠️  Flatpak não encontrado. Pulando backup desta etapa."
fi


# ---------------------------------------------------------
# 4. Resumo Final
# ---------------------------------------------------------
echo "---------------------------------------------------"
if [ $CHANGES_DETECTED -eq 1 ]; then
    echo "⚠️  Houve atualizações nos arquivos!"
    echo "💡 Agora você pode fazer o commit:"
    echo "   git add pkglist_*.txt"
    echo "   git commit -m 'chore: update package lists'"
    echo "   git push"
else
    echo "💤 Tudo sincronizado. Não é necessário commitar."
fi
