package com.wondernest.api.analytics

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.Json

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