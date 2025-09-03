#!/bin/bash

# Quick test to verify Rust code compiles without Docker
# This is faster than Docker build for testing compilation

echo "🦀 Testing Rust compilation..."
echo "================================"

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo is not installed. Install Rust from https://rustup.rs/"
    echo ""
    echo "To install Rust, run:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

echo "✅ Cargo found: $(cargo --version)"
echo ""

# Try to compile (check only, don't build)
echo "🔍 Checking code compilation..."
cargo check 2>&1 | tail -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ Code compiles successfully!"
    echo ""
    echo "You can now build the Docker container with:"
    echo "  ./rebuild-docker.sh"
else
    echo ""
    echo "❌ Compilation failed. See errors above."
    exit 1
fi