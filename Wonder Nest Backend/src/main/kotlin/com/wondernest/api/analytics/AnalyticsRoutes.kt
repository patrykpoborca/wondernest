package com.wondernest.api.analytics

import com.wondernest.data.database.table.SimpleGameData
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.Json
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

// Database operations for game data storage

@Serializable
data class MessageResponse(val message: String)

@Serializable
data class DailyAnalytics(
    val date: String,
    val childId: String,
    val totalScreenTime: Int, // minutes
    val contentConsumed: Int,
    val educationalTime: Int, // minutes
    val averageSessionLength: Int, // minutes
    val mostEngagedCategory: String,
    val completedActivities: Int,
    val learningProgress: Double // 0.0 to 1.0
)

@Serializable
data class ChildInsights(
    val childId: String,
    val preferredLearningStyle: String,
    val strongSubjects: List<String>,
    val improvementAreas: List<String>,
    val recommendedActivities: List<String>,
    val parentalGuidance: List<String>
)

@Serializable
data class AnalyticsEvent(
    val eventType: String,
    val childId: String,
    val contentId: String? = null,
    val duration: Int? = null,
    val eventData: Map<String, kotlinx.serialization.json.JsonElement> = emptyMap(),
    val sessionId: String? = null
)

@Serializable
data class WeeklyOverview(
    val weekStart: String,
    val totalScreenTime: Int,
    val educationalPercentage: Double,
    val averageDailyUsage: Int,
    val topCategories: List<String>,
    val completionRate: Double,
    val parentalInteraction: Int
)

fun Route.analyticsRoutes() {
    authenticate("auth-jwt") {
        route("/analytics") {
            // Daily analytics for a specific child (Flutter expects this)
            get("/daily") {
                try {
                    val childId = call.request.queryParameters["childId"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("Child ID is required"))

                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))

                    // TODO: PRODUCTION - Fetch real analytics from database
                    val mockAnalytics = generateMockDailyAnalytics(childId)
                    
                    call.respond(HttpStatusCode.OK, mockAnalytics)
                    call.application.environment.log.info("Generated daily analytics for child: $childId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error generating daily analytics", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to generate analytics"))
                }
            }

            // Legacy endpoint  
            get("/children/{childId}/daily") {
                call.respond(HttpStatusCode.OK, MessageResponse("Use /analytics/daily?childId={childId} instead"))
            }
            
            get("/children/{childId}/insights") {
                try {
                    val childId = call.parameters["childId"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("Child ID is required"))

                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))

                    // TODO: PRODUCTION - Generate real insights based on child's learning patterns
                    val mockInsights = generateMockChildInsights(childId)
                    
                    call.respond(HttpStatusCode.OK, mockInsights)
                    call.application.environment.log.info("Generated insights for child: $childId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error generating child insights", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to generate insights"))
                }
            }

            // Weekly overview for parent dashboard
            get("/weekly") {
                try {
                    val childId = call.request.queryParameters["childId"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("Child ID is required"))

                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))

                    // TODO: PRODUCTION - Calculate real weekly overview
                    val mockWeekly = generateMockWeeklyOverview(childId)
                    
                    call.respond(HttpStatusCode.OK, mockWeekly)
                    call.application.environment.log.info("Generated weekly overview for child: $childId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error generating weekly overview", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to generate weekly overview"))
                }
            }
            
            get("/children/{childId}/milestones") {
                try {
                    val childId = call.parameters["childId"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("Child ID is required"))

                    // TODO: PRODUCTION - Track and return actual developmental milestones
                    val mockMilestones = mapOf(
                        "age" to 6,
                        "milestones" to listOf(
                            mapOf("category" to "math", "description" to "Can count to 100", "achieved" to true),
                            mapOf("category" to "reading", "description" to "Recognizes sight words", "achieved" to true),
                            mapOf("category" to "social", "description" to "Shares and takes turns", "achieved" to false)
                        ),
                        "nextGoals" to listOf(
                            "Practice addition with objects",
                            "Read simple sentences",
                            "Practice conflict resolution"
                        )
                    )
                    
                    call.respond(HttpStatusCode.OK, mockMilestones)
                    call.application.environment.log.info("Generated milestones for child: $childId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error generating milestones", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to generate milestones"))
                }
            }
            
            // Get analytics events for a child - for game data retrieval
            get("/children/{childId}/events") {
                try {
                    val childIdParam = call.parameters["childId"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("Child ID is required"))

                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))

                    call.application.environment.log.info("Loading game data for child: $childIdParam")
                    
                    val childId = UUID.fromString(childIdParam)
                    
                    // Get stored game data for this child from database
                    val gameDataList = transaction {
                        SimpleGameData.selectAll()
                            .where { SimpleGameData.childId eq childId }
                            .map { row ->
                                val dataValueMap = row[SimpleGameData.dataValue]
                                // Convert the JsonElement map back to a JSON string
                                val dataValueJson = Json.encodeToString(dataValueMap)
                                mapOf(
                                    "dataKey" to row[SimpleGameData.dataKey],
                                    "dataValue" to dataValueJson
                                )
                            }
                    }
                    
                    val response = mapOf(
                        "data" to mapOf(
                            "gameData" to gameDataList
                        )
                    )
                    
                    call.respond(HttpStatusCode.OK, response)
                    call.application.environment.log.info("Loaded ${gameDataList.size} projects from backend")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error retrieving analytics events", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to retrieve events"))
                }
            }
            
            post("/events") {
                call.application.environment.log.info("=== ANALYTICS EVENT POST REQUEST START ===")
                
                try {
                    call.application.environment.log.info("Receiving analytics event...")
                    
                    // Log raw request body for debugging
                    val rawBody = call.receiveText()
                    call.application.environment.log.info("Raw request body: $rawBody")
                    call.application.environment.log.info("Raw body length: ${rawBody.length} characters")
                    
                    // Parse the JSON manually to get better error information
                    val event = try {
                        kotlinx.serialization.json.Json.decodeFromString<AnalyticsEvent>(rawBody)
                    } catch (jsonException: Exception) {
                        call.application.environment.log.error("JSON deserialization failed: ${jsonException.message}", jsonException)
                        call.application.environment.log.error("Failed to parse JSON: $rawBody")
                        return@post call.respond(
                            HttpStatusCode.BadRequest, 
                            MessageResponse("Invalid JSON format: ${jsonException.message}")
                        )
                    }
                    
                    call.application.environment.log.info("Successfully parsed AnalyticsEvent:")
                    call.application.environment.log.info("  eventType: '${event.eventType}' (${event.eventType.javaClass.simpleName})")
                    call.application.environment.log.info("  childId: '${event.childId}' (${event.childId.javaClass.simpleName})")
                    call.application.environment.log.info("  contentId: '${event.contentId}' (${event.contentId?.javaClass?.simpleName})")
                    call.application.environment.log.info("  duration: ${event.duration} (${event.duration?.javaClass?.simpleName})")
                    call.application.environment.log.info("  sessionId: '${event.sessionId}' (${event.sessionId?.javaClass?.simpleName})")
                    call.application.environment.log.info("  eventData keys: ${event.eventData.keys}")
                    call.application.environment.log.info("  eventData size: ${event.eventData.size}")
                    
                    // Log each eventData field with type information
                    event.eventData.forEach { (key, value) ->
                        call.application.environment.log.info("    eventData['$key']: $value (${value.javaClass.simpleName})")
                    }
                    
                    // Basic validation
                    if (event.eventType.isBlank()) {
                        call.application.environment.log.warn("Event type is blank")
                        return@post call.respond(HttpStatusCode.BadRequest, MessageResponse("Event type is required"))
                    }
                    
                    if (event.childId.isBlank()) {
                        call.application.environment.log.warn("Child ID is blank")
                        return@post call.respond(HttpStatusCode.BadRequest, MessageResponse("Child ID is required"))
                    }

                    call.application.environment.log.info("Validating JWT token...")
                    val principal = call.principal<JWTPrincipal>()
                    if (principal == null) {
                        call.application.environment.log.warn("No JWT principal found")
                        return@post call.respond(HttpStatusCode.Unauthorized, MessageResponse("No authentication token"))
                    }
                    
                    val familyId = principal.payload?.getClaim("familyId")?.asString()
                    call.application.environment.log.info("Family ID from token: '$familyId'")
                    
                    if (familyId == null) {
                        call.application.environment.log.warn("No family context in JWT token")
                        return@post call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))
                    }

                    call.application.environment.log.info("All validation passed, processing event...")
                    
                    // Special handling for sticker book project saves
                    call.application.environment.log.info("🎯 CHECKING EVENT TYPE: eventType='${event.eventType}', gameType='${event.eventData["gameType"]}'")
                    
                    if (event.eventType == "save_project" && event.eventData["gameType"]?.toString() == "sticker_book") {
                        call.application.environment.log.info("🎨 ===== STICKER BOOK SAVE DETECTED =====")
                        call.application.environment.log.info("🎨 Project save event for child: ${event.childId}")
                        
                        val projectId = event.eventData["projectId"]?.toString()
                        val fullProjectData = event.eventData["fullProjectData"]?.toString()
                        
                        call.application.environment.log.info("🎨 Project ID: $projectId")
                        call.application.environment.log.info("🎨 Full project data length: ${fullProjectData?.length ?: 0} characters")
                        
                        if (projectId != null && fullProjectData != null) {
                            call.application.environment.log.info("🎨 Both projectId and fullProjectData are present - proceeding with save")
                            val childId = UUID.fromString(event.childId)
                            val dataKey = "sticker_project_$projectId"
                            
                            // Parse and validate the JSON data
                            val projectDataMap: Map<String, kotlinx.serialization.json.JsonElement> = try {
                                // Parse the JSON string to ensure it's valid
                                Json.decodeFromString<Map<String, kotlinx.serialization.json.JsonElement>>(fullProjectData)
                            } catch (e: Exception) {
                                call.application.environment.log.error("Failed to parse project data JSON: $e")
                                call.application.environment.log.error("Project data that failed to parse: ${fullProjectData.take(500)}...")
                                // Create an error map with JsonElement values
                                mapOf(
                                    "error" to kotlinx.serialization.json.JsonPrimitive("parse_error"),
                                    "message" to kotlinx.serialization.json.JsonPrimitive(e.message ?: "Unknown error"),
                                    "timestamp" to kotlinx.serialization.json.JsonPrimitive(Clock.System.now().toString())
                                )
                            }
                            
                            // Store the full project data in database
                            call.application.environment.log.info("🎨 Starting database transaction for child: $childId, dataKey: $dataKey")
                            
                            try {
                                transaction {
                                    call.application.environment.log.info("🎨 Checking for existing project...")
                                    val existingCount = SimpleGameData.selectAll()
                                        .where { 
                                            (SimpleGameData.childId eq childId) and
                                            (SimpleGameData.gameType eq "sticker_book") and
                                            (SimpleGameData.dataKey eq dataKey)
                                        }.count()
                                    
                                    call.application.environment.log.info("🎨 Found $existingCount existing projects with this key")
                                    
                                    if (existingCount > 0) {
                                        call.application.environment.log.info("🎨 Updating existing project...")
                                        // Update existing project
                                        val updatedRows = SimpleGameData.update({
                                            (SimpleGameData.childId eq childId) and
                                            (SimpleGameData.gameType eq "sticker_book") and
                                            (SimpleGameData.dataKey eq dataKey)
                                        }) {
                                            it[dataValue] = projectDataMap
                                            it[updatedAt] = Clock.System.now()
                                        }
                                        call.application.environment.log.info("🎨 ✅ UPDATED sticker project: $projectId for child: ${event.childId} ($updatedRows rows)")
                                    } else {
                                        call.application.environment.log.info("🎨 Inserting new project...")
                                        // Insert new project
                                        SimpleGameData.insert {
                                            it[SimpleGameData.childId] = childId
                                            it[gameType] = "sticker_book"
                                            it[SimpleGameData.dataKey] = dataKey
                                            it[dataValue] = projectDataMap
                                            it[createdAt] = Clock.System.now()
                                            it[updatedAt] = Clock.System.now()
                                        }
                                        call.application.environment.log.info("🎨 ✅ INSERTED new sticker project: $projectId for child: ${event.childId}")
                                    }
                                    
                                    // Get total count for logging
                                    val totalCount = SimpleGameData.selectAll()
                                        .where { 
                                            (SimpleGameData.childId eq childId) and
                                            (SimpleGameData.gameType eq "sticker_book")
                                        }.count()
                                    call.application.environment.log.info("🎨 📊 Total projects for child ${event.childId}: $totalCount")
                                }
                                call.application.environment.log.info("🎨 ✅ DATABASE TRANSACTION COMPLETED SUCCESSFULLY")
                            } catch (dbException: Exception) {
                                call.application.environment.log.error("🎨 ❌ DATABASE TRANSACTION FAILED: ${dbException.message}", dbException)
                                throw dbException
                            }
                        } else {
                            call.application.environment.log.warn("Missing project ID or full project data in save_project event")
                        }
                    }
                    
                    // Handle project deletions
                    if (event.eventType == "delete_project" && event.eventData["gameType"]?.toString() == "sticker_book") {
                        call.application.environment.log.info("Detected sticker book project delete event")
                        
                        val projectId = event.eventData["projectId"]?.toString()
                        if (projectId != null) {
                            val childId = UUID.fromString(event.childId)
                            val dataKey = "sticker_project_$projectId"
                            
                            transaction {
                                val deletedCount = SimpleGameData.deleteWhere {
                                    (SimpleGameData.childId eq childId) and
                                    (SimpleGameData.gameType eq "sticker_book") and
                                    (SimpleGameData.dataKey eq dataKey)
                                }
                                
                                if (deletedCount > 0) {
                                    call.application.environment.log.info("Deleted sticker project: $projectId for child: ${event.childId}")
                                    
                                    // Get remaining count for logging
                                    val remainingCount = SimpleGameData.selectAll()
                                        .where { 
                                            (SimpleGameData.childId eq childId) and
                                            (SimpleGameData.gameType eq "sticker_book")
                                        }.count()
                                    call.application.environment.log.info("Remaining projects for child ${event.childId}: $remainingCount")
                                } else {
                                    call.application.environment.log.warn("Project not found for deletion: $projectId for child: ${event.childId}")
                                }
                            }
                        }
                    }
                    
                    // TODO: PRODUCTION - Store event in analytics database
                    // This would include events like:
                    // - content_started, content_completed, content_paused
                    // - activity_started, activity_completed
                    // - milestone_achieved, struggle_detected
                    // - parent_intervention_needed
                    
                    val eventId = "event_${System.currentTimeMillis()}"
                    val timestamp = System.currentTimeMillis().toString()
                    
                    val response = mapOf(
                        "message" to "Analytics event tracked successfully",
                        "eventId" to eventId,
                        "timestamp" to timestamp
                    )
                    
                    call.application.environment.log.info("Sending success response: $response")
                    call.respond(HttpStatusCode.Created, response)
                    
                    call.application.environment.log.info("Successfully tracked analytics event: ${event.eventType} for child: ${event.childId}")
                    call.application.environment.log.info("=== ANALYTICS EVENT POST REQUEST SUCCESS ===")
                    
                } catch (e: Exception) {
                    call.application.environment.log.error("=== ANALYTICS EVENT POST REQUEST ERROR ===")
                    call.application.environment.log.error("Exception type: ${e.javaClass.simpleName}")
                    call.application.environment.log.error("Exception message: ${e.message}")
                    call.application.environment.log.error("Full exception:", e)
                    
                    // Print stack trace for debugging
                    val stackTrace = e.stackTrace.joinToString("\n") { "  at $it" }
                    call.application.environment.log.error("Stack trace:\n$stackTrace")
                    
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to track event: ${e.message}"))
                    call.application.environment.log.error("=== ANALYTICS EVENT POST REQUEST ERROR END ===")
                }
            }
        }
    }
}

// TODO: PRODUCTION - Replace these with real analytics calculations
private fun generateMockDailyAnalytics(childId: String): DailyAnalytics {
    return DailyAnalytics(
        date = "2024-08-14",
        childId = childId,
        totalScreenTime = 45,
        contentConsumed = 3,
        educationalTime = 30,
        averageSessionLength = 15,
        mostEngagedCategory = "educational",
        completedActivities = 2,
        learningProgress = 0.75
    )
}

private fun generateMockChildInsights(childId: String): ChildInsights {
    return ChildInsights(
        childId = childId,
        preferredLearningStyle = "Visual and Interactive",
        strongSubjects = listOf("Colors and Shapes", "Animals", "Numbers"),
        improvementAreas = listOf("Letter Recognition", "Fine Motor Skills"),
        recommendedActivities = listOf("Alphabet Tracing", "Animal Sound Matching", "Shape Sorting"),
        parentalGuidance = listOf(
            "Encourage more interactive reading sessions",
            "Practice writing letters together",
            "Use physical objects for counting exercises"
        )
    )
}

private fun generateMockWeeklyOverview(childId: String): WeeklyOverview {
    return WeeklyOverview(
        weekStart = "2024-08-11",
        totalScreenTime = 315, // minutes for the week
        educationalPercentage = 68.0,
        averageDailyUsage = 45,
        topCategories = listOf("educational", "stories", "music"),
        completionRate = 0.82,
        parentalInteraction = 12 // number of parent interactions
    )
}