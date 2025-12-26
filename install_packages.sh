#!/bin/bash

# ==============================================================================
# SCRIPT: install_packages.sh
# VERSÃO: 4.1 (Sem alteração de configs do sistema + Shell Setup)
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧈 Iniciando restauração dos pacotes butteryDotfiles...${NC}"

# ==============================================================================
# 0. PREPARAÇÃO DE CONFLITOS
# ==============================================================================

# Removemos a edição do pacman.conf daqui. Assumimos que você já configurou o sistema.

echo -e "${YELLOW}--> Verificando conflitos conhecidos (rust, jack2)...${NC}"
# Remove 'rust' (conflita com rustup) e 'jack2' (conflita com pipewire-jack)
# O '|| true' impede erro se os pacotes não existirem.
sudo pacman -Rdd --noconfirm rust jack2 &> /dev/null || true

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# ==============================================================================

install_list() {
    local list_file="$1"
    local command_prefix="$2"
    local type_label="$3"

    if [ ! -f "$list_file" ]; then
        echo -e "${YELLOW}!! Arquivo $list_file não encontrado. Pulando.${NC}"
        return
    fi

    echo -e "${CYAN}--> Tentando instalação em lote de pacotes $type_label...${NC}"
    
    # Tentativa Rápida (Batch)
    if $command_prefix -S --needed --noconfirm - < "$list_file"; then
        echo -e "${GREEN}✅ Sucesso: Todos os pacotes $type_label instalados!${NC}"
    else
        echo -e "${RED}❌ Falha na instalação em lote. Entrando em modo diagnóstico (um por um)...${NC}"
        
        # Modo Pente Fino (Diagnostic)
        while read -r pkg; do
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            echo -n "Instalando $pkg... "
            if $command_prefix -S --needed --noconfirm "$pkg" &> /dev/null; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}ERRO${NC}"
                echo -e "${YELLOW}    vvv Detalhes do erro vvv${NC}"
                $command_prefix -S --needed --noconfirm "$pkg"
                echo -e "${YELLOW}    ^^^ ---------------- ^^^${NC}"
            fi
        done < "$list_file"
    fi
}

# ==============================================================================
# 1. BASE-DEVEL E GIT
# ==============================================================================
echo -e "${CYAN}--> Verificando base-devel...${NC}"
if sudo pacman -S --needed --noconfirm base-devel git &> /dev/null; then
    echo -e "${GREEN}✅ base-devel ok${NC}"
else
    echo -e "${RED}❌ Erro crítico ao instalar base-devel.${NC}"
    exit 1
fi

# ==============================================================================
# 2. BOOTSTRAPPING YAY
# ==============================================================================
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}--> Yay não encontrado. Instalando manualmente...${NC}"
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    if makepkg -si --noconfirm; then
        echo -e "${GREEN}✅ Yay instalado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Falha ao compilar o Yay.${NC}"
        exit 1
    fi
    cd - > /dev/null
    rm -rf /tmp/yay
else
    echo -e "${GREEN}✅ Yay já está instalado.${NC}"
fi

# ==============================================================================
# 3. INSTALAÇÃO DOS PACOTES
# ==============================================================================

# Nativos
install_list "pkglist_native.txt" "sudo pacman" "NATIVOS"

# AUR
if [ -f pkglist_aur.txt ]; then
    grep -vE '^yay$' pkglist_aur.txt > /tmp/aur_clean.txt
    install_list "/tmp/aur_clean.txt" "yay" "AUR"
    rm /tmp/aur_clean.txt
fi

# ==============================================================================
# 4. CONFIGURAÇÃO DE SHELL (Oh My Zsh & Oh My Posh)
# ==============================================================================

echo -e "${CYAN}--> Configurando Shell e Temas...${NC}"

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}    Instalando Oh My Zsh...${NC}"
    # --unattended: Instala sem bloquear o script
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Remove .zshrc padrão do OMZ para permitir que o Stow use o seu
    if [ -f "$HOME/.zshrc" ]; then
        echo -e "${YELLOW}    Limpando .zshrc padrão...${NC}"
        rm "$HOME/.zshrc"
    fi
    echo -e "${GREEN}✅ Oh My Zsh instalado.${NC}"
else
    echo -e "${GREEN}✅ Oh My Zsh já está instalado.${NC}"
fi

# --- Oh My Posh ---
# Verifica se existe no path ou na pasta local
if ! command -v oh-my-posh &> /dev/null && [ ! -f "$HOME/.local/bin/oh-my-posh" ]; then
    echo -e "${YELLOW}    Instalando Oh My Posh...${NC}"
    curl -s https://ohmyposh.dev/install.sh | bash -s
    echo -e "${GREEN}✅ Oh My Posh baixado.${NC}"
else
    echo -e "${GREEN}✅ Oh My Posh já está instalado.${NC}"
fi

# --- Link Simbólico OMP ---
if [ -f "$HOME/.local/bin/oh-my-posh" ]; then
    # Cria o link se não existir ou força atualização (-f)
    echo -e "${YELLOW}    Verificando link simbólico em /usr/bin/oh-my-posh...${NC}"
    sudo ln -sf "$HOME/.local/bin/oh-my-posh" /usr/bin/oh-my-posh
    echo -e "${GREEN}✅ Link verificado/criado.${NC}"
fi

echo -e "${CYAN}🏁 Processo finalizado!${NC}"
