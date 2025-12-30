#!/bin/bash
# ==============================================================================
# SCRIPT: backup_packages.sh
# LOCATION: scripts/backup_packages.sh
# DESCRIPTION: Backs up installed packages to text files within os/$DISTRO/.
#              Supports Arch (Native/AUR) and Fedora (DNF/COPR).
#              STRATEGY: RPM-based extraction + File System Parsing (Robust).
# ==============================================================================

set -e

# 1. Import Shared Library
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

# 2. Setup
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

    # Native Packages
    pacman -Qqen > "/tmp/pkglist_native.tmp"
    check_and_update "$TARGET_DIR/pkglist_native.txt" "/tmp/pkglist_native.tmp" "Arch Native"

    # AUR Packages
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
    log_info "Querying RPM database (Method: Name & Vendor)..."

    # 4.1 Query ALL packages with Vendor info
    # Format: NAME|VENDOR
    # We use RPM directly because it's faster and output format is consistent.
    rpm -qa --qf '%{NAME}|%{VENDOR}\n' > "/tmp/all_pkgs.tmp"

    # 4.2 Process Native Packages
    # Logic: 
    # 1. Filter out GPG Keys (pseudo-packages) and Debug info.
    # 2. Filter out items where Vendor contains "Copr" (case insensitive).
    # 3. Extract just the Name.
    cat "/tmp/all_pkgs.tmp" \
        | grep -vE '^(gpg-pubkey|.*-debuginfo|.*-debugsource)' \
        | grep -v -i 'copr' \
        | cut -d'|' -f1 \
        | sort | uniq > "/tmp/pkglist_dnf.tmp"

    # Safety Check
    if [ -s "/tmp/pkglist_dnf.tmp" ]; then
        check_and_update "$TARGET_DIR/pkglist_dnf.txt" "/tmp/pkglist_dnf.tmp" "Fedora Native"
    else
        log_error "Generated DNF list is empty. RPM query failed."
    fi

    # 4.3 Process COPR Packages
    # Logic: Keep ONLY items where Vendor contains "Copr".
    cat "/tmp/all_pkgs.tmp" \
        | grep -i 'copr' \
        | cut -d'|' -f1 \
        | sort | uniq > "/tmp/pkglist_copr.tmp"

    # It's valid to have 0 COPR packages.
    check_and_update "$TARGET_DIR/pkglist_copr.txt" "/tmp/pkglist_copr.tmp" "Fedora COPR Pkgs"

    # 4.4 Process COPR Repositories (Filesystem Strategy)
    # The most reliable way: Look at the .repo files DNF created.
    # Typical name: _copr:copr.fedorainfracloud.org:atim:lazygit.repo
    # Target: atim/lazygit
    
    log_info "Detecting COPR repositories from /etc/yum.repos.d/..."
    
    ls -1 /etc/yum.repos.d/ | grep "copr" | grep ".repo$" | while read -r filename; do
        # 1. Remove prefix "_copr:copr.fedorainfracloud.org:" or "copr:copr.fedorainfracloud.org:"
        clean="${filename#_copr:copr.fedorainfracloud.org:}"
        clean="${clean#copr:copr.fedorainfracloud.org:}"
        
        # 2. Remove suffix ".repo"
        clean="${clean%.repo}"
        
        # 3. Replace colons with slashes (user:project -> user/project)
        echo "${clean//://}"
    done | sort | uniq > "/tmp/repolist_copr.tmp"
    
    check_and_update "$TARGET_DIR/repolist_copr.txt" "/tmp/repolist_copr.tmp" "Fedora COPR Repos"

    # Cleanup
    rm -f "/tmp/all_pkgs.tmp"
fi

# ==============================================================================
# 5. FLATPAK BACKUP
# ==============================================================================
if command -v flatpak &> /dev/null; then
    log_info "Processing Flatpak applications..."
    
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
