package com.wondernest

import com.wondernest.config.configureAuthentication
import com.wondernest.config.configureDatabase
import com.wondernest.config.configureDependencyInjection
import com.wondernest.config.configureHTTP
import com.wondernest.config.configureMonitoring
import com.wondernest.config.configureRouting
import com.wondernest.config.configureSecurity
import com.wondernest.config.configureSerialization
import io.ktor.server.application.*

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    configureDependencyInjection()
    configureDatabase()
    configureSerialization()
    configureHTTP()
    configureSecurity()
    configureAuthentication()
    configureMonitoring()
    configureRouting()
}
