package com.wondernest.fixtures

import kotlinx.serialization.Serializable
import java.time.LocalDate
import java.util.*

/**
 * Test fixture data for family and children management
 */
object TestFamilies {
    
    // Family creation request data structures (these would normally be in the actual API)
    @Serializable
    data class FamilyCreateRequest(
        val name: String,
        val description: String? = null,
        val timezone: String = "UTC"
    )
    
    @Serializable
    data class FamilyUpdateRequest(
        val name: String? = null,
        val description: String? = null,
        val timezone: String? = null
    )
    
    @Serializable
    data class ChildCreateRequest(
        val familyId: String,
        val name: String,
        val birthDate: String, // ISO date format
        val gender: String? = null,
        val interests: List<String> = emptyList(),
        val avatarUrl: String? = null
    )
    
    @Serializable
    data class ChildUpdateRequest(
        val name: String? = null,
        val gender: String? = null,
        val interests: List<String>? = null,
        val avatarUrl: String? = null
    )
    
    // Valid family test data
    val validFamily = FamilyCreateRequest(
        name = "The Smith Family",
        description = "Our wonderful family",
        timezone = "America/New_York"
    )
    
    val minimalFamily = FamilyCreateRequest(
        name = "Minimal Family"
    )
    
    val internationalFamily = FamilyCreateRequest(
        name = "International Family",
        description = "A family across continents",
        timezone = "Europe/London"
    )
    
    val singleParentFamily = FamilyCreateRequest(
        name = "Single Parent Family",
        description = "Just me and my kids",
        timezone = "America/Los_Angeles"
    )
    
    val largeFamily = FamilyCreateRequest(
        name = "The Big Family",
        description = "We have lots of children and love it!",
        timezone = "America/Chicago"
    )
    
    // Invalid family test data
    val emptyNameFamily = FamilyCreateRequest(
        name = "",
        description = "Family with empty name"
    )
    
    val longNameFamily = FamilyCreateRequest(
        name = "A".repeat(500),
        description = "Family with very long name"
    )
    
    val longDescriptionFamily = FamilyCreateRequest(
        name = "Long Description Family",
        description = "B".repeat(2000)
    )
    
    val invalidTimezoneFamily = FamilyCreateRequest(
        name = "Invalid Timezone Family",
        description = "Testing invalid timezone",
        timezone = "Invalid/Timezone"
    )
    
    val sqlInjectionFamily = FamilyCreateRequest(
        name = "'; DROP TABLE families; --",
        description = "'; DELETE FROM families; --"
    )
    
    val xssFamily = FamilyCreateRequest(
        name = "<script>alert('xss')</script>",
        description = "<img src=x onerror=alert('xss')>"
    )
    
    // Valid child test data
    private fun createChildRequest(familyId: String, name: String, ageYears: Int) = ChildCreateRequest(
        familyId = familyId,
        name = name,
        birthDate = LocalDate.now().minusYears(ageYears.toLong()).toString(),
        gender = if (name.contains("boy") || name.contains("son")) "male" else "female",
        interests = when (ageYears) {
            in 2..4 -> listOf("stories", "songs", "animals")
            in 5..7 -> listOf("adventures", "learning", "games", "music")
            in 8..10 -> listOf("science", "history", "sports", "reading")
            else -> listOf("stories", "music")
        }
    )
    
    fun validChild(familyId: String) = createChildRequest(familyId, "Emma", 5)
    
    fun toddlerChild(familyId: String) = createChildRequest(familyId, "Little Tommy", 2)
    
    fun schoolAgeChild(familyId: String) = createChildRequest(familyId, "Sarah", 7)
    
    fun tweenChild(familyId: String) = createChildRequest(familyId, "Alex", 10)
    
    fun boyChild(familyId: String) = createChildRequest(familyId, "Baby boy Jake", 1)
    
    fun girlChild(familyId: String) = createChildRequest(familyId, "Princess Sophie", 4)
    
    fun childWithManyInterests(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Curious Charlie",
        birthDate = LocalDate.now().minusYears(6).toString(),
        gender = "male",
        interests = listOf(
            "stories", "music", "science", "animals", "sports", 
            "art", "cooking", "nature", "space", "dinosaurs"
        )
    )
    
    fun childWithNoInterests(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Simple Sam",
        birthDate = LocalDate.now().minusYears(3).toString(),
        gender = "male",
        interests = emptyList()
    )
    
    fun newbornChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Baby Grace",
        birthDate = LocalDate.now().minusMonths(6).toString(),
        gender = "female",
        interests = listOf("lullabies", "gentle music")
    )
    
    // Invalid child test data
    fun invalidFamilyIdChild() = ChildCreateRequest(
        familyId = "invalid-uuid",
        name = "Invalid Family Child",
        birthDate = LocalDate.now().minusYears(5).toString()
    )
    
    fun nonexistentFamilyChild() = ChildCreateRequest(
        familyId = UUID.randomUUID().toString(),
        name = "Nonexistent Family Child",
        birthDate = LocalDate.now().minusYears(5).toString()
    )
    
    fun emptyNameChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "",
        birthDate = LocalDate.now().minusYears(5).toString()
    )
    
    fun longNameChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "A".repeat(500),
        birthDate = LocalDate.now().minusYears(5).toString()
    )
    
    fun futureBirthDateChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Future Child",
        birthDate = LocalDate.now().plusYears(1).toString()
    )
    
    fun veryOldChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Very Old Child",
        birthDate = LocalDate.now().minusYears(25).toString()
    )
    
    fun invalidBirthDateChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Invalid Birth Date Child",
        birthDate = "not-a-date"
    )
    
    fun invalidGenderChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Invalid Gender Child",
        birthDate = LocalDate.now().minusYears(5).toString(),
        gender = "invalid-gender"
    )
    
    fun sqlInjectionChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "'; DROP TABLE children; --",
        birthDate = LocalDate.now().minusYears(5).toString(),
        interests = listOf("'; DELETE FROM children; --")
    )
    
    fun xssChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "<script>alert('xss')</script>",
        birthDate = LocalDate.now().minusYears(5).toString(),
        interests = listOf("<img src=x onerror=alert('xss')>")
    )
    
    // Unicode and special character test data
    fun unicodeChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "小明",
        birthDate = LocalDate.now().minusYears(5).toString(),
        gender = "male",
        interests = listOf("故事", "音乐")
    )
    
    fun emojiChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Happy Child 😊",
        birthDate = LocalDate.now().minusYears(4).toString(),
        interests = listOf("stories 📚", "music 🎵", "animals 🐶")
    )
    
    fun specialCharChild(familyId: String) = ChildCreateRequest(
        familyId = familyId,
        name = "Mary-Jane O'Connor",
        birthDate = LocalDate.now().minusYears(6).toString(),
        gender = "female",
        interests = listOf("reading & writing", "arts & crafts")
    )
    
    // Bulk test data generators
    fun generateMultipleChildren(familyId: String, count: Int): List<ChildCreateRequest> {
        return (1..count).map { index ->
            ChildCreateRequest(
                familyId = familyId,
                name = "Child $index",
                birthDate = LocalDate.now().minusYears((2..10).random().toLong()).toString(),
                gender = if (index % 2 == 0) "female" else "male",
                interests = listOf("stories", "music", "games").shuffled().take((1..3).random())
            )
        }
    }
    
    fun generateMultipleFamilies(count: Int): List<FamilyCreateRequest> {
        return (1..count).map { index ->
            FamilyCreateRequest(
                name = "Test Family $index",
                description = "This is test family number $index",
                timezone = listOf("UTC", "America/New_York", "Europe/London", "Asia/Tokyo").random()
            )
        }
    }
    
    // Update request test data
    fun validFamilyUpdate() = FamilyUpdateRequest(
        name = "Updated Family Name",
        description = "Updated family description",
        timezone = "America/Los_Angeles"
    )
    
    fun partialFamilyUpdate() = FamilyUpdateRequest(
        name = "Only Name Updated"
    )
    
    fun validChildUpdate() = ChildUpdateRequest(
        name = "Updated Child Name",
        gender = "female",
        interests = listOf("updated", "interests", "list")
    )
    
    fun partialChildUpdate() = ChildUpdateRequest(
        interests = listOf("only", "interests", "updated")
    )
    
    // Edge cases
    object EdgeCases {
        fun familyWithWhitespace() = FamilyCreateRequest(
            name = "   Family With Whitespace   ",
            description = "   Description with whitespace   "
        )
        
        fun childWithWhitespace(familyId: String) = ChildCreateRequest(
            familyId = familyId,
            name = "   Child With Whitespace   ",
            birthDate = LocalDate.now().minusYears(5).toString(),
            interests = listOf("   interest1   ", "   interest2   ")
        )
        
        fun familyWithOnlySpaces() = FamilyCreateRequest(
            name = "   ",
            description = "   "
        )
        
        fun childWithOnlySpaces(familyId: String) = ChildCreateRequest(
            familyId = familyId,
            name = "   ",
            birthDate = LocalDate.now().minusYears(5).toString()
        )
        
        fun familyWithSpecialChars() = FamilyCreateRequest(
            name = "Family!@#$%^&*()_+-={}[]|\\:;\"'<>?,./",
            description = "Description with all special chars !@#$%^&*()_+-={}[]|\\:;\"'<>?,./"
        )
        
        fun childWithAllValidInterests(familyId: String) = ChildCreateRequest(
            familyId = familyId,
            name = "Child With All Interests",
            birthDate = LocalDate.now().minusYears(5).toString(),
            interests = listOf(
                "stories", "music", "songs", "lullabies", "adventures", 
                "learning", "games", "science", "animals", "nature",
                "art", "cooking", "sports", "history", "space", "dinosaurs",
                "reading", "writing", "math", "languages"
            )
        )
        
        fun childAtMaxAge(familyId: String) = ChildCreateRequest(
            familyId = familyId,
            name = "Oldest Possible Child",
            birthDate = LocalDate.now().minusYears(18).toString()
        )
        
        fun childAtMinAge(familyId: String) = ChildCreateRequest(
            familyId = familyId,
            name = "Youngest Possible Child",
            birthDate = LocalDate.now().toString()
        )
    }
}