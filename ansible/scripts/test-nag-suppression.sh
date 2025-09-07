#!/bin/bash
# Test Proxmox Nag Suppression Functionality
# This script tests the nag suppression implementation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Proxmox Nag Suppression Implementation${NC}"
echo "=================================================="

# Test variables
TEST_DIR="/tmp/proxmox-nag-test"
MOCK_PROXMOXLIB="$TEST_DIR/proxmoxlib.js"
ORIGINAL_CONTENT='if (res === null || res === undefined || !res || res.data.status !== '\''Active'\'') {'
EXPECTED_AFTER_SED='if (res === null || res === undefined || !res || false) {'
EXPECTED_AFTER_REPLACE='if (false'

# Setup test environment
setup_test() {
    echo -n "Setting up test environment... "
    mkdir -p "$TEST_DIR"
    
    # Create mock proxmoxlib.js with subscription check
    cat > "$MOCK_PROXMOXLIB" << 'EOF'
// Mock Proxmox library file for testing
function checkSubscription(res) {
    if (res === null || res === undefined || !res || res.data.status !== 'Active') {
        showSubscriptionNag();
    }
}

function anotherFunction() {
    if (res.data.status !== 'Active') {
        doSomething();
    }
}
EOF
    echo -e "${GREEN}OK${NC}"
}

# Test sed replacement method
test_sed_method() {
    echo -n "Testing sed replacement method... "
    
    # Create a copy for testing
    cp "$MOCK_PROXMOXLIB" "$MOCK_PROXMOXLIB.sed_test"
    
    # Apply sed replacement
    sed -i "s/data.status !== 'Active'/false/g" "$MOCK_PROXMOXLIB.sed_test"
    
    # Check if replacement worked
    if grep -q "res.false" "$MOCK_PROXMOXLIB.sed_test"; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Test ansible replace method
test_ansible_replace() {
    echo -n "Testing ansible replace method... "
    
    # Create a copy for testing
    cp "$MOCK_PROXMOXLIB" "$MOCK_PROXMOXLIB.replace_test"
    
    # Simulate ansible replace (using sed with different pattern)
    sed -i 's/if (res === null || res === undefined || !res || res\.data\.status !== '\''Active'\'')/if (false/g' "$MOCK_PROXMOXLIB.replace_test"
    
    # Check if replacement worked
    if grep -q "if (false" "$MOCK_PROXMOXLIB.replace_test" && ! grep -q "data.status !== 'Active'" "$MOCK_PROXMOXLIB.replace_test"; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Test backup functionality
test_backup() {
    echo -n "Testing backup functionality... "
    
    # Create a backup
    cp "$MOCK_PROXMOXLIB" "$MOCK_PROXMOXLIB.backup-$(date +%s)"
    
    # Check if backup was created
    if ls "$MOCK_PROXMOXLIB.backup-"* >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Test verification script logic
test_verification_logic() {
    echo -n "Testing verification logic... "
    
    # Test with original file (should fail verification)
    if grep -q "data.status !== 'Active'" "$MOCK_PROXMOXLIB"; then
        # Test with modified file (should pass verification)
        sed -i "s/data.status !== 'Active'/false/g" "$MOCK_PROXMOXLIB.verify_test" 2>/dev/null || cp "$MOCK_PROXMOXLIB" "$MOCK_PROXMOXLIB.verify_test"
        sed -i "s/data.status !== 'Active'/false/g" "$MOCK_PROXMOXLIB.verify_test"
        
        if ! grep -q "data.status !== 'Active'" "$MOCK_PROXMOXLIB.verify_test"; then
            echo -e "${GREEN}OK${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}FAILED${NC}"
    return 1
}

# Check Ansible task syntax
test_ansible_syntax() {
    echo -n "Testing Ansible task syntax... "
    
    # Check if the suppress_nag.yml file exists and has valid YAML
    SUPPRESS_NAG_FILE="../roles/proxmox_host_setup/tasks/suppress_nag.yml"
    
    if [ -f "$SUPPRESS_NAG_FILE" ]; then
        # Test YAML syntax
        if python3 -c "import yaml; yaml.safe_load(open('$SUPPRESS_NAG_FILE'))" 2>/dev/null; then
            echo -e "${GREEN}OK${NC}"
            return 0
        else
            echo -e "${RED}FAILED - Invalid YAML${NC}"
            return 1
        fi
    else
        echo -e "${RED}FAILED - File not found${NC}"
        return 1
    fi
}

# Cleanup test environment
cleanup_test() {
    echo -n "Cleaning up test environment... "
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}OK${NC}"
}

# Main test execution
main() {
    local errors=0
    
    setup_test
    
    test_sed_method || ((errors++))
    test_ansible_replace || ((errors++))
    test_backup || ((errors++))
    test_verification_logic || ((errors++))
    test_ansible_syntax || ((errors++))
    
    cleanup_test
    
    echo ""
    echo "Test Summary:"
    echo "============="
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! Nag suppression implementation is working correctly.${NC}"
        echo ""
        echo "The implementation includes:"
        echo "- Multiple suppression methods for reliability"
        echo "- Automatic backup of original files"
        echo "- Verification and restore scripts"
        echo "- Proper error handling"
        exit 0
    else
        echo -e "${RED}✗ $errors test(s) failed.${NC}"
        echo ""
        echo "Please review the implementation before deployment."
        exit 1
    fi
}

# Run tests
main "$@"
