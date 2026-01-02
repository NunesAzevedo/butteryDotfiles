#!/bin/bash
# ==============================================================================
# SCRIPT: backup_packages.sh
# LOCATION: scripts/backup_packages.sh
# DESCRIPTION: Backs up installed packages to text files within os/$DISTRO/.
#              - Supports Arch (Native/AUR) and Fedora (DNF/COPR).
#              - Ensures output format matches install_packages.sh for diffing.
# ==============================================================================

set -e

# 1. Import Shared Library
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

# 2. Setup
detect_distro
TARGET_DIR="$REPO_ROOT/os/$DISTRO"
TOTAL_CHANGES=0 # Local variable to track changes across all steps

# BRANDING
log_header "Starting Package Backup for: $DISTRO"
log_info "📂 Output directory: $TARGET_DIR"

# ==============================================================================
# 3. ARCH LINUX BACKUP
# ==============================================================================
if [ "$DISTRO" == "arch" ]; then
    log_info "Processing Arch Linux packages..."

    # Native Packages (Explicitly installed only)
    # -Qqe: Query all packages, explicit (installed by user), native only
    pacman -Qqen > "/tmp/pkglist_native.tmp"
    
    if check_and_update "$TARGET_DIR/pkglist_native.txt" "/tmp/pkglist_native.tmp" "Arch Native"; then
        TOTAL_CHANGES=1
    fi

    # AUR Packages
    log_info "Processing AUR packages..."
    if pacman -Qqm > /dev/null 2>&1; then
        pacman -Qqm | grep -v '\-debug$' > "/tmp/pkglist_aur.tmp"
    else
        > "/tmp/pkglist_aur.tmp"
    fi
    
    if check_and_update "$TARGET_DIR/pkglist_aur.txt" "/tmp/pkglist_aur.tmp" "Arch AUR"; then
        TOTAL_CHANGES=1
    fi

    # Cleanup
    rm -f "/tmp/pkglist_native.tmp" "/tmp/pkglist_aur.tmp"

# ==============================================================================
# 4. FEDORA BACKUP
# ==============================================================================
elif [ "$DISTRO" == "fedora" ]; then
    log_info "Processing Fedora packages..."

    # Native DNF Packages
    # STRATEGY: Use 'rpm -qa' formatted to show ONLY the name.
    # This matches the check command in install_packages.sh, allowing the
    # "Smart Diff" logic to correctly identify installed packages.
    rpm -qa --qf "%{NAME}\n" | sort -u > "/tmp/pkglist_dnf.tmp"
    
    if check_and_update "$TARGET_DIR/pkglist_dnf.txt" "/tmp/pkglist_dnf.tmp" "Fedora Native"; then
        TOTAL_CHANGES=1
    fi

    # COPR Repositories (Robust Parsing)
    log_info "Processing COPR repositories..."
    
    # Extract clean repo names from .repo files
    ls -1 /etc/yum.repos.d/ | grep "copr" | grep ".repo$" | while read -r filename; do
        clean="${filename#_copr:copr.fedorainfracloud.org:}"
        clean="${clean#copr:copr.fedorainfracloud.org:}"
        clean="${clean%.repo}"
        # Replace colons with slashes (user:project -> user/project)
        echo "${clean//://}"
    done | sort | uniq > "/tmp/repolist_copr.tmp"
    
    if check_and_update "$TARGET_DIR/repolist_copr.txt" "/tmp/repolist_copr.tmp" "Fedora COPR Repos"; then
        TOTAL_CHANGES=1
    fi

    # Cleanup
    rm -f "/tmp/pkglist_dnf.tmp" "/tmp/repolist_copr.tmp"
fi

# ==============================================================================
# 5. FLATPAK BACKUP
# ==============================================================================
if command -v flatpak &> /dev/null; then
    log_info "Processing Flatpak applications..."
    
    # Backup using Application ID (e.g., com.spotify.Client)
    flatpak list --app --columns=application > "/tmp/pkglist_flatpak.tmp"
    
    if check_and_update "$TARGET_DIR/pkglist_flatpak.txt" "/tmp/pkglist_flatpak.tmp" "Flatpak ($DISTRO)"; then
        TOTAL_CHANGES=1
    fi
    
    rm -f "/tmp/pkglist_flatpak.tmp"
else
    log_warn "Flatpak command not found. Skipping."
fi

# ==============================================================================
# 6. SUMMARY
# ==============================================================================
echo "---------------------------------------------------"
if [ "$TOTAL_CHANGES" -eq 1 ]; then
    log_warn "Changes detected in package lists."
    echo "💡 Suggested Git commands:"
    echo "   git add os/$DISTRO/"
    echo "   git commit -m \"chore($DISTRO): update package lists\""
else
    log_success "Package lists are already up to date."
fi
echo "---------------------------------------------------"
