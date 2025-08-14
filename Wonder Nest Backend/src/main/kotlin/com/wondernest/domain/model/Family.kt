package com.wondernest.domain.model

import kotlinx.datetime.Instant
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class Family(
    @Contextual val id: UUID,
    val name: String,
    @Contextual val createdBy: UUID?,
    val timezone: String = "UTC",
    val language: String = "en",
    val familySettings: FamilySettings,
    val createdAt: Instant,
    val updatedAt: Instant
)

@Serializable
data class FamilySettings(
    val maxScreenTimeMinutes: Int = 60,
    val bedtimeEnabled: Boolean = true,
    val educationalContentOnly: Boolean = false
)

@Serializable
data class FamilyMember(
    @Contextual val id: UUID,
    @Contextual val familyId: UUID,
    @Contextual val userId: UUID,
    val role: String = "parent", // parent, guardian
    val permissions: Map<String, Boolean> = emptyMap(),
    val joinedAt: Instant,
    val leftAt: Instant? = null
)

@Serializable
data class ChildProfile(
    @Contextual val id: UUID,
    @Contextual val familyId: UUID,
    val name: String, // Using firstName for simplicity to match Flutter model
    val age: Int, // Calculated from birthDate
    val birthDate: Instant,
    val gender: String? = null,
    val avatarUrl: String? = null,
    val primaryLanguage: String = "en",
    val additionalLanguages: List<String> = emptyList(),
    val interests: List<String> = emptyList(),
    val favoriteCharacters: List<String> = emptyList(),
    val contentSettings: ContentSettings,
    val timeRestrictions: TimeRestrictions,
    val specialNeeds: List<String>? = null,
    val developmentNotes: String? = null,
    val receivesIntervention: Boolean = false,
    val interventionType: String? = null,
    val themePreferences: ThemePreferences,
    val dataSharingConsent: Boolean = false,
    val researchParticipationConsent: Boolean = false,
    val createdAt: Instant,
    val updatedAt: Instant,
    val archivedAt: Instant? = null
)

@Serializable
data class ContentSettings(
    val maxAgeRating: Int,
    val blockedCategories: List<String> = emptyList(),
    val allowedDomains: List<String> = emptyList(),
    val subtitlesEnabled: Boolean = false,
    val audioMonitoringEnabled: Boolean = false,
    val educationalContentOnly: Boolean = false
)

@Serializable
data class TimeRestrictions(
    val weekdayLimits: Map<String, TimeSlot> = emptyMap(),
    val weekendLimits: Map<String, TimeSlot> = emptyMap(),
    val dailyScreenTimeMinutes: Int = 60,
    val bedtimeEnabled: Boolean = true,
    val bedtimeStart: String? = null,
    val bedtimeEnd: String? = null
)

@Serializable
data class TimeSlot(
    val startTime: String,
    val endTime: String,
    val maxMinutes: Int
)

@Serializable
data class ThemePreferences(
    val primaryColor: String = "blue",
    val darkMode: Boolean = false,
    val animations: Boolean = true
)

@Serializable
data class ContentPreferences(
    val favoriteCategories: List<String> = emptyList(),
    val blockedCategories: List<String> = emptyList(),
    val preferredDurationMinutes: Int = 15,
    val difficultyLevel: String = "age_appropriate"
)