package com.wondernest.config

import com.wondernest.data.database.DatabaseFactory
import io.ktor.server.application.*
import org.koin.ktor.ext.inject

fun Application.configureDatabase() {
    val databaseFactory by inject<DatabaseFactory>()
    databaseFactory.init()
}