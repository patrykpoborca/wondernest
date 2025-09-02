package com.wondernest.routes

import com.wondernest.models.*
import com.wondernest.services.ContentPackServiceSimple
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject
import java.util.UUID

fun Route.contentPackRoutes() {
    val contentPackService by inject<ContentPackServiceSimple>()

    route("/content-packs") {
        authenticate("auth-jwt") {
            // Get all categories
            get("/categories") {
                try {
                    call.application.environment.log.info("Content-packs: Getting categories")
                    val categories = contentPackService.getCategories()
                    call.application.environment.log.info("Content-packs: Retrieved ${categories.size} categories")
                    
                    val response = ContentPackResponse(
                        success = true,
                        data = CategoriesData(categories)
                    )
                    call.application.environment.log.info("Content-packs: About to respond with categories")
                    
                    call.respond(HttpStatusCode.OK, response)
                    call.application.environment.log.info("Content-packs: Categories response sent successfully")
                } catch (e: Exception) {
                    call.application.environment.log.error("Content-packs: Error getting categories", e)
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ContentPackResponse<CategoriesData>(
                            success = false,
                            error = "Failed to fetch categories: ${e.message}"
                        )
                    )
                }
            }

            // Search and browse packs
            get {
                try {
                    val userId = call.principal<JWTPrincipal>()?.payload?.getClaim("user_id")?.asString()
                        ?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")

                    val request = ContentPackSearchRequest(
                        query = call.request.queryParameters["query"],
                        category = call.request.queryParameters["category"],
                        packType = call.request.queryParameters["packType"],
                        ageMin = call.request.queryParameters["ageMin"]?.toIntOrNull(),
                        ageMax = call.request.queryParameters["ageMax"]?.toIntOrNull(),
                        priceMin = call.request.queryParameters["priceMin"]?.toIntOrNull(),
                        priceMax = call.request.queryParameters["priceMax"]?.toIntOrNull(),
                        isFree = call.request.queryParameters["isFree"]?.toBooleanStrictOrNull(),
                        educationalGoals = call.request.queryParameters.getAll("educationalGoals") ?: emptyList(),
                        sortBy = call.request.queryParameters["sortBy"] ?: "popularity",
                        sortOrder = call.request.queryParameters["sortOrder"] ?: "desc",
                        page = call.request.queryParameters["page"]?.toIntOrNull() ?: 0,
                        size = call.request.queryParameters["size"]?.toIntOrNull() ?: 20
                    )

                    val response = contentPackService.searchPacks(request, userId)
                    call.respond(
                        HttpStatusCode.OK,
                        ContentPackResponse(
                            success = true,
                            data = response
                        )
                    )
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<ContentPackSearchResponse>(
                            success = false,
                            error = "Search failed: ${e.message}"
                        )
                    )
                }
            }

            // Get featured packs
            get("/featured") {
                try {
                    call.application.environment.log.info("Content-packs: Getting featured packs")
                    
                    val principal = call.principal<JWTPrincipal>()
                    call.application.environment.log.info("Content-packs: JWT Principal: ${principal != null}")
                    
                    val userIdClaim = principal?.payload?.getClaim("userId")?.asString()
                    call.application.environment.log.info("Content-packs: User ID claim: $userIdClaim")
                    
                    val userId = userIdClaim?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")
                    
                    call.application.environment.log.info("Content-packs: Parsed User ID: $userId")

                    val limit = call.request.queryParameters["limit"]?.toIntOrNull() ?: 10
                    call.application.environment.log.info("Content-packs: Limit: $limit")
                    
                    val packs = contentPackService.getFeaturedPacks(userId, limit)
                    call.application.environment.log.info("Content-packs: Retrieved ${packs.size} featured packs")
                    
                    val response = ContentPackResponse(
                        success = true,
                        data = PacksData(packs)
                    )
                    call.application.environment.log.info("Content-packs: About to respond with featured packs")
                    
                    call.respond(HttpStatusCode.OK, response)
                    call.application.environment.log.info("Content-packs: Featured packs response sent successfully")
                } catch (e: Exception) {
                    call.application.environment.log.error("Content-packs: Error getting featured packs", e)
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ContentPackResponse<PacksData>(
                            success = false,
                            error = "Failed to fetch featured packs: ${e.message}"
                        )
                    )
                }
            }

            // Get user's owned packs
            get("/owned") {
                try {
                    call.application.environment.log.info("Content-packs: Getting owned packs")
                    
                    val principal = call.principal<JWTPrincipal>()
                    call.application.environment.log.info("Content-packs: JWT Principal: ${principal != null}")
                    
                    val userIdClaim = principal?.payload?.getClaim("userId")?.asString()
                    call.application.environment.log.info("Content-packs: User ID claim: $userIdClaim")
                    
                    val userId = userIdClaim?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")
                    
                    call.application.environment.log.info("Content-packs: Parsed User ID: $userId")

                    val childIdParam = call.request.queryParameters["childId"]
                    call.application.environment.log.info("Content-packs: Child ID param: $childIdParam")
                    
                    val childId = childIdParam?.let { UUID.fromString(it) }
                    call.application.environment.log.info("Content-packs: Parsed Child ID: $childId")
                    
                    val packs = contentPackService.getUserOwnedPacks(userId, childId)
                    call.application.environment.log.info("Content-packs: Retrieved ${packs.size} owned packs")
                    
                    val response = ContentPackResponse(
                        success = true,
                        data = PacksData(packs)
                    )
                    call.application.environment.log.info("Content-packs: About to respond with owned packs")
                    
                    call.respond(HttpStatusCode.OK, response)
                    call.application.environment.log.info("Content-packs: Owned packs response sent successfully")
                } catch (e: Exception) {
                    call.application.environment.log.error("Content-packs: Error getting owned packs", e)
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<PacksData>(
                            success = false,
                            error = "Failed to fetch owned packs: ${e.message}"
                        )
                    )
                }
            }

            // Get specific pack details
            get("/{packId}") {
                try {
                    val userId = call.principal<JWTPrincipal>()?.payload?.getClaim("user_id")?.asString()
                        ?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")

                    val packId = call.parameters["packId"]?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("Invalid pack ID")

                    val pack = contentPackService.getPackById(packId, userId)
                        ?: return@get call.respond(
                            HttpStatusCode.NotFound,
                            ContentPackResponse<PackData>(
                                success = false,
                                error = "Pack not found"
                            )
                        )

                    call.respond(
                        HttpStatusCode.OK,
                        ContentPackResponse(
                            success = true,
                            data = PackData(pack)
                        )
                    )
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<PackData>(
                            success = false,
                            error = "Failed to fetch pack: ${e.message}"
                        )
                    )
                }
            }

            // Purchase/acquire a pack
            post("/purchase") {
                try {
                    val userId = call.principal<JWTPrincipal>()?.payload?.getClaim("user_id")?.asString()
                        ?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")

                    val request = call.receive<PackPurchaseRequest>()
                    val response = contentPackService.purchasePack(userId, request)

                    if (response.success) {
                        call.respond(
                            HttpStatusCode.OK,
                            ContentPackResponse(
                                success = true,
                                data = response
                            )
                        )
                    } else {
                        call.respond(
                            HttpStatusCode.BadRequest,
                            ContentPackResponse<PackPurchaseResponse>(
                                success = false,
                                error = response.error
                            )
                        )
                    }
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<PackPurchaseResponse>(
                            success = false,
                            error = "Purchase failed: ${e.message}"
                        )
                    )
                }
            }

            // Update download status
            patch("/{packId}/download") {
                try {
                    val userId = call.principal<JWTPrincipal>()?.payload?.getClaim("user_id")?.asString()
                        ?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")

                    val packId = call.parameters["packId"]?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("Invalid pack ID")

                    val body = call.receive<Map<String, Any>>()
                    val status = body["status"] as? String
                        ?: throw IllegalArgumentException("Status is required")
                    val progress = (body["progress"] as? Number)?.toInt() ?: 0
                    val childId = (body["childId"] as? String)?.let { UUID.fromString(it) }

                    val success = contentPackService.updateDownloadStatus(
                        userId = userId,
                        packId = packId,
                        childId = childId,
                        status = status,
                        progress = progress
                    )

                    if (success) {
                        call.respond(
                            HttpStatusCode.OK,
                            ContentPackResponse(
                                success = true,
                                data = MessageData("Download status updated")
                            )
                        )
                    } else {
                        call.respond(
                            HttpStatusCode.NotFound,
                            ContentPackResponse<MessageData>(
                                success = false,
                                error = "Pack ownership not found"
                            )
                        )
                    }
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<MessageData>(
                            success = false,
                            error = "Failed to update download status: ${e.message}"
                        )
                    )
                }
            }

            // Get pack assets (for owned packs)
            get("/{packId}/assets") {
                try {
                    val userId = call.principal<JWTPrincipal>()?.payload?.getClaim("user_id")?.asString()
                        ?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")

                    val packId = call.parameters["packId"]?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("Invalid pack ID")

                    val childId = call.request.queryParameters["childId"]?.let { UUID.fromString(it) }

                    val assets = contentPackService.getPackAssets(packId, userId, childId)
                        ?: return@get call.respond(
                            HttpStatusCode.Forbidden,
                            ContentPackResponse<AssetsData>(
                                success = false,
                                error = "Pack not owned or not found"
                            )
                        )

                    call.respond(
                        HttpStatusCode.OK,
                        ContentPackResponse(
                            success = true,
                            data = AssetsData(assets)
                        )
                    )
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<AssetsData>(
                            success = false,
                            error = "Failed to fetch assets: ${e.message}"
                        )
                    )
                }
            }

            // Record pack usage
            post("/usage") {
                try {
                    val userId = call.principal<JWTPrincipal>()?.payload?.getClaim("user_id")?.asString()
                        ?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("User ID not found in token")

                    val body = call.receive<Map<String, Any>>()
                    val packId = (body["packId"] as? String)?.let { UUID.fromString(it) }
                        ?: throw IllegalArgumentException("Pack ID is required")
                    val usedInFeature = body["usedInFeature"] as? String
                        ?: throw IllegalArgumentException("Feature is required")
                    
                    val childId = (body["childId"] as? String)?.let { UUID.fromString(it) }
                    val assetId = (body["assetId"] as? String)?.let { UUID.fromString(it) }
                    val sessionId = (body["sessionId"] as? String)?.let { UUID.fromString(it) }
                    val usageDurationSeconds = (body["usageDurationSeconds"] as? Number)?.toInt()
                    val metadata = body["metadata"] as? Map<String, Any>

                    contentPackService.recordPackUsage(
                        userId = userId,
                        packId = packId,
                        childId = childId,
                        assetId = assetId,
                        usedInFeature = usedInFeature,
                        sessionId = sessionId,
                        usageDurationSeconds = usageDurationSeconds,
                        metadata = metadata
                    )

                    call.respond(
                        HttpStatusCode.OK,
                        ContentPackResponse(
                            success = true,
                            data = MessageData("Usage recorded")
                        )
                    )
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ContentPackResponse<MessageData>(
                            success = false,
                            error = "Failed to record usage: ${e.message}"
                        )
                    )
                }
            }
        }
    }
}