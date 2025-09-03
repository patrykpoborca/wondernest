#!/bin/bash

# Colors for output
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine container name
if docker ps -a | grep -q "wondernestrust-backend-rust-backend-1"; then
    CONTAINER_NAME="wondernestrust-backend-rust-backend-1"
elif docker ps -a | grep -q "wondernest-rust-backend"; then
    CONTAINER_NAME="wondernest-rust-backend"
else
    echo "❌ No Rust backend container found!"
    exit 1
fi

echo -e "${BLUE}📋 Showing logs for: $CONTAINER_NAME${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop following logs${NC}"
echo ""

# Follow logs with timestamps
docker logs -f --timestamps "$CONTAINER_NAME"