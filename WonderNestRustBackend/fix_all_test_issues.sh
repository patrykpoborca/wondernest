#!/bin/bash

echo "Fixing all test issues comprehensively..."

# Fix all test files
for file in tests/**/*.rs; do
    if [ -f "$file" ]; then
        echo "Fixing $file"
        
        # Create a temp file
        temp_file="${file}.tmp"
        
        # Process the file line by line to clean up imports
        awk '
        # Skip duplicate StatusCode imports on same line
        /^use http::StatusCode;use/ { 
            gsub(/use http::StatusCode;/, "")
            print "use http::StatusCode;"
            print
            next
        }
        # Skip standalone StatusCode imports after we already have one
        /^use http::StatusCode;$/ && seen_status { next }
        /^use http::StatusCode;$/ { seen_status=1 }
        # Print all other lines
        { print }
        ' "$file" > "$temp_file"
        
        # Move temp file back
        mv "$temp_file" "$file"
    fi
done

# Fix concurrency test email move issue
echo "Fixing concurrency tests email borrow issue..."
sed -i '' 's/"email": email,/"email": \&email,/g' tests/integration/concurrency_tests.rs

# Now run cargo fix
echo "Running cargo fix --tests..."
$HOME/.cargo/bin/cargo fix --tests --allow-dirty --allow-staged 2>/dev/null || true

echo "All test issues fixed!"