#!/bin/bash

# Script to fix all handler signatures to remove Request extraction and use proper Claims extractor

echo "Fixing handler signatures in all route files..."

# First, add the extractors import to all route files
for file in src/routes/v1/*.rs src/routes/v2/*.rs; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        
        # Add extractors import after the crate imports if not already there
        if ! grep -q "use crate::extractors" "$file"; then
            sed -i '' '/use crate::{/,/};/s/use crate::{/use crate::{\n    extractors::AuthClaims,/' "$file"
        fi
        
        # Remove the extract_claims import and Request from middleware imports
        sed -i '' 's/, extract_claims//g' "$file"
        sed -i '' 's/extract_claims, //g' "$file"
        sed -i '' 's/extract_claims//g' "$file"
        
        # Remove Request from extract imports
        sed -i '' 's/, Request//g' "$file"
        sed -i '' 's/Request, //g' "$file"
        sed -i '' 's/extract::{Request/extract::{/g' "$file"
    fi
done

# Now fix the handler function signatures and bodies
cat << 'EOF' > /tmp/fix_handlers.py
#!/usr/bin/env python3
import re
import sys

def fix_handler_signatures(content):
    # Pattern to match handler functions with Request parameter
    pattern = r'async fn (\w+)\([^)]*\) -> AppResult<[^>]+>'
    
    # Find all handler functions
    functions = re.findall(pattern, content)
    
    for func_name in functions:
        # Find the full function including body
        func_pattern = rf'async fn {func_name}\([^{{]*\{{[^{{]*extract_claims\(&req\)[^}}]*\}}'
        
        # Replace Request parameter with AuthClaims
        # Pattern 1: State, Request, other params
        content = re.sub(
            rf'async fn {func_name}\(\s*State\((\w+)\): State<AppState>,\s*req: Request,',
            rf'async fn {func_name}(\n    State(\1): State<AppState>,\n    AuthClaims(claims): AuthClaims,',
            content
        )
        
        # Pattern 2: State, Request at end
        content = re.sub(
            rf'async fn {func_name}\(\s*State\((\w+)\): State<AppState>,\s*([^,]+),\s*req: Request\s*\)',
            rf'async fn {func_name}(\n    State(\1): State<AppState>,\n    \2,\n    AuthClaims(claims): AuthClaims\n)',
            content
        )
        
        # Pattern 3: Multiple params with Request
        content = re.sub(
            rf'async fn {func_name}\(\s*State\((\w+)\): State<AppState>,\s*([^,]+),\s*([^,]+),\s*req: Request\s*\)',
            rf'async fn {func_name}(\n    State(\1): State<AppState>,\n    \2,\n    \3,\n    AuthClaims(claims): AuthClaims\n)',
            content
        )
        
        # Pattern 4: Just State and Request
        content = re.sub(
            rf'async fn {func_name}\(\s*State\((\w+)\): State<AppState>,\s*req: Request\s*\)',
            rf'async fn {func_name}(\n    State(\1): State<AppState>,\n    AuthClaims(claims): AuthClaims\n)',
            content
        )
    
    # Replace extract_claims calls with direct claims usage
    content = re.sub(
        r'let _?claims = extract_claims\(&req\)\.ok_or_else\(\|\| \{[^}]+\}\)\?;',
        '// Claims are now extracted via AuthClaims extractor',
        content
    )
    
    # Replace _claims with claims where used
    content = re.sub(r'\b_claims\b', 'claims', content)
    
    # For file_upload.rs with Multipart - special case
    content = re.sub(
        r'async fn upload_file\(\s*State\((\w+)\): State<AppState>,\s*mut (\w+): Multipart,\s*req: Request',
        r'async fn upload_file(\n    State(\1): State<AppState>,\n    AuthClaims(claims): AuthClaims,\n    mut \2: Multipart',
        content
    )
    
    return content

if __name__ == "__main__":
    for filepath in sys.argv[1:]:
        try:
            with open(filepath, 'r') as f:
                content = f.read()
            
            fixed_content = fix_handler_signatures(content)
            
            with open(filepath, 'w') as f:
                f.write(fixed_content)
            
            print(f"Fixed {filepath}")
        except Exception as e:
            print(f"Error processing {filepath}: {e}")
EOF

chmod +x /tmp/fix_handlers.py

# Run the Python script on all route files
python3 /tmp/fix_handlers.py src/routes/v1/*.rs src/routes/v2/*.rs

echo "Handler signatures fixed!"