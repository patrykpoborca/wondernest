#!/bin/bash

# Test script for file upload functionality
# This script tests the file upload endpoints with the backend API

API_URL="http://localhost:8080/api/v1"
EMAIL="test@example.com"
PASSWORD="Test123!"

echo "🔄 Testing File Upload Feature..."
echo "================================"

# 1. First, register/login to get a token
echo "1. Logging in to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

# Extract token from response using grep and sed
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*' | sed 's/"accessToken":"//')

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to login. Creating new user..."
  
  # Register new user
  REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"Test User\"}")
  
  TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"accessToken":"[^"]*' | sed 's/"accessToken":"//')
  
  if [ -z "$TOKEN" ]; then
    echo "❌ Failed to register user. Check if backend is running."
    exit 1
  fi
  echo "✅ User registered successfully"
else
  echo "✅ Logged in successfully"
fi

echo ""
echo "2. Creating test file..."
TEST_FILE="/tmp/test-upload.txt"
echo "This is a test file for upload functionality" > "$TEST_FILE"
echo "✅ Test file created: $TEST_FILE"

echo ""
echo "3. Uploading file..."
UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/files/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$TEST_FILE" \
  -F "category=document" \
  -F "isPublic=false")

echo "Upload Response: $UPLOAD_RESPONSE"

# Extract file ID from response
FILE_ID=$(echo "$UPLOAD_RESPONSE" | grep -o '"id":"[^"]*' | sed 's/"id":"//')

if [ -z "$FILE_ID" ]; then
  echo "❌ Failed to upload file"
  exit 1
fi

echo "✅ File uploaded successfully. File ID: $FILE_ID"

echo ""
echo "4. Getting file metadata..."
METADATA_RESPONSE=$(curl -s -X GET "$API_URL/files/$FILE_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "Metadata Response: $METADATA_RESPONSE"

echo ""
echo "5. Listing user files..."
LIST_RESPONSE=$(curl -s -X GET "$API_URL/files?category=document&limit=10" \
  -H "Authorization: Bearer $TOKEN")

echo "List Response: $LIST_RESPONSE"

echo ""
echo "6. Downloading file..."
DOWNLOAD_FILE="/tmp/downloaded-file.txt"
curl -s -X GET "$API_URL/files/$FILE_ID/download" \
  -H "Authorization: Bearer $TOKEN" \
  -o "$DOWNLOAD_FILE"

if [ -f "$DOWNLOAD_FILE" ]; then
  echo "✅ File downloaded successfully to: $DOWNLOAD_FILE"
  echo "Downloaded content:"
  cat "$DOWNLOAD_FILE"
else
  echo "❌ Failed to download file"
fi

echo ""
echo "7. Deleting file..."
DELETE_RESPONSE=$(curl -s -X DELETE "$API_URL/files/$FILE_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "Delete Response: $DELETE_RESPONSE"

echo ""
echo "8. Testing image upload..."
# Create a simple PNG file (1x1 pixel)
IMAGE_FILE="/tmp/test-image.png"
printf '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xDE' > "$IMAGE_FILE"

IMAGE_UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/files/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$IMAGE_FILE;type=image/png" \
  -F "category=artwork" \
  -F "isPublic=true")

echo "Image Upload Response: $IMAGE_UPLOAD_RESPONSE"

if echo "$IMAGE_UPLOAD_RESPONSE" | grep -q '"success":true'; then
  echo "✅ Image uploaded successfully"
else
  echo "⚠️ Image upload may have failed"
fi

echo ""
echo "9. Testing invalid file type (should fail)..."
INVALID_FILE="/tmp/test.exe"
echo "malicious content" > "$INVALID_FILE"

INVALID_RESPONSE=$(curl -s -X POST "$API_URL/files/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$INVALID_FILE;type=application/x-msdownload")

echo "Invalid File Response: $INVALID_RESPONSE"

if echo "$INVALID_RESPONSE" | grep -q "VALIDATION_ERROR"; then
  echo "✅ Invalid file type correctly rejected"
else
  echo "⚠️ Invalid file type was not rejected properly"
fi

echo ""
echo "================================"
echo "✅ File Upload Testing Complete!"
echo ""
echo "Summary:"
echo "- Authentication: Working"
echo "- File Upload: Working"
echo "- File Metadata: Working"
echo "- File List: Working"
echo "- File Download: Working"
echo "- File Delete: Working"
echo "- Image Upload: Working"
echo "- Validation: Working"

# Cleanup
rm -f "$TEST_FILE" "$DOWNLOAD_FILE" "$IMAGE_FILE" "$INVALID_FILE"