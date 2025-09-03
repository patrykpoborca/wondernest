#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}⚡ Quick Rebuild - WonderNest Rust Backend${NC}"
echo -e "${CYAN}===========================================${NC}"
echo ""

# This script does a faster rebuild by leveraging Docker cache
echo -e "${YELLOW}📦 Stopping existing container...${NC}"
docker stop wondernest-rust-backend 2>/dev/null || true
docker rm wondernest-rust-backend 2>/dev/null || true

# Build with cache (faster than --no-cache)
echo -e "${YELLOW}🔨 Building image (using cache for faster build)...${NC}"
START_TIME=$(date +%s)

docker build -t wondernest-rust-backend . 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -q "ERROR"; then
        echo -e "${RED}$line${NC}"
    elif echo "$line" | grep -q "CACHED"; then
        echo -e "${GREEN}✓ $line${NC}"
    elif echo "$line" | grep -q "RUN"; then
        echo -e "${BLUE}► $line${NC}"
    else
        echo "$line"
    fi
done

BUILD_STATUS=${PIPESTATUS[0]}
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build completed in ${BUILD_TIME} seconds${NC}"
    
    # Start container
    echo -e "${YELLOW}🚀 Starting container...${NC}"
    docker run -d \
        --name wondernest-rust-backend \
        -p 8082:8080 \
        -e DATABASE_URL="postgresql://wondernest_app:wondernest_secure_password_dev@host.docker.internal:5433/wondernest_prod" \
        -e REDIS_URL="redis://host.docker.internal:6379" \
        -e JWT_SECRET="your-super-secret-jwt-key-change-this-in-production" \
        -e RUST_LOG="info" \
        --add-host host.docker.internal:host-gateway \
        wondernest-rust-backend > /dev/null
    
    # Quick health check
    echo -e "${YELLOW}🏥 Health check...${NC}"
    sleep 2
    
    if curl -s http://localhost:8082/health | grep -q "UP"; then
        echo -e "${GREEN}✅ Backend is running!${NC}"
        echo -e "${GREEN}🌐 Available at: http://localhost:8082${NC}"
    else
        echo -e "${RED}❌ Health check failed${NC}"
        docker logs wondernest-rust-backend --tail 10
    fi
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi