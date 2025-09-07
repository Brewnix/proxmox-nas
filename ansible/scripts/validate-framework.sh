#!/bin/bash
# Service Framework Validation Script
# Validates service configurations and framework readiness

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
SERVICES_DIR="$ANSIBLE_DIR/services"

echo -e "${BLUE}Proxmox Service Framework Validation${NC}"
echo "========================================"

# Check if running on Proxmox
check_proxmox() {
    echo -n "Checking Proxmox VE installation... "
    if [ -d "/etc/pve" ]; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo "This script must be run on a Proxmox VE host"
        return 1
    fi
}

# Check community repositories
check_repositories() {
    echo -n "Checking repository configuration... "
    if [ -f "/etc/apt/sources.list.d/pve-enterprise.list" ]; then
        echo -e "${YELLOW}WARNING${NC} - Enterprise repository still present"
        echo "  Run the playbook to configure community repositories"
    elif grep -q "pve-no-subscription" /etc/apt/sources.list.d/* 2>/dev/null; then
        echo -e "${GREEN}OK${NC} - Community repositories configured"
    else
        echo -e "${YELLOW}WARNING${NC} - Community repositories not configured"
        echo "  Run the playbook to configure repositories"
    fi
}

# Validate service files
validate_service_files() {
    echo "Validating service definition files..."
    
    local errors=0
    for service_file in "$SERVICES_DIR"/*.yml; do
        if [ -f "$service_file" ]; then
            echo -n "  $(basename "$service_file")... "
            if python3 -c "import yaml; yaml.safe_load(open('$service_file'))" 2>/dev/null; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}FAILED${NC}"
                ((errors++))
            fi
        fi
    done
    
    if [ $errors -eq 0 ]; then
        echo -e "Service files validation: ${GREEN}PASSED${NC}"
    else
        echo -e "Service files validation: ${RED}FAILED${NC} ($errors errors)"
        return 1
    fi
}

# Check required packages
check_packages() {
    echo "Checking required packages..."
    
    local packages=("python3-yaml" "python3-jinja2" "qemu-kvm" "qemu-server")
    local missing=0
    
    for pkg in "${packages[@]}"; do
        echo -n "  $pkg... "
        if dpkg -l "$pkg" >/dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}MISSING${NC}"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        echo -e "Package check: ${GREEN}PASSED${NC}"
    else
        echo -e "Package check: ${YELLOW}WARNING${NC} ($missing packages missing)"
        echo "  Install missing packages with: apt update && apt install <package>"
    fi
}

# Check Ansible installation
check_ansible() {
    echo -n "Checking Ansible installation... "
    if command -v ansible-playbook >/dev/null 2>&1; then
        local ansible_version
        ansible_version=$(ansible --version | head -n1 | cut -d' ' -f2)
        echo -e "${GREEN}OK${NC} (version $ansible_version)"
        
        # Check for community.general collection
        echo -n "Checking community.general collection... "
        if ansible-galaxy collection list | grep -q community.general; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${YELLOW}MISSING${NC}"
            echo "  Install with: ansible-galaxy collection install community.general"
        fi
    else
        echo -e "${RED}MISSING${NC}"
        echo "  Install Ansible to use this framework"
        return 1
    fi
}

# Check VM ID conflicts
check_vmid_conflicts() {
    echo "Checking for VMID conflicts..."
    
    local vmids=()
    local conflicts=0
    
    # Extract VMIDs from service files
    for service_file in "$SERVICES_DIR"/*.yml; do
        if [ -f "$service_file" ]; then
            local file_vmids
            file_vmids=$(python3 -c "
import yaml
import sys
try:
    with open('$service_file') as f:
        data = yaml.safe_load(f)
        for service_name, config in data.items():
            if isinstance(config, dict) and 'vmid' in config:
                print(config['vmid'])
except Exception as e:
    pass
" 2>/dev/null)
            
            for vmid in $file_vmids; do
                # Match whole VMID as a separate word to avoid substring matches
                if [[ " ${vmids[*]} " =~ (^|[[:space:]])${vmid}([[:space:]]|$) ]]; then
                    echo -e "  ${RED}CONFLICT${NC}: VMID $vmid used multiple times"
                    ((conflicts++))
                else
                    vmids+=("$vmid")
                fi
            done
        fi
    done
    
    if [ $conflicts -eq 0 ]; then
        echo -e "VMID conflict check: ${GREEN}PASSED${NC} (${#vmids[@]} unique VMIDs)"
    else
        echo -e "VMID conflict check: ${RED}FAILED${NC} ($conflicts conflicts)"
        return 1
    fi
}

# Main validation
main() {
    local errors=0
    
    check_proxmox || ((errors++))
    check_repositories
    check_ansible || ((errors++))
    check_packages
    validate_service_files || ((errors++))
    check_vmid_conflicts || ((errors++))
    
    echo ""
    echo "Validation Summary:"
    echo "==================="
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✓ Framework is ready for deployment${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Configure your services in the appropriate YAML files"
        echo "2. Run: ansible-playbook site.yml --extra-vars 'proxmox_api_password=your_password'"
        exit 0
    else
        echo -e "${RED}✗ Found $errors critical issues${NC}"
        echo ""
        echo "Please resolve the issues above before deploying services."
        exit 1
    fi
}

main "$@"
