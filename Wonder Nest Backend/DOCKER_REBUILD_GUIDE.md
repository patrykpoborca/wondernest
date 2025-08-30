# Docker Rebuild Guide for WonderNest Backend

## 🚀 Quick Commands

### After Code Changes:

#### Option 1: Simple Rebuild (Recommended)
```bash
./rebuild-docker.sh
```
This will stop, rebuild, and restart your container with the latest code.

#### Option 2: Quick Restart (Faster, may miss some changes)
```bash
./quick-restart.sh
```

#### Option 3: Docker Compose Watch (Auto-rebuild on file changes)
```bash
docker compose watch
```
This watches for file changes and automatically rebuilds. Press Ctrl+C to stop.

#### Option 4: Manual Commands
```bash
# Stop current container
docker-compose down api

# Rebuild with no cache (ensures fresh build)
docker-compose build --no-cache api

# Start the container
docker-compose up -d api

# Check logs
docker logs wondernestbackend-api-1 -f
```

## 🔧 Development Workflows

### Best Practice Workflow

1. **Before making changes**, ensure Docker is running:
   ```bash
   docker ps
   ```

2. **After making backend code changes**:
   ```bash
   ./rebuild-docker.sh
   ```

3. **To see live logs**:
   ```bash
   docker logs wondernestbackend-api-1 -f
   ```

4. **To check if backend is healthy**:
   ```bash
   curl http://localhost:8080/health
   ```

### Using Docker Desktop Watch Mode (Recommended for Active Development)

1. Start watch mode:
   ```bash
   docker compose watch
   ```

2. Make your code changes - Docker will automatically detect and rebuild

3. Watch the terminal for rebuild status

4. Test your changes immediately after rebuild completes

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs api

# Remove everything and start fresh
docker-compose down -v
docker-compose build --no-cache api
docker-compose up -d api
```

### Port 8080 already in use
```bash
# Find what's using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Build fails with compilation errors
1. Fix the compilation errors first
2. Test locally: `./gradlew build`
3. Then rebuild Docker: `./rebuild-docker.sh`

### Container is unhealthy
```bash
# Check detailed health status
docker inspect wondernestbackend-api-1 --format='{{json .State.Health}}'

# View recent logs
docker logs wondernestbackend-api-1 --tail 50
```

## 📋 Status Checks

### Quick Health Check
```bash
# All-in-one status check
echo "Container Status:" && docker ps | grep wondernest && \
echo -e "\nHealth Check:" && curl -s http://localhost:8080/health && \
echo -e "\n\nRecent Logs:" && docker logs wondernestbackend-api-1 --tail 5
```

### Check if rebuild is needed
```bash
# Compare file modification times
find src -type f -newer /var/lib/docker/containers/*/config.v2.json 2>/dev/null | head -5
```

## 🎯 Pro Tips

1. **Always rebuild after**:
   - Changing Kotlin code
   - Modifying build.gradle.kts
   - Updating dependencies
   - Changing database migrations

2. **Use watch mode when**:
   - Actively developing
   - Making frequent changes
   - Testing iteratively

3. **Use rebuild script when**:
   - Pulling latest changes from git
   - After major refactoring
   - When watch mode seems stuck

4. **Clear Docker cache if**:
   - Strange build errors occur
   - Dependencies seem outdated
   ```bash
   docker system prune -a --volumes
   ```

## 🔄 Automatic Rebuild on Git Pull

Add this to your `.git/hooks/post-merge` to auto-rebuild after git pull:
```bash
#!/bin/bash
echo "Backend code changed, rebuilding Docker..."
cd "Wonder Nest Backend" && ./rebuild-docker.sh
```

Make it executable:
```bash
chmod +x .git/hooks/post-merge
```

## 📝 Current Configuration

- **Container Name**: wondernestbackend-api-1
- **Port**: 8080
- **Database**: PostgreSQL on port 5433
- **Redis**: Port 6379
- **Health Check**: http://localhost:8080/health

## 🚨 Important Notes

1. **Always ensure the code compiles** before rebuilding Docker
2. **The rebuild process takes 1-2 minutes** depending on changes
3. **Watch mode is best for development** but uses more resources
4. **Production builds should use** `docker-compose.yml` not the dev version