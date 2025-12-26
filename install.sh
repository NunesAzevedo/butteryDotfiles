#!/bin/bash

# ==============================================================================
# SCRIPT: install.sh (MASTER)
# DESCRIÇÃO:
#   Orquestrador que executa todo o processo de instalação na ordem correta.
#   Grava todo o output (sucesso e erros) em um arquivo de log oculto.
# ==============================================================================

# Definição do arquivo de log (com Timestamp para não sobrescrever anteriores)
LOG_FILE=".install_$(date +%Y-%m-%d_%H-%M-%S).log"

# Cores para o Mestre
VIOLET='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Garante que estamos na raiz do repositório
cd "$(dirname "${BASH_SOURCE[0]}")"

echo -e "${VIOLET}🧈 INICIANDO O SETUP COMPLETO DO BUTTERYDOTFILES...${NC}"
echo -e "${VIOLET}📝 Um log detalhado será salvo em: ${CYAN}$LOG_FILE${NC}"
echo ""

# A mágica acontece aqui:
# Agrupamos todos os comandos dentro de { ... } e jogamos para o 'tee'
{
    echo "===================================================================="
    echo " INÍCIO DO PROCESSO: $(date)"
    echo "===================================================================="

    # 1. Dar permissão de execução para todos os scripts
    echo "--> Tornando scripts executáveis..."
    chmod +x install_packages.sh install_dotfiles.sh system/install_system.sh

    # 2. Configurações de Sistema (Root / /etc)
    # É importante rodar antes para configurar o pacman.conf (multilib/downloads)
    echo ""
    echo "===================================================================="
    echo " ETAPA 1: CONFIGURAÇÕES DE SISTEMA (Requer Sudo)"
    echo "===================================================================="
    ./system/install_system.sh

    # 3. Instalação de Pacotes (Pacman/Yay/OMZ/OMP)
    echo ""
    echo "===================================================================="
    echo " ETAPA 2: INSTALAÇÃO DE PACOTES E SHELL"
    echo "===================================================================="
    ./install_packages.sh

    # 4. Linkagem dos Dotfiles (Stow)
    echo ""
    echo "===================================================================="
    echo " ETAPA 3: APLICAÇÃO DOS DOTFILES (STOW)"
    echo "===================================================================="
    ./install_dotfiles.sh

    echo ""
    echo "===================================================================="
    echo " FIM DO PROCESSO: $(date)"
    echo "===================================================================="

# 2>&1 redireciona os ERROS para a saída padrão, para o tee pegar tudo.
} 2>&1 | tee "$LOG_FILE"

echo ""
echo -e "${VIOLET}🏁 Instalação finalizada!${NC}"
echo -e "   Se algo deu errado, verifique o arquivo: ${CYAN}$LOG_FILE${NC}"
