package com.wondernest.services.family

import com.wondernest.domain.model.*
import com.wondernest.domain.repository.FamilyRepository
import kotlinx.datetime.*
import kotlinx.serialization.Serializable
import mu.KotlinLogging
import java.util.UUID

private val logger = KotlinLogging.logger {}

@Serializable
data class CreateChildRequest(
    val name: String,
    val birthDate: String, // ISO date string like "2020-01-15"
    val gender: String? = null,
    val avatarUrl: String? = null,
    val interests: List<String> = emptyList()
)

@Serializable
data class UpdateChildRequest(
    val name: String? = null,
    val gender: String? = null,
    val avatarUrl: String? = null,
    val interests: List<String>? = null,
    val contentSettings: ContentSettings? = null,
    val timeRestrictions: TimeRestrictions? = null
)

@Serializable
data class FamilyProfileResponse(
    val family: Family,
    val members: List<FamilyMember>,
    val children: List<ChildProfile>
)

class FamilyService(
    private val familyRepository: FamilyRepository
) {

    suspend fun getFamilyProfile(familyId: UUID): FamilyProfileResponse? {
        val family = familyRepository.getFamilyById(familyId) ?: return null
        val members = familyRepository.getFamilyMembers(familyId)
        val children = familyRepository.getChildrenByFamily(familyId)
        
        logger.info { "Retrieved family profile for family: $familyId" }
        
        return FamilyProfileResponse(
            family = family,
            members = members,
            children = children
        )
    }

    suspend fun getChildren(familyId: UUID): List<ChildProfile> {
        val children = familyRepository.getChildrenByFamily(familyId)
        logger.info { "Retrieved ${children.size} children for family: $familyId" }
        return children
    }

    suspend fun createChild(familyId: UUID, request: CreateChildRequest): ChildProfile {
        val now = Clock.System.now()
        
        // Parse birth date
        val birthDate = try {
            LocalDate.parse(request.birthDate).atStartOfDayIn(TimeZone.UTC)
        } catch (e: Exception) {
            throw IllegalArgumentException("Invalid birth date format. Use YYYY-MM-DD")
        }

        // Calculate age
        val birthLocalDate = birthDate.toLocalDateTime(TimeZone.UTC).date
        val nowLocalDate = now.toLocalDateTime(TimeZone.UTC).date
        val age = nowLocalDate.year - birthLocalDate.year - 
            if (nowLocalDate.dayOfYear < birthLocalDate.dayOfYear) 1 else 0

        // Validate age (COPPA compliance - children must be under 13 for this flow)
        if (age >= 13) {
            // TODO: COPPA - For children 13+, additional verification steps are required
            logger.warn { "Creating child profile for age $age - COPPA verification required for 13+" }
        }

        val childProfile = ChildProfile(
            id = UUID.randomUUID(),
            familyId = familyId,
            name = request.name.trim(),
            age = age,
            birthDate = birthDate,
            gender = request.gender?.trim(),
            avatarUrl = request.avatarUrl?.trim(),
            interests = request.interests,
            contentSettings = ContentSettings(
                maxAgeRating = minOf(age + 2, 18), // Conservative age rating
                blockedCategories = if (age < 8) listOf("horror", "violence", "mature") else emptyList(),
                subtitlesEnabled = false,
                audioMonitoringEnabled = true, // Default to enabled for safety
                educationalContentOnly = age < 6 // Educational only for very young children
            ),
            timeRestrictions = TimeRestrictions(
                dailyScreenTimeMinutes = when {
                    age < 6 -> 30
                    age < 10 -> 60
                    else -> 90
                },
                bedtimeEnabled = true,
                bedtimeStart = when {
                    age < 6 -> "18:30"
                    age < 10 -> "19:30"
                    else -> "20:30"
                },
                bedtimeEnd = when {
                    age < 6 -> "07:00"
                    age < 10 -> "07:00"
                    else -> "07:30"
                }
            ),
            themePreferences = ThemePreferences(),
            createdAt = now,
            updatedAt = now
        )

        val created = familyRepository.createChildProfile(childProfile)
        logger.info { "Created child profile: ${request.name} (${created.id}) for family: $familyId" }
        return created
    }

    suspend fun updateChild(childId: UUID, request: UpdateChildRequest): ChildProfile? {
        val existingChild = familyRepository.getChildProfile(childId) 
            ?: throw IllegalArgumentException("Child profile not found")
        
        val updatedChild = existingChild.copy(
            name = request.name?.trim() ?: existingChild.name,
            gender = request.gender?.trim() ?: existingChild.gender,
            avatarUrl = request.avatarUrl?.trim() ?: existingChild.avatarUrl,
            interests = request.interests ?: existingChild.interests,
            contentSettings = request.contentSettings ?: existingChild.contentSettings,
            timeRestrictions = request.timeRestrictions ?: existingChild.timeRestrictions,
            updatedAt = Clock.System.now()
        )

        val updated = familyRepository.updateChildProfile(updatedChild)
        if (updated != null) {
            logger.info { "Updated child profile: ${updatedChild.name} (${childId})" }
        }
        return updated
    }

    suspend fun deleteChild(childId: UUID): Boolean {
        // Soft delete by archiving
        val archived = familyRepository.archiveChildProfile(childId)
        if (archived) {
            logger.info { "Archived child profile: $childId" }
        }
        return archived
    }

    suspend fun getChildProfile(childId: UUID): ChildProfile? {
        return familyRepository.getChildProfile(childId)
    }

    suspend fun updateFamilySettings(familyId: UUID, settings: FamilySettings): Family? {
        val family = familyRepository.getFamilyById(familyId) ?: return null
        val updatedFamily = family.copy(
            familySettings = settings,
            updatedAt = Clock.System.now()
        )
        
        val updated = familyRepository.updateFamily(updatedFamily)
        if (updated != null) {
            logger.info { "Updated family settings for family: $familyId" }
        }
        return updated
    }
}