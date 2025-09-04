#!/bin/bash

# Test the create child endpoint

BASE_URL="http://localhost:8080/api/v1"
EMAIL="test$(date +%s)@example.com"
PASSWORD="TestPass123!"

echo "Testing child creation with Rust backend..."
echo "Email: $EMAIL"
echo ""

# 1. Register and get token
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

if [ "$ACCESS_TOKEN" == "null" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."
echo ""

# 2. Test child creation
echo "2. Creating child profile..."
CHILD_RESPONSE=$(curl -s -X POST "$BASE_URL/family/children" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "name": "Test Child",
    "birthDate": "2020-09-05",
    "gender": "Male",
    "interests": ["Reading", "Games"],
    "avatar": ""
  }')

echo "Child creation response:"
echo "$CHILD_RESPONSE" | jq '.'
echo ""

# Check if successful
if echo "$CHILD_RESPONSE" | grep -q "success.*true"; then
  echo "✅ Child created successfully!"
else
  echo "❌ Child creation failed"
  exit 1
fi

echo ""
echo "All tests completed!"