#!/bin/bash

# Quick test runner for development
# Runs only fast tests without coverage

set -e

echo "⚡ Quick Test Runner"
echo "==================="
echo ""

# Run only unit tests (fastest)
echo "Running unit tests..."
cargo test --lib -- --quiet

echo ""
echo "✅ Quick tests completed!"
echo ""
echo "For comprehensive testing, run: ./scripts/run_all_tests.sh"