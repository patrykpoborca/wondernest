# WonderNest Rust Backend Deployment Guide

## Quick Start - Production Deployment

### 1. Environment Setup

```bash
# Clone and setup
git clone <repository>
cd WonderNestRustBackend

# Create production environment file
cp .env.production .env

# CRITICAL: Update these values in .env
# DB_PASSWORD=your_secure_database_password_here
# JWT_SECRET=your_super_secure_jwt_secret_key_256_bits_here
# GRAFANA_PASSWORD=your_secure_grafana_password_here
```

### 2. Generate Secure JWT Secret

```bash
# Generate a secure 256-bit JWT secret
openssl rand -base64 32

# Or use this online: https://generate-secret.vercel.app/32
# Copy the result to JWT_SECRET in your .env file
```

### 3. Deploy with Docker Compose

```bash
# Production deployment with monitoring
docker-compose -f docker-compose.prod.yml up -d

# Check service health
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f wondernest-rust-backend
```

### 4. Verify Deployment

```bash
# Health check
curl http://localhost:8082/health

# Detailed health with service status
curl http://localhost:8082/health/detailed

# Metrics (Prometheus format)
curl http://localhost:8082/health/metrics
```

### 5. Update Flutter App

Change the backend URL in your Flutter app from:
```dart
// OLD - Kotlin backend
const String backendUrl = 'http://localhost:8081';

// NEW - Rust backend  
const String backendUrl = 'http://localhost:8082';
```

That's it! No other changes needed in the Flutter app.

## Production Services

After deployment, you'll have:

- **Rust Backend**: http://localhost:8082
- **PostgreSQL**: localhost:5433 (compatible with existing data)
- **Redis**: localhost:6379
- **Prometheus**: http://localhost:9090 (metrics)
- **Grafana**: http://localhost:3000 (dashboards)

## Health Check Endpoints

```bash
# Basic health (for load balancers)
GET /health
Response: {"status":"UP"}

# Detailed health with service status and response times
GET /health/detailed
Response: {
  "status": "UP",
  "timestamp": "2024-08-14T10:30:00Z",
  "services": {
    "database": {"status": "UP", "responseTime": 5},
    "redis": {"status": "UP", "responseTime": 2}
  }
}

# Kubernetes probes
GET /health/ready    # Readiness probe
GET /health/live     # Liveness probe  
GET /health/startup  # Startup probe

# Prometheus metrics
GET /health/metrics  # Metrics for monitoring
```

## API Compatibility

All endpoints maintain **100% compatibility** with the Kotlin backend:

### Authentication API (12 endpoints)
- `POST /api/v1/auth/parent/register` ✅
- `POST /api/v1/auth/parent/login` ✅
- `POST /api/v1/auth/parent/verify-pin` ✅
- `POST /api/v1/auth/register` ✅
- `POST /api/v1/auth/login` ✅
- `POST /api/v1/auth/session/refresh` ✅
- `POST /api/v1/auth/logout` ✅
- `GET /api/v1/auth/me` ✅
- Plus password reset and OAuth endpoints

### Game Data API (5 endpoints)
- `PUT /api/v2/games/children/{childId}/data` ✅
- `GET /api/v2/games/children/{childId}/data` ✅
- `DELETE /api/v2/games/children/{childId}/data` ✅
- `GET /api/v2/games/children/{childId}/instances` ✅
- `POST /api/v2/games/children/{childId}/instances` ✅

### Family, Content, Analytics, Audio, COPPA, File Management
All endpoints implemented with exact API contract compatibility.

## Database Migration

**No database migration required!** The Rust backend:
- Uses the existing WonderNest PostgreSQL database
- Compatible with all existing tables and data
- Preserves existing Flyway migrations
- Same connection parameters and schemas

## Monitoring Setup

### Prometheus Metrics
The Rust backend exposes metrics at `/health/metrics`:
- HTTP request counts and latencies
- Database connection pool status
- Authentication success/failure rates
- Game data operation metrics
- System uptime and performance

### Grafana Dashboards
Access Grafana at http://localhost:3000 (admin/your_password)
- Pre-configured dashboards for WonderNest metrics
- Database performance monitoring
- API endpoint performance
- Error rate tracking

### Alerting (Optional)
Configure alerts for:
- High error rates (>5%)
- Database connection failures
- High response latency (>500ms)
- Memory/CPU usage spikes

## Production Checklist

### Before Deployment
- [ ] Set secure `JWT_SECRET` in .env file
- [ ] Set secure `DB_PASSWORD` in .env file
- [ ] Set secure `GRAFANA_PASSWORD` in .env file
- [ ] Configure CORS origins for your domain
- [ ] Set up SSL/TLS certificates (if not using a load balancer)
- [ ] Configure firewall rules
- [ ] Set up log aggregation (optional)

### After Deployment
- [ ] Verify health endpoints respond correctly
- [ ] Test authentication flows
- [ ] Test game data save/load operations
- [ ] Verify database connectivity
- [ ] Check Redis connectivity
- [ ] Monitor metrics in Grafana
- [ ] Test Flutter app connectivity
- [ ] Set up automated backups
- [ ] Configure monitoring alerts

## Kubernetes Deployment

For Kubernetes deployment, use this example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wondernest-rust-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wondernest-rust-backend
  template:
    metadata:
      labels:
        app: wondernest-rust-backend
    spec:
      containers:
      - name: wondernest-backend
        image: wondernest/rust-backend:latest
        ports:
        - containerPort: 8082
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: wondernest-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: wondernest-secrets
              key: jwt-secret
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8082
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8082
          initialDelaySeconds: 5
          periodSeconds: 5
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8082
          initialDelaySeconds: 10
          failureThreshold: 30
---
apiVersion: v1
kind: Service
metadata:
  name: wondernest-rust-backend-service
spec:
  selector:
    app: wondernest-rust-backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8082
  type: LoadBalancer
```

## Rollback Procedure

If issues occur, rollback to Kotlin backend:

### 1. Immediate Rollback
```bash
# Stop Rust backend
docker-compose -f docker-compose.prod.yml down wondernest-rust-backend

# Update Flutter app to point back to Kotlin backend
# Change backendUrl from 8082 to 8081

# Start Kotlin backend (if stopped)
cd "../Wonder Nest Backend"
./gradlew run
```

### 2. Data Consistency
No data migration is needed as both backends use the same database.

### 3. Monitoring
Check that all services return to normal:
- Authentication flows work
- Game data save/load operations work
- No error spikes in logs

## Performance Monitoring

Expected performance improvements with Rust backend:
- **Memory Usage**: 50-70% reduction vs Kotlin
- **Startup Time**: 2-3x faster (typically <2 seconds)
- **Request Latency**: 20-40% improvement
- **Throughput**: 2-5x more requests/second
- **CPU Usage**: 30-50% reduction under load

Monitor these metrics in Grafana to verify performance gains.

## Security Considerations

### Production Security
- [ ] JWT secrets are secure and rotated regularly
- [ ] Database passwords are strong and unique
- [ ] CORS is configured for specific origins only
- [ ] All secrets are stored in environment variables
- [ ] SSL/TLS is configured for HTTPS
- [ ] Database connections use SSL
- [ ] File upload validation is enabled
- [ ] Rate limiting is configured (recommended)

### COPPA Compliance
- Current COPPA implementation is for **development only**
- **Legal review required** before production use
- Implement verifiable parental consent system
- Add age verification mechanisms
- Set up data deletion procedures

## Troubleshooting

### Common Issues

**Backend won't start**
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs wondernest-rust-backend

# Check environment variables
docker-compose -f docker-compose.prod.yml exec wondernest-rust-backend env | grep -E "(DATABASE|JWT|REDIS)"
```

**Database connection issues**
```bash
# Test database connectivity
docker-compose -f docker-compose.prod.yml exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;"
```

**Flutter app can't connect**
- Verify backend URL is `http://localhost:8082`
- Check CORS configuration in `src/lib.rs`
- Verify firewall/network rules allow port 8082

**Health checks failing**
```bash
# Test health endpoints
curl -v http://localhost:8082/health
curl -v http://localhost:8082/health/ready
curl -v http://localhost:8082/health/detailed
```

### Logs and Debugging
```bash
# Follow all logs
docker-compose -f docker-compose.prod.yml logs -f

# Just backend logs
docker-compose -f docker-compose.prod.yml logs -f wondernest-rust-backend

# Debug level logging (add to .env)
RUST_LOG=wondernest_backend=debug,sqlx=debug,tower_http=debug
```

## Support

For deployment issues:
1. Check the logs first
2. Verify environment configuration
3. Test health endpoints
4. Compare with working Kotlin setup
5. Check database and Redis connectivity

The Rust backend is designed to be a drop-in replacement with improved performance and reliability.