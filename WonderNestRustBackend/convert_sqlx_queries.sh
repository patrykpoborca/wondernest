#!/bin/bash

echo "Converting sqlx::query! to runtime sqlx::query..."

# Replace sqlx::query! with sqlx::query and update the pattern
for file in tests/**/*.rs; do
    if [ -f "$file" ] && grep -q "sqlx::query!" "$file"; then
        echo "Converting $file"
        
        # Convert sqlx::query! to sqlx::query
        sed -i '' 's/sqlx::query!/sqlx::query/g' "$file"
        
        # Convert sqlx::query_scalar! to sqlx::query_scalar  
        sed -i '' 's/sqlx::query_scalar!/sqlx::query_scalar/g' "$file"
        
        echo "Converted $file"
    fi
done

echo "All sqlx macros converted to runtime queries"