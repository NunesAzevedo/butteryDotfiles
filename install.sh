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

# ==============================================================================
# SAFETY CHECK: DO NOT RUN AS ROOT
# ==============================================================================
# Prevents installing dotfiles into /root or messing up user permissions
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ CRITICAL ERROR: Do not run this script as root (sudo).${NC}"
    echo -e "   Run it as your normal user. The script will ask for sudo permissions when needed."
    echo -e "   Usage: ./install.sh"
    exit 1
fi

# Define Log File
LOG_FILE=".install_$(date +%Y-%m-%d_%H-%M-%S).log"

# Clean up previous error tracker to avoid false positives
rm -f "$ERROR_LOG_TRACKER"

# Initialize PID variable for process cleanup
SUDO_LOOP_PID=""

# BRANDING: Use Yellow for "Buttery" identity
echo -e "${YELLOW}🧈 STARTING BUTTERYDOTFILES SETUP...${NC}"
echo -e "${YELLOW}📝 Detailed log will be saved to: ${CYAN}$LOG_FILE${NC}"
echo ""

# ==============================================================================
# SUMMARY HANDLER (Runs at the end, always)
# ==============================================================================
show_summary() {
    local exit_code=$?
    
    # 1. Clean up background processes (Sudo Loop)
    if [ -n "$SUDO_LOOP_PID" ]; then
        kill "$SUDO_LOOP_PID" 2>/dev/null || true
    fi

    # 2. Generate Report and append it to the log file explicitly
    {
        echo ""
        echo "===================================================================="
        echo " INSTALLATION SUMMARY"
        echo "===================================================================="
        
        # Check for collected errors in the tracker file
        if [ -s "$ERROR_LOG_TRACKER" ]; then
            echo -e "${RED}${BOLD}⚠️  ERRORS WERE DETECTED DURING INSTALLATION:${NC}"
            echo -e "${RED}"
            # Print the content of the error log with a red tint
            cat "$ERROR_LOG_TRACKER"
            echo -e "${NC}"
            echo -e "Check the full log for details: ${CYAN}$LOG_FILE${NC}"
        elif [ $exit_code -ne 0 ]; then
            # Script crashed or was interrupted by user
            echo -e "${RED}❌ Script aborted unexpectedly (Exit Code: $exit_code).${NC}"
            echo -e "Check the log: ${CYAN}$LOG_FILE${NC}"
        else
            # Success scenario
            echo -e "${GREEN}✅ SUCCESS! No errors reported.${NC}"
            # FIX: Added log file path display for success scenario too
            echo -e "Check the log: ${CYAN}$LOG_FILE${NC}"
            echo -e "${YELLOW}⚠️  NOTE: Some changes (Groups, Shell, GRUB) require a System Reboot to take full effect.${NC}"
            echo -e "Enjoy your buttery smooth system! 🧈"
        fi
    } 2>&1 | tee -a "$LOG_FILE"

    # 3. Switch Shell (Must be done outside the pipe/tee to replace the process)
    # Only switch if successful and no errors were tracked
    if [ ! -s "$ERROR_LOG_TRACKER" ] && [ $exit_code -eq 0 ]; then
        if command -v zsh >/dev/null; then
            echo -e "${YELLOW}🔄 Switching to Zsh...${NC}"
            exec zsh -l
        fi
    fi
}

# Trap EXIT signal to run summary no matter what happens (Success, Fail, Ctrl+C)
trap show_summary EXIT

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

    # Sudo Keep-Alive Mechanism
    # Ask for password once, then keep updating the timestamp in the background.
    echo ""
    log_info "Validating sudo permissions..."
    sudo -v || { log_error "Sudo validation failed. Password incorrect or not in sudoers."; exit 1; }
    
    # Background loop to refresh sudo timeout every 60s while the script runs
    # We capture the PID ($!) to kill it cleanly later.
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done > /dev/null 2>&1 &
    SUDO_LOOP_PID=$!

    # SELF-HEALING: Ensure all scripts are executable before proceeding.
    # This prevents "Permission denied" errors if files lost their +x flag.
    echo ""
    log_info "Ensuring execution permissions for all scripts..."
    
    # Check if the helper script exists, then run it explicitly with bash
    if [ -f "./scripts/setup_permissions.sh" ]; then
        bash ./scripts/setup_permissions.sh
    else
        # Fallback inline command in case the file is missing
        find . -name "*.sh" -type f -exec chmod +x {} +
    fi

    # 2. System Configuration (Root Level)
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
        log_warn "Skipping system configuration step."
    fi

    # 3. Package Installation (User/Root Level)
    echo ""
    echo "===================================================================="
    echo " STEP 2: PACKAGES & SHELL SETUP"
    echo "===================================================================="
    bash ./scripts/install_packages.sh

    # 4. Dotfiles Linking (User Level)
    echo ""
    echo "===================================================================="
    echo " STEP 3: DOTFILES LINKING (Stow)"
    echo "===================================================================="
    bash ./scripts/install_dotfiles.sh

    echo ""
    echo "===================================================================="
    echo " END: $(date)"
    echo "===================================================================="

} 2>&1 | tee "$LOG_FILE"
