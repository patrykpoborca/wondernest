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
    id("org.flywaydb.flyway") version "10.4.1"
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

// Add configuration for Flyway runtime dependencies
configurations {
    create("flywayRuntime")
}

dependencies {
    // Flyway runtime dependencies (for Gradle plugin)
    "flywayRuntime"("org.postgresql:postgresql:$postgresql_version")
    "flywayRuntime"("org.flywaydb:flyway-database-postgresql:10.4.1")
    
    // Core Ktor dependencies
    implementation("io.ktor:ktor-server-core-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-netty-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-config-yaml:$ktor_version")
    implementation("io.ktor:ktor-server-host-common-jvm:$ktor_version")
    
    // Content negotiation and serialization
    implementation("io.ktor:ktor-server-content-negotiation-jvm:$ktor_version")
    implementation("io.ktor:ktor-serialization-kotlinx-json-jvm:$ktor_version")
    implementation("io.ktor:ktor-serialization-jackson-jvm:$ktor_version")
    
    // Authentication and authorization
    implementation("io.ktor:ktor-server-auth-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-auth-jwt-jvm:$ktor_version")
    implementation("io.ktor:ktor-client-core:$ktor_version")
    implementation("io.ktor:ktor-client-cio:$ktor_version")
    implementation("io.ktor:ktor-client-content-negotiation:$ktor_version")
    
    // CORS and other HTTP features
    implementation("io.ktor:ktor-server-cors-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-compression-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-caching-headers-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-conditional-headers-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-default-headers-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-forwarded-header-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-call-logging-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-call-id-jvm:$ktor_version")
    
    // WebSocket support
    implementation("io.ktor:ktor-server-websockets-jvm:$ktor_version")
    
    // Status pages and error handling
    implementation("io.ktor:ktor-server-status-pages-jvm:$ktor_version")
    
    // Rate limiting
    implementation("io.ktor:ktor-server-rate-limit-jvm:$ktor_version")
    
    // OpenAPI and Swagger UI
    implementation("io.ktor:ktor-server-openapi:$ktor_version")
    implementation("io.ktor:ktor-server-swagger:$ktor_version")
    
    // Monitoring and metrics
    implementation("io.ktor:ktor-server-metrics-micrometer-jvm:$ktor_version")
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
    implementation("io.insert-koin:koin-ktor3:$koin_version")
    implementation("io.insert-koin:koin-logger-slf4j:$koin_version")
    
    // Validation
    implementation("am.ik.yavi:yavi:0.14.1")
    
    // Password hashing
    implementation("org.springframework.security:spring-security-crypto:6.3.6")
    
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
    implementation("io.ktor:ktor-client-apache-jvm:$ktor_version")
    implementation("io.ktor:ktor-client-logging-jvm:$ktor_version")
    
    // Logging
    implementation("ch.qos.logback:logback-classic:$logback_version")
    implementation("net.logstash.logback:logstash-logback-encoder:7.4")
    implementation("io.github.microutils:kotlin-logging-jvm:3.0.5")
    
    // Date and time
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")
    
    // UUID serialization support
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
    
    // Configuration
    implementation("io.github.config4k:config4k:0.7.0")
    
    // Jackson for JSON processing (for complex scenarios)
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin:$jackson_version")
    implementation("com.fasterxml.jackson.datatype:jackson-datatype-jsr310:$jackson_version")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // Testing
    testImplementation("io.ktor:ktor-server-test-host-jvm:$ktor_version")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5:$kotlin_version")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.testcontainers:postgresql:1.19.3")
    testImplementation("org.testcontainers:junit-jupiter:1.19.3")
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

// Configure Java compatibility to match Docker container
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        jvmTarget = "17"
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

// =============================================================================
// Flyway Configuration for Database Migrations
// =============================================================================

flyway {
    // Database connection configuration - uses same env vars as application
    url = System.getenv("DB_URL") ?: run {
        val dbHost = System.getenv("DB_HOST") ?: "localhost"
        val dbPort = System.getenv("DB_PORT") ?: "5433"
        val dbName = System.getenv("DB_NAME") ?: "wondernest_prod"
        "jdbc:postgresql://$dbHost:$dbPort/$dbName"
    }
    user = System.getenv("DB_USERNAME") ?: "wondernest_app"
    password = System.getenv("DB_PASSWORD") ?: "wondernest_secure_password_dev"
    driver = "org.postgresql.Driver"
    
    // Use the flywayRuntime configuration for dependencies
    configurations = arrayOf("flywayRuntime")
    
    // Migration settings
    locations = arrayOf("classpath:db/migration")
    table = "flyway_schema_history"
    validateMigrationNaming = true
    validateOnMigrate = true
    cleanOnValidationError = false
    mixed = false
    outOfOrder = false
    
    // Environment-specific settings
    val environment = System.getenv("KTOR_ENV") ?: "production"
    if (environment == "development") {
        cleanDisabled = false  // Allow clean in development
    } else {
        cleanDisabled = true   // Prevent accidental clean in production
    }
    
    // Encoding and file patterns
    encoding = "UTF-8"
    sqlMigrationSuffixes = arrayOf(".sql")
}

// Custom Gradle tasks for migration management
tasks.register("flywayStatus") {
    group = "flyway"
    description = "Shows the current migration status"
    dependsOn("flywayInfo")
}

tasks.register("flywayMigrateVerbose") {
    group = "flyway"
    description = "Migrates the database with verbose output"
    doFirst {
        println("========================================")
        println("Running database migrations...")
        println("URL: ${flyway.url}")
        println("User: ${flyway.user}")
        println("Locations: ${flyway.locations.joinToString(", ")}")
        println("========================================")
    }
    dependsOn("flywayMigrate")
    doLast {
        println("========================================")
        println("Migration completed successfully!")
        println("========================================")
    }
}

tasks.register("flywayValidateVerbose") {
    group = "flyway"
    description = "Validates migration files with verbose output"
    doFirst {
        println("Validating migration files...")
    }
    dependsOn("flywayValidate")
    doLast {
        println("Migration validation completed!")
    }
}
