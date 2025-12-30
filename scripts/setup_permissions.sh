#!/bin/bash
# ==============================================================================
# SCRIPT: setup_permissions.sh
# LOCATION: scripts/setup_permissions.sh
# DESCRIPTION: Recursively finds all .sh files in the repository and makes
#              them executable. Useful after a fresh clone or file transfer.
# ==============================================================================

set -e

# 1. Import Shared Library
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/lib/utils.sh"

# 2. Setup
detect_distro # Just for logging consistency
cd "$REPO_ROOT"

# BRANDING: Yellow Header
log_header "Buttery Permissions Fixer"
log_info "Scanning repository for shell scripts..."

# 3. Execution (The "Find" Strategy)
#    -type f: Only files (ignore directories)
#    -name "*.sh": Only files ending in .sh
#    -exec chmod +x: Apply executable permission
#    -print: Show us what it found

count=0
while IFS= read -r file; do
    # FIX: Add '|| true' to suppress errors in environments (like Docker bind-mounts)
    # where the user might not own the file to change its permissions.
    chmod +x "$file" || true
    
    # Optional: Print only if not already executable, or just print all.
    # Here we print relative path for cleaner output.
    echo -e "   ${GREEN}Fixed:${NC} ./${file#./}"
    ((count++))
done < <(find . -type f -name "*.sh")

# 4. Summary
echo ""
log_success "Permissions updated for $count scripts."
