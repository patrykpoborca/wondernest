val kotlin_version: String by project
val logback_version: String by project
val ktor_version: String by project
val exposed_version: String by project
val postgresql_version: String by project
val koin_version: String by project
val jackson_version: String by project

plugins {
    kotlin("jvm") version "2.1.10"
    kotlin("plugin.serialization") version "2.1.10"
    id("io.ktor.plugin") version "3.2.3"
}

group = "com.wondernest"
version = "0.0.1"

application {
    mainClass = "com.wondernest.ApplicationKt"
    val isDevelopment: Boolean = project.ext.has("development")
    applicationDefaultJvmArgs = listOf("-Dio.ktor.development=$isDevelopment")
}

repositories {
    mavenCentral()
}

dependencies {
    // Core Ktor dependencies
    implementation("io.ktor:ktor-server-core-jvm")
    implementation("io.ktor:ktor-server-netty-jvm")
    implementation("io.ktor:ktor-server-config-yaml")
    implementation("io.ktor:ktor-server-host-common-jvm")
    
    // Content negotiation and serialization
    implementation("io.ktor:ktor-server-content-negotiation-jvm")
    implementation("io.ktor:ktor-serialization-kotlinx-json-jvm")
    implementation("io.ktor:ktor-serialization-jackson-jvm")
    
    // Authentication and authorization
    implementation("io.ktor:ktor-server-auth-jvm")
    implementation("io.ktor:ktor-server-auth-jwt-jvm")
    implementation("io.ktor:ktor-client-core")
    implementation("io.ktor:ktor-client-cio")
    implementation("io.ktor:ktor-client-content-negotiation")
    
    // CORS and other HTTP features
    implementation("io.ktor:ktor-server-cors-jvm")
    implementation("io.ktor:ktor-server-compression-jvm")
    implementation("io.ktor:ktor-server-caching-headers-jvm")
    implementation("io.ktor:ktor-server-conditional-headers-jvm")
    implementation("io.ktor:ktor-server-default-headers-jvm")
    implementation("io.ktor:ktor-server-forwarded-header-jvm")
    implementation("io.ktor:ktor-server-call-logging-jvm")
    implementation("io.ktor:ktor-server-call-id-jvm")
    
    // WebSocket support
    implementation("io.ktor:ktor-server-websockets-jvm")
    
    // Status pages and error handling
    implementation("io.ktor:ktor-server-status-pages-jvm")
    
    // Rate limiting
    implementation("io.ktor:ktor-server-rate-limit-jvm")
    
    // Monitoring and metrics
    implementation("io.ktor:ktor-server-metrics-micrometer-jvm")
    implementation("io.micrometer:micrometer-registry-prometheus:1.12.1")
    
    // Database - Exposed ORM
    implementation("org.jetbrains.exposed:exposed-core:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-dao:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-jdbc:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-kotlin-datetime:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-json:$exposed_version")
    
    // PostgreSQL driver
    implementation("org.postgresql:postgresql:$postgresql_version")
    
    // Connection pooling
    implementation("com.zaxxer:HikariCP:5.1.0")
    
    // Database migrations
    implementation("org.flywaydb:flyway-core:10.4.1")
    implementation("org.flywaydb:flyway-database-postgresql:10.4.1")
    
    // Redis for caching
    implementation("io.lettuce:lettuce-core:6.3.0.RELEASE")
    
    // Dependency injection
    implementation("io.insert-koin:koin-ktor:$koin_version")
    implementation("io.insert-koin:koin-logger-slf4j:$koin_version")
    
    // Validation
    implementation("am.ik.yavi:yavi:0.14.1")
    
    // Password hashing
    implementation("org.springframework:spring-security-crypto:6.2.1")
    
    // JSON Web Tokens
    implementation("com.auth0:java-jwt:4.4.0")
    
    // AWS SDK for S3 and other services
    implementation("aws.sdk.kotlin:s3:1.0.30")
    implementation("aws.sdk.kotlin:ses:1.0.30")
    implementation("aws.sdk.kotlin:sns:1.0.30")
    implementation("aws.sdk.kotlin:sqs:1.0.30")
    
    // Email
    implementation("com.sendgrid:sendgrid-java:4.10.2")
    
    // HTTP client for external APIs
    implementation("io.ktor:ktor-client-apache-jvm")
    implementation("io.ktor:ktor-client-logging-jvm")
    
    // Logging
    implementation("ch.qos.logback:logback-classic:$logback_version")
    implementation("net.logstash.logback:logstash-logback-encoder:7.4")
    implementation("io.github.microutils:kotlin-logging-jvm:3.0.5")
    
    // Date and time
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")
    
    // Configuration
    implementation("io.github.config4k:config4k:0.7.0")
    
    // Jackson for JSON processing (for complex scenarios)
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin:$jackson_version")
    implementation("com.fasterxml.jackson.datatype:jackson-datatype-jsr310:$jackson_version")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // Testing
    testImplementation("io.ktor:ktor-server-tests-jvm")
    testImplementation("io.ktor:ktor-server-test-host-jvm")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:$kotlin_version")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.testcontainers:postgresql:1.19.3")
    testImplementation("org.testcontainers:junit-jupiter:1.19.3")
    testImplementation("io.insert-koin:koin-test:$koin_version")
    testImplementation("io.insert-koin:koin-test-junit5:$koin_version")
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
}
