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
if [ -f "scripts/lib/utils.sh" ]; then
    source "scripts/lib/utils.sh"
else
    echo "❌ Error: scripts/lib/utils.sh not found. Is the repo structure correct?"
    exit 1
fi

# ==============================================================================
# SAFETY CHECK: DO NOT RUN AS ROOT
# ==============================================================================
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ CRITICAL ERROR: Do not run this script as root (sudo).${NC}"
    echo -e "   Run it as your normal user. The script will ask for sudo permissions when needed."
    echo -e "   Usage: ./install.sh"
    exit 1
fi

# ==============================================================================
# INITIALIZATION & LOGGING
# ==============================================================================
# Detect Distro EARLY to include it in the log filename
detect_distro

# Define Log File with Distro Name (Requested Improvement)
LOG_FILE=".install_${DISTRO}_$(date +%Y-%m-%d_%H-%M-%S).log"
rm -f "$ERROR_LOG_TRACKER"

# Track execution time
START_TIME=$(date +%s)

# Pre-Log Header
{
    echo -e "${YELLOW}🧈 STARTING BUTTERYDOTFILES SETUP (${DISTRO^^})...${NC}"
    echo -e "${YELLOW}📝 Detailed log will be saved to: ${CYAN}$LOG_FILE${NC}"
    echo ""
} | tee "$LOG_FILE"

# ==============================================================================
# HELPER: SUDO KEEP-ALIVE
# ==============================================================================
ask_for_sudo() {
    log_info "Validating sudo permissions..."
    sudo -v || { log_error "Sudo validation failed. Password incorrect or not in sudoers."; exit 1; }
    
    # Background loop to refresh sudo timeout every 60s
    ( 
        while true; do 
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null 
    ) &
    SUDO_LOOP_PID=$!
}

# ==============================================================================
# SUMMARY HANDLER
# ==============================================================================
show_summary() {
    local exit_code=$?

    # KILL THE SUDO LOOP
    if [ -n "$SUDO_LOOP_PID" ]; then
        kill "$SUDO_LOOP_PID" 2>/dev/null
    fi
    
    # Generate Report
    {
        echo ""
        echo "===================================================================="
        echo " INSTALLATION SUMMARY"
        echo "===================================================================="
        
        # Calculate elapsed time
        END_TIME=$(date +%s)
        ELAPSED=$((END_TIME - START_TIME))
        ELAPSED_MIN=$((ELAPSED / 60))
        ELAPSED_SEC=$((ELAPSED % 60))
        
        if [ -s "$ERROR_LOG_TRACKER" ]; then
            echo -e "${RED}${BOLD}⚠️  ERRORS WERE DETECTED DURING INSTALLATION:${NC}"
            echo -e "${RED}"
            cat "$ERROR_LOG_TRACKER"
            echo -e "${NC}"
            echo -e "Check the full log for details: ${CYAN}$LOG_FILE${NC}"
        elif [ $exit_code -ne 0 ]; then
            echo -e "${RED}❌ Script aborted unexpectedly (Exit Code: $exit_code).${NC}"
            echo -e "Check the log: ${CYAN}$LOG_FILE${NC}"
        else
            echo -e "${GREEN}✅ SUCCESS! No errors reported.${NC}"
            echo -e "${YELLOW}⚠️  NOTE: Some changes (Groups, Shell, GRUB) require a System Reboot.${NC}"
            echo -e "Enjoy your buttery smooth system! 🧈"
            echo -e "Full log available at: ${CYAN}$LOG_FILE${NC}"
        fi
        
        echo ""
        echo -e "${CYAN}⏱️  Total execution time: ${ELAPSED_MIN}m ${ELAPSED_SEC}s${NC}"
    } 2>&1 | tee -a "$LOG_FILE"

    # Switch Shell if successful AND .zshrc exists
    if [ ! -s "$ERROR_LOG_TRACKER" ] && [ $exit_code -eq 0 ]; then
        if command -v zsh >/dev/null && [ -f "$HOME/.zshrc" ]; then
            echo -e "${YELLOW}🔄 Switching to Zsh...${NC}"
            exec zsh -l
        else
            echo -e "${YELLOW}ℹ️  Zsh installed but .zshrc missing (or errors occurred). Keeping current shell.${NC}"
        fi
    fi
}

trap show_summary EXIT INT TERM

# ==============================================================================
# PHASE 1: PRE-FLIGHT (Run in Main Shell)
# ==============================================================================
# detect_distro was already called at the top
ask_for_sudo

# ==============================================================================
# PHASE 2: MAIN EXECUTION (Logged via Pipe)
# ==============================================================================
{
    echo "===================================================================="
    echo " START: $(date)"
    echo " HOST: $DISTRO"
    echo "===================================================================="

    # SELF-HEALING: Permissions
    echo ""
    log_info "Ensuring execution permissions for all scripts..."
    if [ -f "./scripts/setup_permissions.sh" ]; then
        bash ./scripts/setup_permissions.sh
    else
        find . -name "*.sh" -type f -exec chmod +x {} +
    fi

    # 1. System Configuration
    echo ""
    echo "===================================================================="
    echo " STEP 1: SYSTEM CONFIGURATION (Root/Sudo)"
    echo "===================================================================="
    
    SYSTEM_SCRIPT="./os/$DISTRO/system/install_system.sh"
    if [ -f "$SYSTEM_SCRIPT" ]; then
        log_info "Executing system setup for $DISTRO..."
        bash "$SYSTEM_SCRIPT"
    else
        log_warn "No system script found for $DISTRO ($SYSTEM_SCRIPT)."
    fi

    # 2. Package Installation
    echo ""
    echo "===================================================================="
    echo " STEP 2: PACKAGES & SHELL SETUP"
    echo "===================================================================="
    bash ./scripts/install_packages.sh

    # 3. Dotfiles Linking
    echo ""
    echo "===================================================================="
    echo " STEP 3: DOTFILES LINKING (Stow)"
    echo "===================================================================="
    bash ./scripts/install_dotfiles.sh

    echo ""
    echo "===================================================================="
    echo " END: $(date)"
    echo "===================================================================="

} 2>&1 | tee -a "$LOG_FILE"
