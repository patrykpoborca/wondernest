package com.wondernest.data.database.repository

import com.wondernest.data.database.table.*
import com.wondernest.domain.model.*
import com.wondernest.domain.repository.FamilyRepository
import kotlinx.datetime.*
import mu.KotlinLogging
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.Period
import java.util.UUID

private val logger = KotlinLogging.logger {}

class FamilyRepositoryImpl : FamilyRepository {

    override suspend fun createFamily(family: Family): Family = transaction {
        val familyId = Families.insertAndGetId {
            it[id] = family.id
            it[name] = family.name
            it[createdBy] = family.createdBy
            it[createdAt] = family.createdAt
            it[updatedAt] = family.updatedAt
        }
        
        logger.info { "Created family: ${family.name} (${familyId.value})" }
        family
    }

    override suspend fun getFamilyById(id: UUID): Family? = transaction {
        Families.selectAll()
            .where { Families.id eq id }
            .singleOrNull()
            ?.let { row ->
                Family(
                    id = row[Families.id].value,
                    name = row[Families.name],
                    createdBy = row[Families.createdBy].value,
                    timezone = "UTC", // Default values since not stored in this table
                    language = "en",
                    familySettings = com.wondernest.domain.model.FamilySettings(), // Default settings
                    createdAt = row[Families.createdAt],
                    updatedAt = row[Families.updatedAt]
                )
            }
    }

    override suspend fun getFamilyByUserId(userId: UUID): Family? = transaction {
        (Families innerJoin FamilyMembers)
            .selectAll()
            .where { FamilyMembers.userId eq userId }
            .singleOrNull()
            ?.let { row ->
                Family(
                    id = row[Families.id].value,
                    name = row[Families.name],
                    createdBy = row[Families.createdBy].value,
                    timezone = "UTC", // Default values since not stored in this table
                    language = "en",
                    familySettings = com.wondernest.domain.model.FamilySettings(), // Default settings
                    createdAt = row[Families.createdAt],
                    updatedAt = row[Families.updatedAt]
                )
            }
    }

    override suspend fun updateFamily(family: Family): Family? = transaction {
        val updated = Families.update({ Families.id eq family.id }) {
            it[name] = family.name
            it[updatedAt] = Clock.System.now()
        }
        
        if (updated > 0) {
            logger.info { "Updated family: ${family.name} (${family.id})" }
            family.copy(updatedAt = Clock.System.now())
        } else null
    }

    override suspend fun deleteFamily(id: UUID): Boolean = transaction {
        val deleted = Families.deleteWhere { Families.id eq id }
        if (deleted > 0) {
            logger.info { "Deleted family: $id" }
        }
        deleted > 0
    }

    override suspend fun addFamilyMember(member: FamilyMember): FamilyMember = transaction {
        FamilyMembers.insert {
            it[id] = member.id
            it[familyId] = member.familyId
            it[userId] = member.userId
            it[role] = member.role
            it[joinedAt] = member.joinedAt
        }
        
        logger.info { "Added family member: ${member.userId} to family ${member.familyId}" }
        member
    }

    override suspend fun getFamilyMembers(familyId: UUID): List<FamilyMember> = transaction {
        FamilyMembers.selectAll()
            .where { FamilyMembers.familyId eq familyId }
            .map { row ->
                FamilyMember(
                    id = row[FamilyMembers.id].value,
                    familyId = row[FamilyMembers.familyId].value,
                    userId = row[FamilyMembers.userId].value,
                    role = row[FamilyMembers.role],
                    permissions = emptyMap(), // Default since not stored in simplified table
                    joinedAt = row[FamilyMembers.joinedAt],
                    leftAt = null // Not supported in simplified table
                )
            }
    }

    override suspend fun removeFamilyMember(familyId: UUID, userId: UUID): Boolean = transaction {
        val deleted = FamilyMembers.deleteWhere { 
            (FamilyMembers.familyId eq familyId) and (FamilyMembers.userId eq userId) 
        }
        
        if (deleted > 0) {
            logger.info { "Removed family member: $userId from family $familyId" }
        }
        deleted > 0
    }

    override suspend fun updateFamilyMemberRole(familyId: UUID, userId: UUID, role: String): Boolean = transaction {
        val updated = FamilyMembers.update(
            { (FamilyMembers.familyId eq familyId) and (FamilyMembers.userId eq userId) }
        ) {
            it[FamilyMembers.role] = role
        }
        
        if (updated > 0) {
            logger.info { "Updated family member role: $userId in family $familyId to $role" }
        }
        updated > 0
    }

    override suspend fun createChildProfile(profile: ChildProfile): ChildProfile = transaction {
        ChildProfiles.insert {
            it[id] = profile.id
            it[familyId] = profile.familyId
            it[name] = profile.name
            it[nickname] = null // Can be set later via updates
            it[birthDate] = profile.birthDate.toLocalDateTime(TimeZone.UTC).date
            it[gender] = profile.gender
            it[avatarUrl] = profile.avatarUrl
            it[interests] = null // Skip interests for now to test basic insertion
            it[favoriteColors] = null // Default empty, can be set later
            it[isActive] = true
            it[createdAt] = profile.createdAt
            it[updatedAt] = profile.updatedAt
            it[archivedAt] = profile.archivedAt
        }
        
        logger.info { "Created child profile: ${profile.name} (${profile.id})" }
        profile
    }

    override suspend fun getChildProfile(id: UUID): ChildProfile? = transaction {
        ChildProfiles.selectAll()
            .where { (ChildProfiles.id eq id) and (ChildProfiles.isActive eq true) }
            .singleOrNull()
            ?.let { row ->
                val birthDate = row[ChildProfiles.birthDate] // This is already kotlinx.datetime.LocalDate
                val now = Clock.System.now().toLocalDateTime(TimeZone.UTC).date
                val age = Period.between(
                    java.time.LocalDate.of(birthDate.year, birthDate.monthNumber, birthDate.dayOfMonth),
                    java.time.LocalDate.of(now.year, now.monthNumber, now.dayOfMonth)
                ).years
                
                val interests = row[ChildProfiles.interests]?.let { 
                    if (it.startsWith("{") && it.endsWith("}")) {
                        it.substring(1, it.length - 1).split(",").filter { item -> item.isNotBlank() }
                    } else {
                        it.split(",").filter { item -> item.isNotBlank() }
                    }
                } ?: emptyList()
                
                ChildProfile(
                    id = row[ChildProfiles.id].value,
                    familyId = row[ChildProfiles.familyId].value,
                    name = row[ChildProfiles.name],
                    age = age,
                    birthDate = birthDate.atStartOfDayIn(TimeZone.UTC),
                    gender = row[ChildProfiles.gender],
                    avatarUrl = row[ChildProfiles.avatarUrl],
                    primaryLanguage = "en", // Default since not stored in simplified table
                    additionalLanguages = emptyList(), // Default since not stored in simplified table
                    interests = interests,
                    favoriteCharacters = emptyList(), // Default since not stored in simplified table
                    contentSettings = ContentSettings(
                        maxAgeRating = age + 1, // Conservative age rating
                        blockedCategories = emptyList(), // Default
                        allowedDomains = emptyList(),
                        subtitlesEnabled = false,
                        audioMonitoringEnabled = false,
                        educationalContentOnly = false
                    ),
                    timeRestrictions = TimeRestrictions(
                        dailyScreenTimeMinutes = 60,
                        bedtimeEnabled = true,
                        bedtimeStart = if (age < 8) "19:00" else "20:00",
                        bedtimeEnd = if (age < 8) "07:00" else "07:30"
                    ),
                    specialNeeds = emptyList(), // Default since not stored in simplified table
                    developmentNotes = null, // Default since not stored in simplified table
                    receivesIntervention = false, // Default since not stored in simplified table
                    interventionType = null, // Default since not stored in simplified table
                    themePreferences = com.wondernest.domain.model.ThemePreferences(
                        primaryColor = "blue",
                        darkMode = false,
                        animations = true
                    ),
                    dataSharingConsent = false, // Default since not stored in simplified table
                    researchParticipationConsent = false, // Default since not stored in simplified table
                    createdAt = row[ChildProfiles.createdAt],
                    updatedAt = row[ChildProfiles.updatedAt],
                    archivedAt = row[ChildProfiles.archivedAt]
                )
            }
    }

    override suspend fun getChildrenByFamily(familyId: UUID): List<ChildProfile> = transaction {
        ChildProfiles.selectAll()
            .where { (ChildProfiles.familyId eq familyId) and (ChildProfiles.isActive eq true) and ChildProfiles.archivedAt.isNull() }
            .map { row ->
                val birthDate = row[ChildProfiles.birthDate] // This is already kotlinx.datetime.LocalDate
                val now = Clock.System.now().toLocalDateTime(TimeZone.UTC).date
                val age = Period.between(
                    java.time.LocalDate.of(birthDate.year, birthDate.monthNumber, birthDate.dayOfMonth),
                    java.time.LocalDate.of(now.year, now.monthNumber, now.dayOfMonth)
                ).years
                
                val interests = row[ChildProfiles.interests]?.let { 
                    if (it.startsWith("{") && it.endsWith("}")) {
                        it.substring(1, it.length - 1).split(",").filter { item -> item.isNotBlank() }
                    } else {
                        it.split(",").filter { item -> item.isNotBlank() }
                    }
                } ?: emptyList()
                
                ChildProfile(
                    id = row[ChildProfiles.id].value,
                    familyId = row[ChildProfiles.familyId].value,
                    name = row[ChildProfiles.name],
                    age = age,
                    birthDate = birthDate.atStartOfDayIn(TimeZone.UTC),
                    gender = row[ChildProfiles.gender],
                    avatarUrl = row[ChildProfiles.avatarUrl],
                    primaryLanguage = "en", // Default since not stored in simplified table
                    additionalLanguages = emptyList(), // Default since not stored in simplified table
                    interests = interests,
                    favoriteCharacters = emptyList(), // Default since not stored in simplified table
                    contentSettings = ContentSettings(
                        maxAgeRating = age + 1,
                        blockedCategories = emptyList(), // Default
                        allowedDomains = emptyList(),
                        subtitlesEnabled = false,
                        audioMonitoringEnabled = false,
                        educationalContentOnly = false
                    ),
                    timeRestrictions = TimeRestrictions(
                        dailyScreenTimeMinutes = 60,
                        bedtimeEnabled = true,
                        bedtimeStart = if (age < 8) "19:00" else "20:00",
                        bedtimeEnd = if (age < 8) "07:00" else "07:30"
                    ),
                    specialNeeds = emptyList(), // Default since not stored in simplified table
                    developmentNotes = null, // Default since not stored in simplified table
                    receivesIntervention = false, // Default since not stored in simplified table
                    interventionType = null, // Default since not stored in simplified table
                    themePreferences = com.wondernest.domain.model.ThemePreferences(
                        primaryColor = "blue",
                        darkMode = false,
                        animations = true
                    ),
                    dataSharingConsent = false, // Default since not stored in simplified table
                    researchParticipationConsent = false, // Default since not stored in simplified table
                    createdAt = row[ChildProfiles.createdAt],
                    updatedAt = row[ChildProfiles.updatedAt],
                    archivedAt = row[ChildProfiles.archivedAt]
                )
            }
    }

    override suspend fun updateChildProfile(profile: ChildProfile): ChildProfile? = transaction {
        val updated = ChildProfiles.update({ ChildProfiles.id eq profile.id }) {
            it[name] = profile.name
            it[gender] = profile.gender
            it[avatarUrl] = profile.avatarUrl
            it[interests] = null // Skip interests for now to test basic insertion
            it[updatedAt] = Clock.System.now()
        }
        
        if (updated > 0) {
            logger.info { "Updated child profile: ${profile.name} (${profile.id})" }
            profile.copy(updatedAt = Clock.System.now())
        } else null
    }

    override suspend fun archiveChildProfile(id: UUID): Boolean = transaction {
        val updated = ChildProfiles.update({ ChildProfiles.id eq id }) {
            it[isActive] = false
            it[archivedAt] = Clock.System.now()
        }
        
        if (updated > 0) {
            logger.info { "Archived child profile: $id" }
        }
        updated > 0
    }

    override suspend fun deleteChildProfile(id: UUID): Boolean = transaction {
        val deleted = ChildProfiles.deleteWhere { ChildProfiles.id eq id }
        if (deleted > 0) {
            logger.info { "Deleted child profile: $id" }
        }
        deleted > 0
    }
}