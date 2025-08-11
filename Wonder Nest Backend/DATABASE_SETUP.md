# WonderNest Database Setup Guide

This guide covers the complete database setup for the WonderNest backend, including PostgreSQL with Docker, data persistence, and migration management.

## 🏗️ Architecture Overview

The database setup includes:

- **PostgreSQL 15.5** with persistent storage
- **Redis 7.2** for caching and sessions  
- **pgAdmin 8.0** for database management
- **Flyway migrations** for schema versioning
- **Health checks** and monitoring
- **Backup/restore** capabilities

## 🚀 Quick Start

### Initial Setup

1. **Set up the complete development environment:**
   ```bash
   cd "Wonder Nest Backend"
   ./scripts/setup.sh
   ```

2. **Start the development environment:**
   ```bash
   ./scripts/start-dev.sh
   ```

3. **Access the services:**
   - **API**: http://localhost:8080
   - **pgAdmin**: http://localhost:5050 (admin@wondernest.dev / wondernest_pgadmin_password)
   - **Health Check**: http://localhost:8080/health/detailed

That's it! The database, Redis, and pgAdmin are now running with persistent data.

## 📊 Service Information

### PostgreSQL Database
- **Host**: localhost:5433
- **Database**: wondernest_prod
- **App User**: wondernest_app
- **Password**: wondernest_secure_password_dev
- **Connection URL**: `postgresql://wondernest_app:wondernest_secure_password_dev@localhost:5433/wondernest_prod`

### Redis Cache
- **Host**: localhost:6379
- **Password**: wondernest_redis_password_dev
- **Connection URL**: `redis://:wondernest_redis_password_dev@localhost:6379/0`

### pgAdmin
- **URL**: http://localhost:5050
- **Email**: admin@wondernest.dev
- **Password**: wondernest_pgadmin_password

## 🔧 Management Scripts

### Setup and Start
```bash
# Initial setup (first time)
./scripts/setup.sh

# Start development environment
./scripts/start-dev.sh

# Reset everything (DESTRUCTIVE)
./scripts/setup.sh --reset
```

### Database Management
```bash
# Reset database only (keeps other services)
./scripts/reset-db.sh

# Backup database
./scripts/backup.sh
./scripts/backup.sh --compress    # Compressed backup
./scripts/backup.sh --schema-only # Schema only

# Restore database
./scripts/restore.sh /path/to/backup.sql
./scripts/restore.sh /path/to/backup.sql.gz --force
```

## 🗂️ Directory Structure

```
Wonder Nest Backend/
├── docker/                    # Docker configurations
│   ├── postgres/             # PostgreSQL configs
│   │   ├── postgresql.conf   # Performance-tuned config
│   │   └── pg_hba.conf      # Authentication config
│   ├── redis/               # Redis configuration
│   │   └── redis.conf       # Persistence-enabled config
│   ├── pgadmin/             # pgAdmin setup
│   │   └── servers.json     # Pre-configured server
│   └── volumes/             # Persistent data storage
│       ├── postgres/        # PostgreSQL data (survives restarts)
│       ├── redis/          # Redis data (survives restarts)
│       └── pgadmin/        # pgAdmin data
├── scripts/                 # Management scripts
│   ├── init-database.sh    # Database initialization
│   ├── setup.sh            # Complete environment setup
│   ├── start-dev.sh        # Quick start script
│   ├── reset-db.sh         # Database reset
│   ├── backup.sh           # Database backup
│   └── restore.sh          # Database restore
├── src/main/resources/db/migration/  # Flyway migrations
└── backups/                # Automatic backup storage
```

## 🔄 Data Persistence

### What Persists
- ✅ **PostgreSQL data** - All database content survives container restarts
- ✅ **Redis data** - Cache and sessions persist across restarts
- ✅ **pgAdmin config** - Server connections and preferences saved
- ✅ **Backups** - Stored in `backups/` directory

### Verification
To test persistence:

1. **Add some test data**
2. **Stop services**: `docker-compose down`
3. **Restart Docker Desktop** (or reboot system)
4. **Start services**: `./scripts/start-dev.sh`
5. **Verify data still exists**

### Volume Locations
Data is stored in bind-mounted directories:
- PostgreSQL: `./docker/volumes/postgres/`
- Redis: `./docker/volumes/redis/`
- pgAdmin: `./docker/volumes/pgadmin/`

## 🔄 Database Migrations

### Flyway Integration

Migrations run automatically on application startup:

```kotlin
// Migrations are in: src/main/resources/db/migration/
// Format: V{VERSION}__{DESCRIPTION}.sql
// Example: V1__Initial_Schema.sql
```

### Environment Variables
```bash
FLYWAY_ENABLED=true                 # Enable migrations
FLYWAY_BASELINE_ON_MIGRATE=true    # Baseline existing DB
```

### Migration Commands (Future Implementation)
```bash
# View migration status
./scripts/flyway-info.sh

# Validate migrations
./scripts/flyway-validate.sh

# Repair schema history
./scripts/flyway-repair.sh
```

## 🏥 Health Checks

### Application Health Endpoints

```bash
# Basic health (for load balancers)
curl http://localhost:8080/health
# Response: {"status":"UP"}

# Detailed health (with service status)
curl http://localhost:8080/health/detailed
# Response: Full health report with DB and Redis status

# Kubernetes-style checks
curl http://localhost:8080/health/ready    # Readiness probe
curl http://localhost:8080/health/live     # Liveness probe  
curl http://localhost:8080/health/startup  # Startup probe
```

### Docker Health Checks
All services include health checks:
- **PostgreSQL**: `pg_isready` check every 10s
- **Redis**: `redis-cli ping` every 10s
- **API**: HTTP health endpoint every 30s

Check service health:
```bash
docker-compose ps
# Shows health status for all services
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Services Won't Start
```bash
# Check Docker is running
docker info

# View service logs
docker-compose logs postgres
docker-compose logs redis
docker-compose logs api

# Check port conflicts
lsof -i :5433  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :5050  # pgAdmin
```

#### 2. Database Connection Issues
```bash
# Test database connection
docker-compose exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;"

# Check database users
docker-compose exec postgres psql -U postgres -c "\\du"

# Verify database exists
docker-compose exec postgres psql -U postgres -c "\\l"
```

#### 3. Permission Issues (Linux/macOS)
```bash
# Fix volume permissions
sudo chown -R $(whoami):$(whoami) docker/volumes/

# Reset and recreate
./scripts/setup.sh --reset
```

#### 4. Data Loss
```bash
# Restore from backup
./scripts/restore.sh backups/wondernest_backup_YYYYMMDD_HHMMSS.sql

# Check for recent backups
ls -la backups/
```

### Logs and Debugging

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f api

# Follow API logs in real-time
docker-compose logs -f api | grep -i error
```

## 🔒 Security Notes

### Development Environment
- Passwords are hardcoded for development convenience
- PostgreSQL allows local connections without SSL
- Redis is password-protected but not SSL-encrypted

### Production Considerations
- Use environment-specific passwords
- Enable SSL/TLS for all connections
- Restrict network access with firewalls
- Regular security updates for Docker images
- Use secrets management (Kubernetes secrets, Docker secrets, etc.)

## 📈 Performance Tuning

### PostgreSQL Configuration
Current settings in `docker/postgres/postgresql.conf`:
- `shared_buffers = 256MB` (25% of RAM)
- `effective_cache_size = 1GB` (OS cache estimate)
- `work_mem = 8MB` (per operation)
- `maintenance_work_mem = 64MB`

### Redis Configuration
Current settings in `docker/redis/redis.conf`:
- Persistence: Both RDB snapshots and AOF enabled
- Memory policy: `allkeys-lru`
- Performance logging: Slow queries logged

### Monitoring
- Prometheus metrics at http://localhost:9090
- PostgreSQL query statistics via `pg_stat_statements`
- Redis INFO command for performance metrics

## 🚀 Production Deployment

### Environment Variables
Update these for production:
```bash
# Database
DB_HOST=your-postgres-host
DB_PASSWORD=your-secure-password
POSTGRES_PASSWORD=your-postgres-password

# Redis  
REDIS_HOST=your-redis-host
REDIS_PASSWORD=your-secure-redis-password

# Application
KTOR_ENV=production
FLYWAY_BASELINE_ON_MIGRATE=false
```

### Docker Compose Override
Create `docker-compose.prod.yml` for production-specific settings:
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15.5
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports: []  # Don't expose ports in production
  
  redis:
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports: []  # Don't expose ports in production
```

Deploy with:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 📚 Additional Resources

- [PostgreSQL 15 Documentation](https://www.postgresql.org/docs/15/)
- [Redis 7.2 Documentation](https://redis.io/docs/)
- [Flyway Documentation](https://flywaydb.org/documentation/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [KTOR Documentation](https://ktor.io/)

---

## 📞 Support

For issues or questions:

1. **Check logs**: `docker-compose logs -f [service]`
2. **Review health**: `curl http://localhost:8080/health/detailed`
3. **Reset environment**: `./scripts/setup.sh --reset`
4. **Check this guide**: Most common issues are covered above

Last updated: December 2024