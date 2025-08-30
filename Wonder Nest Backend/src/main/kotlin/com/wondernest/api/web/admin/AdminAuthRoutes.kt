package com.wondernest.api.web.admin

import com.wondernest.domain.web.AdminLoginRequest
import com.wondernest.services.web.admin.AdminAuthService
import com.wondernest.services.web.admin.AuthenticationException
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import mu.KotlinLogging
import org.koin.ktor.ext.inject
import java.util.*

private val logger = KotlinLogging.logger {}

@Serializable
data class RefreshTokenRequest(
    val refreshToken: String
)

@Serializable
data class ErrorResponse(
    val error: String,
    val message: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)

@Serializable
data class SuccessResponse(
    val message: String,
    val timestamp: Long = System.currentTimeMillis()
)

/**
 * Admin authentication routes for the web platform
 */
fun Route.adminAuthRoutes() {
    val adminAuthService by inject<AdminAuthService>()

    route("/admin/auth") {
        
        /**
         * Admin login endpoint
         * POST /api/web/v1/admin/auth/login
         */
        post("/login") {
            try {
                val request = call.receive<AdminLoginRequest>()
                
                // Validate input
                if (request.email.isBlank() || request.password.isBlank()) {
                    call.respond(
                        HttpStatusCode.BadRequest, 
                        ErrorResponse("validation_error", "Email and password are required")
                    )
                    return@post
                }
                
                // Get client information
                val ipAddress = call.request.headers["X-Forwarded-For"] 
                    ?: call.request.headers["X-Real-IP"]
                    ?: call.request.local.remoteHost
                val userAgent = call.request.headers["User-Agent"]
                
                logger.info { "Admin login attempt: ${request.email} from $ipAddress" }
                
                // Authenticate admin
                val response = adminAuthService.authenticateAdmin(
                    request = request,
                    ipAddress = ipAddress,
                    userAgent = userAgent
                )
                
                call.respond(HttpStatusCode.OK, response)
                
            } catch (e: AuthenticationException) {
                logger.warn { "Admin authentication failed: ${e.message}" }
                call.respond(
                    HttpStatusCode.Unauthorized, 
                    ErrorResponse("authentication_failed", e.message)
                )
            } catch (e: IllegalArgumentException) {
                logger.warn { "Invalid admin login request: ${e.message}" }
                call.respond(
                    HttpStatusCode.BadRequest, 
                    ErrorResponse("invalid_request", e.message)
                )
            } catch (e: Exception) {
                logger.error(e) { "Unexpected error during admin login" }
                call.respond(
                    HttpStatusCode.InternalServerError, 
                    ErrorResponse("internal_error", "Login failed")
                )
            }
        }
        
        /**
         * Admin token refresh endpoint  
         * POST /api/web/v1/admin/auth/refresh
         */
        post("/refresh") {
            try {
                val request = call.receive<RefreshTokenRequest>()
                
                if (request.refreshToken.isBlank()) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("validation_error", "Refresh token is required")
                    )
                    return@post
                }
                
                val response = adminAuthService.refreshAdminToken(request.refreshToken)
                call.respond(HttpStatusCode.OK, response)
                
            } catch (e: AuthenticationException) {
                logger.warn { "Admin token refresh failed: ${e.message}" }
                call.respond(
                    HttpStatusCode.Unauthorized,
                    ErrorResponse("token_refresh_failed", e.message)
                )
            } catch (e: Exception) {
                logger.error(e) { "Unexpected error during token refresh" }
                call.respond(
                    HttpStatusCode.InternalServerError,
                    ErrorResponse("internal_error", "Token refresh failed")
                )
            }
        }
        
        /**
         * Protected admin routes (require valid JWT)
         */
        authenticate("admin-jwt") {
            
            /**
             * Admin logout endpoint
             * POST /api/web/v1/admin/auth/logout
             */
            post("/logout") {
                try {
                    val token = call.request.headers["Authorization"]?.removePrefix("Bearer ")
                    
                    if (token.isNullOrBlank()) {
                        call.respond(
                            HttpStatusCode.BadRequest,
                            ErrorResponse("validation_error", "Authorization token required")
                        )
                        return@post
                    }
                    
                    val success = adminAuthService.logoutAdmin(token)
                    
                    if (success) {
                        call.respond(
                            HttpStatusCode.OK,
                            SuccessResponse("Logged out successfully")
                        )
                    } else {
                        call.respond(
                            HttpStatusCode.BadRequest,
                            ErrorResponse("logout_failed", "Invalid session")
                        )
                    }
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error during admin logout" }
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse("internal_error", "Logout failed")
                    )
                }
            }
            
            /**
             * Get current admin user profile
             * GET /api/web/v1/admin/auth/profile
             */
            get("/profile") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val adminIdStr = principal?.payload?.getClaim("userId")?.asString()
                    
                    if (adminIdStr.isNullOrBlank()) {
                        call.respond(
                            HttpStatusCode.Unauthorized,
                            ErrorResponse("invalid_token", "Invalid user ID in token")
                        )
                        return@get
                    }
                    
                    val adminId = UUID.fromString(adminIdStr)
                    val token = call.request.headers["Authorization"]?.removePrefix("Bearer ")
                        ?: return@get
                    
                    val adminUser = adminAuthService.validateSession(token)
                    
                    if (adminUser == null) {
                        call.respond(
                            HttpStatusCode.Unauthorized,
                            ErrorResponse("invalid_session", "Session not valid")
                        )
                        return@get
                    }
                    
                    call.respond(HttpStatusCode.OK, adminUser.toProfile())
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error getting admin profile" }
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse("internal_error", "Failed to get profile")
                    )
                }
            }
            
            /**
             * Get active sessions for current admin user
             * GET /api/web/v1/admin/auth/sessions
             */
            get("/sessions") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val adminIdStr = principal?.payload?.getClaim("userId")?.asString()
                    
                    if (adminIdStr.isNullOrBlank()) {
                        call.respond(
                            HttpStatusCode.Unauthorized,
                            ErrorResponse("invalid_token", "Invalid user ID in token")
                        )
                        return@get
                    }
                    
                    val adminId = UUID.fromString(adminIdStr)
                    val sessions = adminAuthService.getActiveSessions(adminId)
                    
                    call.respond(HttpStatusCode.OK, mapOf("sessions" to sessions))
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error getting admin sessions" }
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse("internal_error", "Failed to get sessions")
                    )
                }
            }
            
            /**
             * Force logout all sessions (requires MANAGE_SECURITY_SETTINGS permission)
             * POST /api/web/v1/admin/auth/logout-all
             */
            post("/logout-all") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val permissions = principal?.payload?.getClaim("permissions")
                        ?.asList(String::class.java) ?: emptyList()
                    
                    if ("manage_security_settings" !in permissions) {
                        call.respond(
                            HttpStatusCode.Forbidden,
                            ErrorResponse("insufficient_permissions", "Security management permission required")
                        )
                        return@post
                    }
                    
                    val adminIdStr = principal?.payload?.getClaim("userId")?.asString()
                    if (adminIdStr.isNullOrBlank()) {
                        call.respond(
                            HttpStatusCode.Unauthorized,
                            ErrorResponse("invalid_token", "Invalid user ID in token")
                        )
                        return@post
                    }
                    
                    val adminId = UUID.fromString(adminIdStr)
                    val loggedOutCount = adminAuthService.deactivateAllSessions(adminId)
                    
                    call.respond(
                        HttpStatusCode.OK,
                        mapOf(
                            "message" to "All sessions logged out successfully",
                            "sessionsLoggedOut" to loggedOutCount
                        )
                    )
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error during force logout all" }
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse("internal_error", "Force logout failed")
                    )
                }
            }
        }
    }
}