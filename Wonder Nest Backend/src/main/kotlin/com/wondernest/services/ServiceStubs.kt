package com.wondernest.services.notification

import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

class NotificationService {
    suspend fun sendPushNotification(userId: String, title: String, body: String): Boolean {
        logger.info { "Would send push notification to $userId: $title - $body" }
        return true
    }
}