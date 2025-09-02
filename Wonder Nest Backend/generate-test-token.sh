#!/bin/bash

# Generate a test JWT token directly using node.js (which is commonly available)
# This creates a token that matches the expected format

USER_ID="f04035ac-a2cf-418e-b119-e489dfcfcf15"
SECRET="your-super-secret-jwt-key-change-this-in-production"

# Create a simple node script to generate the JWT
cat << 'EOF' > /tmp/generate-jwt.js
const crypto = require('crypto');

const header = {
  alg: 'HS256',
  typ: 'JWT'
};

const now = Math.floor(Date.now() / 1000);
const payload = {
  iss: 'wondernest-api',
  aud: 'wondernest-users',
  sub: process.env.USER_ID,
  userId: process.env.USER_ID,
  email: 'test@example.com',
  role: 'PARENT',
  verified: true,
  nonce: crypto.randomUUID(),
  iat: now,
  exp: now + 3600
};

function base64url(str) {
  return Buffer.from(str)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

const encodedHeader = base64url(JSON.stringify(header));
const encodedPayload = base64url(JSON.stringify(payload));
const signature = crypto
  .createHmac('sha256', process.env.SECRET)
  .update(encodedHeader + '.' + encodedPayload)
  .digest('base64')
  .replace(/=/g, '')
  .replace(/\+/g, '-')
  .replace(/\//g, '_');

const jwt = encodedHeader + '.' + encodedPayload + '.' + signature;
console.log(jwt);
EOF

# Generate the token
TOKEN=$(USER_ID="$USER_ID" SECRET="$SECRET" node /tmp/generate-jwt.js 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "Failed to generate token. Make sure Node.js is installed."
  exit 1
fi

echo "Generated JWT Token:"
echo "$TOKEN"
echo ""
echo "Test commands:"
echo ""
echo "# Test categories endpoint:"
echo "curl -X GET \"http://localhost:8080/api/v1/content-packs/categories\" \\"
echo "  -H \"Authorization: Bearer $TOKEN\""
echo ""
echo "# Test featured packs endpoint:"
echo "curl -X GET \"http://localhost:8080/api/v1/content-packs/featured\" \\"
echo "  -H \"Authorization: Bearer $TOKEN\""
echo ""
echo "# Test owned packs endpoint:"
echo "curl -X GET \"http://localhost:8080/api/v1/content-packs/owned\" \\"
echo "  -H \"Authorization: Bearer $TOKEN\""