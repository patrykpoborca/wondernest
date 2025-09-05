#!/bin/bash

# Test direct multipart upload to check if the Vite proxy fix works

echo "Testing direct file upload to check multipart parsing..."

# Create a simple test image (1x1 PNG)
echo -n -e '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\x0D\x49\x44\x41\x54\x78\x9C\x62\x00\x01\x00\x00\x05\x00\x01\x0D\x0A\x2D\xB4\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82' > /tmp/test_direct.png

echo "First, testing direct connection to Rust backend (port 8080)..."
DIRECT_RESPONSE=$(curl -X POST "http://localhost:8080/api/v1/files/upload?category=game_asset&isPublic=true" \
  -H "Authorization: Bearer fake-token-for-testing" \
  -F "file=@/tmp/test_direct.png;type=image/png" \
  2>/dev/null)

echo "Direct backend response:"
echo "$DIRECT_RESPONSE" | jq . 2>/dev/null || echo "$DIRECT_RESPONSE"

echo ""
echo "Now testing through Vite proxy (port 3000)..."
PROXY_RESPONSE=$(curl -X POST "http://localhost:3000/api/v1/files/upload?category=game_asset&isPublic=true" \
  -H "Authorization: Bearer fake-token-for-testing" \
  -F "file=@/tmp/test_direct.png;type=image/png" \
  2>/dev/null)

echo "Vite proxy response:"
echo "$PROXY_RESPONSE" | jq . 2>/dev/null || echo "$PROXY_RESPONSE"

echo ""
echo "Comparing responses:"
if [[ "$DIRECT_RESPONSE" == "$PROXY_RESPONSE" ]]; then
    echo "✅ Both responses are identical - proxy is not corrupting multipart data!"
else
    echo "⚠️  Responses differ - there may still be proxy issues"
fi

rm -f /tmp/test_direct.png