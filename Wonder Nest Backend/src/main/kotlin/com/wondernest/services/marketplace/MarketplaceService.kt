package com.wondernest.services.marketplace

import com.wondernest.data.database.repository.marketplace.MarketplaceRepository
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import mu.KotlinLogging
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

private val logger = KotlinLogging.logger {}

/**
 * Service for managing marketplace content discovery, purchasing, and creator management
 */
class MarketplaceService(
    private val marketplaceRepository: MarketplaceRepository
) {
    
    /**
     * Search and discover marketplace content
     */
    suspend fun searchContent(request: SearchRequest): SearchResult {
        logger.info { "Searching marketplace with query: ${request.query}" }
        return marketplaceRepository.searchListings(request)
    }
    
    /**
     * Get featured content for the marketplace homepage
     */
    suspend fun getFeaturedContent(): FeaturedContent {
        logger.info { "Getting featured marketplace content" }
        return marketplaceRepository.getFeaturedContent()
    }
    
    /**
     * Get detailed information about a marketplace item
     */
    suspend fun getItemDetails(itemId: UUID): MarketplaceItemDetails? {
        logger.info { "Getting details for marketplace item: $itemId" }
        return marketplaceRepository.getListingById(itemId)
    }
    
    /**
     * Purchase a marketplace item
     */
    suspend fun purchaseItem(
        userId: UUID,
        familyId: UUID,
        itemId: UUID,
        paymentMethod: String
    ): PurchaseResult {
        logger.info { "Processing purchase for user $userId, item $itemId" }
        return marketplaceRepository.createPurchase(userId, familyId, itemId, paymentMethod)
    }
    
    /**
     * Get user's purchase history
     */
    suspend fun getUserPurchases(userId: UUID, page: Int = 0, pageSize: Int = 20): PurchaseHistory {
        logger.info { "Getting purchase history for user $userId" }
        return marketplaceRepository.getUserPurchases(userId, page, pageSize)
    }
    
    /**
     * Submit a review for a purchased item
     */
    suspend fun submitReview(
        userId: UUID,
        itemId: UUID,
        rating: Int,
        review: String?
    ): ReviewResult {
        logger.info { "Submitting review for item $itemId from user $userId" }
        
        require(rating in 1..5) { "Rating must be between 1 and 5" }
        
        return marketplaceRepository.submitReview(userId, itemId, rating, review)
    }
    
    /**
     * Get content recommendations
     */
    suspend fun getRecommendations(childId: UUID?, familyId: UUID): List<MarketplaceItem> {
        logger.info { "Getting recommendations for child $childId, family $familyId" }
        return marketplaceRepository.getRecommendations(childId, familyId)
    }
    
    /**
     * Track user interaction with content
     */
    suspend fun trackInteraction(childId: UUID?, itemId: UUID, interactionType: String) {
        logger.info { "Tracking interaction: $interactionType for item $itemId" }
        marketplaceRepository.trackInteraction(childId, itemId, interactionType)
    }
}

// Data classes for marketplace operations

@Serializable
data class SearchRequest(
    val query: String? = null,
    val contentTypes: List<ContentType> = emptyList(),
    val ageRanges: List<String> = emptyList(),
    @Contextual val minPrice: BigDecimal? = null,
    @Contextual val maxPrice: BigDecimal? = null,
    val tags: List<String> = emptyList(),
    @Contextual val creatorId: UUID? = null,
    val sortBy: SortOption = SortOption.RELEVANCE,
    val page: Int = 0,
    val pageSize: Int = 20
)

@Serializable
data class SearchResult(
    val items: List<MarketplaceItem>,
    val totalCount: Int,
    val page: Int,
    val pageSize: Int,
    val facets: SearchFacets
)

@Serializable
data class SearchFacets(
    val contentTypes: Map<ContentType, Int>,
    val ageRanges: Map<String, Int>,
    val priceRanges: Map<String, Int>
)

@Serializable
data class MarketplaceItem(
    @Contextual val id: UUID,
    val title: String,
    val description: String,
    val contentType: ContentType,
    @Contextual val creatorId: UUID,
    val creatorName: String,
    @Contextual val price: BigDecimal,
    val rating: Double,
    val ratingCount: Int,
    val ageRange: String,
    val tags: List<String>,
    val thumbnailUrl: String?,
    val previewAvailable: Boolean,
    val isAIGenerated: Boolean,
    val purchaseCount: Int,
    @Contextual val createdAt: Instant
)

@Serializable
data class MarketplaceItemDetails(
    val item: MarketplaceItem,
    val fullDescription: String,
    val educationalGoals: List<String>,
    val screenshots: List<String>,
    val reviews: List<Review>,
    val similarItems: List<MarketplaceItem>,
    val creatorInfo: CreatorInfo
)

@Serializable
data class Review(
    @Contextual val id: UUID,
    @Contextual val userId: UUID,
    val userName: String,
    val rating: Int,
    val review: String?,
    val helpful: Int,
    @Contextual val createdAt: Instant
)

@Serializable
data class CreatorInfo(
    @Contextual val id: UUID,
    val displayName: String,
    val bio: String?,
    val avatarUrl: String?,
    val verified: Boolean,
    val contentCount: Int,
    val followerCount: Int
)

@Serializable
data class FeaturedContent(
    val spotlightItems: List<MarketplaceItem>,
    val newReleases: List<MarketplaceItem>,
    val topRated: List<MarketplaceItem>,
    val editorsPicks: List<MarketplaceItem>,
    val trendingNow: List<MarketplaceItem>,
    val categories: List<ContentCategory>
)

@Serializable
data class ContentCategory(
    val id: String,
    val name: String,
    val description: String,
    val itemCount: Int
)

@Serializable
data class PurchaseResult(
    val success: Boolean,
    @Contextual val purchaseId: UUID?,
    @Contextual val itemId: UUID,
    @Contextual val amount: BigDecimal,
    val transactionId: String?,
    val message: String
)

@Serializable
data class PurchaseHistory(
    val purchases: List<Purchase>,
    val totalCount: Int,
    @Contextual val totalSpent: BigDecimal,
    val page: Int,
    val pageSize: Int
)

@Serializable
data class Purchase(
    @Contextual val id: UUID,
    @Contextual val itemId: UUID,
    val itemTitle: String,
    @Contextual val amount: BigDecimal,
    @Contextual val purchasedAt: Instant,
    val downloadUrl: String?
)

@Serializable
data class ReviewResult(
    val success: Boolean,
    @Contextual val reviewId: UUID?,
    val message: String
)

enum class ContentType {
    STORY,
    GAME,
    ACTIVITY,
    EDUCATIONAL_VIDEO,
    INTERACTIVE_BOOK
}

enum class SortOption {
    RELEVANCE,
    PRICE_LOW_HIGH,
    PRICE_HIGH_LOW,
    RATING,
    NEWEST,
    POPULAR
}