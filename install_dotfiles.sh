#!/bin/bash

# ==============================================================================
# SCRIPT: install_dotfiles.sh
# DESCRIÇÃO:
#   Aplica as configurações de usuário (dotfiles) usando GNU Stow.
#   Percorre todas as pastas do repositório e cria os links simbólicos na $HOME.
# ==============================================================================

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Garante que o script rode a partir da raiz do repositório
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

echo -e "${CYAN}🔗 Iniciando linkagem dos dotfiles (GNU Stow)...${NC}"

# 1. Verifica se o Stow está instalado
if ! command -v stow &> /dev/null; then
    echo -e "${RED}❌ O GNU Stow não está instalado.${NC}"
    echo -e "${YELLOW}   Instale com: sudo pacman -S stow${NC}"
    exit 1
fi

# 2. Lista de pastas para IGNORAR (Não devem ser linkadas na Home)
# Adicione aqui qualquer outra pasta que não seja de configuração de app
IGNORE_LIST=" system scripts .git .github "

# 3. Loop através de todas as subpastas
# O */ pega apenas diretórios, ignorando arquivos soltos (como README.md ou .txt)
for folder in */; do
    # Remove a barra do final do nome (ex: "nvim/" vira "nvim")
    app_name=${folder%/}

    # Verifica se a pasta está na lista de ignorados
    if [[ $IGNORE_LIST =~ " $app_name " ]]; then
        # echo -e "   -> Pulando $app_name (sistema/interno)" # (Opcional: Descomente para ver o que foi pulado)
        continue
    fi

    echo -n "   Linkando $app_name... "

    # Executa o Stow
    # -R (Restow): Atualiza links, removendo os velhos se necessário.
    # --target=$HOME: Garante que o alvo é a pasta de usuário (padrão, mas explícito é melhor)
    if stow -R "$app_name"; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}ERRO${NC}"
        echo -e "${YELLOW}      ⚠️  Conflito detectado em $app_name.${NC}"
        echo -e "${YELLOW}          O Stow não pode sobrescrever arquivos reais com links.${NC}"
        echo -e "${YELLOW}          Ação: Apague o arquivo original na sua Home e rode este script novamente.${NC}"
    fi
done

echo -e "${CYAN}🏁 Dotfiles aplicados!${NC}"
