#!/bin/bash

# Fix AppError issues in all route files

for file in src/routes/v1/*.rs; do
    echo "Processing $file..."
    
    # Add AppError import if not present
    if ! grep -q "error::{AppError" "$file"; then
        sed -i '' 's/error::AppResult/error::{AppError, AppResult}/g' "$file"
        
        # If AppResult is not there, add both
        if ! grep -q "error::AppResult" "$file"; then
            sed -i '' 's/use crate::{/use crate::{\n    error::{AppError, AppResult},/g' "$file"
        fi
    fi
    
    # Fix the error patterns - replace into_response() with AppError::BadRequest
    perl -i -pe 's/\(StatusCode::BAD_REQUEST, Json\(MessageResponse \{\s*message: "([^"]+)"\.to_string\(\)\s*\}\)\)\.into_response\(\)/AppError::BadRequest("$1".to_string())/g' "$file"
    
    # Fix patterns with tracing::warn
    perl -i -0pe 's/\{\s*tracing::warn!\("([^"]+)"\);\s*\(StatusCode::BAD_REQUEST, Json\(MessageResponse \{\s*message: "([^"]+)"\.to_string\(\)\s*\}\)\)\.into_response\(\)\s*\}/{\n        tracing::warn!("$1");\n        AppError::BadRequest("$2".to_string())\n    }/g' "$file"
done

echo "Fixed all AppError issues!"