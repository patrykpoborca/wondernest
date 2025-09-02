package com.wondernest.services

import com.wondernest.models.*
import java.time.Instant
import java.util.UUID
import java.math.BigDecimal

/**
 * Simplified ContentPackService that returns mock data
 * This allows the API endpoints to work while the full implementation is being fixed
 */
class ContentPackServiceSimple {

    fun getCategories(): List<ContentPackCategory> {
        return listOf(
            ContentPackCategory(
                id = UUID.randomUUID(),
                name = "Characters",
                description = "Character bundles and avatars",
                displayOrder = 1,
                iconUrl = null,
                colorHex = "#FF6B6B",
                isActive = true,
                ageMin = 3,
                ageMax = 12,
                createdAt = Instant.now(),
                updatedAt = Instant.now()
            ),
            ContentPackCategory(
                id = UUID.randomUUID(),
                name = "Backgrounds",
                description = "Scenic backgrounds and environments",
                displayOrder = 2,
                iconUrl = null,
                colorHex = "#4ECDC4",
                isActive = true,
                ageMin = 3,
                ageMax = 12,
                createdAt = Instant.now(),
                updatedAt = Instant.now()
            ),
            ContentPackCategory(
                id = UUID.randomUUID(),
                name = "Stickers",
                description = "Fun stickers and decorations",
                displayOrder = 3,
                iconUrl = null,
                colorHex = "#FFD93D",
                isActive = true,
                ageMin = 3,
                ageMax = 12,
                createdAt = Instant.now(),
                updatedAt = Instant.now()
            )
        )
    }

    fun getFeaturedPacks(userId: UUID, limit: Int = 10): List<ContentPack> {
        return getMockPacks().take(limit)
    }

    fun searchPacks(request: ContentPackSearchRequest, userId: UUID): ContentPackSearchResponse {
        val allPacks = getMockPacks()
        
        // Simple filtering
        var filteredPacks = allPacks
        
        request.query?.let { query ->
            filteredPacks = filteredPacks.filter { 
                it.name.contains(query, ignoreCase = true) || 
                it.description?.contains(query, ignoreCase = true) == true 
            }
        }
        
        request.category?.let { category ->
            // Filter by category if needed
        }
        
        // Pagination
        val start = request.page * request.size
        val end = minOf(start + request.size, filteredPacks.size)
        val paginatedPacks = if (start < filteredPacks.size) {
            filteredPacks.subList(start, end)
        } else {
            emptyList()
        }
        
        return ContentPackSearchResponse(
            packs = paginatedPacks,
            total = filteredPacks.size.toLong(),
            page = request.page,
            size = request.size,
            hasNext = end < filteredPacks.size
        )
    }

    fun getPackById(packId: UUID, userId: UUID): ContentPack? {
        return getMockPacks().find { it.id == packId }
    }

    fun getUserOwnedPacks(userId: UUID, childId: UUID? = null): List<ContentPack> {
        // Return first 3 packs as owned for demo
        return getMockPacks().take(3).map { pack ->
            pack.copy(
                userOwnership = UserPackOwnership(
                    id = UUID.randomUUID(),
                    userId = userId,
                    packId = pack.id,
                    childId = childId,
                    acquiredAt = Instant.now().minusSeconds(86400 * 7),
                    acquisitionType = "purchase",
                    purchasePriceCents = pack.priceCents,
                    transactionId = "txn-${System.currentTimeMillis()}",
                    downloadStatus = "completed",
                    downloadProgress = 100,
                    downloadedAt = Instant.now().minusSeconds(86400 * 6),
                    lastUsedAt = Instant.now().minusSeconds(7200),
                    usageCount = 15,
                    isFavorite = pack.name == "Safari Animals",
                    isHidden = false,
                    customTags = if (pack.name == "Safari Animals") listOf("favorite") else emptyList()
                )
            )
        }
    }

    fun purchasePack(userId: UUID, request: PackPurchaseRequest): PackPurchaseResponse {
        val pack = getMockPacks().find { it.id == request.packId }
            ?: return PackPurchaseResponse(false, error = "Pack not found")
        
        val ownership = UserPackOwnership(
            id = UUID.randomUUID(),
            userId = userId,
            packId = request.packId,
            childId = request.childId,
            acquiredAt = Instant.now(),
            acquisitionType = if (pack.isFree) "free" else "purchase",
            purchasePriceCents = pack.priceCents,
            transactionId = "txn-${System.currentTimeMillis()}",
            downloadStatus = "pending",
            downloadProgress = 0,
            downloadedAt = null,
            lastUsedAt = null,
            usageCount = 0,
            isFavorite = false,
            isHidden = false,
            customTags = emptyList()
        )
        
        return PackPurchaseResponse(
            success = true,
            transactionId = ownership.transactionId,
            ownership = ownership
        )
    }

    fun updateDownloadStatus(
        userId: UUID, 
        packId: UUID, 
        childId: UUID? = null,
        status: String, 
        progress: Int = 0
    ): Boolean {
        // Mock implementation
        return true
    }

    fun recordPackUsage(
        userId: UUID,
        packId: UUID,
        childId: UUID? = null,
        assetId: UUID? = null,
        usedInFeature: String,
        sessionId: UUID? = null,
        usageDurationSeconds: Int? = null,
        metadata: Map<String, Any>? = null
    ) {
        // Mock implementation - just log
        println("Recording pack usage: $packId in $usedInFeature")
    }

    fun getPackAssets(packId: UUID, userId: UUID, childId: UUID? = null): List<ContentPackAsset>? {
        val pack = getMockPacks().find { it.id == packId } ?: return null
        
        return listOf(
            ContentPackAsset(
                id = UUID.randomUUID(),
                packId = packId,
                name = "Asset 1",
                description = "Sample asset",
                assetType = "imageStatic",
                fileUrl = "https://placeholder.com/asset1.png",
                thumbnailUrl = "https://placeholder.com/asset1_thumb.png",
                fileFormat = "png",
                fileSizeBytes = 1024 * 50,
                dimensionsWidth = 512,
                dimensionsHeight = 512,
                durationSeconds = null,
                frameRate = null,
                tags = listOf("sample"),
                colorPalette = mapOf("primary" to "#FF6B6B"),
                transparencySupport = true,
                loopPoints = null,
                interactionConfig = null,
                animationTriggers = emptyList(),
                displayOrder = 0,
                groupName = null,
                isActive = true,
                createdAt = Instant.now(),
                updatedAt = Instant.now()
            )
        )
    }

    private fun getMockPacks(): List<ContentPack> {
        val packId1 = UUID.fromString("11111111-1111-1111-1111-111111111111")
        val packId2 = UUID.fromString("22222222-2222-2222-2222-222222222222")
        val packId3 = UUID.fromString("33333333-3333-3333-3333-333333333333")
        
        return listOf(
            ContentPack(
                id = packId1,
                name = "Safari Animals",
                description = "A wonderful collection of African safari animals including lions, elephants, and giraffes",
                shortDescription = "African safari animals",
                packType = "characterBundle",
                categoryId = null,
                category = null,
                priceCents = 299,
                isFree = false,
                isFeatured = true,
                isPremium = false,
                ageMin = 3,
                ageMax = 8,
                educationalGoals = listOf("Animal Recognition", "Geography"),
                curriculumTags = listOf("Science", "Nature"),
                thumbnailUrl = "https://placeholder.com/safari_thumb.jpg",
                previewUrls = listOf("https://placeholder.com/safari_preview1.jpg"),
                bannerImageUrl = "https://placeholder.com/safari_banner.jpg",
                colorPalette = mapOf("primary" to "#8B4513", "secondary" to "#FFD700"),
                artStyle = "Cartoon",
                moodTags = listOf("Adventure", "Educational"),
                totalAssets = 25,
                fileSizeBytes = 1024 * 1024 * 5,
                supportedPlatforms = listOf("ios", "android", "web"),
                minAppVersion = "1.0.0",
                performanceTier = "standard",
                status = "published",
                publishedAt = Instant.now().minusSeconds(86400 * 30),
                createdAt = Instant.now().minusSeconds(86400 * 45),
                updatedAt = Instant.now().minusSeconds(86400),
                createdBy = UUID.randomUUID(),
                searchKeywords = "safari animals africa lion elephant giraffe",
                popularityScore = BigDecimal("0.85"),
                downloadCount = 1250,
                ratingAverage = BigDecimal("4.7"),
                ratingCount = 234,
                assets = emptyList(),
                userOwnership = null
            ),
            ContentPack(
                id = packId2,
                name = "Magical Castle",
                description = "Enter a world of fantasy with castles, dragons, and magical creatures",
                shortDescription = "Fantasy castle backgrounds",
                packType = "backdropCollection",
                categoryId = null,
                category = null,
                priceCents = 399,
                isFree = false,
                isFeatured = true,
                isPremium = true,
                ageMin = 5,
                ageMax = 10,
                educationalGoals = listOf("Imagination", "Storytelling"),
                curriculumTags = listOf("Creative Arts"),
                thumbnailUrl = "https://placeholder.com/castle_thumb.jpg",
                previewUrls = listOf("https://placeholder.com/castle_preview1.jpg"),
                bannerImageUrl = "https://placeholder.com/castle_banner.jpg",
                colorPalette = mapOf("primary" to "#663399", "secondary" to "#FFB6C1"),
                artStyle = "Fantasy",
                moodTags = listOf("Magical", "Adventure"),
                totalAssets = 30,
                fileSizeBytes = 1024 * 1024 * 8,
                supportedPlatforms = listOf("ios", "android", "web"),
                minAppVersion = "1.0.0",
                performanceTier = "premium",
                status = "published",
                publishedAt = Instant.now().minusSeconds(86400 * 20),
                createdAt = Instant.now().minusSeconds(86400 * 35),
                updatedAt = Instant.now().minusSeconds(86400 * 2),
                createdBy = UUID.randomUUID(),
                searchKeywords = "castle magic dragon fantasy medieval",
                popularityScore = BigDecimal("0.92"),
                downloadCount = 2100,
                ratingAverage = BigDecimal("4.9"),
                ratingCount = 456,
                assets = emptyList(),
                userOwnership = null
            ),
            ContentPack(
                id = packId3,
                name = "Happy Vehicles",
                description = "Fun and colorful vehicles including cars, trains, and airplanes",
                shortDescription = "Colorful vehicle stickers",
                packType = "stickerPack",
                categoryId = null,
                category = null,
                priceCents = 0,
                isFree = true,
                isFeatured = false,
                isPremium = false,
                ageMin = 2,
                ageMax = 6,
                educationalGoals = listOf("Transportation", "Colors"),
                curriculumTags = listOf("Early Learning"),
                thumbnailUrl = "https://placeholder.com/vehicles_thumb.jpg",
                previewUrls = listOf("https://placeholder.com/vehicles_preview1.jpg"),
                bannerImageUrl = "https://placeholder.com/vehicles_banner.jpg",
                colorPalette = mapOf("primary" to "#FF0000", "secondary" to "#0000FF"),
                artStyle = "Bright and Colorful",
                moodTags = listOf("Fun", "Educational"),
                totalAssets = 15,
                fileSizeBytes = 1024 * 1024 * 2,
                supportedPlatforms = listOf("ios", "android", "web"),
                minAppVersion = "1.0.0",
                performanceTier = "standard",
                status = "published",
                publishedAt = Instant.now().minusSeconds(86400 * 60),
                createdAt = Instant.now().minusSeconds(86400 * 90),
                updatedAt = Instant.now().minusSeconds(86400 * 7),
                createdBy = UUID.randomUUID(),
                searchKeywords = "vehicles cars trains planes transportation",
                popularityScore = BigDecimal("0.75"),
                downloadCount = 5000,
                ratingAverage = BigDecimal("4.5"),
                ratingCount = 789,
                assets = emptyList(),
                userOwnership = null
            )
        )
    }
}