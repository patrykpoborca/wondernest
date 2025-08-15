package com.wondernest.api.auth

import com.wondernest.api.validation.AuthValidation
import com.wondernest.api.validation.AuthValidationException
import com.wondernest.api.validation.throwIfInvalid
import com.wondernest.services.auth.AuthService
import com.wondernest.services.auth.SignupRequest
import com.wondernest.services.auth.LoginRequest
import com.wondernest.services.auth.OAuthLoginRequest
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.plugins.ratelimit.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.util.*

@Serializable
data class VerifyEmailRequest(val userId: String)

@Serializable
data class PasswordResetRequest(val email: String)

@Serializable
data class PasswordResetConfirmRequest(
    val token: String,
    val newPassword: String
)

@Serializable
data class RefreshTokenRequest(val refreshToken: String)

@Serializable
data class PinVerificationRequest(val pin: String)

@Serializable  
data class PinVerificationResponse(
    val verified: Boolean,
    val message: String,
    val sessionToken: String? = null
)

@Serializable
data class MessageResponse(val message: String)

fun Route.authRoutes() {
    val authService by inject<AuthService>()

    route("/auth") {
        
        rateLimit(RateLimitName("auth")) {
            // Parent-specific registration (Flutter expects this endpoint)
            post("/parent/register") {
                try {
                    val rawRequest = call.receive<SignupRequest>()
                    call.application.environment.log.info("Received parent signup request: email=${rawRequest.email}, name=${rawRequest.firstName} ${rawRequest.lastName}")
                    
                    // Validate request
                    val validationResult = AuthValidation.validateSignupRequest(rawRequest)
                    if (!validationResult.isValid) {
                        call.application.environment.log.warn("Parent signup validation failed: ${validationResult.errors}")
                        call.respond(HttpStatusCode.BadRequest, MessageResponse("Validation failed: ${validationResult.errors.joinToString(", ")}"))
                        return@post
                    }
                    
                    // Sanitize request
                    val sanitizedRequest = AuthValidation.sanitizeSignupRequest(rawRequest)
                    call.application.environment.log.info("Sanitized parent signup request: ${sanitizedRequest}")
                    
                    // Create parent account with family
                    val response = authService.signupParent(sanitizedRequest)
                    call.application.environment.log.info("Parent signup successful for user: ${sanitizedRequest.email}")
                    call.respond(HttpStatusCode.Created, response)
                } catch (e: AuthValidationException) {
                    call.application.environment.log.warn("Parent signup validation exception: ${e.message}", e)
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: IllegalArgumentException) {
                    call.application.environment.log.warn("Parent signup illegal argument: ${e.message}", e)
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Invalid input"))
                } catch (e: ContentTransformationException) {
                    call.application.environment.log.warn("JSON parsing error: ${e.message}", e)
                    call.respond(HttpStatusCode.BadRequest, MessageResponse("Invalid JSON format"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Parent signup error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Registration failed"))
                }
            }

            // Parent-specific login (Flutter expects this endpoint)  
            post("/parent/login") {
                try {
                    val rawRequest = call.receive<LoginRequest>()
                    call.application.environment.log.info("Received parent login request: email=${rawRequest.email}")
                    
                    // Validate request
                    AuthValidation.validateLoginRequest(rawRequest).throwIfInvalid()
                    
                    // Sanitize request
                    val sanitizedRequest = AuthValidation.sanitizeLoginRequest(rawRequest)
                    
                    // Login with family context
                    val response = authService.loginParent(sanitizedRequest)
                    call.application.environment.log.info("Parent login successful for user: ${sanitizedRequest.email}")
                    call.respond(HttpStatusCode.OK, response)
                } catch (e: AuthValidationException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: SecurityException) {
                    call.respond(HttpStatusCode.Unauthorized, MessageResponse("Invalid credentials"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Parent login error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Login failed"))
                }
            }

            // PIN verification endpoint (Flutter expects this for parent mode switching)
            post("/parent/verify-pin") {
                try {
                    val rawRequest = call.receive<PinVerificationRequest>()
                    
                    // Basic validation
                    if (rawRequest.pin.isBlank() || rawRequest.pin.length != 4 || !rawRequest.pin.all { it.isDigit() }) {
                        call.respond(HttpStatusCode.BadRequest, PinVerificationResponse(
                            verified = false,
                            message = "Invalid PIN format. Must be 4 digits."
                        ))
                        return@post
                    }
                    
                    // TODO: PRODUCTION - Implement proper PIN storage and verification
                    // For now, we'll use a default PIN for development/demo
                    val defaultPin = "1234" // TODO: Remove this and implement proper PIN management
                    
                    if (rawRequest.pin == defaultPin) {
                        // Generate a temporary session token for parent mode
                        // TODO: Implement proper parent mode session management
                        val sessionToken = "parent_mode_${System.currentTimeMillis()}"
                        
                        call.respond(HttpStatusCode.OK, PinVerificationResponse(
                            verified = true,
                            message = "PIN verified successfully",
                            sessionToken = sessionToken
                        ))
                        call.application.environment.log.info("PIN verification successful")
                    } else {
                        call.respond(HttpStatusCode.Unauthorized, PinVerificationResponse(
                            verified = false,
                            message = "Invalid PIN"
                        ))
                        call.application.environment.log.warn("PIN verification failed")
                    }
                } catch (e: Exception) {
                    call.application.environment.log.error("PIN verification error", e)
                    call.respond(HttpStatusCode.InternalServerError, PinVerificationResponse(
                        verified = false,
                        message = "PIN verification failed"
                    ))
                }
            }

            // Generic signup (keeping for backward compatibility)
            post("/signup") {
                try {
                    val rawRequest = call.receive<SignupRequest>()
                    call.application.environment.log.info("Received signup request: email=${rawRequest.email}, firstName=${rawRequest.firstName}, lastName=${rawRequest.lastName}")
                    
                    // Validate request
                    val validationResult = AuthValidation.validateSignupRequest(rawRequest)
                    if (!validationResult.isValid) {
                        call.application.environment.log.warn("Signup validation failed: ${validationResult.errors}")
                        call.respond(HttpStatusCode.BadRequest, MessageResponse("Validation failed: ${validationResult.errors.joinToString(", ")}"))
                        return@post
                    }
                    
                    // Sanitize request
                    val sanitizedRequest = AuthValidation.sanitizeSignupRequest(rawRequest)
                    call.application.environment.log.info("Sanitized signup request: ${sanitizedRequest}")
                    
                    val response = authService.signup(sanitizedRequest)
                    call.application.environment.log.info("Signup successful for user: ${sanitizedRequest.email}")
                    call.respond(HttpStatusCode.Created, response)
                } catch (e: AuthValidationException) {
                    call.application.environment.log.warn("Signup validation exception: ${e.message}", e)
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: IllegalArgumentException) {
                    call.application.environment.log.warn("Signup illegal argument: ${e.message}", e)
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Invalid input"))
                } catch (e: ContentTransformationException) {
                    call.application.environment.log.warn("JSON parsing error: ${e.message}", e)
                    call.respond(HttpStatusCode.BadRequest, MessageResponse("Invalid JSON format"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Signup error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Registration failed"))
                }
            }

            // Login
            post("/login") {
                try {
                    val rawRequest = call.receive<LoginRequest>()
                    
                    // Validate request
                    AuthValidation.validateLoginRequest(rawRequest).throwIfInvalid()
                    
                    // Sanitize request
                    val sanitizedRequest = AuthValidation.sanitizeLoginRequest(rawRequest)
                    
                    val response = authService.login(sanitizedRequest)
                    call.respond(HttpStatusCode.OK, response)
                } catch (e: AuthValidationException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: SecurityException) {
                    call.respond(HttpStatusCode.Unauthorized, MessageResponse("Invalid credentials"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Login error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Login failed"))
                }
            }

            // OAuth login (Google, Apple, Facebook)
            post("/oauth") {
                try {
                    val rawRequest = call.receive<OAuthLoginRequest>()
                    
                    // Validate request
                    AuthValidation.validateOAuthLoginRequest(rawRequest).throwIfInvalid()
                    
                    // Sanitize request
                    val sanitizedRequest = AuthValidation.sanitizeOAuthLoginRequest(rawRequest)
                    
                    val response = authService.oauthLogin(sanitizedRequest)
                    call.respond(HttpStatusCode.OK, response)
                } catch (e: AuthValidationException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: SecurityException) {
                    call.respond(HttpStatusCode.Unauthorized, MessageResponse("OAuth authentication failed"))
                } catch (e: Exception) {
                    call.application.environment.log.error("OAuth error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("OAuth login failed"))
                }
            }

            // Request password reset
            post("/password-reset") {
                try {
                    val rawRequest = call.receive<PasswordResetRequest>()
                    
                    // Validate request
                    AuthValidation.validatePasswordResetRequest(rawRequest).throwIfInvalid()
                    
                    val success = authService.requestPasswordReset(rawRequest.email.trim().lowercase())
                    if (success) {
                        call.respond(HttpStatusCode.OK, MessageResponse("Password reset email sent"))
                    } else {
                        // Always return success for security (don't reveal if email exists)
                        call.respond(HttpStatusCode.OK, MessageResponse("Password reset email sent"))
                    }
                } catch (e: AuthValidationException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Password reset request error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Password reset request failed"))
                }
            }

            // Confirm password reset
            post("/password-reset/confirm") {
                try {
                    val rawRequest = call.receive<PasswordResetConfirmRequest>()
                    
                    // Validate request
                    AuthValidation.validatePasswordResetConfirmRequest(rawRequest).throwIfInvalid()
                    
                    val success = authService.resetPassword(rawRequest.token.trim(), rawRequest.newPassword)
                    if (success) {
                        call.respond(HttpStatusCode.OK, MessageResponse("Password reset successful"))
                    } else {
                        call.respond(HttpStatusCode.BadRequest, MessageResponse("Invalid or expired token"))
                    }
                } catch (e: AuthValidationException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Validation failed"))
                } catch (e: IllegalArgumentException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Invalid password"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Password reset confirm error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Password reset failed"))
                }
            }
        }

        // Refresh token endpoint for Flutter compatibility
        route("/session") {
            post("/refresh") {
                try {
                    val request = call.receive<RefreshTokenRequest>()
                    val response = authService.refreshToken(request.refreshToken)
                    call.respond(HttpStatusCode.OK, response)
                } catch (e: SecurityException) {
                    call.respond(HttpStatusCode.Unauthorized, MessageResponse("Invalid refresh token"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Token refresh error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Token refresh failed"))
                }
            }
        }

        // Legacy refresh token endpoint (higher rate limit)
        post("/refresh") {
            try {
                val request = call.receive<RefreshTokenRequest>()
                val response = authService.refreshToken(request.refreshToken)
                call.respond(HttpStatusCode.OK, response)
            } catch (e: SecurityException) {
                call.respond(HttpStatusCode.Unauthorized, MessageResponse("Invalid refresh token"))
            } catch (e: Exception) {
                call.application.environment.log.error("Token refresh error", e)
                call.respond(HttpStatusCode.InternalServerError, MessageResponse("Token refresh failed"))
            }
        }

        // Protected routes (require authentication)
        authenticate("auth-jwt") {
            
            // Logout
            post("/logout") {
                try {
                    val token = call.principal<JWTPrincipal>()?.payload?.getClaim("sessionToken")?.asString()
                    if (token != null) {
                        val success = authService.logout(token)
                        call.respond(HttpStatusCode.OK, MessageResponse("Logged out successfully"))
                    } else {
                        call.respond(HttpStatusCode.BadRequest, MessageResponse("Invalid session"))
                    }
                } catch (e: Exception) {
                    call.application.environment.log.error("Logout error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Logout failed"))
                }
            }

            // Verify email
            post("/verify-email") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val userId = principal?.payload?.getClaim("userId")?.asString()
                    
                    if (userId != null) {
                        val success = authService.verifyEmail(UUID.fromString(userId))
                        if (success) {
                            call.respond(HttpStatusCode.OK, MessageResponse("Email verified successfully"))
                        } else {
                            call.respond(HttpStatusCode.BadRequest, MessageResponse("Email verification failed"))
                        }
                    } else {
                        call.respond(HttpStatusCode.Unauthorized, MessageResponse("Invalid token"))
                    }
                } catch (e: Exception) {
                    call.application.environment.log.error("Email verification error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Email verification failed"))
                }
            }

            // Get current user profile
            get("/me") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val userId = principal?.payload?.getClaim("userId")?.asString()
                    
                    if (userId != null) {
                        // Return user info from token or fetch from database
                        val userInfo = mapOf(
                            "id" to userId,
                            "email" to principal.payload.getClaim("email").asString(),
                            "role" to principal.payload.getClaim("role").asString(),
                            "verified" to principal.payload.getClaim("verified").asBoolean()
                        )
                        call.respond(HttpStatusCode.OK, userInfo)
                    } else {
                        call.respond(HttpStatusCode.Unauthorized, MessageResponse("Invalid token"))
                    }
                } catch (e: Exception) {
                    call.application.environment.log.error("Get user profile error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to get user profile"))
                }
            }
        }
    }
}