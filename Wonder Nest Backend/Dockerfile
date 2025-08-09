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

# Build the application (skip tests for faster builds and focus on migration testing)
RUN gradle build -x test --no-daemon --info

# Production stage
FROM eclipse-temurin:17-jre

# Install necessary tools
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    dumb-init \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create app user for security
RUN useradd -u 1001 -g users -d /app -m wondernest

WORKDIR /app

# Copy built JAR from builder stage
COPY --from=builder /app/build/libs/*-all.jar app.jar

# Set ownership
RUN chown wondernest:users app.jar

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