package com.wondernest.data.database

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import io.ktor.server.config.*
import kotlinx.coroutines.Dispatchers
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.SchemaUtils
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction
import org.jetbrains.exposed.sql.transactions.transaction
import com.wondernest.data.database.table.*

class DatabaseFactory {
    private lateinit var dataSource: HikariDataSource
    
    fun init() {
        val config = HikariConfig().apply {
            driverClassName = System.getenv("DB_DRIVER") ?: "org.postgresql.Driver"
            jdbcUrl = System.getenv("DB_URL") ?: "jdbc:postgresql://localhost:5432/wondernest_dev"
            username = System.getenv("DB_USERNAME") ?: "wondernest_user"
            password = System.getenv("DB_PASSWORD") ?: "wondernest_password"
            maximumPoolSize = System.getenv("DB_MAX_POOL_SIZE")?.toInt() ?: 20
            minimumIdle = System.getenv("DB_MIN_IDLE")?.toInt() ?: 5
            connectionTimeout = 30000
            idleTimeout = 600000
            maxLifetime = 1800000
            isAutoCommit = false
            transactionIsolation = "TRANSACTION_REPEATABLE_READ"
            validate()
        }
        
        dataSource = HikariDataSource(config)
        Database.connect(dataSource)
        
        // Create tables in development
        if (System.getenv("KTOR_ENV") == "development") {
            transaction {
                SchemaUtils.create(
                    Users,
                    UserSessions,
                    PasswordResetTokens,
                    Families,
                    FamilyMembers,
                    ChildProfiles,
                    Plans,
                    UserSubscriptions,
                    Transactions,
                    Categories,
                    Creators,
                    ContentItems,
                    ItemCategories,
                    ContentEngagement,
                    AudioSessions,
                    SpeechMetrics,
                    DailyChildMetrics,
                    Milestones,
                    Events,
                    RecommendationModels,
                    ContentRecommendations,
                    ContentReviews,
                    ParentalControls,
                    ActivityLog,
                    DataRetentionPolicies
                )
            }
        }
    }
    
    suspend fun <T> dbQuery(block: suspend () -> T): T =
        newSuspendedTransaction(Dispatchers.IO) { block() }
    
    fun close() {
        if (::dataSource.isInitialized) {
            dataSource.close()
        }
    }
}