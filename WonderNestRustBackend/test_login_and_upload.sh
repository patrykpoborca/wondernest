#!/bin/bash

# Test login and file upload

# First, create an account or login
echo "Logging in..."
LOGIN_RESPONSE=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }' \
  2>/dev/null)

# Check if login failed, try signup
if echo "$LOGIN_RESPONSE" | grep -q "error"; then
    echo "Login failed, trying signup..."
    SIGNUP_RESPONSE=$(curl -X POST http://localhost:8080/api/v1/auth/signup \
      -H "Content-Type: application/json" \
      -d '{
        "email": "test@example.com",
        "password": "password123",
        "name": "Test User",
        "familyName": "Test Family",
        "timezone": "America/New_York",
        "language": "en"
      }' \
      2>/dev/null)
    
    TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.data.token' 2>/dev/null)
else
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token' 2>/dev/null)
fi

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "Failed to get authentication token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "Got token: ${TOKEN:0:20}..."

# Create a simple test image (1x1 PNG)
echo -n -e '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\x0D\x49\x44\x41\x54\x78\x9C\x62\x00\x01\x00\x00\x05\x00\x01\x0D\x0A\x2D\xB4\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82' > /tmp/test.png

# Upload the file
echo ""
echo "Uploading test file..."
UPLOAD_RESPONSE=$(curl -X POST "http://localhost:8080/api/v1/files/upload?category=game_asset&isPublic=true" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test.png;type=image/png" \
  2>/dev/null)

echo "Upload Response:"
echo "$UPLOAD_RESPONSE" | jq .

# Extract file ID if successful
FILE_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.data.id' 2>/dev/null)

if [ "$FILE_ID" != "null" ] && [ -n "$FILE_ID" ]; then
    echo ""
    echo "✅ File uploaded successfully!"
    echo "File ID: $FILE_ID"
    echo "Public URL: http://localhost:8080/api/v1/files/$FILE_ID/public"
    
    # Test the public download
    echo ""
    echo "Testing public download (no auth required)..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/api/v1/files/$FILE_ID/public")
    
    if [ "$HTTP_STATUS" == "200" ]; then
        echo "✅ Public download works! (HTTP $HTTP_STATUS)"
    else
        echo "❌ Public download failed (HTTP $HTTP_STATUS)"
    fi
    
    # List user's files
    echo ""
    echo "Listing user's files..."
    curl -X GET "http://localhost:8080/api/v1/files?category=game_asset" \
      -H "Authorization: Bearer $TOKEN" \
      2>/dev/null | jq '.data[] | {id: .id, name: .original_name, url: .url}'
else
    echo "❌ Upload failed"
fi

rm -f /tmp/test.png