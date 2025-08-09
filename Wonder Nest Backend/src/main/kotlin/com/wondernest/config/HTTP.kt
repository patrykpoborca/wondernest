package com.wondernest.config

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.cachingheaders.*
import io.ktor.server.plugins.compression.*
import io.ktor.server.plugins.conditionalheaders.*
import io.ktor.server.plugins.cors.routing.*
import io.ktor.server.plugins.defaultheaders.*
import io.ktor.server.plugins.forwardedheaders.*

fun Application.configureHTTP() {
    install(CORS) {
        allowMethod(HttpMethod.Options)
        allowMethod(HttpMethod.Put)
        allowMethod(HttpMethod.Delete)
        allowMethod(HttpMethod.Patch)
        allowHeader(HttpHeaders.Authorization)
        allowHeader(HttpHeaders.ContentType)
        allowHeader("X-Requested-With")
        
        // Allow specific origins in production
        val allowedOrigins = this@configureHTTP.environment.config.propertyOrNull("cors.allowed_origins")?.getString()?.split(",") ?: listOf("*")
        if (allowedOrigins.contains("*")) {
            anyHost()
        } else {
            allowedOrigins.forEach { origin ->
                val trimmedOrigin = origin.trim()
                // Parse the origin to extract host and port
                if (trimmedOrigin.startsWith("http://") || trimmedOrigin.startsWith("https://")) {
                    val url = Url(trimmedOrigin)
                    if (url.port != DEFAULT_PORT) {
                        allowHost(url.host, listOf(url.protocol.name), listOf(url.port.toString()))
                    } else {
                        allowHost(url.host, listOf(url.protocol.name))
                    }
                } else {
                    // Fallback for simple hostnames
                    allowHost(trimmedOrigin)
                }
            }
        }
        
        allowCredentials = true
        maxAgeInSeconds = 86400 // 24 hours
    }

    install(Compression) {
        gzip {
            priority = 1.0
        }
        deflate {
            priority = 10.0
            minimumSize(1024) // condition
        }
    }

    install(ConditionalHeaders)
    
    install(CachingHeaders)

    install(DefaultHeaders) {
        header("X-Engine", "Ktor") // will send this header with each response
    }

    install(ForwardedHeaders) // WARNING: for security, do not include this if not behind a reverse proxy
    install(XForwardedHeaders) // WARNING: for security, do not include this if not behind a reverse proxy
}