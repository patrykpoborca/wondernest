#!/usr/bin/env kotlin

@file:DependsOn("com.auth0:java-jwt:4.4.0")

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import java.util.*

// Generate a test JWT token with proper claims
val secret = "your-super-secret-jwt-key-change-this-in-production"
val issuer = "wondernest-api"
val audience = "wondernest-users"
val userId = "f04035ac-a2cf-418e-b119-e489dfcfcf15" // Use a valid UUID from your logs

val algorithm = Algorithm.HMAC256(secret)
val now = Date()
val expiresAt = Date(now.time + 3600000) // 1 hour from now

val token = JWT.create()
    .withIssuer(issuer)
    .withAudience(audience)
    .withSubject(userId)
    .withClaim("userId", userId)
    .withClaim("email", "test@example.com")
    .withClaim("role", "PARENT")
    .withClaim("verified", true)
    .withClaim("nonce", UUID.randomUUID().toString())
    .withIssuedAt(now)
    .withExpiresAt(expiresAt)
    .sign(algorithm)

println("Generated JWT Token:")
println(token)
println()
println("Test with:")
println("curl -X GET \"http://localhost:8080/api/v1/content-packs/categories\" \\")
println("  -H \"Authorization: Bearer $token\"")