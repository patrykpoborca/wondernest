package com.wondernest.api.family

import com.wondernest.services.family.FamilyService
import com.wondernest.services.family.CreateChildRequest
import com.wondernest.services.family.UpdateChildRequest
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.util.*

@Serializable
data class MessageResponse(val message: String)

@Serializable
data class ErrorResponse(val error: String, val message: String)

fun Route.familyRoutes() {
    val familyService by inject<FamilyService>()
    
    authenticate("auth-jwt") {
        // Family profile endpoint (Flutter expects this path)
        route("/family") {
            get("/profile") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, ErrorResponse("auth_error", "No family context in token"))

                    val familyProfile = familyService.getFamilyProfile(UUID.fromString(familyId))
                        ?: return@get call.respond(HttpStatusCode.NotFound, ErrorResponse("family_not_found", "Family not found"))

                    call.respond(HttpStatusCode.OK, mapOf(
                        "success" to true,
                        "data" to familyProfile
                    ))
                } catch (e: IllegalArgumentException) {
                    call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_family_id", e.message ?: "Invalid family ID"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Error retrieving family profile", e)
                    call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to retrieve family profile"))
                }
            }

            // Children management endpoints
            route("/children") {
                // Get all children for the family
                get {
                    try {
                        val principal = call.principal<JWTPrincipal>()
                        val familyId = principal?.payload?.getClaim("familyId")?.asString()
                            ?: return@get call.respond(HttpStatusCode.BadRequest, ErrorResponse("auth_error", "No family context in token"))

                        val children = familyService.getChildren(UUID.fromString(familyId))
                        call.respond(HttpStatusCode.OK, mapOf(
                            "success" to true,
                            "data" to children
                        ))
                    } catch (e: IllegalArgumentException) {
                        call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_family_id", e.message ?: "Invalid family ID"))
                    } catch (e: Exception) {
                        call.application.environment.log.error("Error retrieving children", e)
                        call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to retrieve children"))
                    }
                }

                // Create new child profile
                post {
                    try {
                        val principal = call.principal<JWTPrincipal>()
                        val familyId = principal?.payload?.getClaim("familyId")?.asString()
                            ?: return@post call.respond(HttpStatusCode.BadRequest, ErrorResponse("auth_error", "No family context in token"))

                        val request = call.receive<CreateChildRequest>()
                        
                        // Basic validation
                        if (request.name.isBlank()) {
                            return@post call.respond(HttpStatusCode.BadRequest, ErrorResponse("validation_error", "Child name is required"))
                        }

                        val childProfile = familyService.createChild(UUID.fromString(familyId), request)
                        call.respond(HttpStatusCode.Created, mapOf(
                            "success" to true,
                            "data" to childProfile
                        ))
                    } catch (e: IllegalArgumentException) {
                        call.respond(HttpStatusCode.BadRequest, ErrorResponse("validation_error", e.message ?: "Invalid input"))
                    } catch (e: Exception) {
                        call.application.environment.log.error("Error creating child profile", e)
                        call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to create child profile"))
                    }
                }

                // Child-specific operations
                route("/{childId}") {
                    // Get specific child profile
                    get {
                        try {
                            val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                                ?: return@get call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID"))

                            val childProfile = familyService.getChildProfile(childId)
                                ?: return@get call.respond(HttpStatusCode.NotFound, ErrorResponse("child_not_found", "Child profile not found"))

                            call.respond(HttpStatusCode.OK, mapOf(
                                "success" to true,
                                "data" to childProfile
                            ))
                        } catch (e: IllegalArgumentException) {
                            call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID format"))
                        } catch (e: Exception) {
                            call.application.environment.log.error("Error retrieving child profile", e)
                            call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to retrieve child profile"))
                        }
                    }

                    // Update child profile
                    put {
                        try {
                            val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                                ?: return@put call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID"))

                            val request = call.receive<UpdateChildRequest>()
                            val updatedProfile = familyService.updateChild(childId, request)
                                ?: return@put call.respond(HttpStatusCode.NotFound, ErrorResponse("child_not_found", "Child profile not found"))

                            call.respond(HttpStatusCode.OK, mapOf(
                                "success" to true,
                                "data" to updatedProfile
                            ))
                        } catch (e: IllegalArgumentException) {
                            call.respond(HttpStatusCode.BadRequest, ErrorResponse("validation_error", e.message ?: "Invalid input"))
                        } catch (e: Exception) {
                            call.application.environment.log.error("Error updating child profile", e)
                            call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to update child profile"))
                        }
                    }

                    // Delete/Archive child profile
                    delete {
                        try {
                            val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                                ?: return@delete call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID"))

                            val deleted = familyService.deleteChild(childId)
                            if (deleted) {
                                call.respond(HttpStatusCode.OK, MessageResponse("Child profile archived successfully"))
                            } else {
                                call.respond(HttpStatusCode.NotFound, ErrorResponse("child_not_found", "Child profile not found"))
                            }
                        } catch (e: IllegalArgumentException) {
                            call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID format"))
                        } catch (e: Exception) {
                            call.application.environment.log.error("Error deleting child profile", e)
                            call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to delete child profile"))
                        }
                    }

                    // Select active child (for child session management)
                    post("/select") {
                        try {
                            val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                                ?: return@post call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID"))

                            // Verify child exists and belongs to family
                            val childProfile = familyService.getChildProfile(childId)
                                ?: return@post call.respond(HttpStatusCode.NotFound, ErrorResponse("child_not_found", "Child profile not found"))

                            val principal = call.principal<JWTPrincipal>()
                            val familyId = principal?.payload?.getClaim("familyId")?.asString()
                                ?: return@post call.respond(HttpStatusCode.BadRequest, ErrorResponse("auth_error", "No family context in token"))

                            if (childProfile.familyId.toString() != familyId) {
                                return@post call.respond(HttpStatusCode.Forbidden, ErrorResponse("access_denied", "Child does not belong to your family"))
                            }

                            // TODO: Implement active child session management
                            // For now, just return success with child profile
                            call.respond(HttpStatusCode.OK, mapOf(
                                "message" to "Child selected successfully",
                                "activeChild" to childProfile,
                                "sessionToken" to "TODO_IMPLEMENT_CHILD_SESSION_TOKEN"
                            ))
                        } catch (e: IllegalArgumentException) {
                            call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_child_id", "Invalid child ID format"))
                        } catch (e: Exception) {
                            call.application.environment.log.error("Error selecting child", e)
                            call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to select child"))
                        }
                    }
                }
            }
        }

        // Direct children endpoints for Flutter compatibility
        route("/children") {
            // Get all children for the authenticated family (Flutter expects this path)
            get {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, ErrorResponse("auth_error", "No family context in token"))

                    val children = familyService.getChildren(UUID.fromString(familyId))
                    call.respond(HttpStatusCode.OK, mapOf(
                        "success" to true,
                        "data" to children
                    ))
                } catch (e: IllegalArgumentException) {
                    call.respond(HttpStatusCode.BadRequest, ErrorResponse("invalid_family_id", e.message ?: "Invalid family ID"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Error retrieving children", e)
                    call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to retrieve children"))
                }
            }

            // Create new child profile (Flutter expects this path)
            post {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@post call.respond(HttpStatusCode.BadRequest, ErrorResponse("auth_error", "No family context in token"))

                    val request = call.receive<CreateChildRequest>()
                    
                    // Basic validation
                    if (request.name.isBlank()) {
                        return@post call.respond(HttpStatusCode.BadRequest, ErrorResponse("validation_error", "Child name is required"))
                    }

                    val childProfile = familyService.createChild(UUID.fromString(familyId), request)
                    call.respond(HttpStatusCode.Created, mapOf(
                        "success" to true,
                        "data" to childProfile
                    ))
                } catch (e: IllegalArgumentException) {
                    call.respond(HttpStatusCode.BadRequest, ErrorResponse("validation_error", e.message ?: "Invalid input"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Error creating child profile", e)
                    call.respond(HttpStatusCode.InternalServerError, ErrorResponse("server_error", "Failed to create child profile"))
                }
            }
        }
        
        // Legacy endpoints for backward compatibility
        route("/families") {
            get {
                call.respond(HttpStatusCode.OK, MessageResponse("Use /family/profile instead"))
            }
        }
    }
}