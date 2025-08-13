#!/bin/bash

# Health Checks Test Script
# Tests all health monitoring endpoints

set -e  # Exit on error

# Configuration
BASE_URL="${BASE_URL:-http://localhost:8080}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ SUCCESS: $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

test_endpoint() {
    local endpoint="$1"
    local expected_status="$2"
    local description="$3"
    
    print_test "$description"
    
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint" 2>/dev/null || echo -e "\n000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "$expected_status" ]; then
        print_success "$description - Status: $http_code"
        if command -v jq >/dev/null 2>&1 && echo "$body" | jq . >/dev/null 2>&1; then
            status_field=$(echo "$body" | jq -r '.status // "N/A"')
            print_info "Response status: $status_field"
            
            # For detailed health check, show service statuses
            if [ "$endpoint" = "/health/detailed" ]; then
                if echo "$body" | jq -e '.services' >/dev/null 2>&1; then
                    echo "$body" | jq -r '.services | to_entries[] | "  \(.key): \(.value.status)"'
                fi
            fi
        else
            print_info "Response: $body"
        fi
        echo
        return 0
    else
        print_error "$description - Expected: $expected_status, Got: $http_code"
        print_info "Response: $body"
        echo
        return 1
    fi
}

# Main execution
print_header "WonderNest Health Checks Test Suite"

echo -e "${BLUE}Base URL: $BASE_URL${NC}"
echo

# Test basic health check
test_endpoint "/health" "200" "Basic Health Check"

# Test detailed health check
test_endpoint "/health/detailed" "200" "Detailed Health Check" || \
test_endpoint "/health/detailed" "503" "Detailed Health Check (Service Unavailable)"

# Test readiness probe
test_endpoint "/health/ready" "200" "Readiness Probe" || \
test_endpoint "/health/ready" "503" "Readiness Probe (Not Ready)"

# Test liveness probe
test_endpoint "/health/live" "200" "Liveness Probe"

# Test startup probe
test_endpoint "/health/startup" "200" "Startup Probe" || \
test_endpoint "/health/startup" "503" "Startup Probe (Starting)"

# Test that health endpoints don't require authentication
print_test "Verifying health endpoints don't require authentication"
auth_response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer invalid_token" "$BASE_URL/health" 2>/dev/null || echo -e "\n000")
auth_http_code=$(echo "$auth_response" | tail -n1)

if [ "$auth_http_code" = "200" ]; then
    print_success "Health endpoints correctly accessible without authentication"
else
    print_error "Health endpoints incorrectly require authentication - Status: $auth_http_code"
fi
echo

# Test invalid HTTP methods
print_test "Testing invalid HTTP methods on health endpoints"
post_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/health" 2>/dev/null || echo -e "\n000")
post_http_code=$(echo "$post_response" | tail -n1)

if [ "$post_http_code" = "405" ] || [ "$post_http_code" = "404" ]; then
    print_success "Health endpoints correctly reject POST method - Status: $post_http_code"
else
    print_error "Health endpoints should reject POST method - Status: $post_http_code"
fi
echo

# Performance test - multiple rapid health checks
print_test "Performance test - 10 rapid health checks"
start_time=$(date +%s.%N)
for i in {1..10}; do
    curl -s "$BASE_URL/health" >/dev/null 2>&1
done
end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")

if [ "$duration" != "N/A" ]; then
    avg_time=$(echo "scale=3; $duration / 10" | bc -l)
    print_success "10 health checks completed in ${duration}s (avg: ${avg_time}s per request)"
else
    print_info "Performance timing not available (bc not installed)"
fi
echo

# Test metrics endpoint (if available)
print_test "Testing metrics endpoint (Prometheus)"
metrics_response=$(curl -s -w "\n%{http_code}" "$BASE_URL/metrics" 2>/dev/null || echo -e "\n000")
metrics_http_code=$(echo "$metrics_response" | tail -n1)

if [ "$metrics_http_code" = "200" ]; then
    print_success "Metrics endpoint available - Status: $metrics_http_code"
    metrics_body=$(echo "$metrics_response" | head -n -1)
    if echo "$metrics_body" | grep -q "http_requests_total\|ktor_"; then
        print_info "Metrics contain expected Ktor/HTTP metrics"
    fi
elif [ "$metrics_http_code" = "503" ]; then
    print_info "Metrics endpoint unavailable (registry not ready) - Status: $metrics_http_code"
else
    print_info "Metrics endpoint not implemented or not accessible - Status: $metrics_http_code"
fi
echo

print_header "Health Checks Test Complete"

print_info "All health monitoring endpoints have been tested."
print_info "Check the output above for any failures or issues."

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Run authentication tests: ./auth-flow.sh"
echo "  2. Run all tests: ./run-all-tests.sh"