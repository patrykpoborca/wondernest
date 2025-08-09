package com.wondernest.api.audio

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable

@Serializable
data class MessageResponse(val message: String)

fun Route.audioRoutes() {
    authenticate("auth-jwt") {
        route("/audio") {
            post("/sessions") {
                call.respond(HttpStatusCode.Created, MessageResponse("Create audio session - TODO"))
            }
            
            post("/sessions/{sessionId}/end") {
                call.respond(HttpStatusCode.OK, MessageResponse("End audio session - TODO"))
            }
            
            post("/metrics") {
                call.respond(HttpStatusCode.Created, MessageResponse("Upload audio metrics - TODO"))
            }
            
            get("/sessions/{sessionId}/status") {
                call.respond(HttpStatusCode.OK, MessageResponse("Audio session status - TODO"))
            }
        }
    }
}