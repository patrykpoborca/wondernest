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

object Families : UUIDTable("family.families") {
    val name = varchar("name", 100)
    val createdBy = reference("created_by", Users)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}

object FamilyMembers : UUIDTable("family.family_members") {
    val familyId = reference("family_id", Families)
    val userId = reference("user_id", Users)
    val role = varchar("role", 20).default("member")
    val joinedAt = timestamp("joined_at").defaultExpression(CurrentTimestamp())
}

object ChildProfiles : UUIDTable("family.child_profiles") {
    val familyId = reference("family_id", Families)
    val name = varchar("name", 100)
    val nickname = varchar("nickname", 50).nullable()
    val birthDate = date("birth_date")
    val gender = varchar("gender", 20).nullable()
    val avatarUrl = text("avatar_url").nullable()
    val interests = text("interests").nullable() // Store as JSON string
    val favoriteColors = text("favorite_colors").nullable() // Store as JSON string
    val isActive = bool("is_active").default(true)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
    val archivedAt = timestamp("archived_at").nullable()
}