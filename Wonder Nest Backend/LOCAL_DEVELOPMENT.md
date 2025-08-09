# Local Development Guide

This guide explains how to run the WonderNest KTOR application locally while using Docker for the database and Redis.

## Quick Start

### Option 1: Use the convenience script (Recommended)
```bash
./scripts/run-local.sh
```

This script will:
1. Start PostgreSQL and Redis services in Docker
2. Wait for services to be ready
3. Set up the correct environment variables
4. Run the KTOR application with `./gradlew run`

### Option 2: Manual setup
1. Start the Docker services:
   ```bash
   docker compose up -d postgres redis
   ```

2. Load the local environment variables:
   ```bash
   source .env.local
   ```

3. Run the application:
   ```bash
   ./gradlew run
   ```

## Configuration Details

The application is configured to work in both environments:

### Local Development
- **Database**: Connects to `localhost:5432` (Docker PostgreSQL exposed port)
- **Redis**: Connects to `localhost:6379` (Docker Redis exposed port)
- **KTOR**: Runs directly on your machine using `./gradlew run`

### Docker Deployment
- **Database**: Connects to `postgres:5432` (Docker service name)
- **Redis**: Connects to `redis:6379` (Docker service name)  
- **KTOR**: Runs in Docker container using service names

## Environment Variables

The application uses these environment variables for local development:

- `DB_HOST=localhost` (instead of `postgres`)
- `DB_PORT=5432`
- `DB_NAME=wondernest_prod`
- `DB_USERNAME=wondernest_app`
- `DB_PASSWORD=wondernest_secure_password_dev`
- `REDIS_HOST=localhost` (instead of `redis`)
- `REDIS_PORT=6379`
- `REDIS_PASSWORD=wondernest_redis_password_dev`

## Troubleshooting

### "UnknownHostException: postgres" Error
This error occurs when the application tries to connect to the Docker service name `postgres` while running locally. The fix is to:

1. Use the provided scripts or environment file
2. Ensure `DB_HOST=localhost` is set before running the application

### Services Not Ready
If you get connection errors, ensure Docker services are running:
```bash
docker compose ps postgres redis
```

Both services should show as "healthy" before starting the KTOR application.

### Database Connection Issues
Test the database connection manually:
```bash
docker exec wondernest_postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;"
```

## Development Workflow

1. **First time setup**: Run `./scripts/setup.sh` to initialize the development environment
2. **Daily development**: Use `./scripts/run-local.sh` to start everything
3. **Debugging**: Use `docker compose logs postgres` or `docker compose logs redis` to check service logs
4. **Cleanup**: Use `docker compose down` to stop all services when done

## Services Access

When running locally, you can access:

- **API**: http://localhost:8080
- **PostgreSQL**: localhost:5432 (credentials in `.env.local`)
- **Redis**: localhost:6379 (password in `.env.local`)
- **pgAdmin**: http://localhost:5050 (if started with `docker compose up -d pgadmin`)