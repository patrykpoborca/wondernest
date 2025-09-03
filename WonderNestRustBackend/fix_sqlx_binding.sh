#!/bin/bash

echo "Fixing sqlx::query binding syntax..."

for file in tests/**/*.rs; do
    if [ -f "$file" ] && grep -q "sqlx::query(" "$file"; then
        echo "Processing $file"
        
        # This is complex to do with sed, so let's just identify files that need manual fixing
        if grep -q "sqlx::query(" "$file" | head -5; then
            echo "File $file needs manual sqlx::query fix"
        fi
    fi
done

echo "Done identifying files"