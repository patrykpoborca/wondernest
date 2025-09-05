#!/bin/bash

# Test file upload to Rust backend

# First, create a simple test image (1x1 PNG)
echo -n -e '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\x0D\x49\x44\x41\x54\x78\x9C\x62\x00\x01\x00\x00\x05\x00\x01\x0D\x0A\x2D\xB4\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82' > /tmp/test.png

# Get a test JWT token (you'll need to login first)
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZjA0MDM1YWMtYTJjZi00MThlLWIxMTktZTQ4OWRmY2ZjZjE1IiwiZW1haWwiOiJwYXRyeWtAdGVzdC5jb20iLCJleHAiOjE3MzMzNjUxNzMsImlhdCI6MTczMzI3ODc3MywiaXNzIjoid29uZGVybmVzdCIsImF1ZCI6IndvbmRlcm5lc3QtYXBpIn0.GD3O7KAP93cT25CvGjVoJg8e1VJf7bBBhWL6ghJz-P4"

# Upload the file
echo "Uploading test file..."
RESPONSE=$(curl -X POST http://localhost:8080/api/v1/files/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test.png" \
  2>/dev/null)

echo "Response:"
echo "$RESPONSE" | jq .

# Extract file ID if successful
FILE_ID=$(echo "$RESPONSE" | jq -r '.data.id' 2>/dev/null)

if [ "$FILE_ID" != "null" ] && [ -n "$FILE_ID" ]; then
    echo ""
    echo "File uploaded successfully with ID: $FILE_ID"
    echo "Public URL: http://localhost:8080/api/v1/files/$FILE_ID/public"
    
    # Test the public download
    echo ""
    echo "Testing public download..."
    curl -I "http://localhost:8080/api/v1/files/$FILE_ID/public" 2>/dev/null | head -5
else
    echo "Upload failed"
fi

rm -f /tmp/test.png