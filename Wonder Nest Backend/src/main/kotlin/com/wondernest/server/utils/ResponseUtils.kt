package com.wondernest.server.utils

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import kotlinx.serialization.Serializable

@Serializable
data class SuccessResponse<T>(
    val success: Boolean = true,
    val data: T
)

@Serializable
data class ErrorResponse(
    val success: Boolean = false,
    val error: ErrorDetails
)

@Serializable
data class ErrorDetails(
    val code: String,
    val message: String
)

/**
 * Responds with a successful response containing data
 */
suspend inline fun <reified T> ApplicationCall.respondSuccess(
    data: T,
    status: HttpStatusCode = HttpStatusCode.OK
) {
    respond(status, SuccessResponse(data = data))
}

/**
 * Responds with an error response
 */
suspend fun ApplicationCall.respondError(
    status: HttpStatusCode,
    message: String,
    code: String = status.value.toString()
) {
    respond(status, ErrorResponse(
        error = ErrorDetails(
            code = code,
            message = message
        )
    ))
}