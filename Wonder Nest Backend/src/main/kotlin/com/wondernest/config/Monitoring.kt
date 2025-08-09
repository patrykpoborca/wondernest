package com.wondernest.config

import io.ktor.server.application.*
import io.ktor.server.metrics.micrometer.*
import io.ktor.server.plugins.callid.*
import io.ktor.server.plugins.calllogging.*
import io.ktor.server.request.*
import io.micrometer.prometheus.PrometheusConfig
import io.micrometer.prometheus.PrometheusMeterRegistry
import org.slf4j.event.Level
import java.util.*

fun Application.configureMonitoring() {
    install(CallLogging) {
        level = Level.INFO
        filter { call -> call.request.path().startsWith("/") }
        callIdMdc("call-id")
    }
    
    install(CallId) {
        header(HttpHeaders.XRequestId)
        generate { UUID.randomUUID().toString() }
        verify { callId: String ->
            callId.isNotEmpty()
        }
    }
    
    val appMicrometerRegistry = PrometheusMeterRegistry(PrometheusConfig.DEFAULT)
    
    install(MicrometerMetrics) {
        registry = appMicrometerRegistry
        
        // Configure custom metrics
        timers { call, exception ->
            tag("path", call.request.path())
            tag("method", call.request.httpMethod.value)
            tag("status", call.response.status()?.value?.toString() ?: "unknown")
        }
    }
    
    // Store registry for use in routes
    environment.monitor.subscribe(ApplicationStarted) {
        it.attributes.put(MicrometerRegistryKey, appMicrometerRegistry)
    }
}

val MicrometerRegistryKey = AttributeKey<PrometheusMeterRegistry>("MicrometerRegistry")