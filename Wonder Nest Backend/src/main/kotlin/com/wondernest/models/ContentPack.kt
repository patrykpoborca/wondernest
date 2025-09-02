package com.wondernest.models

import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

@Serializable
data class ContentPackCategory(
    @Contextual val id: UUID,
    val name: String,
    val description: String? = null,
    val displayOrder: Int = 0,
    val iconUrl: String? = null,
    val colorHex: String? = null,
    val isActive: Boolean = true,
    val ageMin: Int = 3,
    val ageMax: Int = 12,
    @Contextual val createdAt: Instant,
    @Contextual val updatedAt: Instant
)

@Serializable
data class ContentPack(
    @Contextual val id: UUID,
    val name: String,
    val description: String? = null,
    val shortDescription: String? = null,
    val packType: String,
    @Contextual val categoryId: UUID? = null,
    val category: ContentPackCategory? = null,
    
    // Pricing and availability
    val priceCents: Int = 0,
    val isFree: Boolean = false,
    val isFeatured: Boolean = false,
    val isPremium: Boolean = false,
    
    // Age and educational info
    val ageMin: Int = 3,
    val ageMax: Int = 12,
    val educationalGoals: List<String> = emptyList(),
    val curriculumTags: List<String> = emptyList(),
    
    // Visual and metadata
    val thumbnailUrl: String? = null,
    val previewUrls: List<String> = emptyList(),
    val bannerImageUrl: String? = null,
    val colorPalette: Map<String, String>? = null,
    val artStyle: String? = null,
    val moodTags: List<String> = emptyList(),
    
    // Technical metadata
    val totalAssets: Int = 0,
    val fileSizeBytes: Long = 0,
    val supportedPlatforms: List<String> = listOf("ios", "android", "web"),
    val minAppVersion: String? = null,
    val performanceTier: String = "standard",
    
    // Status and timestamps
    val status: String = "draft",
    @Contextual val publishedAt: Instant? = null,
    @Contextual val createdAt: Instant,
    @Contextual val updatedAt: Instant,
    @Contextual val createdBy: UUID? = null,
    
    // Search and discovery
    val searchKeywords: String? = null,
    @Contextual val popularityScore: BigDecimal = BigDecimal("0.00"),
    val downloadCount: Long = 0,
    @Contextual val ratingAverage: BigDecimal = BigDecimal("0.00"),
    val ratingCount: Int = 0,
    
    // Related data
    val assets: List<ContentPackAsset> = emptyList(),
    val userOwnership: UserPackOwnership? = null,
    val userReview: ContentPackReview? = null
)

@Serializable
data class ContentPackAsset(
    @Contextual val id: UUID,
    @Contextual val packId: UUID,
    
    // Basic asset info
    val name: String,
    val description: String? = null,
    val assetType: String,
    val fileUrl: String,
    val thumbnailUrl: String? = null,
    
    // File technical details
    val fileFormat: String? = null,
    val fileSizeBytes: Int? = null,
    val dimensionsWidth: Int? = null,
    val dimensionsHeight: Int? = null,
    @Contextual val durationSeconds: BigDecimal? = null,
    val frameRate: Int? = null,
    
    // Creative metadata
    val tags: List<String> = emptyList(),
    val colorPalette: Map<String, String>? = null,
    val transparencySupport: Boolean = false,
    val loopPoints: Map<String, Int>? = null,
    
    // Interactive properties
    val interactionConfig: Map<String, String>? = null,
    val animationTriggers: List<String> = emptyList(),
    
    // Ordering and grouping
    val displayOrder: Int = 0,
    val groupName: String? = null,
    
    // Status
    val isActive: Boolean = true,
    @Contextual val createdAt: Instant,
    @Contextual val updatedAt: Instant
)

@Serializable
data class UserPackOwnership(
    @Contextual val id: UUID,
    @Contextual val userId: UUID,
    @Contextual val packId: UUID,
    @Contextual val childId: UUID? = null,
    
    // Purchase/acquisition info
    @Contextual val acquiredAt: Instant,
    val acquisitionType: String = "purchase",
    val purchasePriceCents: Int = 0,
    val transactionId: String? = null,
    
    // Download and usage
    val downloadStatus: String = "pending",
    val downloadProgress: Int = 0,
    @Contextual val downloadedAt: Instant? = null,
    @Contextual val lastUsedAt: Instant? = null,
    val usageCount: Int = 0,
    
    // Preferences
    val isFavorite: Boolean = false,
    val isHidden: Boolean = false,
    val customTags: List<String> = emptyList()
)

@Serializable
data class ContentPackUsage(
    @Contextual val id: UUID,
    @Contextual val userId: UUID,
    @Contextual val childId: UUID? = null,
    @Contextual val packId: UUID,
    @Contextual val assetId: UUID? = null,
    
    // Usage context
    val usedInFeature: String? = null,
    @Contextual val sessionId: UUID? = null,
    val usageDurationSeconds: Int? = null,
    
    // Metadata
    @Contextual val usedAt: Instant,
    val usageMetadata: Map<String, String>? = null
)

@Serializable
data class ContentPackCollection(
    @Contextual val id: UUID,
    val name: String,
    val description: String? = null,
    val collectionType: String = "bundle",
    
    // Pricing and availability
    val priceCents: Int = 0,
    val discountPercentage: Int = 0,
    
    // Visual
    val thumbnailUrl: String? = null,
    val bannerImageUrl: String? = null,
    
    // Status
    val isActive: Boolean = true,
    val isFeatured: Boolean = false,
    @Contextual val availableFrom: Instant? = null,
    @Contextual val availableUntil: Instant? = null,
    
    @Contextual val createdAt: Instant,
    @Contextual val updatedAt: Instant,
    
    // Related data
    val packs: List<ContentPack> = emptyList()
)

@Serializable
data class ContentPackReview(
    @Contextual val id: UUID,
    @Contextual val packId: UUID,
    @Contextual val userId: UUID,
    
    // Review content
    val rating: Int,
    val reviewText: String? = null,
    val reviewTitle: String? = null,
    
    // Helpful metrics
    val helpfulCount: Int = 0,
    val notHelpfulCount: Int = 0,
    
    // Child context (anonymous)
    val childAgeRange: String? = null,
    val usedFeatures: List<String> = emptyList(),
    
    // Moderation
    val isApproved: Boolean = false,
    val isFeatured: Boolean = false,
    @Contextual val moderatedAt: Instant? = null,
    @Contextual val moderatedBy: UUID? = null,
    
    @Contextual val createdAt: Instant,
    @Contextual val updatedAt: Instant
)

// Request/Response DTOs
@Serializable
data class ContentPackSearchRequest(
    val query: String? = null,
    val category: String? = null,
    val packType: String? = null,
    val ageMin: Int? = null,
    val ageMax: Int? = null,
    val priceMin: Int? = null,
    val priceMax: Int? = null,
    val isFree: Boolean? = null,
    val educationalGoals: List<String> = emptyList(),
    val sortBy: String = "popularity",
    val sortOrder: String = "desc",
    val page: Int = 0,
    val size: Int = 20
)

@Serializable
data class ContentPackSearchResponse(
    val packs: List<ContentPack>,
    val total: Long,
    val page: Int,
    val size: Int,
    val hasNext: Boolean
)

@Serializable
data class PackPurchaseRequest(
    @Contextual val packId: UUID,
    @Contextual val childId: UUID? = null,
    val paymentMethod: String? = null
)

@Serializable
data class PackPurchaseResponse(
    val success: Boolean,
    val transactionId: String? = null,
    val ownership: UserPackOwnership? = null,
    val error: String? = null
)