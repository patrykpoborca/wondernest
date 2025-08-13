#!/bin/bash

# Run All Tests Script
# Executes the complete test suite for WonderNest Backend

set -e  # Exit on error

# Configuration
BASE_URL="${BASE_URL:-http://localhost:8080}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test results tracking
declare -a test_results
declare -a test_names

# Functions
print_header() {
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BOLD}${BLUE}==========================================${NC}"
}

print_section() {
    echo -e "${BOLD}${YELLOW}--- $1 ---${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

run_test_script() {
    local script_name="$1"
    local description="$2"
    
    print_section "Running $description"
    
    if [ ! -f "$script_name" ]; then
        print_error "Test script not found: $script_name"
        test_results+=("FAILED")
        test_names+=("$description")
        return 1
    fi
    
    if [ ! -x "$script_name" ]; then
        chmod +x "$script_name"
    fi
    
    local start_time=$(date +%s)
    
    if ./"$script_name"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "$description completed in ${duration}s"
        test_results+=("PASSED")
        test_names+=("$description")
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_error "$description failed after ${duration}s"
        test_results+=("FAILED")
        test_names+=("$description")
        return 1
    fi
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if server is running
    if curl -s "$BASE_URL/health" >/dev/null 2>&1; then
        print_success "WonderNest Backend is running at $BASE_URL"
    else
        print_error "WonderNest Backend is not accessible at $BASE_URL"
        print_info "Please start the backend server before running tests"
        exit 1
    fi
    
    # Check for required tools
    local missing_tools=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        print_info "jq not found - JSON parsing will be limited"
        print_info "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        print_info "bc not found - performance timing will be limited"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    print_success "All prerequisites met"
    echo
}

print_summary() {
    print_header "Test Summary"
    
    local total_tests=${#test_results[@]}
    local passed_tests=0
    local failed_tests=0
    
    echo -e "${BOLD}Test Results:${NC}"
    echo
    
    for i in "${!test_results[@]}"; do
        local result="${test_results[$i]}"
        local name="${test_names[$i]}"
        
        if [ "$result" = "PASSED" ]; then
            print_success "$name"
            ((passed_tests++))
        else
            print_error "$name"
            ((failed_tests++))
        fi
    done
    
    echo
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  Total Tests: $total_tests"
    echo -e "  ${GREEN}Passed: $passed_tests${NC}"
    echo -e "  ${RED}Failed: $failed_tests${NC}"
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "\n${BOLD}${GREEN}🎉 All tests passed! 🎉${NC}"
        return 0
    else
        echo -e "\n${BOLD}${RED}❌ Some tests failed. Please review the output above.${NC}"
        return 1
    fi
}

cleanup() {
    print_section "Cleanup"
    
    # Remove temporary files if any were created
    if [ -f .env ]; then
        print_info "Removing temporary .env file"
        rm -f .env
    fi
    
    print_info "Cleanup complete"
}

# Signal handlers
trap cleanup EXIT
trap 'echo -e "\n${RED}Tests interrupted${NC}"; exit 1' INT TERM

# Main execution
print_header "WonderNest Backend - Complete Test Suite"

echo -e "${BLUE}Starting comprehensive test suite...${NC}"
echo -e "${BLUE}Base URL: $BASE_URL${NC}"
echo -e "${BLUE}Timestamp: $(date)${NC}"
echo

# Check prerequisites
check_prerequisites

# Run test scripts in order
print_info "Running tests in sequence..."
echo

# 1. Health checks (no authentication required)
run_test_script "health-checks.sh" "Health Monitoring Tests"
echo

# 2. Authentication flow (creates tokens for subsequent tests)
run_test_script "auth-flow.sh" "Authentication Flow Tests"
echo

# 3. Family management (requires authentication)
run_test_script "test-families.sh" "Family Management Tests" || true
echo

# 4. Content management (requires authentication) - if implemented
if [ -f "test-content.sh" ]; then
    run_test_script "test-content.sh" "Content Management Tests" || true
    echo
fi

# 5. Audio management (requires authentication) - if implemented
if [ -f "test-audio.sh" ]; then
    run_test_script "test-audio.sh" "Audio Management Tests" || true
    echo
fi

# 6. Analytics (requires authentication) - if implemented
if [ -f "test-analytics.sh" ]; then
    run_test_script "test-analytics.sh" "Analytics Tests" || true
    echo
fi

# 7. Security tests - if implemented
if [ -f "security-tests.sh" ]; then
    run_test_script "security-tests.sh" "Security Tests" || true
    echo
fi

# 8. Performance tests - if implemented
if [ -f "performance-tests.sh" ]; then
    run_test_script "performance-tests.sh" "Performance Tests" || true
    echo
fi

# Print final summary
print_summary

# Exit with appropriate code
if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi