#!/bin/bash

# Fix all axum-test assertions in test files

echo "Fixing axum-test assertions..."

# Add http::StatusCode import to test files if not present
for file in tests/**/*.rs; do
    if grep -q "assert_status" "$file" 2>/dev/null; then
        if ! grep -q "use http::StatusCode" "$file" 2>/dev/null; then
            # Add the import after the first use statement
            sed -i '' '/^use /a\
use http::StatusCode;' "$file"
        fi
    fi
done

# Replace all incorrect assertions
find tests -name "*.rs" -type f -exec sed -i '' \
    -e 's/\.assert_status_created()/.assert_status(StatusCode::CREATED)/g' \
    -e 's/\.assert_status_ok()/.assert_status(StatusCode::OK)/g' \
    -e 's/\.assert_status_bad_request()/.assert_status(StatusCode::BAD_REQUEST)/g' \
    -e 's/\.assert_status_unauthorized()/.assert_status(StatusCode::UNAUTHORIZED)/g' \
    -e 's/\.assert_status_not_found()/.assert_status(StatusCode::NOT_FOUND)/g' \
    -e 's/\.assert_status_internal_server_error()/.assert_status(StatusCode::INTERNAL_SERVER_ERROR)/g' \
    {} \;

echo "Fixed all axum-test assertions"