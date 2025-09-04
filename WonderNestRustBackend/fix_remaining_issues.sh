#!/bin/bash

# Fix duplicate imports
for file in src/routes/v1/*.rs; do
    echo "Fixing duplicates in $file..."
    # Remove duplicate error import lines
    sed -i '' 's/error::{AppError, AppResult},$/error::{AppError, AppResult},/g' "$file"
    sed -i '' ':a;N;$!ba;s/error::{AppError, AppResult},\n[[:space:]]*error::{AppError, AppResult},/error::{AppError, AppResult},/g' "$file"
done

# Fix remaining into_response() patterns that return errors in other contexts
for file in src/routes/v1/*.rs; do
    echo "Fixing remaining into_response() patterns in $file..."
    
    # Fix patterns like: return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { ... })).into_response());
    perl -i -pe 's/return Ok\(\(StatusCode::BAD_REQUEST, Json\(MessageResponse \{\s*message: "([^"]+)"\.to_string\(\)\s*\}\)\)\.into_response\(\)\)/return Err(AppError::BadRequest("$1".to_string()))/g' "$file"
    
    # Fix patterns with other status codes
    perl -i -pe 's/return Ok\(\(StatusCode::NOT_FOUND, Json\(MessageResponse \{\s*message: "([^"]+)"\.to_string\(\)\s*\}\)\)\.into_response\(\)\)/return Err(AppError::NotFound("$1".to_string()))/g' "$file"
done

# Fix v1/mod.rs specifically
echo "Fixing v1/mod.rs..."
sed -i '' 's/error::{AppError, AppResult},middleware/error::{AppError, AppResult},\n    middleware/g' src/routes/v1/mod.rs

echo "Done!"