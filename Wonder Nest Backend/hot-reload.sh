#!/bin/bash

# Hot reload script for development
# This watches for changes and rebuilds + restarts the container

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔥 Starting hot reload mode...${NC}"

# Function to rebuild and restart
rebuild_and_restart() {
    echo -e "${YELLOW}Changes detected! Rebuilding...${NC}"
    
    # Build the JAR locally
    ./gradlew shadowJar -x test
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful!${NC}"
        
        # Restart the container to pick up new JAR
        docker restart wondernestbackend-api-1
        
        echo -e "${GREEN}✅ Container restarted!${NC}"
    else
        echo -e "${RED}❌ Build failed! Fix errors and save again.${NC}"
    fi
}

# Initial build
echo -e "${YELLOW}Building initial JAR...${NC}"
./gradlew shadowJar -x test

# Start the container if not running
if ! docker ps | grep -q wondernestbackend-api-1; then
    echo -e "${YELLOW}Starting container...${NC}"
    docker-compose up -d api
fi

echo -e "${GREEN}✅ Watching for changes in src/...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"

# Watch for changes in Kotlin files
fswatch -o src/ | while read f; do
    rebuild_and_restart
done