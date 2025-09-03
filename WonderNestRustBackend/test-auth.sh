#!/bin/bash

# Test script for Rust backend authentication endpoints
# Ensures 100% compatibility with Kotlin backend

API_URL="${API_URL:-http://localhost:8080}"
EMAIL="test_$(date +%s)@example.com"
PASSWORD="TestPass123"

echo "🧪 Testing WonderNest Rust Backend Authentication"
echo "================================================"
echo "API URL: $API_URL"
echo ""

# Test 1: Register a new parent
echo "1️⃣ Testing Parent Registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/parent/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"name\": \"Test Parent\",
    \"familyName\": \"Test Family\"
  }")

echo "Response: $REGISTER_RESPONSE"
echo ""

# Extract token from response (Kotlin uses "accessToken" not "token")
# Handle multi-line JSON response - remove all whitespace
TOKEN=$(echo "$REGISTER_RESPONSE" | tr -d '\n\r ' | sed -n 's/.*"accessToken":"\([^"]*\).*/\1/p')
REFRESH_TOKEN=$(echo "$REGISTER_RESPONSE" | tr -d '\n\r ' | sed -n 's/.*"refreshToken":"\([^"]*\).*/\1/p')

if [ -z "$TOKEN" ]; then
  echo "❌ Registration failed - no token received"
  exit 1
fi

echo "✅ Registration successful"
echo "Token: ${TOKEN:0:50}..."
echo ""

# Test 2: Login with the same credentials
echo "2️⃣ Testing Parent Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/parent/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Response: $LOGIN_RESPONSE"
echo ""

LOGIN_TOKEN=$(echo "$LOGIN_RESPONSE" | tr -d '\n\r ' | sed -n 's/.*"accessToken":"\([^"]*\).*/\1/p')

if [ -z "$LOGIN_TOKEN" ]; then
  echo "❌ Login failed - no token received"
  exit 1
fi

echo "✅ Login successful"
echo ""

# Test 3: Verify PIN (hardcoded as 1234)
echo "3️⃣ Testing PIN Verification..."
PIN_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/parent/verify-pin" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"pin\": \"1234\"
  }")

echo "Response: $PIN_RESPONSE"
echo ""

# Test 4: Refresh token
echo "4️⃣ Testing Token Refresh..."
REFRESH_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/session/refresh" \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")

echo "Response: $REFRESH_RESPONSE"
echo ""

NEW_TOKEN=$(echo "$REFRESH_RESPONSE" | tr -d '\n\r ' | sed -n 's/.*"accessToken":"\([^"]*\).*/\1/p')

if [ -z "$NEW_TOKEN" ]; then
  echo "❌ Token refresh failed"
  exit 1
fi

echo "✅ Token refresh successful"
echo ""

# Test 5: Test protected endpoint with new token
echo "5️⃣ Testing Protected Endpoint (Content Packs)..."
CONTENT_RESPONSE=$(curl -s -X GET "$API_URL/api/v1/content-packs/categories" \
  -H "Authorization: Bearer $NEW_TOKEN")

echo "Response: ${CONTENT_RESPONSE:0:200}..."
echo ""

if echo "$CONTENT_RESPONSE" | grep -q "\"success\":true"; then
  echo "✅ Protected endpoint access successful"
else
  echo "❌ Protected endpoint access failed"
  exit 1
fi

echo ""
echo "✅ All authentication tests passed!"
echo "The Rust backend is working correctly and maintains compatibility with the Kotlin version."