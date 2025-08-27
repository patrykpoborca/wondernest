# Docker Logs Guide for WonderNest Backend

## Quick Commands

### 1. Real-time logs (follow mode)
```bash
# API server logs only
docker-compose logs -f api

# All services
docker-compose logs -f

# Multiple specific services
docker-compose logs -f api postgres redis
```

### 2. Show recent logs
```bash
# Last 100 lines
docker-compose logs api --tail=100

# Last 5 minutes
docker-compose logs --since 5m api

# Since specific time
docker-compose logs --since "2024-08-27T07:00:00" api
```

### 3. Filter logs
```bash
# Filter for Story Adventure
docker-compose logs api | grep -i "story"

# Filter for errors
docker-compose logs api | grep -i "error\|exception\|failed"

# Filter for specific child ID
docker-compose logs api | grep "50cb1b31-bd85-4604-8cd1-efc1a73c9359"
```

### 4. Save logs to file
```bash
# Save all logs
docker-compose logs api > api_logs.txt

# Save with timestamps
docker-compose logs -t api > api_logs_with_time.txt
```

### 5. Check specific container
```bash
# Get container ID
docker ps | grep api

# View logs directly
docker logs wondernestbackend-api-1 --tail=50
```

### 6. Interactive log monitoring
```bash
# Watch for errors in real-time
docker-compose logs -f api 2>&1 | grep --line-buffered -i "error"

# Monitor Story Adventure activity
docker-compose logs -f api 2>&1 | grep --line-buffered -i "story"
```

## Current Story Adventure Activity
Based on recent logs, Story Adventure is working with events:
- story_started
- progress_update (page navigation)
- story_completed

## Useful Aliases
Add to your .zshrc or .bashrc:
```bash
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'
alias dclapi='docker-compose logs -f api'
alias dcltail='docker-compose logs --tail=100'
```
