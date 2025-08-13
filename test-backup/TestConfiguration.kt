package com.wondernest

import com.wondernest.config.*
import com.wondernest.data.cache.RedisCache
import com.wondernest.data.database.DatabaseFactory
import com.wondernest.services.auth.AuthService
import com.wondernest.services.auth.JwtService
import io.ktor.server.application.*
import io.ktor.server.testing.*
import io.mockk.mockk
import org.koin.dsl.module
import org.koin.ktor.plugin.Koin
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

/**
 * Test configuration for WonderNest Backend
 * Provides test-specific module configuration and containerized dependencies
 */
@Testcontainers
object TestConfiguration {
    
    @Container
    val postgres: PostgreSQLContainer<*> = PostgreSQLContainer("postgres:15")
        .withDatabaseName("wondernest_test")
        .withUsername("test")
        .withPassword("test")
        .withReuse(true)
    
    /**
     * Creates a test Koin module with mocked services
     */
    fun createTestModule() = module {
        // Mock external services for testing
        single<RedisCache> { mockk(relaxed = true) }
        single<DatabaseFactory> { mockk(relaxed = true) }
        single<AuthService> { mockk(relaxed = true) }
        single<JwtService> { mockk(relaxed = true) }
    }
    
    /**
     * Creates a test module with real database connection
     */
    fun createIntegrationTestModule() = module {
        single<DatabaseFactory> { 
            DatabaseFactory().apply {
                init(
                    url = postgres.jdbcUrl,
                    user = postgres.username,
                    password = postgres.password
                )
            }
        }
        single<RedisCache> { mockk(relaxed = true) }
        single<JwtService> { JwtService() }
        single<AuthService> { AuthService(get(), get(), get()) }
    }
}

/**
 * Test application configuration
 */
fun Application.testModule(useRealDatabase: Boolean = false) {
    install(Koin) {
        modules(
            if (useRealDatabase) {
                TestConfiguration.createIntegrationTestModule()
            } else {
                TestConfiguration.createTestModule()
            }
        )
    }
    
    configureSerialization()
    configureHTTP()
    configureSecurity()
    configureAuthentication()
    configureRouting()
    configureMonitoring()
}

/**
 * Creates a test application with the given configuration
 */
fun testApplication(
    useRealDatabase: Boolean = false,
    test: suspend ApplicationTestBuilder.() -> Unit
) = io.ktor.server.testing.testApplication {
    application {
        testModule(useRealDatabase)
    }
    test()
}