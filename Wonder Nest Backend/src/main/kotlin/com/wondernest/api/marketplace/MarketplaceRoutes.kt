package com.wondernest.api.marketplace

import com.wondernest.api.extractUser
import com.wondernest.domain.repository.FamilyRepository
import com.wondernest.services.marketplace.MarketplaceService
import com.wondernest.services.marketplace.CreatorService
import com.wondernest.services.marketplace.SearchRequest
import com.wondernest.services.marketplace.ContentType
import com.wondernest.services.marketplace.SortOption
import com.wondernest.services.marketplace.LicensingModel
import com.wondernest.services.marketplace.CreatorRegistrationRequest
import com.wondernest.services.marketplace.PublishContentRequest
import com.wondernest.services.marketplace.CreatorProfileUpdate
import com.wondernest.services.marketplace.TimeRange
import com.wondernest.services.marketplace.SearchFacets
import com.wondernest.services.marketplace.ContentCategory
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import mu.KotlinLogging
import org.koin.ktor.ext.inject
import java.math.BigDecimal
import java.util.*

private val logger = KotlinLogging.logger {}

fun Route.marketplaceRoutes() {
    val marketplaceService by inject<MarketplaceService>()
    val creatorService by inject<CreatorService>()
    val familyRepository by inject<FamilyRepository>()
    
    route("/api/v2/marketplace") {
        
        // Public endpoints (no auth required)
        
        // Browse and search marketplace
        post("/search") {
            try {
                val request = call.receive<MarketplaceSearchRequest>()
                logger.info { "Marketplace search: ${request.query}" }
                
                val searchRequest = SearchRequest(
                    query = request.query,
                    contentTypes = request.contentTypes?.mapNotNull { 
                        try {
                            ContentType.valueOf(it.uppercase())
                        } catch (e: IllegalArgumentException) {
                            null
                        }
                    } ?: emptyList(),
                    ageRanges = request.ageRanges ?: emptyList(),
                    minPrice = request.minPrice?.let { BigDecimal(it) },
                    maxPrice = request.maxPrice?.let { BigDecimal(it) },
                    tags = request.tags ?: emptyList(),
                    creatorId = request.creatorId,
                    sortBy = request.sortBy?.let { 
                        SortOption.valueOf(it.uppercase()) 
                    } ?: SortOption.RELEVANCE,
                    page = request.page ?: 0,
                    pageSize = request.pageSize ?: 20
                )
                
                val result = marketplaceService.searchContent(searchRequest)
                
                call.respond(HttpStatusCode.OK, MarketplaceSearchResponse(
                    items = result.items,
                    totalCount = result.totalCount,
                    page = result.page,
                    pageSize = result.pageSize,
                    facets = result.facets
                ))
                
            } catch (e: Exception) {
                logger.error(e) { "Error searching marketplace" }
                call.respond(HttpStatusCode.InternalServerError, 
                    ErrorResponse("Search failed: ${e.message}"))
            }
        }
        
        // Get featured content
        get("/featured") {
            try {
                val featured = marketplaceService.getFeaturedContent()
                
                call.respond(HttpStatusCode.OK, featured)
                
            } catch (e: Exception) {
                logger.error(e) { "Error getting featured content" }
                call.respond(HttpStatusCode.InternalServerError, 
                    ErrorResponse("Failed to get featured content"))
            }
        }
        
        // Get item details
        get("/items/{itemId}") {
            try {
                val itemId = call.parameters["itemId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, 
                        ErrorResponse("Invalid item ID"))
                
                val details = marketplaceService.getItemDetails(itemId)
                
                if (details != null) {
                    call.respond(HttpStatusCode.OK, details)
                } else {
                    call.respond(HttpStatusCode.NotFound, 
                        ErrorResponse("Item not found"))
                }
                
            } catch (e: Exception) {
                logger.error(e) { "Error getting item details" }
                call.respond(HttpStatusCode.InternalServerError, 
                    ErrorResponse("Failed to get item details"))
            }
        }
        
        // Authenticated endpoints
        authenticate("auth-jwt") {
            
            // Purchase an item
            post("/purchase") {
                try {
                    val user = call.extractUser()
                    val request = call.receive<PurchaseRequest>()
                    
                    // Get user's family ID
                    val family = familyRepository.getFamilyByUserId(user.id)
                    val familyId = family?.id 
                        ?: throw IllegalStateException("User must belong to a family to make purchases")
                    
                    val result = marketplaceService.purchaseItem(
                        userId = user.id,
                        familyId = familyId,
                        itemId = request.itemId,
                        paymentMethod = request.paymentMethod
                    )
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, PurchaseResponse(
                            success = true,
                            purchaseId = result.purchaseId,
                            transactionId = result.transactionId,
                            message = result.message
                        ))
                    } else {
                        call.respond(HttpStatusCode.BadRequest, 
                            ErrorResponse(result.message))
                    }
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error processing purchase" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Purchase failed"))
                }
            }
            
            // Get user's purchase history
            get("/purchases") {
                try {
                    val user = call.extractUser()
                    val page = call.request.queryParameters["page"]?.toIntOrNull() ?: 0
                    val pageSize = call.request.queryParameters["pageSize"]?.toIntOrNull() ?: 20
                    
                    val history = marketplaceService.getUserPurchases(user.id, page, pageSize)
                    
                    call.respond(HttpStatusCode.OK, history)
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error getting purchase history" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Failed to get purchase history"))
                }
            }
            
            // Submit a review
            post("/reviews") {
                try {
                    val user = call.extractUser()
                    val request = call.receive<ReviewRequest>()
                    
                    val result = marketplaceService.submitReview(
                        userId = user.id,
                        itemId = request.itemId,
                        rating = request.rating,
                        review = request.review
                    )
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, 
                            ErrorResponse(result.message))
                    }
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error submitting review" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Failed to submit review"))
                }
            }
            
            // Creator endpoints
            route("/creator") {
                
                // Register as a creator
                post("/register") {
                    try {
                        val user = call.extractUser()
                        val request = call.receive<CreatorRegistrationDto>()
                        
                        val profile = creatorService.registerCreator(
                            userId = user.id,
                            request = CreatorRegistrationRequest(
                                displayName = request.displayName,
                                bio = request.bio,
                                avatarUrl = request.avatarUrl,
                                contentSpecialties = request.contentSpecialties,
                                languagesSupported = request.languagesSupported,
                                educatorCredentials = request.educatorCredentials
                            )
                        )
                        
                        call.respond(HttpStatusCode.Created, profile)
                        
                    } catch (e: Exception) {
                        logger.error(e) { "Error registering creator" }
                        call.respond(HttpStatusCode.InternalServerError, 
                            ErrorResponse("Creator registration failed"))
                    }
                }
                
                // Get creator profile
                get("/profile/{creatorId}") {
                    try {
                        val creatorId = call.parameters["creatorId"]?.let { UUID.fromString(it) }
                            ?: return@get call.respond(HttpStatusCode.BadRequest, 
                                ErrorResponse("Invalid creator ID"))
                        
                        val profile = creatorService.getCreatorProfile(creatorId)
                        
                        if (profile != null) {
                            call.respond(HttpStatusCode.OK, profile)
                        } else {
                            call.respond(HttpStatusCode.NotFound, 
                                ErrorResponse("Creator not found"))
                        }
                        
                    } catch (e: Exception) {
                        logger.error(e) { "Error getting creator profile" }
                        call.respond(HttpStatusCode.InternalServerError, 
                            ErrorResponse("Failed to get creator profile"))
                    }
                }
                
                // Get creator analytics (creator only)
                get("/analytics") {
                    try {
                        val user = call.extractUser()
                        val timeRange = call.request.queryParameters["timeRange"]?.let {
                            TimeRange.valueOf(it.uppercase())
                        } ?: TimeRange.LAST_30_DAYS
                        
                        // TODO: Verify user is the creator
                        val creatorId = UUID.randomUUID() // Get from user's creator profile
                        
                        val analytics = creatorService.getCreatorAnalytics(creatorId, timeRange)
                        
                        call.respond(HttpStatusCode.OK, analytics)
                        
                    } catch (e: Exception) {
                        logger.error(e) { "Error getting creator analytics" }
                        call.respond(HttpStatusCode.InternalServerError, 
                            ErrorResponse("Failed to get analytics"))
                    }
                }
                
                // Publish content
                post("/publish") {
                    try {
                        val user = call.extractUser()
                        val request = call.receive<PublishContentDto>()
                        
                        // TODO: Verify user is a creator
                        val creatorId = UUID.randomUUID() // Get from user's creator profile
                        
                        val result = creatorService.publishContent(
                            creatorId = creatorId,
                            request = PublishContentRequest(
                                title = request.title,
                                description = request.description,
                                contentType = try {
                                    ContentType.valueOf(request.contentType.uppercase())
                                } catch (e: IllegalArgumentException) {
                                    ContentType.STORY // Default to STORY if invalid
                                },
                                ageRange = request.ageRange,
                                price = BigDecimal(request.price),
                                licensingModel = LicensingModel.valueOf(request.licensingModel.uppercase()),
                                tags = request.tags,
                                educationalGoals = request.educationalGoals,
                                contentData = request.contentData
                            )
                        )
                        
                        if (result.success) {
                            call.respond(HttpStatusCode.Created, result)
                        } else {
                            call.respond(HttpStatusCode.BadRequest, 
                                ErrorResponse(result.message))
                        }
                        
                    } catch (e: Exception) {
                        logger.error(e) { "Error publishing content" }
                        call.respond(HttpStatusCode.InternalServerError, 
                            ErrorResponse("Failed to publish content"))
                    }
                }
                
                // Get earnings
                get("/earnings") {
                    try {
                        val user = call.extractUser()
                        
                        // TODO: Verify user is a creator
                        val creatorId = UUID.randomUUID() // Get from user's creator profile
                        
                        val earnings = creatorService.getCreatorEarnings(creatorId)
                        
                        call.respond(HttpStatusCode.OK, earnings)
                        
                    } catch (e: Exception) {
                        logger.error(e) { "Error getting earnings" }
                        call.respond(HttpStatusCode.InternalServerError, 
                            ErrorResponse("Failed to get earnings"))
                    }
                }
                
                // Request payout
                post("/payout") {
                    try {
                        val user = call.extractUser()
                        val request = call.receive<PayoutRequest>()
                        
                        // TODO: Verify user is a creator
                        val creatorId = UUID.randomUUID() // Get from user's creator profile
                        
                        val result = creatorService.requestPayout(
                            creatorId = creatorId,
                            amount = BigDecimal(request.amount)
                        )
                        
                        if (result.success) {
                            call.respond(HttpStatusCode.OK, result)
                        } else {
                            call.respond(HttpStatusCode.BadRequest, 
                                ErrorResponse(result.message))
                        }
                        
                    } catch (e: Exception) {
                        logger.error(e) { "Error requesting payout" }
                        call.respond(HttpStatusCode.InternalServerError, 
                            ErrorResponse("Payout request failed"))
                    }
                }
            }
            
            // Follow/unfollow creator
            post("/creators/{creatorId}/follow") {
                try {
                    val user = call.extractUser()
                    val creatorId = call.parameters["creatorId"]?.let { UUID.fromString(it) }
                        ?: return@post call.respond(HttpStatusCode.BadRequest, 
                            ErrorResponse("Invalid creator ID"))
                    
                    val follow = call.receive<FollowRequest>().follow
                    
                    val result = creatorService.toggleFollowCreator(
                        userId = user.id,
                        creatorId = creatorId,
                        follow = follow
                    )
                    
                    call.respond(HttpStatusCode.OK, result)
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error toggling follow" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Follow operation failed"))
                }
            }
        }
    }
}

// Request/Response DTOs

@Serializable
data class ErrorResponse(val error: String)

@Serializable
data class MarketplaceSearchRequest(
    val query: String? = null,
    val contentTypes: List<String>? = null,
    val ageRanges: List<String>? = null,
    val minPrice: String? = null,
    val maxPrice: String? = null,
    val tags: List<String>? = null,
    @Contextual val creatorId: UUID? = null,
    val sortBy: String? = null,
    val page: Int? = null,
    val pageSize: Int? = null
)

@Serializable
data class MarketplaceSearchResponse(
    val items: List<com.wondernest.services.marketplace.MarketplaceItem>,
    val totalCount: Int,
    val page: Int,
    val pageSize: Int,
    val facets: com.wondernest.services.marketplace.SearchFacets
)

// Request/Response DTOs

@Serializable
data class PurchaseRequest(
    @Contextual val itemId: UUID,
    val paymentMethod: String
)

@Serializable
data class PurchaseResponse(
    val success: Boolean,
    @Contextual val purchaseId: UUID?,
    val transactionId: String?,
    val message: String
)

@Serializable
data class ReviewRequest(
    @Contextual val itemId: UUID,
    val rating: Int,
    val review: String? = null
)

@Serializable
data class CreatorRegistrationDto(
    val displayName: String,
    val bio: String?,
    val avatarUrl: String?,
    val contentSpecialties: List<String>,
    val languagesSupported: List<String>,
    val educatorCredentials: Map<String, String>? = null
)

@Serializable
data class PublishContentDto(
    val title: String,
    val description: String,
    val contentType: String,
    val ageRange: String,
    val price: String,
    val licensingModel: String,
    val tags: List<String>,
    val educationalGoals: List<String>,
    val contentData: Map<String, String>
)

@Serializable
data class PayoutRequest(
    val amount: String
)

@Serializable
data class FollowRequest(
    val follow: Boolean
)

/* Other DTOs - commented out as not needed
@Serializable
data class MarketplaceItemDto(
    @Contextual val id: UUID,
    val title: String,
    val description: String,
    val contentType: String,
    @Contextual val creatorId: UUID,
    val creatorName: String,
    val price: String,
    val rating: Double,
    val ratingCount: Int,
    val ageRange: String,
    val tags: List<String>,
    val thumbnailUrl: String?,
    val previewAvailable: Boolean,
    val isAIGenerated: Boolean,
    val purchaseCount: Int,
    val createdAt: String
)

@Serializable
data class FeaturedContentResponse(
    val spotlightItems: List<MarketplaceItemDto>,
    val newReleases: List<MarketplaceItemDto>,
    val topRated: List<MarketplaceItemDto>,
    val editorsPicks: List<MarketplaceItemDto>,
    val trendingNow: List<MarketplaceItemDto>,
    val categories: List<ContentCategory>
)

@Serializable
data class MarketplaceItemDetailsDto(
    val item: MarketplaceItemDto,
    val fullDescription: String,
    val educationalGoals: List<String>,
    val screenshots: List<String>,
    val reviews: List<Review>,
    val similarItems: List<MarketplaceItemDto>,
    val creatorInfo: CreatorInfo
)

@Serializable
data class PurchaseRequest(
    @Contextual val itemId: UUID,
    val paymentMethod: String
)

@Serializable
data class PurchaseResponse(
    val success: Boolean,
    @Contextual val purchaseId: UUID?,
    val transactionId: String?,
    val message: String
)

@Serializable
data class ReviewRequest(
    @Contextual val itemId: UUID,
    val rating: Int,
    val review: String? = null
)

@Serializable
data class CreatorRegistrationDto(
    val displayName: String,
    val bio: String? = null,
    val avatarUrl: String? = null,
    val contentSpecialties: List<String>,
    val languagesSupported: List<String>,
    val educatorCredentials: Map<String, String>? = null
)

@Serializable
data class CreatorProfileDto(
    @Contextual val id: UUID,
    @Contextual val userId: UUID,
    val displayName: String,
    val bio: String?,
    val avatarUrl: String?,
    val tier: String,
    val verified: Boolean,
    val totalSales: Int,
    val totalRevenue: String,
    val averageRating: Double,
    val contentCount: Int,
    val followerCount: Int,
    val accountStatus: String,
    val createdAt: String
)

@Serializable
data class PublishContentDto(
    val title: String,
    val description: String,
    val contentType: String,
    val ageRange: String,
    val price: String,
    val licensingModel: String,
    val tags: List<String>,
    val educationalGoals: List<String>,
    val contentData: Map<String, String>
)

*/

/* Extension functions for DTO conversion - Not needed anymore

fun MarketplaceItem.toDto() = MarketplaceItemDto(
    id = id,
    title = title,
    description = description,
    contentType = contentType.name,
    creatorId = creatorId,
    creatorName = creatorName,
    price = price.toString(),
    rating = rating,
    ratingCount = ratingCount,
    ageRange = ageRange,
    tags = tags,
    thumbnailUrl = thumbnailUrl,
    previewAvailable = previewAvailable,
    isAIGenerated = isAIGenerated,
    purchaseCount = purchaseCount,
    createdAt = createdAt.toString()
)

fun MarketplaceItemDetails.toDto() = MarketplaceItemDetailsDto(
    item = item.toDto(),
    fullDescription = fullDescription,
    educationalGoals = educationalGoals,
    screenshots = screenshots,
    reviews = reviews,
    similarItems = similarItems.map { it.toDto() },
    creatorInfo = creatorInfo
)

fun CreatorProfile.toDto() = CreatorProfileDto(
    id = id,
    userId = userId,
    displayName = displayName,
    bio = bio,
    avatarUrl = avatarUrl,
    tier = tier.name,
    verified = verified,
    totalSales = totalSales,
    totalRevenue = totalRevenue.toString(),
    averageRating = averageRating,
    contentCount = contentCount,
    followerCount = followerCount,
    accountStatus = accountStatus.name,
    createdAt = createdAt.toString()
)
*/