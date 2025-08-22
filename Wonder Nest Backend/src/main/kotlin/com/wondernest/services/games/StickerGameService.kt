package com.wondernest.services.games

import com.wondernest.api.games.*
import com.wondernest.domain.model.games.*
import com.wondernest.domain.repository.games.*
import kotlinx.datetime.Clock
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.util.UUID

// =============================================================================
// STICKER GAME SERVICE INTERFACE
// =============================================================================

interface StickerGameService {
    suspend fun initializeStickerGame(childId: UUID, ageMonths: Int): ChildGameInstance
    suspend fun getAvailableStickerSets(childId: UUID, theme: String? = null): List<StickerSet>
    suspend fun getChildStickerCollections(childId: UUID): List<ChildStickerCollection>
    suspend fun unlockStickerSet(childId: UUID, stickerSetId: UUID): Boolean
    suspend fun getChildProjects(childId: UUID): List<StickerBookProject>
    suspend fun createProject(childId: UUID, projectName: String, creationMode: String, templateId: UUID? = null): StickerBookProject
    suspend fun getProject(childId: UUID, projectId: UUID): StickerBookProject?
    suspend fun updateProject(childId: UUID, projectId: UUID, projectData: Map<String, Any>, sessionId: UUID? = null): StickerBookProject?
    suspend fun deleteProject(childId: UUID, projectId: UUID): Boolean
    suspend fun getGameTemplates(ageMonths: Int, difficulty: Int? = null): List<GameTemplate>
    suspend fun recordInteraction(childId: UUID, projectId: UUID, sessionId: UUID, interactionType: String, interactionData: Map<String, Any>): Boolean
    suspend fun getChildProgress(childId: UUID): StickerGameProgress
    suspend fun exportProject(childId: UUID, projectId: UUID, format: String, options: Map<String, Any>): ExportData?
}

// =============================================================================
// STICKER GAME SERVICE IMPLEMENTATION
// =============================================================================

class StickerGameServiceImpl(
    private val gameService: GameService,
    private val gameRegistryRepo: GameRegistryRepository,
    private val instanceRepo: ChildGameInstanceRepository,
    private val dataRepo: GameDataRepository,
    private val sessionRepo: GameSessionRepository,
    private val stickerSetRepo: StickerSetRepository,
    private val stickerCollectionRepo: ChildStickerCollectionRepository,
    private val stickerProjectRepo: StickerBookProjectRepository,
    private val templateRepo: StickerGameTemplateRepository,
    private val interactionRepo: StickerProjectInteractionRepository
) : StickerGameService {

    private val stickerGameKey = "sticker_book"
    
    override suspend fun initializeStickerGame(childId: UUID, ageMonths: Int): ChildGameInstance {
        // Find the sticker game in registry
        val stickerGame = gameRegistryRepo.findByKey(stickerGameKey)
            ?: throw GameNotFoundException("Sticker game not found in registry")
        
        // Create or get existing game instance
        val existingInstance = instanceRepo.findByChildAndGame(childId, stickerGame.id)
        if (existingInstance != null) {
            return existingInstance
        }
        
        // Create new instance with age-appropriate settings
        val settings = createAgeAppropriateSettings(ageMonths)
        val instance = gameService.createGameInstance(childId, stickerGame.id, settings)
        
        // Unlock basic sticker sets for the child's age
        unlockBasicStickerSets(childId, ageMonths)
        
        return instance
    }
    
    override suspend fun getAvailableStickerSets(childId: UUID, theme: String?): List<StickerSet> {
        // Get child's age from their profile (simplified - would need actual child age lookup)
        val ageMonths = 60 // Default to 5 years, should be retrieved from child profile
        
        val availableSets = if (theme != null) {
            stickerSetRepo.findByTheme(theme, ageMonths)
        } else {
            stickerSetRepo.findByAgeRange(ageMonths)
        }
        
        // Get child's unlocked collections to mark sets as unlocked
        val unlockedCollections = stickerCollectionRepo.findByChild(childId)
        val unlockedSetIds = unlockedCollections.map { it.stickerSetId }.toSet()
        
        return availableSets.map { set ->
            StickerSet(
                id = set.id,
                name = set.name,
                theme = set.theme,
                description = set.description,
                stickerData = Json.decodeFromString(set.stickerData),
                isPremium = set.isPremium,
                minAgeMonths = set.minAgeMonths,
                maxAgeMonths = set.maxAgeMonths,
                isUnlocked = unlockedSetIds.contains(set.id)
            )
        }
    }
    
    override suspend fun getChildStickerCollections(childId: UUID): List<ChildStickerCollection> {
        val collections = stickerCollectionRepo.findByChild(childId)
        return collections.map { collection ->
            val stickerSet = stickerSetRepo.findById(collection.stickerSetId)
                ?: throw IllegalStateException("Sticker set not found: ${collection.stickerSetId}")
            
            ChildStickerCollection(
                id = collection.id,
                childId = collection.childId,
                stickerSetId = collection.stickerSetId,
                stickerSet = StickerSet(
                    id = stickerSet.id,
                    name = stickerSet.name,
                    theme = stickerSet.theme,
                    description = stickerSet.description,
                    stickerData = Json.decodeFromString(stickerSet.stickerData),
                    isPremium = stickerSet.isPremium,
                    minAgeMonths = stickerSet.minAgeMonths,
                    maxAgeMonths = stickerSet.maxAgeMonths,
                    isUnlocked = true
                ),
                unlockedAt = collection.unlockedAt.toString(),
                isFavorite = collection.isFavorite,
                usageCount = collection.usageCount
            )
        }
    }
    
    override suspend fun unlockStickerSet(childId: UUID, stickerSetId: UUID): Boolean {
        return try {
            val collection = ChildStickerCollectionData(
                childId = childId,
                stickerSetId = stickerSetId,
                unlockedAt = Clock.System.now(),
                isFavorite = false,
                usageCount = 0
            )
            stickerCollectionRepo.create(collection)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    override suspend fun getChildProjects(childId: UUID): List<StickerBookProject> {
        val instance = instanceRepo.findByChild(childId)
            .firstOrNull { it.gameId == gameRegistryRepo.findByKey(stickerGameKey)?.id }
            ?: return emptyList()
        
        val projects = stickerProjectRepo.findByInstance(instance.id)
        return projects.map { project ->
            StickerBookProject(
                id = project.id,
                childGameInstanceId = project.childGameInstanceId,
                projectName = project.projectName,
                description = project.description,
                creationMode = project.creationMode,
                projectData = Json.decodeFromString(project.projectData),
                thumbnailUrl = project.thumbnailUrl,
                isCompleted = project.isCompleted,
                isShared = project.isShared,
                createdAt = project.createdAt.toString(),
                lastModified = project.lastModified.toString()
            )
        }
    }
    
    override suspend fun createProject(
        childId: UUID,
        projectName: String,
        creationMode: String,
        templateId: UUID?
    ): StickerBookProject {
        val stickerGame = gameRegistryRepo.findByKey(stickerGameKey)
            ?: throw GameNotFoundException("Sticker game not found")
        
        val instance = instanceRepo.findByChildAndGame(childId, stickerGame.id)
            ?: throw GameInstanceNotFoundException("Game instance not found")
        
        // Get template data if specified
        val templateData = templateId?.let { id ->
            templateRepo.findById(id)?.templateData
        }
        
        // Create initial project data structure
        val initialProjectData = createInitialProjectData(creationMode, templateData)
        
        val projectData = StickerBookProjectData(
            childGameInstanceId = instance.id,
            projectName = projectName,
            description = null,
            creationMode = creationMode,
            projectData = Json.encodeToString(initialProjectData),
            thumbnailUrl = null,
            isCompleted = false,
            isShared = false,
            createdAt = Clock.System.now(),
            lastModified = Clock.System.now()
        )
        
        val created = stickerProjectRepo.create(projectData)
        
        return StickerBookProject(
            id = created.id,
            childGameInstanceId = created.childGameInstanceId,
            projectName = created.projectName,
            description = created.description,
            creationMode = created.creationMode,
            projectData = Json.decodeFromString(created.projectData),
            thumbnailUrl = created.thumbnailUrl,
            isCompleted = created.isCompleted,
            isShared = created.isShared,
            createdAt = created.createdAt.toString(),
            lastModified = created.lastModified.toString()
        )
    }
    
    override suspend fun getProject(childId: UUID, projectId: UUID): StickerBookProject? {
        val project = stickerProjectRepo.findById(projectId) ?: return null
        
        // Verify ownership through instance
        val instance = instanceRepo.findById(project.childGameInstanceId)
        if (instance?.childId != childId) return null
        
        return StickerBookProject(
            id = project.id,
            childGameInstanceId = project.childGameInstanceId,
            projectName = project.projectName,
            description = project.description,
            creationMode = project.creationMode,
            projectData = Json.decodeFromString(project.projectData),
            thumbnailUrl = project.thumbnailUrl,
            isCompleted = project.isCompleted,
            isShared = project.isShared,
            createdAt = project.createdAt.toString(),
            lastModified = project.lastModified.toString()
        )
    }
    
    override suspend fun updateProject(
        childId: UUID,
        projectId: UUID,
        projectData: Map<String, Any>,
        sessionId: UUID?
    ): StickerBookProject? {
        val project = stickerProjectRepo.findById(projectId) ?: return null
        
        // Verify ownership
        val instance = instanceRepo.findById(project.childGameInstanceId)
        if (instance?.childId != childId) return null
        
        val updated = project.copy(
            projectData = Json.encodeToString(projectData),
            lastModified = Clock.System.now()
        )
        
        val result = stickerProjectRepo.update(updated)
        
        return StickerBookProject(
            id = result.id,
            childGameInstanceId = result.childGameInstanceId,
            projectName = result.projectName,
            description = result.description,
            creationMode = result.creationMode,
            projectData = Json.decodeFromString(result.projectData),
            thumbnailUrl = result.thumbnailUrl,
            isCompleted = result.isCompleted,
            isShared = result.isShared,
            createdAt = result.createdAt.toString(),
            lastModified = result.lastModified.toString()
        )
    }
    
    override suspend fun deleteProject(childId: UUID, projectId: UUID): Boolean {
        val project = stickerProjectRepo.findById(projectId) ?: return false
        
        // Verify ownership
        val instance = instanceRepo.findById(project.childGameInstanceId)
        if (instance?.childId != childId) return false
        
        return stickerProjectRepo.delete(projectId)
    }
    
    override suspend fun getGameTemplates(ageMonths: Int, difficulty: Int?): List<GameTemplate> {
        val templates = if (difficulty != null) {
            templateRepo.findByAgeAndDifficulty(ageMonths, difficulty)
        } else {
            templateRepo.findByAge(ageMonths)
        }
        
        return templates.map { template ->
            GameTemplate(
                id = template.id,
                title = template.title,
                description = template.description,
                backgroundImageUrl = template.backgroundImageUrl,
                stickerSetIds = Json.decodeFromString(template.stickerSetIds),
                targetAgeMin = template.targetAgeMin,
                targetAgeMax = template.targetAgeMax,
                difficultyLevel = template.difficultyLevel,
                templateData = Json.decodeFromString(template.templateData)
            )
        }
    }
    
    override suspend fun recordInteraction(
        childId: UUID,
        projectId: UUID,
        sessionId: UUID,
        interactionType: String,
        interactionData: Map<String, Any>
    ): Boolean {
        return try {
            val interaction = StickerProjectInteractionData(
                projectId = projectId,
                sessionId = sessionId,
                interactionType = interactionType,
                interactionData = Json.encodeToString(interactionData),
                timestamp = Clock.System.now()
            )
            interactionRepo.create(interaction)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    override suspend fun getChildProgress(childId: UUID): StickerGameProgress {
        val stickerGame = gameRegistryRepo.findByKey(stickerGameKey)
        val instance = stickerGame?.let { 
            instanceRepo.findByChildAndGame(childId, it.id)
        }
        
        if (instance == null) {
            return StickerGameProgress(
                totalProjects = 0,
                completedProjects = 0,
                totalPlayTimeMinutes = 0,
                unlockedStickerSets = 0,
                totalStickersUsed = 0,
                achievementsUnlocked = 0
            )
        }
        
        val projects = stickerProjectRepo.findByInstance(instance.id)
        val collections = stickerCollectionRepo.findByChild(childId)
        
        return StickerGameProgress(
            totalProjects = projects.size,
            completedProjects = projects.count { it.isCompleted },
            totalPlayTimeMinutes = instance.totalPlayTimeMinutes,
            unlockedStickerSets = collections.size,
            totalStickersUsed = calculateTotalStickersUsed(projects),
            achievementsUnlocked = 0 // Would need to query achievements
        )
    }
    
    override suspend fun exportProject(
        childId: UUID,
        projectId: UUID,
        format: String,
        options: Map<String, Any>
    ): ExportData? {
        val project = getProject(childId, projectId) ?: return null
        
        // This would implement actual export logic
        // For now, return a placeholder
        return ExportData(
            downloadUrl = "/api/v1/exports/${UUID.randomUUID()}",
            fileName = "${project.projectName}.${format}",
            fileSize = 1024L
        )
    }
    
    // =============================================================================
    // PRIVATE HELPER METHODS
    // =============================================================================
    
    private fun createAgeAppropriateSettings(ageMonths: Int): GameSettings {
        return if (ageMonths < 48) { // Under 4 years
            GameSettings(
                soundEnabled = true,
                animationsEnabled = true,
                autoSave = true,
                tutorialCompleted = false,
                difficulty = "easy",
                customSettings = mapOf(
                    "simple_ui" to "true",
                    "large_buttons" to "true",
                    "voice_guidance" to "true"
                )
            )
        } else {
            GameSettings(
                soundEnabled = true,
                animationsEnabled = true,
                autoSave = true,
                tutorialCompleted = false,
                difficulty = "normal",
                customSettings = mapOf(
                    "advanced_tools" to "true",
                    "sharing_enabled" to "true"
                )
            )
        }
    }
    
    private suspend fun unlockBasicStickerSets(childId: UUID, ageMonths: Int) {
        val basicSets = stickerSetRepo.findBasicSets(ageMonths)
        basicSets.forEach { set ->
            unlockStickerSet(childId, set.id)
        }
    }
    
    private fun createInitialProjectData(creationMode: String, templateData: String?): Map<String, Any> {
        return when (creationMode) {
            "infinite_canvas" -> mapOf(
                "canvas" to mapOf(
                    "id" to UUID.randomUUID().toString(),
                    "name" to "My Canvas",
                    "isInfinite" to true,
                    "stickers" to emptyList<Any>(),
                    "drawings" to emptyList<Any>(),
                    "texts" to emptyList<Any>(),
                    "zones" to emptyList<Any>(),
                    "background" to mapOf("id" to "default", "name" to "White")
                )
            )
            "flip_book" -> mapOf(
                "flipBook" to mapOf(
                    "id" to UUID.randomUUID().toString(),
                    "name" to "My Flip Book",
                    "pages" to emptyList<Any>(),
                    "currentPageIndex" to 0
                )
            )
            else -> emptyMap()
        }
    }
    
    private fun calculateTotalStickersUsed(projects: List<StickerBookProjectData>): Int {
        // Would implement logic to count unique stickers used across all projects
        return 0
    }
}

// =============================================================================
// DATA MODELS FOR REPOSITORIES
// =============================================================================

// These would be in separate repository files, but included here for completeness

data class StickerSetData(
    val id: UUID = UUID.randomUUID(),
    val name: String,
    val theme: String,
    val description: String,
    val stickerData: String, // JSON string
    val isPremium: Boolean = false,
    val minAgeMonths: Int,
    val maxAgeMonths: Int,
    val createdAt: kotlinx.datetime.Instant,
    val isActive: Boolean = true
)

data class ChildStickerCollectionData(
    val id: UUID = UUID.randomUUID(),
    val childId: UUID,
    val stickerSetId: UUID,
    val unlockedAt: kotlinx.datetime.Instant,
    val isFavorite: Boolean = false,
    val usageCount: Int = 0
)

data class StickerBookProjectData(
    val id: UUID = UUID.randomUUID(),
    val childGameInstanceId: UUID,
    val projectName: String,
    val description: String? = null,
    val creationMode: String,
    val projectData: String, // JSON string
    val thumbnailUrl: String? = null,
    val isCompleted: Boolean = false,
    val isShared: Boolean = false,
    val createdAt: kotlinx.datetime.Instant,
    val lastModified: kotlinx.datetime.Instant
)

data class StickerGameTemplateData(
    val id: UUID = UUID.randomUUID(),
    val title: String,
    val description: String,
    val backgroundImageUrl: String? = null,
    val stickerSetIds: String, // JSON array
    val targetAgeMin: Int,
    val targetAgeMax: Int,
    val difficultyLevel: Int,
    val templateData: String, // JSON string
    val createdAt: kotlinx.datetime.Instant,
    val isActive: Boolean = true
)

data class StickerProjectInteractionData(
    val id: UUID = UUID.randomUUID(),
    val projectId: UUID,
    val sessionId: UUID,
    val interactionType: String,
    val interactionData: String, // JSON string
    val timestamp: kotlinx.datetime.Instant
)

// =============================================================================
// REPOSITORY INTERFACES (simplified)
// =============================================================================

interface StickerSetRepository {
    suspend fun findById(id: UUID): StickerSetData?
    suspend fun findByTheme(theme: String, ageMonths: Int): List<StickerSetData>
    suspend fun findByAgeRange(ageMonths: Int): List<StickerSetData>
    suspend fun findBasicSets(ageMonths: Int): List<StickerSetData>
}

interface ChildStickerCollectionRepository {
    suspend fun findByChild(childId: UUID): List<ChildStickerCollectionData>
    suspend fun create(collection: ChildStickerCollectionData): ChildStickerCollectionData
}

interface StickerBookProjectRepository {
    suspend fun findById(id: UUID): StickerBookProjectData?
    suspend fun findByInstance(instanceId: UUID): List<StickerBookProjectData>
    suspend fun create(project: StickerBookProjectData): StickerBookProjectData
    suspend fun update(project: StickerBookProjectData): StickerBookProjectData
    suspend fun delete(id: UUID): Boolean
}

interface StickerGameTemplateRepository {
    suspend fun findById(id: UUID): StickerGameTemplateData?
    suspend fun findByAge(ageMonths: Int): List<StickerGameTemplateData>
    suspend fun findByAgeAndDifficulty(ageMonths: Int, difficulty: Int): List<StickerGameTemplateData>
}

interface StickerProjectInteractionRepository {
    suspend fun create(interaction: StickerProjectInteractionData): StickerProjectInteractionData
}