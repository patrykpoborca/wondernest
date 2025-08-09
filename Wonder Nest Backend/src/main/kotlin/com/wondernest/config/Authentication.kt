package com.wondernest.config

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.wondernest.services.auth.JwtService
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import org.koin.ktor.ext.inject

fun Application.configureAuthentication() {
    val jwtService by inject<JwtService>()
    
    install(Authentication) {
        jwt("auth-jwt") {
            realm = jwtService.realm
            verifier(
                JWT
                    .require(Algorithm.HMAC256(jwtService.secret))
                    .withIssuer(jwtService.issuer)
                    .build()
            )
            validate { credential ->
                if (credential.payload.getClaim("userId").asString() != "") {
                    JWTPrincipal(credential.payload)
                } else {
                    null
                }
            }
        }
        
        jwt("admin-jwt") {
            realm = jwtService.realm
            verifier(
                JWT
                    .require(Algorithm.HMAC256(jwtService.secret))
                    .withIssuer(jwtService.issuer)
                    .build()
            )
            validate { credential ->
                val role = credential.payload.getClaim("role").asString()
                if (credential.payload.getClaim("userId").asString() != "" && role == "admin") {
                    JWTPrincipal(credential.payload)
                } else {
                    null
                }
            }
        }
    }
}