package com.wondernest.api.family

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable

@Serializable
data class MessageResponse(val message: String)

fun Route.familyRoutes() {
    authenticate("auth-jwt") {
        route("/families") {
            get {
                call.respond(HttpStatusCode.OK, MessageResponse("Families endpoint - TODO"))
            }
            
            post {
                call.respond(HttpStatusCode.Created, MessageResponse("Create family - TODO"))
            }
        }
        
        route("/children") {
            get {
                call.respond(HttpStatusCode.OK, MessageResponse("Children profiles endpoint - TODO"))
            }
            
            post {
                call.respond(HttpStatusCode.Created, MessageResponse("Create child profile - TODO"))
            }
        }
    }
}