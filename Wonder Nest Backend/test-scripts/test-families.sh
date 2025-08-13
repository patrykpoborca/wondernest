#!/bin/bash

# Family and Children Management Test Script
# Tests family creation, management, and children profiles

set -e  # Exit on error

# Configuration
BASE_URL="${BASE_URL:-http://localhost:8080}"

# Load access token from environment or .env file
if [ -f .env ]; then
    source .env
fi

if [ -z "$ACCESS_TOKEN" ]; then
    echo "ERROR: No ACCESS_TOKEN found. Please run ./auth-flow.sh first."
    exit 1
fi

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

make_authenticated_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local curl_cmd="curl -s -w \"\\n%{http_code}\" -X $method"
    curl_cmd="$curl_cmd -H \"Authorization: Bearer $ACCESS_TOKEN\""
    curl_cmd="$curl_cmd -H \"Content-Type: application/json\""
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    curl_cmd="$curl_cmd \"$BASE_URL$endpoint\""
    
    eval "$curl_cmd" 2>/dev/null || echo -e "\n000"
}

make_unauthenticated_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local curl_cmd="curl -s -w \"\\n%{http_code}\" -X $method"
    curl_cmd="$curl_cmd -H \"Content-Type: application/json\""
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    curl_cmd="$curl_cmd \"$BASE_URL$endpoint\""
    
    eval "$curl_cmd" 2>/dev/null || echo -e "\n000"
}

test_get_families() {
    print_test "Get User Families (GET /api/v1/families)"
    
    response=$(make_authenticated_request "GET" "/api/v1/families")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Get families successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local message=$(echo "$body" | jq -r '.message // empty')
            if [ -n "$message" ]; then
                print_info "Response: $message"
            fi
        else
            print_info "Response: $body"
        fi
    else
        print_error "Get families failed - Status: $http_code"
        print_info "Response: $body"
    fi
    echo
}

test_get_families_unauthorized() {
    print_test "Get Families Without Authentication"
    
    response=$(make_unauthenticated_request "GET" "/api/v1/families")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "401" ]; then
        print_success "Correctly rejected unauthorized access - Status: $http_code"
    else
        print_error "Should reject unauthorized access - Status: $http_code"
    fi
    echo
}

test_create_family() {
    print_test "Create Family (POST /api/v1/families)"
    
    local family_data="{
        \"name\": \"Test Family $(date +%s)\",
        \"description\": \"A test family created by automated testing\",
        \"timezone\": \"America/New_York\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/families" "$family_data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "201" ]; then
        print_success "Create family successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local message=$(echo "$body" | jq -r '.message // empty')
            if [ -n "$message" ]; then
                print_info "Response: $message"
            fi
        else
            print_info "Response: $body"
        fi
    else
        print_error "Create family failed - Status: $http_code"
        print_info "Response: $body"
    fi
    echo
}

test_create_family_minimal() {
    print_test "Create Family With Minimal Data"
    
    local minimal_family_data="{
        \"name\": \"Minimal Family $(date +%s)\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/families" "$minimal_family_data")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        print_success "Create minimal family successful - Status: $http_code"
    else
        print_info "Create minimal family - Status: $http_code (validation may be implemented)"
    fi
    echo
}

test_create_family_validation() {
    print_test "Create Family Validation Errors"
    
    # Test empty name
    local empty_name_data="{
        \"name\": \"\",
        \"description\": \"Family with empty name\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/families" "$empty_name_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected empty family name - Status: $http_code"
    else
        print_info "Empty name validation - Status: $http_code (may be implemented differently)"
    fi
    
    # Test very long name
    local long_name_data="{
        \"name\": \"$(printf 'A%.0s' {1..500})\",
        \"description\": \"Family with very long name\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/families" "$long_name_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected overly long family name - Status: $http_code"
    else
        print_info "Long name validation - Status: $http_code (may handle gracefully)"
    fi
    echo
}

test_create_family_unauthorized() {
    print_test "Create Family Without Authentication"
    
    local family_data="{
        \"name\": \"Unauthorized Family\",
        \"description\": \"Should not be created\"
    }"
    
    response=$(make_unauthenticated_request "POST" "/api/v1/families" "$family_data")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "401" ]; then
        print_success "Correctly rejected unauthorized family creation - Status: $http_code"
    else
        print_error "Should reject unauthorized family creation - Status: $http_code"
    fi
    echo
}

test_get_children() {
    print_test "Get Family Children (GET /api/v1/children)"
    
    response=$(make_authenticated_request "GET" "/api/v1/children")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Get children successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local message=$(echo "$body" | jq -r '.message // empty')
            if [ -n "$message" ]; then
                print_info "Response: $message"
            fi
        else
            print_info "Response: $body"
        fi
    else
        print_error "Get children failed - Status: $http_code"
        print_info "Response: $body"
    fi
    echo
}

test_create_child() {
    print_test "Create Child Profile (POST /api/v1/children)"
    
    # Use a fake UUID for family ID since this is a TODO endpoint
    local family_id="12345678-1234-1234-1234-123456789012"
    local birth_date=$(date -d '5 years ago' '+%Y-%m-%d' 2>/dev/null || date -v-5y '+%Y-%m-%d' 2>/dev/null || echo "2019-01-01")
    
    local child_data="{
        \"familyId\": \"$family_id\",
        \"name\": \"Test Child $(date +%s)\",
        \"birthDate\": \"$birth_date\",
        \"gender\": \"female\",
        \"interests\": [\"stories\", \"music\", \"games\"]
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/children" "$child_data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "201" ]; then
        print_success "Create child successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local message=$(echo "$body" | jq -r '.message // empty')
            if [ -n "$message" ]; then
                print_info "Response: $message"
            fi
        else
            print_info "Response: $body"
        fi
    else
        print_error "Create child failed - Status: $http_code"
        print_info "Response: $body"
    fi
    echo
}

test_create_child_different_ages() {
    print_test "Create Children of Different Ages"
    
    local family_id="12345678-1234-1234-1234-123456789012"
    local ages=(1 3 5 8 10)
    
    for age in "${ages[@]}"; do
        local birth_date=$(date -d "$age years ago" '+%Y-%m-%d' 2>/dev/null || date -v-${age}y '+%Y-%m-%d' 2>/dev/null || echo "2019-01-01")
        local child_data="{
            \"familyId\": \"$family_id\",
            \"name\": \"Child Age $age\",
            \"birthDate\": \"$birth_date\",
            \"gender\": \"male\",
            \"interests\": [\"stories\", \"music\"]
        }"
        
        response=$(make_authenticated_request "POST" "/api/v1/children" "$child_data")
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" = "201" ]; then
            print_info "Created child age $age - Status: $http_code"
        else
            print_info "Child age $age creation - Status: $http_code"
        fi
    done
    echo
}

test_create_child_validation() {
    print_test "Create Child Validation Errors"
    
    local family_id="12345678-1234-1234-1234-123456789012"
    
    # Test empty name
    local empty_name_data="{
        \"familyId\": \"$family_id\",
        \"name\": \"\",
        \"birthDate\": \"2020-01-01\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/children" "$empty_name_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected empty child name - Status: $http_code"
    else
        print_info "Empty name validation - Status: $http_code (may be implemented differently)"
    fi
    
    # Test invalid birth date
    local invalid_date_data="{
        \"familyId\": \"$family_id\",
        \"name\": \"Invalid Date Child\",
        \"birthDate\": \"not-a-date\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/children" "$invalid_date_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected invalid birth date - Status: $http_code"
    else
        print_info "Invalid date validation - Status: $http_code (may be implemented differently)"
    fi
    
    # Test future birth date
    local future_date=$(date -d '1 year' '+%Y-%m-%d' 2>/dev/null || date -v+1y '+%Y-%m-%d' 2>/dev/null || echo "2025-01-01")
    local future_date_data="{
        \"familyId\": \"$family_id\",
        \"name\": \"Future Child\",
        \"birthDate\": \"$future_date\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/children" "$future_date_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected future birth date - Status: $http_code"
    else
        print_info "Future date validation - Status: $http_code (may be implemented differently)"
    fi
    echo
}

test_unicode_support() {
    print_test "Unicode and Special Character Support"
    
    local family_id="12345678-1234-1234-1234-123456789012"
    
    # Test Unicode characters
    local unicode_data="{
        \"familyId\": \"$family_id\",
        \"name\": \"小明 👶\",
        \"birthDate\": \"2020-01-01\",
        \"interests\": [\"故事 📚\", \"音乐 🎵\"]
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/children" "$unicode_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        print_success "Unicode characters handled correctly - Status: $http_code"
    else
        print_info "Unicode character handling - Status: $http_code"
    fi
    
    # Test special characters in family name
    local special_family_data="{
        \"name\": \"The O'Connor-Smith Family #1\",
        \"description\": \"Family with special chars: !@#$%^&*()_+-=\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/families" "$special_family_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        print_success "Special characters in family name handled correctly - Status: $http_code"
    else
        print_info "Special character handling - Status: $http_code"
    fi
    echo
}

test_security() {
    print_test "Security Tests (SQL Injection & XSS Prevention)"
    
    local family_id="12345678-1234-1234-1234-123456789012"
    
    # Test SQL injection attempt
    local sql_injection_data="{
        \"name\": \"'; DROP TABLE families; --\",
        \"description\": \"'; DELETE FROM families; --\"
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/families" "$sql_injection_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "SQL injection attempt properly blocked - Status: $http_code"
    elif [ "$http_code" = "201" ]; then
        print_info "SQL injection attempt handled (may be sanitized) - Status: $http_code"
    else
        print_info "SQL injection handling - Status: $http_code"
    fi
    
    # Test XSS attempt
    local xss_data="{
        \"familyId\": \"$family_id\",
        \"name\": \"<script>alert('xss')</script>\",
        \"birthDate\": \"2020-01-01\",
        \"interests\": [\"<img src=x onerror=alert('xss')>\"]
    }"
    
    response=$(make_authenticated_request "POST" "/api/v1/children" "$xss_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "XSS attempt properly blocked - Status: $http_code"
    elif [ "$http_code" = "201" ]; then
        print_info "XSS attempt handled (may be sanitized) - Status: $http_code"
    else
        print_info "XSS handling - Status: $http_code"
    fi
    echo
}

test_performance() {
    print_test "Performance Tests"
    
    # Test multiple rapid requests
    print_info "Testing 5 rapid GET /api/v1/families requests..."
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    for i in {1..5}; do
        make_authenticated_request "GET" "/api/v1/families" >/dev/null 2>&1
    done
    
    end_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    if command -v bc >/dev/null 2>&1; then
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null)
        avg_time=$(echo "scale=3; $duration / 5" | bc -l)
        print_success "5 requests completed in ${duration}s (avg: ${avg_time}s per request)"
    else
        print_info "Performance timing not available (bc not installed)"
    fi
    echo
}

# Main execution
print_header "WonderNest Family Management Test Suite"

echo -e "${BLUE}Base URL: $BASE_URL${NC}"
echo -e "${BLUE}Using Access Token: ${ACCESS_TOKEN:0:20}...${NC}"
echo

# Test family endpoints
test_get_families_unauthorized
test_get_families
test_create_family_unauthorized
test_create_family
test_create_family_minimal
test_create_family_validation

# Test children endpoints
test_get_children
test_create_child
test_create_child_different_ages
test_create_child_validation

# Test special cases
test_unicode_support
test_security
test_performance

print_header "Family Management Test Complete"

print_info "All family and children management endpoints have been tested."
print_info "Note: Many endpoints are currently TODO implementations."

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Run content tests: ./test-content.sh"
echo "  2. Run audio tests: ./test-audio.sh"
echo "  3. Run analytics tests: ./test-analytics.sh"