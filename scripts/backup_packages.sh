#!/bin/bash
# ==============================================================================
# SCRIPT: backup_packages.sh
# LOCATION: scripts/backup_packages.sh
# DESCRIPTION: Backs up installed packages to text files within os/$DISTRO/.
#              Supports Arch (Native/AUR) and Fedora (DNF/COPR).
#              Uses 'utils.sh' to detect changes and avoid unnecessary git updates.
# ==============================================================================

set -e

# 1. Import Shared Library
#    Locates the directory where this script is, then sources lib/utils.sh.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

# 2. Setup
#    Detects distro and sets the target path (e.g., ../os/arch).
detect_distro
TARGET_DIR="$REPO_ROOT/os/$DISTRO"

# BRANDING: Use Yellow Header
log_header "Starting Package Backup for: $DISTRO"
log_info "📂 Output directory: $TARGET_DIR"

# ==============================================================================
# 3. ARCH LINUX BACKUP
# ==============================================================================
if [ "$DISTRO" == "arch" ]; then
    log_info "Processing Arch Linux packages..."

    # Native Packages (Explicitly installed)
    pacman -Qqen > "/tmp/pkglist_native.tmp"
    check_and_update "$TARGET_DIR/pkglist_native.txt" "/tmp/pkglist_native.tmp" "Arch Native"

    # AUR Packages (Foreign)
    # Filters out '-debug' packages to keep the list clean.
    log_info "Processing AUR packages..."
    if pacman -Qqm > /dev/null 2>&1; then
        pacman -Qqm | grep -v '\-debug$' > "/tmp/pkglist_aur.tmp"
    else
        > "/tmp/pkglist_aur.tmp"
    fi
    check_and_update "$TARGET_DIR/pkglist_aur.txt" "/tmp/pkglist_aur.tmp" "Arch AUR"

# ==============================================================================
# 4. FEDORA BACKUP
# ==============================================================================
elif [ "$DISTRO" == "fedora" ]; then
    log_info "Processing Fedora packages..."

    # A. Native DNF Packages
    # Lists user-installed packages, EXCLUDING those from COPR repositories.
    dnf repoquery --userinstalled --qf '%{name} %{reponame}' | grep -v 'copr' | awk '{print $1}' | sort > "/tmp/pkglist_dnf.tmp"
    check_and_update "$TARGET_DIR/pkglist_dnf.txt" "/tmp/pkglist_dnf.tmp" "Fedora Native"

    # B. COPR Packages
    # Lists user-installed packages ONLY from COPR repositories.
    dnf repoquery --userinstalled --qf '%{name} %{reponame}' | grep 'copr' | awk '{print $1}' | sort > "/tmp/pkglist_copr.tmp"
    check_and_update "$TARGET_DIR/pkglist_copr.txt" "/tmp/pkglist_copr.tmp" "Fedora COPR Pkgs"

    # C. COPR Repositories
    # Lists enabled COPR repositories so they can be re-enabled during install.
    dnf repolist enabled | grep 'copr' | awk '{print $1}' | sort > "/tmp/repolist_copr.tmp"
    check_and_update "$TARGET_DIR/repolist_copr.txt" "/tmp/repolist_copr.tmp" "Fedora COPR Repos"
fi

# ==============================================================================
# 5. FLATPAK BACKUP
# ==============================================================================
if command -v flatpak &> /dev/null; then
    log_info "Processing Flatpak applications..."
    
    # Lists only Applications (skips runtimes) and extracts the Application ID.
    flatpak list --app --columns=application > "/tmp/pkglist_flatpak.tmp"
    check_and_update "$TARGET_DIR/pkglist_flatpak.txt" "/tmp/pkglist_flatpak.tmp" "Flatpak ($DISTRO)"
else
    log_warn "Flatpak command not found. Skipping."
fi

# ==============================================================================
# 6. SUMMARY
# ==============================================================================
echo "---------------------------------------------------"
if [ $CHANGES_DETECTED -eq 1 ]; then
    log_warn "Changes detected in package lists."
    echo "💡 Suggested Git commands:"
    echo "   git add os/$DISTRO/"
    echo "   git commit -m 'chore: update $DISTRO package lists'"
else
    log_success "All lists are synchronized."
fi
