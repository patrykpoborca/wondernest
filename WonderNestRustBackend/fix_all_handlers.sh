#!/bin/bash

cd /Users/patrykpoborca/Documents/personal_projects/wonder_nest/WonderNestRustBackend

echo "Fixing all Request parameters in handler files..."

# List of files to fix
files=(
    "src/routes/v1/audio.rs"
    "src/routes/v1/auth.rs" 
    "src/routes/v1/content.rs"
    "src/routes/v1/coppa.rs"
    "src/routes/v1/family.rs"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        
        # Replace Request parameters with AuthClaims
        sed -i '' 's/req: Request,/AuthClaims(claims): AuthClaims,/g' "$file"
        
        # Fix the claims extraction pattern - more specific
        sed -i '' 's/let claims = (&req)\.ok_or_else.*{/let _claims_check = \&claims;/g' "$file"
        sed -i '' '/tracing::warn!("No family context in token");/d' "$file"
        sed -i '' '/AppError::BadRequest("No family context in token"\.to_string())/d' "$file"
        
        # Remove orphaned })?; lines
        sed -i '' '/^[[:space:]]*})?;[[:space:]]*$/d' "$file"
        
        echo "Fixed $file"
    else
        echo "Warning: $file not found"
    fi
done

echo "All Request handlers fixed!"