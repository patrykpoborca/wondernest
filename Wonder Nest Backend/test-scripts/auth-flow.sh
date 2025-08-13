#!/bin/bash

# Authentication Flow Test Script
# Tests complete authentication flow: signup, login, profile, logout

set -e  # Exit on error

# Configuration
BASE_URL="${BASE_URL:-http://localhost:8080}"
TEST_EMAIL="${TEST_EMAIL:-test$(date +%s)@example.com}"  # Unique email each run
TEST_PASSWORD="${TEST_PASSWORD:-TestPassword123!}"
TEST_FIRSTNAME="${TEST_FIRSTNAME:-Test}"
TEST_LASTNAME="${TEST_LASTNAME:-User}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
ACCESS_TOKEN=""
REFRESH_TOKEN=""
USER_ID=""

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

make_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local auth_header="$4"
    
    local curl_cmd="curl -s -w \"\\n%{http_code}\" -X $method"
    
    if [ -n "$auth_header" ]; then
        curl_cmd="$curl_cmd -H \"Authorization: Bearer $auth_header\""
    fi
    
    curl_cmd="$curl_cmd -H \"Content-Type: application/json\""
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    curl_cmd="$curl_cmd \"$BASE_URL$endpoint\""
    
    eval "$curl_cmd" 2>/dev/null || echo -e "\n000"
}

test_signup() {
    print_test "User Registration (POST /api/v1/auth/signup)"
    
    local signup_data="{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"$TEST_FIRSTNAME\",
        \"lastName\": \"$TEST_LASTNAME\",
        \"timezone\": \"America/New_York\",
        \"language\": \"en\"
    }"
    
    response=$(make_request "POST" "/api/v1/auth/signup" "$signup_data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "201" ]; then
        print_success "User registration successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            ACCESS_TOKEN=$(echo "$body" | jq -r '.accessToken // empty')
            REFRESH_TOKEN=$(echo "$body" | jq -r '.refreshToken // empty')
            USER_ID=$(echo "$body" | jq -r '.user.id // empty')
            
            if [ -n "$ACCESS_TOKEN" ] && [ -n "$REFRESH_TOKEN" ]; then
                print_info "Tokens extracted successfully"
                print_info "User ID: $USER_ID"
                export ACCESS_TOKEN
            else
                print_error "Failed to extract tokens from response"
                return 1
            fi
        else
            print_error "jq not available - cannot extract tokens"
            return 1
        fi
    else
        print_error "User registration failed - Status: $http_code"
        print_info "Response: $body"
        return 1
    fi
    echo
}

test_login() {
    print_test "User Login (POST /api/v1/auth/login)"
    
    local login_data="{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }"
    
    response=$(make_request "POST" "/api/v1/auth/login" "$login_data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "User login successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local new_access_token=$(echo "$body" | jq -r '.accessToken // empty')
            local new_refresh_token=$(echo "$body" | jq -r '.refreshToken // empty')
            
            if [ -n "$new_access_token" ]; then
                ACCESS_TOKEN="$new_access_token"
                REFRESH_TOKEN="$new_refresh_token"
                export ACCESS_TOKEN
                print_info "New tokens extracted from login"
            fi
        fi
    else
        print_error "User login failed - Status: $http_code"
        print_info "Response: $body"
        return 1
    fi
    echo
}

test_profile() {
    print_test "Get User Profile (GET /api/v1/auth/me)"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "No access token available for profile test"
        return 1
    fi
    
    response=$(make_request "GET" "/api/v1/auth/me" "" "$ACCESS_TOKEN")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Profile retrieval successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local profile_email=$(echo "$body" | jq -r '.email // empty')
            local profile_id=$(echo "$body" | jq -r '.id // empty')
            local profile_role=$(echo "$body" | jq -r '.role // empty')
            
            print_info "Profile Email: $profile_email"
            print_info "Profile ID: $profile_id"
            print_info "Profile Role: $profile_role"
            
            if [ "$profile_email" = "$TEST_EMAIL" ]; then
                print_success "Profile email matches registered email"
            else
                print_error "Profile email mismatch - Expected: $TEST_EMAIL, Got: $profile_email"
            fi
        fi
    else
        print_error "Profile retrieval failed - Status: $http_code"
        print_info "Response: $body"
        return 1
    fi
    echo
}

test_profile_unauthorized() {
    print_test "Profile Access Without Token (GET /api/v1/auth/me)"
    
    response=$(make_request "GET" "/api/v1/auth/me" "")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "401" ]; then
        print_success "Correctly rejected unauthorized profile access - Status: $http_code"
    else
        print_error "Should reject unauthorized access - Status: $http_code"
    fi
    echo
}

test_profile_invalid_token() {
    print_test "Profile Access With Invalid Token (GET /api/v1/auth/me)"
    
    response=$(make_request "GET" "/api/v1/auth/me" "" "invalid.jwt.token")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "401" ]; then
        print_success "Correctly rejected invalid token - Status: $http_code"
    else
        print_error "Should reject invalid token - Status: $http_code"
    fi
    echo
}

test_logout() {
    print_test "User Logout (POST /api/v1/auth/logout)"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "No access token available for logout test"
        return 1
    fi
    
    response=$(make_request "POST" "/api/v1/auth/logout" "" "$ACCESS_TOKEN")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "User logout successful - Status: $http_code"
        
        if command -v jq >/dev/null 2>&1; then
            local message=$(echo "$body" | jq -r '.message // empty')
            print_info "Logout message: $message"
        fi
        
        # Clear tokens after logout
        ACCESS_TOKEN=""
        REFRESH_TOKEN=""
    else
        print_error "User logout failed - Status: $http_code"
        print_info "Response: $body"
        return 1
    fi
    echo
}

test_invalid_credentials() {
    print_test "Login With Invalid Credentials"
    
    local invalid_login_data="{
        \"email\": \"nonexistent@example.com\",
        \"password\": \"WrongPassword123!\"
    }"
    
    response=$(make_request "POST" "/api/v1/auth/login" "$invalid_login_data")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "401" ]; then
        print_success "Correctly rejected invalid credentials - Status: $http_code"
    else
        print_error "Should reject invalid credentials - Status: $http_code"
    fi
    echo
}

test_validation_errors() {
    print_test "Signup Validation Errors"
    
    # Test invalid email
    local invalid_email_data="{
        \"email\": \"invalid-email\",
        \"password\": \"ValidPass123!\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\"
    }"
    
    response=$(make_request "POST" "/api/v1/auth/signup" "$invalid_email_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected invalid email - Status: $http_code"
    else
        print_info "Invalid email validation - Status: $http_code (may be implemented differently)"
    fi
    
    # Test weak password
    local weak_password_data="{
        \"email\": \"weakpass@example.com\",
        \"password\": \"123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\"
    }"
    
    response=$(make_request "POST" "/api/v1/auth/signup" "$weak_password_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Correctly rejected weak password - Status: $http_code"
    else
        print_info "Weak password validation - Status: $http_code (may be implemented differently)"
    fi
    echo
}

test_duplicate_registration() {
    print_test "Duplicate Email Registration"
    
    # Try to register with the same email again
    local duplicate_data="{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"Duplicate\",
        \"lastName\": \"User\"
    }"
    
    response=$(make_request "POST" "/api/v1/auth/signup" "$duplicate_data")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "409" ] || [ "$http_code" = "400" ]; then
        print_success "Correctly rejected duplicate email - Status: $http_code"
    else
        print_info "Duplicate email handling - Status: $http_code (may be implemented differently)"
    fi
    echo
}

# Main execution
print_header "WonderNest Authentication Flow Test Suite"

echo -e "${BLUE}Base URL: $BASE_URL${NC}"
echo -e "${BLUE}Test Email: $TEST_EMAIL${NC}"
echo

# Test complete authentication flow
test_signup
test_login
test_profile

# Test authentication security
test_profile_unauthorized
test_profile_invalid_token

# Test logout
test_logout

# Test error cases
test_invalid_credentials
test_validation_errors
test_duplicate_registration

print_header "Authentication Flow Test Complete"

if [ -n "$ACCESS_TOKEN" ]; then
    print_info "Access token is available for subsequent tests: ${ACCESS_TOKEN:0:20}..."
    echo "export ACCESS_TOKEN=\"$ACCESS_TOKEN\"" > .env
    print_info "Token saved to .env file for other test scripts"
else
    print_info "No access token available (user may be logged out)"
fi

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Run family tests: ./test-families.sh"
echo "  2. Run content tests: ./test-content.sh"
echo "  3. Run all tests: ./run-all-tests.sh"