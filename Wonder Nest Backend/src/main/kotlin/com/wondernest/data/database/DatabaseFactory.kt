package com.wondernest.data.database

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import io.ktor.server.config.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.SchemaUtils
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction
import org.jetbrains.exposed.sql.transactions.transaction
import org.slf4j.LoggerFactory
import com.wondernest.data.database.table.*
import java.sql.SQLException
import kotlin.time.Duration.Companion.seconds

class DatabaseFactory {
    private lateinit var dataSource: HikariDataSource
    private val logger = LoggerFactory.getLogger(DatabaseFactory::class.java)
    
    fun init() {
        val config = HikariConfig().apply {
            driverClassName = System.getenv("DB_DRIVER") ?: "org.postgresql.Driver"
            
            // Build JDBC URL from environment variables or use fallback
            val dbHost = System.getenv("DB_HOST") ?: "localhost"
            val dbPort = System.getenv("DB_PORT") ?: "5432"
            val dbName = System.getenv("DB_NAME") ?: "wondernest_prod"
            jdbcUrl = System.getenv("DB_URL") ?: "jdbc:postgresql://$dbHost:$dbPort/$dbName"
            
            username = System.getenv("DB_USERNAME") ?: "wondernest_app"
            password = System.getenv("DB_PASSWORD") ?: "wondernest_secure_password_dev"
            maximumPoolSize = System.getenv("DB_MAX_POOL_SIZE")?.toIntOrNull() ?: 20
            minimumIdle = System.getenv("DB_MIN_IDLE")?.toIntOrNull() ?: 5
            
            // Connection settings optimized for both Docker and local development
            connectionTimeout = 30000  // 30 seconds
            idleTimeout = 600000       // 10 minutes
            maxLifetime = 1800000      // 30 minutes
            leakDetectionThreshold = 60000 // 1 minute
            
            // Connection validation
            connectionTestQuery = "SELECT 1"
            validationTimeout = 5000   // 5 seconds
            
            // PostgreSQL specific optimizations
            isAutoCommit = false
            // Note: Transaction isolation is handled by Exposed, not HikariCP
            // transactionIsolation = "TRANSACTION_REPEATABLE_READ"
            
            // Additional connection properties for PostgreSQL
            addDataSourceProperty("cachePrepStmts", "true")
            addDataSourceProperty("prepStmtCacheSize", "250")
            addDataSourceProperty("prepStmtCacheSqlLimit", "2048")
            addDataSourceProperty("useServerPrepStmts", "true")
            addDataSourceProperty("reWriteBatchedInserts", "true")
            
            validate()
        }
        
        // Initialize connection with retry logic for Docker startup
        initializeWithRetry(config)
        
        // Run database migrations after successful connection
        runMigrations()
        
        logger.info("Database connection initialized successfully")
        logger.info("JDBC URL: ${config.jdbcUrl}")
        logger.info("Username: ${config.username}")
        logger.info("Max Pool Size: ${config.maximumPoolSize}")
    }
    
    private fun initializeWithRetry(config: HikariConfig, maxAttempts: Int = 10) {
        var attempt = 1
        var lastException: Exception? = null
        
        while (attempt <= maxAttempts) {
            try {
                logger.info("Attempting to connect to database (attempt $attempt/$maxAttempts)")
                dataSource = HikariDataSource(config)
                
                // Test the connection
                dataSource.connection.use { connection ->
                    connection.createStatement().use { statement ->
                        statement.executeQuery("SELECT 1").use { resultSet ->
                            if (resultSet.next()) {
                                logger.info("Database connection test successful")
                            }
                        }
                    }
                }
                
                Database.connect(dataSource)
                
                // Verify schema exists - if not, the database may still be initializing
                verifyDatabaseInitialization()
                
                return // Success!
                
            } catch (e: Exception) {
                lastException = e
                logger.warn("Database connection attempt $attempt failed: ${e.message}")
                
                if (::dataSource.isInitialized) {
                    try {
                        dataSource.close()
                    } catch (closeException: Exception) {
                        logger.warn("Error closing failed connection: ${closeException.message}")
                    }
                }
                
                if (attempt < maxAttempts) {
                    val delaySeconds = minOf(attempt * 2, 30) // Exponential backoff, max 30 seconds
                    logger.info("Retrying in $delaySeconds seconds...")
                    Thread.sleep(delaySeconds * 1000L)
                }
                
                attempt++
            }
        }
        
        throw SQLException("Failed to connect to database after $maxAttempts attempts", lastException)
    }
    
    private fun verifyDatabaseInitialization() {
        var attempts = 0
        val maxAttempts = 30 // 5 minutes with 10-second intervals
        
        while (attempts < maxAttempts) {
            try {
                transaction {
                    // Check if core schema exists (indicates successful initialization)
                    val schemaExists = exec("SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core')") { rs ->
                        rs.next() && rs.getBoolean(1)
                    } ?: false
                    
                    if (!schemaExists) {
                        logger.info("Database schema not yet initialized, waiting... (attempt ${attempts + 1}/$maxAttempts)")
                        throw SQLException("Schema not initialized")
                    }
                }
                
                logger.info("Database schema verification successful")
                return
                
            } catch (e: Exception) {
                attempts++
                if (attempts >= maxAttempts) {
                    logger.error("Database schema verification failed after $maxAttempts attempts")
                    throw SQLException("Database not properly initialized", e)
                }
                
                Thread.sleep(10000) // Wait 10 seconds before retry
            }
        }
    }
    
    private fun runMigrations() {
        try {
            val migrationService = MigrationService(dataSource)
            val migrationsExecuted = migrationService.migrate()
            
            if (migrationsExecuted > 0) {
                logger.info("Database migrations completed: $migrationsExecuted migrations applied")
            } else {
                logger.info("Database is up to date, no migrations needed")
            }
            
        } catch (e: Exception) {
            logger.error("Database migration failed", e)
            
            // In development, we might want to continue even if migrations fail
            val environment = System.getenv("KTOR_ENV") ?: "production"
            if (environment != "development") {
                throw e
            } else {
                logger.warn("Continuing in development mode despite migration failure")
            }
        }
    }
    
    suspend fun <T> dbQuery(block: suspend () -> T): T =
        newSuspendedTransaction(Dispatchers.IO) { block() }
    
    fun close() {
        if (::dataSource.isInitialized) {
            try {
                dataSource.close()
                logger.info("Database connection closed")
            } catch (e: Exception) {
                logger.error("Error closing database connection", e)
            }
        }
    }
    
    fun isHealthy(): Boolean {
        return try {
            if (!::dataSource.isInitialized) return false
            
            dataSource.connection.use { connection ->
                connection.createStatement().use { statement ->
                    statement.executeQuery("SELECT 1").use { resultSet ->
                        resultSet.next()
                    }
                }
            }
            true
        } catch (e: Exception) {
            logger.warn("Database health check failed: ${e.message}")
            false
        }
    }
}