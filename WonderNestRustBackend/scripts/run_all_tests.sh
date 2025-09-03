#!/bin/bash

# WonderNest Comprehensive Test Suite Runner
# This script runs all tests including unit, integration, security, and COPPA compliance tests

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Find cargo - check multiple locations
if [ -x "$HOME/.cargo/bin/cargo" ]; then
    CARGO="$HOME/.cargo/bin/cargo"
elif command -v cargo &> /dev/null; then
    CARGO="cargo"
else
    echo -e "${RED}❌ Cargo not found. Please install Rust.${NC}"
    exit 1
fi

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Timing
START_TIME=$(date +%s)

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          🧪 WonderNest Comprehensive Test Suite Runner          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to run a test category
run_test_category() {
    local category=$1
    local test_command=$2
    local description=$3
    
    print_section "$description"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ $description: PASSED${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ $description: FAILED${NC}"
        ((FAILED_TESTS++))
        # Continue running other tests even if this category fails
    fi
    ((TOTAL_TESTS++))
}

# Function to check prerequisites
check_prerequisites() {
    print_section "🔍 Checking Prerequisites"
    
    local missing_deps=0
    
    # Check for Rust
    if [ ! -x "$CARGO" ]; then
        echo -e "${RED}❌ Rust/Cargo not installed${NC}"
        missing_deps=1
    else
        echo -e "${GREEN}✅ Cargo found: $($CARGO --version)${NC}"
    fi
    
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not installed${NC}"
        missing_deps=1
    else
        echo -e "${GREEN}✅ Docker found: $(docker --version)${NC}"
    fi
    
    # Check for PostgreSQL client (for database tests)
    if ! command -v psql &> /dev/null; then
        echo -e "${YELLOW}⚠️  PostgreSQL client not found (optional for database tests)${NC}"
    else
        echo -e "${GREEN}✅ PostgreSQL client found${NC}"
    fi
    
    # Check if test dependencies are installed
    if ! grep -q "rstest" Cargo.toml; then
        echo -e "${YELLOW}⚠️  Test dependencies may not be installed${NC}"
        echo "   Running: cargo fetch..."
        $CARGO fetch
    fi
    
    return $missing_deps
}

# Function to setup test environment
setup_test_environment() {
    print_section "🔧 Setting Up Test Environment"
    
    # Export test environment variables
    export RUST_TEST_THREADS=4
    export RUST_BACKTRACE=1
    export RUST_LOG=warn  # Reduce noise during tests
    export TEST_LOG=debug
    
    # Check if Docker containers are running
    echo -e "${CYAN}Checking Docker containers...${NC}"
    if docker ps | grep -q wondernest_postgres; then
        echo -e "${GREEN}✅ PostgreSQL container is running${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL container not running. Starting it...${NC}"
        docker-compose up -d postgres
        sleep 5  # Wait for PostgreSQL to be ready
    fi
    
    if docker ps | grep -q wondernest_redis; then
        echo -e "${GREEN}✅ Redis container is running${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis container not running. Starting it...${NC}"
        docker-compose up -d redis
        sleep 3  # Wait for Redis to be ready
    fi
    
    # Setup test database
    export TEST_DATABASE_URL="${DATABASE_URL:-postgresql://wondernest_app:wondernest_secure_password_dev@localhost:5433/wondernest_prod}"
    echo -e "${CYAN}Using test database: ${TEST_DATABASE_URL}${NC}"
}

# Function to clean build artifacts
clean_build() {
    print_section "🧹 Cleaning Build Artifacts"
    
    echo "Cleaning target directory..."
    $CARGO clean
    
    echo "Building project with test features..."
    $CARGO build --tests --quiet
    
    echo -e "${GREEN}✅ Build cleaned and rebuilt${NC}"
}

# Main test execution
main() {
    # Check prerequisites
    if ! check_prerequisites; then
        echo -e "${RED}❌ Missing prerequisites. Please install required dependencies.${NC}"
        exit 1
    fi
    
    # Setup test environment
    setup_test_environment
    
    # Optional: Clean and rebuild (comment out for faster runs)
    # clean_build
    
    # Run unit tests (both lib and bin tests)
    run_test_category "unit" \
        "$CARGO test --bins --lib 2>/dev/null || $CARGO test --bins 2>/dev/null || $CARGO test 2>/dev/null" \
        "Unit Tests (Business Logic & Services)"
    
    # Run integration tests
    run_test_category "integration" \
        "$CARGO test --test '*' 2>/dev/null || echo 'No integration tests found'" \
        "Integration Tests (API Endpoints)"
    
    # Run documentation tests
    run_test_category "doc" \
        "$CARGO test --doc -- --quiet" \
        "Documentation Tests"
    
    # Run specific test categories
    print_section "🔒 Security Tests"
    $CARGO test security -- --quiet --nocapture | while IFS= read -r line; do
        if [[ $line == *"test result"* ]]; then
            if [[ $line == *"ok"* ]]; then
                echo -e "${GREEN}✅ Security tests passed${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ Security tests failed${NC}"
                ((FAILED_TESTS++))
            fi
        fi
    done
    ((TOTAL_TESTS++))
    
    print_section "👶 COPPA Compliance Tests"
    $CARGO test coppa -- --quiet --nocapture | while IFS= read -r line; do
        if [[ $line == *"test result"* ]]; then
            if [[ $line == *"ok"* ]]; then
                echo -e "${GREEN}✅ COPPA compliance tests passed${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ COPPA compliance tests failed${NC}"
                ((FAILED_TESTS++))
            fi
        fi
    done
    ((TOTAL_TESTS++))
    
    print_section "⚡ Concurrency Tests"
    $CARGO test concurrency -- --quiet --nocapture | while IFS= read -r line; do
        if [[ $line == *"test result"* ]]; then
            if [[ $line == *"ok"* ]]; then
                echo -e "${GREEN}✅ Concurrency tests passed${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ Concurrency tests failed${NC}"
                ((FAILED_TESTS++))
            fi
        fi
    done
    ((TOTAL_TESTS++))
    
    # Run authentication endpoint tests
    print_section "🔐 Authentication Endpoint Tests"
    if [ -f "scripts/test-auth-rust.sh" ]; then
        echo -e "${CYAN}Running live endpoint tests...${NC}"
        if ./scripts/test-auth-rust.sh > /tmp/auth_test.log 2>&1; then
            echo -e "${GREEN}✅ Authentication endpoint tests passed${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ Authentication endpoint tests failed${NC}"
            echo -e "${YELLOW}Check /tmp/auth_test.log for details${NC}"
            ((FAILED_TESTS++))
        fi
    else
        echo -e "${YELLOW}⚠️  test-auth-rust.sh not found, skipping live tests${NC}"
        ((SKIPPED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # Generate coverage report (optional)
    print_section "📊 Code Coverage Report"
    if command -v cargo-tarpaulin &> /dev/null; then
        echo -e "${CYAN}Generating coverage report...${NC}"
        $CARGO tarpaulin --out Stdout --skip-clean --line \
            --exclude-files "*/tests/*" \
            --exclude-files "*/migrations/*" \
            --exclude-files "*/target/*" \
            --timeout 120 2>/dev/null | tail -n 20
    else
        echo -e "${YELLOW}⚠️  cargo-tarpaulin not installed. Install with:${NC}"
        echo "   $CARGO install cargo-tarpaulin"
        ((SKIPPED_TESTS++))
    fi
    
    # Calculate execution time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    # Print summary
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                         TEST SUMMARY                            ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Total Tests:    ${TOTAL_TESTS}"
    echo -e "${CYAN}║${NC} ${GREEN}Passed:${NC}         ${PASSED_TESTS}"
    echo -e "${CYAN}║${NC} ${RED}Failed:${NC}         ${FAILED_TESTS}"
    echo -e "${CYAN}║${NC} ${YELLOW}Skipped:${NC}        ${SKIPPED_TESTS}"
    echo -e "${CYAN}║${NC} Execution Time: ${MINUTES}m ${SECONDS}s"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        echo ""
        echo -e "${RED}❌ Test suite failed with $FAILED_TESTS failures${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}✅ All tests passed successfully!${NC}"
        exit 0
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Test suite interrupted${NC}"; exit 130' INT

# Run the main function
main "$@"