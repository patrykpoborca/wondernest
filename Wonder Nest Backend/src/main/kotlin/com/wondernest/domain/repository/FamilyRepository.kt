package com.wondernest.domain.repository

import com.wondernest.domain.model.Family
import com.wondernest.domain.model.FamilyMember
import com.wondernest.domain.model.ChildProfile
import java.util.UUID

interface FamilyRepository {
    suspend fun createFamily(family: Family): Family
    suspend fun getFamilyById(id: UUID): Family?
    suspend fun getFamilyByUserId(userId: UUID): Family?
    suspend fun updateFamily(family: Family): Family?
    suspend fun deleteFamily(id: UUID): Boolean
    
    // Family member management
    suspend fun addFamilyMember(member: FamilyMember): FamilyMember
    suspend fun getFamilyMembers(familyId: UUID): List<FamilyMember>
    suspend fun removeFamilyMember(familyId: UUID, userId: UUID): Boolean
    suspend fun updateFamilyMemberRole(familyId: UUID, userId: UUID, role: String): Boolean
    
    // Child profile management
    suspend fun createChildProfile(profile: ChildProfile): ChildProfile
    suspend fun getChildProfile(id: UUID): ChildProfile?
    suspend fun getChildrenByFamily(familyId: UUID): List<ChildProfile>
    suspend fun updateChildProfile(profile: ChildProfile): ChildProfile?
    suspend fun archiveChildProfile(id: UUID): Boolean
    suspend fun deleteChildProfile(id: UUID): Boolean
}