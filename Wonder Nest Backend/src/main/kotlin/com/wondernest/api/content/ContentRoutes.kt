package com.wondernest.api.content

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable

@Serializable
data class MessageResponse(val message: String)

@Serializable
data class ContentItem(
    val id: String,
    val title: String,
    val description: String,
    val category: String,
    val ageRating: Int,
    val duration: Int, // minutes
    val thumbnailUrl: String,
    val contentUrl: String,
    val tags: List<String>,
    val isEducational: Boolean,
    val difficulty: String, // "easy", "medium", "hard"
    val createdAt: String
)

@Serializable
data class ContentCategory(
    val id: String,
    val name: String,
    val description: String,
    val icon: String,
    val color: String,
    val minAge: Int,
    val maxAge: Int
)

@Serializable
data class ContentResponse(
    val items: List<ContentItem>,
    val totalItems: Int,
    val currentPage: Int,
    val totalPages: Int,
    val categories: List<ContentCategory>
)

fun Route.contentRoutes() {
    authenticate("auth-jwt") {
        route("/content") {
            // Get content library with filtering (Flutter calls this endpoint)
            get {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))

                    // Get query parameters
                    val category = call.request.queryParameters["category"]
                    val ageGroup = call.request.queryParameters["ageGroup"]?.toIntOrNull()
                    val page = call.request.queryParameters["page"]?.toIntOrNull() ?: 1
                    val limit = call.request.queryParameters["limit"]?.toIntOrNull() ?: 20

                    // TODO: PRODUCTION - Replace with real content from database
                    // Mock content data for development
                    val mockContent = generateMockContent(ageGroup, category)
                    val totalItems = mockContent.size
                    val startIndex = (page - 1) * limit
                    val endIndex = minOf(startIndex + limit, totalItems)
                    val paginatedContent = if (startIndex < totalItems) {
                        mockContent.subList(startIndex, endIndex)
                    } else {
                        emptyList()
                    }

                    val response = ContentResponse(
                        items = paginatedContent,
                        totalItems = totalItems,
                        currentPage = page,
                        totalPages = (totalItems + limit - 1) / limit,
                        categories = getMockCategories()
                    )

                    call.respond(HttpStatusCode.OK, response)
                    call.application.environment.log.info("Returned ${paginatedContent.size} content items for family: $familyId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error retrieving content", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to retrieve content"))
                }
            }

            // Legacy endpoint for backward compatibility
            get("/library") {
                call.respond(HttpStatusCode.OK, MessageResponse("Use /content instead of /content/library"))
            }
            
            get("/recommendations/{childId}") {
                try {
                    val childId = call.parameters["childId"] ?: return@get call.respond(
                        HttpStatusCode.BadRequest, MessageResponse("Child ID is required")
                    )

                    val principal = call.principal<JWTPrincipal>()
                    val familyId = principal?.payload?.getClaim("familyId")?.asString()
                        ?: return@get call.respond(HttpStatusCode.BadRequest, MessageResponse("No family context in token"))

                    // TODO: PRODUCTION - Implement personalized recommendations based on:
                    // - Child's age and interests
                    // - Previous content engagement
                    // - Educational goals
                    // - Content preferences
                    
                    // For now, return mock recommendations
                    val recommendations = generateMockRecommendations(childId)
                    
                    call.respond(HttpStatusCode.OK, mapOf(
                        "childId" to childId,
                        "recommendations" to recommendations,
                        "reason" to "Based on age-appropriate content and interests",
                        "generatedAt" to System.currentTimeMillis()
                    ))
                    
                    call.application.environment.log.info("Generated content recommendations for child: $childId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error generating content recommendations", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to generate recommendations"))
                }
            }
            
            post("/engagement") {
                try {
                    // TODO: PRODUCTION - Implement content engagement tracking
                    call.respond(HttpStatusCode.Created, MessageResponse("Content engagement tracked - TODO: Implement analytics"))
                } catch (e: Exception) {
                    call.application.environment.log.error("Error tracking content engagement", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to track engagement"))
                }
            }

            // Get specific content item
            get("/{contentId}") {
                try {
                    val contentId = call.parameters["contentId"] ?: return@get call.respond(
                        HttpStatusCode.BadRequest, MessageResponse("Content ID is required")
                    )

                    // TODO: PRODUCTION - Fetch from database and check family access permissions
                    val contentItem = findMockContentById(contentId)
                        ?: return@get call.respond(HttpStatusCode.NotFound, MessageResponse("Content not found"))

                    call.respond(HttpStatusCode.OK, contentItem)
                    call.application.environment.log.info("Retrieved content item: $contentId")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error retrieving content item", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to retrieve content"))
                }
            }
        }
        
        route("/categories") {
            get {
                try {
                    val categories = getMockCategories()
                    call.respond(HttpStatusCode.OK, mapOf("categories" to categories))
                    call.application.environment.log.info("Retrieved ${categories.size} content categories")
                } catch (e: Exception) {
                    call.application.environment.log.error("Error retrieving content categories", e)
                    call.respond(HttpStatusCode.InternalServerError, MessageResponse("Failed to retrieve categories"))
                }
            }
        }
    }
}

// TODO: PRODUCTION - Replace these mock functions with real database queries
private fun generateMockContent(ageGroup: Int?, category: String?): List<ContentItem> {
    val baseContent = listOf(
        ContentItem(
            id = "content_1",
            title = "Learning Colors with Animals",
            description = "Fun way to learn colors through animal friends",
            category = "educational",
            ageRating = 3,
            duration = 10,
            thumbnailUrl = "/thumbnails/colors_animals.jpg",
            contentUrl = "/content/colors_animals.mp4",
            tags = listOf("colors", "animals", "learning"),
            isEducational = true,
            difficulty = "easy",
            createdAt = "2024-01-15T10:00:00Z"
        ),
        ContentItem(
            id = "content_2", 
            title = "Adventure Island Stories",
            description = "Exciting adventures on a magical island",
            category = "stories",
            ageRating = 5,
            duration = 15,
            thumbnailUrl = "/thumbnails/adventure_island.jpg",
            contentUrl = "/content/adventure_island.mp4",
            tags = listOf("adventure", "story", "imagination"),
            isEducational = false,
            difficulty = "medium",
            createdAt = "2024-01-16T14:30:00Z"
        ),
        ContentItem(
            id = "content_3",
            title = "Math Puzzles for Kids",
            description = "Interactive math problems and puzzles",
            category = "educational",
            ageRating = 6,
            duration = 20,
            thumbnailUrl = "/thumbnails/math_puzzles.jpg",
            contentUrl = "/content/math_puzzles.mp4",
            tags = listOf("math", "puzzles", "problem-solving"),
            isEducational = true,
            difficulty = "medium",
            createdAt = "2024-01-17T09:15:00Z"
        )
    )

    return baseContent.filter { content ->
        (ageGroup == null || content.ageRating <= ageGroup + 2) &&
        (category == null || content.category == category)
    }
}

private fun generateMockRecommendations(childId: String): List<ContentItem> {
    // TODO: PRODUCTION - Implement actual recommendation algorithm
    return generateMockContent(null, null).take(5)
}

private fun getMockCategories(): List<ContentCategory> {
    return listOf(
        ContentCategory("educational", "Educational", "Learn while you play", "🎓", "#4CAF50", 3, 12),
        ContentCategory("stories", "Stories", "Amazing tales and adventures", "📚", "#FF9800", 4, 10),
        ContentCategory("music", "Music", "Songs and musical activities", "🎵", "#E91E63", 2, 8),
        ContentCategory("art", "Art & Craft", "Creative drawing and crafts", "🎨", "#9C27B0", 4, 12),
        ContentCategory("science", "Science", "Explore the world around us", "🔬", "#2196F3", 5, 12)
    )
}

private fun findMockContentById(contentId: String): ContentItem? {
    return generateMockContent(null, null).find { it.id == contentId }
}