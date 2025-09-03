#!/bin/bash

# Fix duplicate imports in test files

echo "Fixing duplicate imports..."

# Fix integration/auth_endpoints_tests.rs
sed -i '' '/^use http::StatusCode;$/d' tests/integration/auth_endpoints_tests.rs
sed -i '' 's/use axum::http::{StatusCode, Method};/use http::{StatusCode, Method};/' tests/integration/auth_endpoints_tests.rs

# Fix other test files - remove all duplicate StatusCode imports
for file in tests/**/*.rs; do
    if [ -f "$file" ]; then
        # Remove all lines that are just "use http::StatusCode;"
        sed -i '' '/^use http::StatusCode;$/d' "$file"
        # Add single StatusCode import if needed and not already present
        if grep -q "StatusCode::" "$file" 2>/dev/null; then
            if ! grep -q "use.*StatusCode" "$file" 2>/dev/null; then
                sed -i '' '1a\
use http::StatusCode;' "$file"
            fi
        fi
    fi
done

echo "Fixed duplicate imports"