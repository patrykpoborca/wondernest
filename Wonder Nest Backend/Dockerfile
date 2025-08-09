# Multi-stage Docker build for WonderNest KTOR Backend

# Build stage
FROM gradle:8.5-jdk17 AS builder

WORKDIR /app

# Copy build files
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .

# Copy source code
COPY src/ src/

# Build the application
RUN gradle build --no-daemon --info

# Production stage
FROM eclipse-temurin:17-jre-alpine

# Install necessary tools
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    dumb-init

# Create app user for security
RUN addgroup -g 1000 wondernest && \
    adduser -u 1000 -G wondernest -D -h /app wondernest

WORKDIR /app

# Copy built JAR from builder stage
COPY --from=builder /app/build/libs/*-all.jar app.jar

# Set ownership
RUN chown wondernest:wondernest app.jar

# Switch to non-root user
USER wondernest

# Environment variables
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions \
               -XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+UseG1GC \
               -XX:+UseStringDeduplication"

ENV KTOR_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Use dumb-init for proper signal handling
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run the application
CMD java $JAVA_OPTS -jar app.jar