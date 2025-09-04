#!/bin/bash

# Test the authentication flow with the Rust backend

BASE_URL="http://localhost:8080/api/v1"
EMAIL="test$(date +%s)@example.com"
PASSWORD="TestPass123!"

echo "Testing authentication with Rust backend..."
echo "Email: $EMAIL"
echo ""

# 1. Register a new account
echo "1. Registering new account..."
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/parent/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'",
    "name": "Test User",
    "phoneNumber": "1234567890",
    "countryCode": "US",
    "timezone": "America/New_York",
    "language": "en"
  }')

echo "Signup response:"
echo "$SIGNUP_RESPONSE" | jq '.'
echo ""

# Extract tokens
ACCESS_TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.data.accessToken')
REFRESH_TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.data.refreshToken')

if [ "$ACCESS_TOKEN" == "null" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."
echo ""

# 2. Test authenticated request
echo "2. Testing authenticated request to /family/profile..."
PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/family/profile" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Profile response:"
echo "$PROFILE_RESPONSE" | jq '.'
echo ""

# Check if we got a 401
if echo "$PROFILE_RESPONSE" | grep -q "Unauthorized"; then
  echo "❌ Still getting 401 Unauthorized"
  exit 1
else
  echo "✅ Authenticated request successful!"
fi

# 3. Test token refresh
echo "3. Testing token refresh..."
REFRESH_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/session/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "'$REFRESH_TOKEN'"
  }')

echo "Refresh response:"
echo "$REFRESH_RESPONSE" | jq '.'
echo ""

NEW_ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.data.accessToken')
if [ "$NEW_ACCESS_TOKEN" != "null" ]; then
  echo "✅ Token refresh successful!"
else
  echo "❌ Token refresh failed"
fi

echo ""
echo "All tests completed!"