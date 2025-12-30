#!/bin/bash

# ==============================================================================
# SCRIPT: install.sh
# DESCRIPTION: Master Orchestrator for ButteryDotfiles.
#   1. Detects the host Distribution (Arch/Fedora).
#   2. Applies System-Level Configurations (Root).
#   3. Installs Packages & Shell Environment.
#   4. Links User Dotfiles (Stow).
# ==============================================================================

# Ensure execution from repository root
cd "$(dirname "${BASH_SOURCE[0]}")"

# 1. Import Shared Library
#    Used here for colors and distro detection logic.
if [ -f "scripts/lib/utils.sh" ]; then
    source "scripts/lib/utils.sh"
else
    echo "❌ Error: scripts/lib/utils.sh not found. Is the repo structure correct?"
    exit 1
fi

# Define Log File
LOG_FILE=".install_$(date +%Y-%m-%d_%H-%M-%S).log"

# BRANDING: Use Yellow for "Buttery" identity
echo -e "${YELLOW}🧈 STARTING BUTTERYDOTFILES SETUP...${NC}"
echo -e "${YELLOW}📝 Detailed log will be saved to: ${CYAN}$LOG_FILE${NC}"
echo ""

# ==============================================================================
# MAIN EXECUTION BLOCK
# ==============================================================================
# All output inside this block is captured by 'tee' into the log file
{
    echo "===================================================================="
    echo " START: $(date)"
    echo "===================================================================="

    # 1. Initialization
    detect_distro # Sets $DISTRO global variable

    # SELF-HEALING: Ensure all scripts are executable before proceeding.
    # We run this via 'bash' explicitly in case setup_permissions.sh itself
    # lost its +x permission during download/unzip.
    echo ""
    log_info "Ensuring execution permissions for all scripts..."
    bash ./scripts/setup_permissions.sh

    # 2. System Configuration (Root Level)
    #    Resolves the script path dynamically based on the detected distro.
    echo ""
    echo "===================================================================="
    echo " STEP 1: SYSTEM CONFIGURATION (Root/Sudo)"
    echo "===================================================================="
    
    SYSTEM_SCRIPT="./os/$DISTRO/system/install_system.sh"
    
    if [ -f "$SYSTEM_SCRIPT" ]; then
        log_info "Executing system setup for $DISTRO..."
        "$SYSTEM_SCRIPT"
    else
        log_warn "No system script found for $DISTRO ($SYSTEM_SCRIPT)."
        log_warn "Skipping system configuration step."
    fi

    # 3. Package Installation (User/Root Level)
    #    Installs Pacman/DNF packages, Flatpaks, and Shell tools.
    echo ""
    echo "===================================================================="
    echo " STEP 2: PACKAGES & SHELL SETUP"
    echo "===================================================================="
    ./scripts/install_packages.sh

    # 4. Dotfiles Linking (User Level)
    #    Runs GNU Stow and asset copying.
    echo ""
    echo "===================================================================="
    echo " STEP 3: DOTFILES LINKING (Stow)"
    echo "===================================================================="
    ./scripts/install_dotfiles.sh

    echo ""
    echo "===================================================================="
    echo " END: $(date)"
    echo "===================================================================="

} 2>&1 | tee "$LOG_FILE"

# ==============================================================================
# POST-EXECUTION
# ==============================================================================
echo ""
echo -e "${GREEN}🏁 Installation finished!${NC}"
echo -e "   If errors occurred, check the log: ${CYAN}$LOG_FILE${NC}"
