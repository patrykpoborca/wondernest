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
            it[timezone] = family.timezone
            it[language] = family.language
            it[familySettings] = com.wondernest.data.database.table.FamilySettings(
                maxScreenTimeMinutes = family.familySettings.maxScreenTimeMinutes,
                bedtimeEnabled = family.familySettings.bedtimeEnabled,
                educationalContentOnly = family.familySettings.educationalContentOnly
            )
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
                    createdBy = row[Families.createdBy]?.value,
                    timezone = row[Families.timezone],
                    language = row[Families.language],
                    familySettings = com.wondernest.domain.model.FamilySettings(
                        maxScreenTimeMinutes = row[Families.familySettings].maxScreenTimeMinutes,
                        bedtimeEnabled = row[Families.familySettings].bedtimeEnabled,
                        educationalContentOnly = row[Families.familySettings].educationalContentOnly
                    ),
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
                    createdBy = row[Families.createdBy]?.value,
                    timezone = row[Families.timezone],
                    language = row[Families.language],
                    familySettings = com.wondernest.domain.model.FamilySettings(
                        maxScreenTimeMinutes = row[Families.familySettings].maxScreenTimeMinutes,
                        bedtimeEnabled = row[Families.familySettings].bedtimeEnabled,
                        educationalContentOnly = row[Families.familySettings].educationalContentOnly
                    ),
                    createdAt = row[Families.createdAt],
                    updatedAt = row[Families.updatedAt]
                )
            }
    }

    override suspend fun updateFamily(family: Family): Family? = transaction {
        val updated = Families.update({ Families.id eq family.id }) {
            it[name] = family.name
            it[timezone] = family.timezone
            it[language] = family.language
            it[familySettings] = com.wondernest.data.database.table.FamilySettings(
                maxScreenTimeMinutes = family.familySettings.maxScreenTimeMinutes,
                bedtimeEnabled = family.familySettings.bedtimeEnabled,
                educationalContentOnly = family.familySettings.educationalContentOnly
            )
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
            it[permissions] = member.permissions
            it[joinedAt] = member.joinedAt
            it[leftAt] = member.leftAt
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
                    permissions = row[FamilyMembers.permissions],
                    joinedAt = row[FamilyMembers.joinedAt],
                    leftAt = row[FamilyMembers.leftAt]
                )
            }
    }

    override suspend fun removeFamilyMember(familyId: UUID, userId: UUID): Boolean = transaction {
        val updated = FamilyMembers.update(
            { (FamilyMembers.familyId eq familyId) and (FamilyMembers.userId eq userId) }
        ) {
            it[leftAt] = Clock.System.now()
        }
        
        if (updated > 0) {
            logger.info { "Removed family member: $userId from family $familyId" }
        }
        updated > 0
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
            it[firstName] = profile.name
            it[birthDate] = profile.birthDate.toLocalDateTime(TimeZone.UTC).date
            it[gender] = profile.gender
            it[primaryLanguage] = profile.primaryLanguage
            it[additionalLanguages] = profile.additionalLanguages
            it[interests] = profile.interests
            it[favoriteCharacters] = profile.favoriteCharacters
            it[contentPreferences] = com.wondernest.data.database.table.ContentPreferences(
                favoriteCategories = profile.interests,
                blockedCategories = profile.contentSettings.blockedCategories,
                preferredDurationMinutes = 15,
                difficultyLevel = "age_appropriate"
            )
            it[specialNeeds] = profile.specialNeeds
            it[developmentNotes] = profile.developmentNotes
            it[receivesIntervention] = profile.receivesIntervention
            it[interventionType] = profile.interventionType
            it[avatarUrl] = profile.avatarUrl
            it[themePreferences] = com.wondernest.data.database.table.ThemePreferences(
                primaryColor = profile.themePreferences.primaryColor,
                darkMode = profile.themePreferences.darkMode,
                animations = profile.themePreferences.animations
            )
            it[dataSharingConsent] = profile.dataSharingConsent
            it[researchParticipationConsent] = profile.researchParticipationConsent
            it[createdAt] = profile.createdAt
            it[updatedAt] = profile.updatedAt
            it[archivedAt] = profile.archivedAt
        }
        
        logger.info { "Created child profile: ${profile.name} (${profile.id})" }
        profile
    }

    override suspend fun getChildProfile(id: UUID): ChildProfile? = transaction {
        ChildProfiles.selectAll()
            .where { ChildProfiles.id eq id }
            .singleOrNull()
            ?.let { row ->
                val birthDate = row[ChildProfiles.birthDate] // This is already kotlinx.datetime.LocalDate
                val now = Clock.System.now().toLocalDateTime(TimeZone.UTC).date
                val age = Period.between(
                    java.time.LocalDate.of(birthDate.year, birthDate.monthNumber, birthDate.dayOfMonth),
                    java.time.LocalDate.of(now.year, now.monthNumber, now.dayOfMonth)
                ).years
                
                ChildProfile(
                    id = row[ChildProfiles.id].value,
                    familyId = row[ChildProfiles.familyId].value,
                    name = row[ChildProfiles.firstName],
                    age = age,
                    birthDate = birthDate.atStartOfDayIn(TimeZone.UTC),
                    gender = row[ChildProfiles.gender],
                    avatarUrl = row[ChildProfiles.avatarUrl],
                    primaryLanguage = row[ChildProfiles.primaryLanguage],
                    additionalLanguages = row[ChildProfiles.additionalLanguages],
                    interests = row[ChildProfiles.interests],
                    favoriteCharacters = row[ChildProfiles.favoriteCharacters],
                    contentSettings = ContentSettings(
                        maxAgeRating = age + 1, // Conservative age rating
                        blockedCategories = row[ChildProfiles.contentPreferences].blockedCategories,
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
                    specialNeeds = row[ChildProfiles.specialNeeds],
                    developmentNotes = row[ChildProfiles.developmentNotes],
                    receivesIntervention = row[ChildProfiles.receivesIntervention],
                    interventionType = row[ChildProfiles.interventionType],
                    themePreferences = com.wondernest.domain.model.ThemePreferences(
                        primaryColor = row[ChildProfiles.themePreferences].primaryColor,
                        darkMode = row[ChildProfiles.themePreferences].darkMode,
                        animations = row[ChildProfiles.themePreferences].animations
                    ),
                    dataSharingConsent = row[ChildProfiles.dataSharingConsent],
                    researchParticipationConsent = row[ChildProfiles.researchParticipationConsent],
                    createdAt = row[ChildProfiles.createdAt],
                    updatedAt = row[ChildProfiles.updatedAt],
                    archivedAt = row[ChildProfiles.archivedAt]
                )
            }
    }

    override suspend fun getChildrenByFamily(familyId: UUID): List<ChildProfile> = transaction {
        ChildProfiles.selectAll()
            .where { (ChildProfiles.familyId eq familyId) and ChildProfiles.archivedAt.isNull() }
            .map { row ->
                val birthDate = row[ChildProfiles.birthDate] // This is already kotlinx.datetime.LocalDate
                val now = Clock.System.now().toLocalDateTime(TimeZone.UTC).date
                val age = Period.between(
                    java.time.LocalDate.of(birthDate.year, birthDate.monthNumber, birthDate.dayOfMonth),
                    java.time.LocalDate.of(now.year, now.monthNumber, now.dayOfMonth)
                ).years
                
                ChildProfile(
                    id = row[ChildProfiles.id].value,
                    familyId = row[ChildProfiles.familyId].value,
                    name = row[ChildProfiles.firstName],
                    age = age,
                    birthDate = birthDate.atStartOfDayIn(TimeZone.UTC),
                    gender = row[ChildProfiles.gender],
                    avatarUrl = row[ChildProfiles.avatarUrl],
                    primaryLanguage = row[ChildProfiles.primaryLanguage],
                    additionalLanguages = row[ChildProfiles.additionalLanguages],
                    interests = row[ChildProfiles.interests],
                    favoriteCharacters = row[ChildProfiles.favoriteCharacters],
                    contentSettings = ContentSettings(
                        maxAgeRating = age + 1,
                        blockedCategories = row[ChildProfiles.contentPreferences].blockedCategories,
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
                    specialNeeds = row[ChildProfiles.specialNeeds],
                    developmentNotes = row[ChildProfiles.developmentNotes],
                    receivesIntervention = row[ChildProfiles.receivesIntervention],
                    interventionType = row[ChildProfiles.interventionType],
                    themePreferences = com.wondernest.domain.model.ThemePreferences(
                        primaryColor = row[ChildProfiles.themePreferences].primaryColor,
                        darkMode = row[ChildProfiles.themePreferences].darkMode,
                        animations = row[ChildProfiles.themePreferences].animations
                    ),
                    dataSharingConsent = row[ChildProfiles.dataSharingConsent],
                    researchParticipationConsent = row[ChildProfiles.researchParticipationConsent],
                    createdAt = row[ChildProfiles.createdAt],
                    updatedAt = row[ChildProfiles.updatedAt],
                    archivedAt = row[ChildProfiles.archivedAt]
                )
            }
    }

    override suspend fun updateChildProfile(profile: ChildProfile): ChildProfile? = transaction {
        val updated = ChildProfiles.update({ ChildProfiles.id eq profile.id }) {
            it[firstName] = profile.name
            it[gender] = profile.gender
            it[primaryLanguage] = profile.primaryLanguage
            it[additionalLanguages] = profile.additionalLanguages
            it[interests] = profile.interests
            it[favoriteCharacters] = profile.favoriteCharacters
            it[contentPreferences] = com.wondernest.data.database.table.ContentPreferences(
                favoriteCategories = profile.interests,
                blockedCategories = profile.contentSettings.blockedCategories
            )
            it[specialNeeds] = profile.specialNeeds
            it[developmentNotes] = profile.developmentNotes
            it[receivesIntervention] = profile.receivesIntervention
            it[interventionType] = profile.interventionType
            it[avatarUrl] = profile.avatarUrl
            it[themePreferences] = com.wondernest.data.database.table.ThemePreferences(
                primaryColor = profile.themePreferences.primaryColor,
                darkMode = profile.themePreferences.darkMode,
                animations = profile.themePreferences.animations
            )
            it[dataSharingConsent] = profile.dataSharingConsent
            it[researchParticipationConsent] = profile.researchParticipationConsent
            it[updatedAt] = Clock.System.now()
        }
        
        if (updated > 0) {
            logger.info { "Updated child profile: ${profile.name} (${profile.id})" }
            profile.copy(updatedAt = Clock.System.now())
        } else null
    }

    override suspend fun archiveChildProfile(id: UUID): Boolean = transaction {
        val updated = ChildProfiles.update({ ChildProfiles.id eq id }) {
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