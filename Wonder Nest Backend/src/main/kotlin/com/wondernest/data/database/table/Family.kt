package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import org.jetbrains.exposed.sql.kotlin.datetime.date
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

@Serializable
data class FamilySettings(
    val maxScreenTimeMinutes: Int = 60,
    val bedtimeEnabled: Boolean = true,
    val educationalContentOnly: Boolean = false
)

@Serializable
data class ContentPreferences(
    val favoriteCategories: List<String> = emptyList(),
    val blockedCategories: List<String> = emptyList(),
    val preferredDurationMinutes: Int = 15,
    val difficultyLevel: String = "age_appropriate"
)

@Serializable
data class ThemePreferences(
    val primaryColor: String = "blue",
    val darkMode: Boolean = false,
    val animations: Boolean = true
)

object Families : UUIDTable("families") {
    val name = varchar("name", 200)
    val createdBy = reference("created_by", Users).nullable()
    
    // Family settings
    val timezone = varchar("timezone", 50).default("UTC")
    val language = varchar("language", 10).default("en")
    val familySettings = jsonb<FamilySettings>("family_settings",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(FamilySettings())
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}

object FamilyMembers : UUIDTable("family_members") {
    val familyId = reference("family_id", Families)
    val userId = reference("user_id", Users)
    val role = varchar("role", 50).default("parent")
    val permissions = jsonb<Map<String, Boolean>>("permissions",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyMap())
    
    val joinedAt = timestamp("joined_at").defaultExpression(CurrentTimestamp())
    val leftAt = timestamp("left_at").nullable()
    
    init {
        uniqueIndex(familyId, userId)
    }
}

object ChildProfiles : UUIDTable("child_profiles") {
    val familyId = reference("family_id", Families)
    
    // Basic information (minimal for privacy)
    val firstName = varchar("first_name", 100)
    val birthDate = date("birth_date")
    val gender = varchar("gender", 20).nullable()
    
    // Development information
    val primaryLanguage = varchar("primary_language", 10).default("en")
    val additionalLanguages = jsonb<List<String>>("additional_languages",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    
    // Interests and preferences (for content curation)
    val interests = jsonb<List<String>>("interests",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val favoriteCharacters = jsonb<List<String>>("favorite_characters",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val contentPreferences = jsonb<ContentPreferences>("content_preferences",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(ContentPreferences())
    
    // Special needs or development notes
    val specialNeeds = jsonb<List<String>>("special_needs",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable()
    val developmentNotes = text("development_notes").nullable()
    val receivesIntervention = bool("receives_intervention").default(false)
    val interventionType = varchar("intervention_type", 100).nullable()
    
    // Avatar and customization
    val avatarUrl = varchar("avatar_url", 500).nullable()
    val themePreferences = jsonb<ThemePreferences>("theme_preferences",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(ThemePreferences())
    
    // Privacy settings
    val dataSharingConsent = bool("data_sharing_consent").default(false)
    val researchParticipationConsent = bool("research_participation_consent").default(false)
    
    // Audit fields
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
    val archivedAt = timestamp("archived_at").nullable()
}