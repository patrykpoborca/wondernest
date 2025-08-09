package com.wondernest.api.auth

import com.wondernest.services.auth.AuthService
import com.wondernest.services.auth.SignupRequest
import com.wondernest.services.auth.LoginRequest
import com.wondernest.services.auth.OAuthLoginRequest
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
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
data class MessageResponse(val message: String)

fun Route.authRoutes() {
    val authService by inject<AuthService>()

    route("/auth") {
        
        rateLimit(RateLimitName("auth")) {
            // Sign up
            post("/signup") {
                try {
                    val request = call.receive<SignupRequest>()
                    val response = authService.signup(request)
                    call.respond(HttpStatusCode.Created, response)
                } catch (e: IllegalArgumentException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Invalid input"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Signup error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Registration failed"))
                }
            }

            // Login
            post("/login") {
                try {
                    val request = call.receive<LoginRequest>()
                    val response = authService.login(request)
                    call.respond(HttpStatusCode.OK, response)
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
                    val request = call.receive<OAuthLoginRequest>()
                    val response = authService.oauthLogin(request)
                    call.respond(HttpStatusCode.OK, response)
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
                    val request = call.receive<PasswordResetRequest>()
                    val success = authService.requestPasswordReset(request.email)
                    if (success) {
                        call.respond(HttpStatusCode.OK, MessageResponse("Password reset email sent"))
                    } else {
                        // Always return success for security (don't reveal if email exists)
                        call.respond(HttpStatusCode.OK, MessageResponse("Password reset email sent"))
                    }
                } catch (e: Exception) {
                    call.application.environment.log.error("Password reset request error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Password reset request failed"))
                }
            }

            // Confirm password reset
            post("/password-reset/confirm") {
                try {
                    val request = call.receive<PasswordResetConfirmRequest>()
                    val success = authService.resetPassword(request.token, request.newPassword)
                    if (success) {
                        call.respond(HttpStatusCode.OK, MessageResponse("Password reset successful"))
                    } else {
                        call.respond(HttpStatusCode.BadRequest, MessageResponse("Invalid or expired token"))
                    }
                } catch (e: IllegalArgumentException) {
                    call.respond(HttpStatusCode.BadRequest, MessageResponse(e.message ?: "Invalid password"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Password reset confirm error", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Password reset failed"))
                }
            }
        }

        // Refresh token (higher rate limit)
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