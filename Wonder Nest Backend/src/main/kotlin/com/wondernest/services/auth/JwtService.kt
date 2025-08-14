package com.wondernest.services.auth

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.wondernest.domain.model.User
import kotlinx.datetime.*
import kotlinx.serialization.Serializable
import java.util.*

@Serializable
data class TokenPair(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long
)

class JwtService {
    val issuer = System.getenv("JWT_ISSUER") ?: "wondernest-api"
    val audience = System.getenv("JWT_AUDIENCE") ?: "wondernest-users"
    val realm = System.getenv("JWT_REALM") ?: "WonderNest API"
    val secret = System.getenv("JWT_SECRET") ?: "your-super-secret-jwt-key-change-this-in-production"
    
    private val expiresIn = System.getenv("JWT_EXPIRES_IN")?.toLong() ?: 3600000L // 1 hour
    private val refreshExpiresIn = System.getenv("JWT_REFRESH_EXPIRES_IN")?.toLong() ?: 2592000000L // 30 days
    
    private val algorithm = Algorithm.HMAC256(secret)

    fun generateToken(user: User): TokenPair {
        val now = Clock.System.now()
        val nonce = UUID.randomUUID().toString() // Ensure token uniqueness
        val expiresAt = now.plus(expiresIn, DateTimeUnit.MILLISECOND)
        val refreshExpiresAt = now.plus(refreshExpiresIn, DateTimeUnit.MILLISECOND)
        
        val accessToken = JWT.create()
            .withIssuer(issuer)
            .withAudience(audience)
            .withSubject(user.id.toString())
            .withClaim("userId", user.id.toString())
            .withClaim("email", user.email)
            .withClaim("role", user.role.name)
            .withClaim("verified", user.emailVerified)
            .withClaim("nonce", nonce) // Add unique nonce for token uniqueness
            .withIssuedAt(Date(now.toEpochMilliseconds()))
            .withExpiresAt(Date(expiresAt.toEpochMilliseconds()))
            .sign(algorithm)
        
        val refreshNonce = UUID.randomUUID().toString() // Separate nonce for refresh token
        val refreshToken = JWT.create()
            .withIssuer(issuer)
            .withAudience("$audience-refresh")
            .withSubject(user.id.toString())
            .withClaim("userId", user.id.toString())
            .withClaim("type", "refresh")
            .withClaim("nonce", refreshNonce) // Add unique nonce for refresh token uniqueness
            .withIssuedAt(Date(now.toEpochMilliseconds()))
            .withExpiresAt(Date(refreshExpiresAt.toEpochMilliseconds()))
            .sign(algorithm)
        
        return TokenPair(accessToken, refreshToken, expiresIn)
    }

    fun generateTokenWithFamilyContext(user: User, familyId: UUID): TokenPair {
        val now = Clock.System.now()
        val nonce = UUID.randomUUID().toString() // Ensure token uniqueness
        val expiresAt = now.plus(expiresIn, DateTimeUnit.MILLISECOND)
        val refreshExpiresAt = now.plus(refreshExpiresIn, DateTimeUnit.MILLISECOND)
        
        val accessToken = JWT.create()
            .withIssuer(issuer)
            .withAudience(audience)
            .withSubject(user.id.toString())
            .withClaim("userId", user.id.toString())
            .withClaim("familyId", familyId.toString())
            .withClaim("email", user.email)
            .withClaim("role", user.role.name)
            .withClaim("verified", user.emailVerified)
            .withClaim("nonce", nonce) // Add unique nonce for token uniqueness
            .withIssuedAt(Date(now.toEpochMilliseconds()))
            .withExpiresAt(Date(expiresAt.toEpochMilliseconds()))
            .sign(algorithm)
        
        val refreshNonce = UUID.randomUUID().toString() // Separate nonce for refresh token
        val refreshToken = JWT.create()
            .withIssuer(issuer)
            .withAudience("$audience-refresh")
            .withSubject(user.id.toString())
            .withClaim("userId", user.id.toString())
            .withClaim("familyId", familyId.toString())
            .withClaim("type", "refresh")
            .withClaim("nonce", refreshNonce) // Add unique nonce for refresh token uniqueness
            .withIssuedAt(Date(now.toEpochMilliseconds()))
            .withExpiresAt(Date(refreshExpiresAt.toEpochMilliseconds()))
            .sign(algorithm)
        
        return TokenPair(accessToken, refreshToken, expiresIn)
    }

    fun verifyToken(token: String): String? {
        return try {
            val jwt = JWT.require(algorithm)
                .withIssuer(issuer)
                .build()
                .verify(token)
            jwt.getClaim("userId").asString()
        } catch (e: Exception) {
            null
        }
    }

    fun verifyRefreshToken(token: String): String? {
        return try {
            val jwt = JWT.require(algorithm)
                .withIssuer(issuer)
                .withAudience("$audience-refresh")
                .build()
                .verify(token)
            
            if (jwt.getClaim("type").asString() == "refresh") {
                jwt.getClaim("userId").asString()
            } else null
        } catch (e: Exception) {
            null
        }
    }

    fun extractUserIdFromToken(token: String): String? {
        return try {
            val jwt = JWT.decode(token)
            jwt.getClaim("userId").asString()
        } catch (e: Exception) {
            null
        }
    }

    fun extractRoleFromToken(token: String): String? {
        return try {
            val jwt = JWT.decode(token)
            jwt.getClaim("role").asString()
        } catch (e: Exception) {
            null
        }
    }

    fun extractFamilyIdFromToken(token: String): String? {
        return try {
            val jwt = JWT.decode(token)
            jwt.getClaim("familyId").asString()
        } catch (e: Exception) {
            null
        }
    }
}