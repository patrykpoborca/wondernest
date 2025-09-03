#!/bin/bash

# Simple test runner that works with current project structure
# This runs the tests that actually exist

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧪 WonderNest Simple Test Runner${NC}"
echo -e "${CYAN}=================================${NC}"
echo ""

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Cargo not found. Please install Rust first.${NC}"
    echo "Visit https://rustup.rs/ for installation instructions."
    exit 1
fi

echo -e "${CYAN}Building project...${NC}"
cargo build --quiet 2>/dev/null || cargo build

echo ""
echo -e "${CYAN}Running all available tests...${NC}"
echo ""

# Run all tests with nice output
if cargo test -- --nocapture; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi