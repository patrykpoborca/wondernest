package com.wondernest.utils

import kotlinx.serialization.Serializable
import java.util.*
import java.util.regex.Pattern

/**
 * Validation utilities for request data
 */
object ValidationUtils {
    
    // Email validation pattern - more comprehensive than simple contains check
    private val EMAIL_PATTERN = Pattern.compile(
        "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    )
    
    // Password validation patterns
    private val PASSWORD_LOWERCASE = Pattern.compile(".*[a-z].*")
    private val PASSWORD_UPPERCASE = Pattern.compile(".*[A-Z].*")
    private val PASSWORD_DIGIT = Pattern.compile(".*\\d.*")
    private val PASSWORD_SPECIAL = Pattern.compile(".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?].*")
    
    /**
     * Validates email format
     */
    fun isValidEmail(email: String?): Boolean {
        if (email.isNullOrBlank()) return false
        return EMAIL_PATTERN.matcher(email.trim()).matches()
    }
    
    /**
     * Validates password strength
     */
    fun validatePassword(password: String?): ValidationResult {
        if (password.isNullOrBlank()) {
            return ValidationResult.failure("Password is required")
        }
        
        val errors = mutableListOf<String>()
        
        if (password.length < 8) {
            errors.add("Password must be at least 8 characters long")
        }
        
        if (password.length > 128) {
            errors.add("Password must not exceed 128 characters")
        }
        
        if (!PASSWORD_LOWERCASE.matcher(password).matches()) {
            errors.add("Password must contain at least one lowercase letter")
        }
        
        if (!PASSWORD_UPPERCASE.matcher(password).matches()) {
            errors.add("Password must contain at least one uppercase letter")
        }
        
        if (!PASSWORD_DIGIT.matcher(password).matches()) {
            errors.add("Password must contain at least one digit")
        }
        
        // Special characters are recommended but not required for better user experience
        // if (!PASSWORD_SPECIAL.matcher(password).matches()) {
        //     errors.add("Password must contain at least one special character")
        // }
        
        // Check for common weak passwords
        val commonPasswords = setOf(
            "password", "123456", "123456789", "12345678", "12345", "1234567",
            "password123", "admin", "qwerty", "abc123", "Password123"
        )
        
        if (commonPasswords.contains(password.lowercase())) {
            errors.add("Password is too common")
        }
        
        return if (errors.isEmpty()) {
            ValidationResult.success()
        } else {
            ValidationResult.failure(errors.joinToString(", "))
        }
    }
    
    /**
     * Validates UUID format
     */
    fun isValidUUID(uuid: String?): Boolean {
        if (uuid.isNullOrBlank()) return false
        return try {
            UUID.fromString(uuid.trim())
            true
        } catch (e: IllegalArgumentException) {
            false
        }
    }
    
    /**
     * Validates string length within bounds
     */
    fun validateStringLength(
        value: String?,
        fieldName: String,
        minLength: Int = 0,
        maxLength: Int = Int.MAX_VALUE,
        required: Boolean = true
    ): ValidationResult {
        if (value.isNullOrBlank()) {
            return if (required) {
                ValidationResult.failure("$fieldName is required")
            } else {
                ValidationResult.success()
            }
        }
        
        val trimmedValue = value.trim()
        
        if (trimmedValue.length < minLength) {
            return ValidationResult.failure("$fieldName must be at least $minLength characters long")
        }
        
        if (trimmedValue.length > maxLength) {
            return ValidationResult.failure("$fieldName must not exceed $maxLength characters")
        }
        
        return ValidationResult.success()
    }
    
    /**
     * Validates timezone string
     */
    fun isValidTimezone(timezone: String?): Boolean {
        if (timezone.isNullOrBlank()) return false
        return try {
            java.time.ZoneId.of(timezone.trim())
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Validates language code (ISO 639-1)
     */
    fun isValidLanguageCode(language: String?): Boolean {
        if (language.isNullOrBlank()) return false
        val validLanguages = setOf(
            "en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh",
            "ar", "hi", "nl", "sv", "da", "no", "fi", "pl", "tr", "he"
        )
        return validLanguages.contains(language.trim().lowercase())
    }
    
    /**
     * Validates date string format (ISO 8601: YYYY-MM-DD)
     */
    fun isValidDateString(dateString: String?): Boolean {
        if (dateString.isNullOrBlank()) return false
        return try {
            java.time.LocalDate.parse(dateString.trim())
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Validates that a birth date is reasonable (not in the future, not too old)
     */
    fun validateBirthDate(birthDate: String?): ValidationResult {
        if (birthDate.isNullOrBlank()) {
            return ValidationResult.failure("Birth date is required")
        }
        
        if (!isValidDateString(birthDate)) {
            return ValidationResult.failure("Birth date must be in YYYY-MM-DD format")
        }
        
        val date = java.time.LocalDate.parse(birthDate.trim())
        val today = java.time.LocalDate.now()
        
        if (date.isAfter(today)) {
            return ValidationResult.failure("Birth date cannot be in the future")
        }
        
        if (date.isBefore(today.minusYears(150))) {
            return ValidationResult.failure("Birth date cannot be more than 150 years ago")
        }
        
        return ValidationResult.success()
    }
    
    /**
     * Validates child age is within reasonable bounds
     */
    fun validateChildAge(birthDate: String?): ValidationResult {
        val birthDateValidation = validateBirthDate(birthDate)
        if (!birthDateValidation.isValid) {
            return birthDateValidation
        }
        
        val date = java.time.LocalDate.parse(birthDate!!.trim())
        val today = java.time.LocalDate.now()
        val age = java.time.Period.between(date, today).years
        
        if (age > 18) {
            return ValidationResult.failure("Child must be 18 years old or younger")
        }
        
        return ValidationResult.success()
    }
    
    /**
     * Validates gender value
     */
    fun validateGender(gender: String?): ValidationResult {
        if (gender.isNullOrBlank()) {
            return ValidationResult.success() // Gender is optional
        }
        
        val validGenders = setOf("male", "female", "other", "prefer_not_to_say")
        return if (validGenders.contains(gender.trim().lowercase())) {
            ValidationResult.success()
        } else {
            ValidationResult.failure("Gender must be one of: ${validGenders.joinToString(", ")}")
        }
    }
    
    /**
     * Validates interest list
     */
    fun validateInterests(interests: List<String>?): ValidationResult {
        if (interests.isNullOrEmpty()) {
            return ValidationResult.success() // Interests are optional
        }
        
        if (interests.size > 20) {
            return ValidationResult.failure("Cannot have more than 20 interests")
        }
        
        val validInterests = setOf(
            "stories", "music", "songs", "lullabies", "adventures", "learning",
            "games", "science", "animals", "nature", "art", "cooking", "sports",
            "history", "space", "dinosaurs", "reading", "writing", "math", "languages"
        )
        
        val invalidInterests = interests.filterNot { interest ->
            validInterests.contains(interest.trim().lowercase())
        }
        
        return if (invalidInterests.isEmpty()) {
            ValidationResult.success()
        } else {
            ValidationResult.failure("Invalid interests: ${invalidInterests.joinToString(", ")}")
        }
    }
    
    /**
     * Validates numeric range
     */
    fun validateNumericRange(
        value: Number?,
        fieldName: String,
        min: Number? = null,
        max: Number? = null,
        required: Boolean = true
    ): ValidationResult {
        if (value == null) {
            return if (required) {
                ValidationResult.failure("$fieldName is required")
            } else {
                ValidationResult.success()
            }
        }
        
        val doubleValue = value.toDouble()
        
        if (min != null && doubleValue < min.toDouble()) {
            return ValidationResult.failure("$fieldName must be at least ${min}")
        }
        
        if (max != null && doubleValue > max.toDouble()) {
            return ValidationResult.failure("$fieldName must not exceed ${max}")
        }
        
        return ValidationResult.success()
    }
    
    /**
     * Validates URL format
     */
    fun isValidUrl(url: String?): Boolean {
        if (url.isNullOrBlank()) return false
        return try {
            java.net.URL(url.trim())
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Sanitizes string input to prevent XSS and injection attacks
     */
    fun sanitizeString(input: String?): String? {
        if (input.isNullOrBlank()) return input
        
        return input.trim()
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("&", "&amp;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;")
            .replace("/", "&#x2F;")
    }
    
    /**
     * Checks for potential SQL injection patterns
     */
    fun containsSqlInjection(input: String?): Boolean {
        if (input.isNullOrBlank()) return false
        
        val sqlPatterns = listOf(
            "drop\\s+table", "delete\\s+from", "insert\\s+into", "update\\s+set",
            "select\\s+.*\\s+from", "union\\s+select", "exec\\s*\\(",
            "--", "/*", "*/", "xp_", "sp_"
        )
        
        val lowercaseInput = input.lowercase()
        return sqlPatterns.any { pattern ->
            try {
                lowercaseInput.contains(Regex(pattern))
            } catch (e: Exception) {
                // If regex fails, check for literal string match as fallback
                lowercaseInput.contains(pattern)
            }
        }
    }
    
    /**
     * Checks for potential XSS patterns
     */
    fun containsXss(input: String?): Boolean {
        if (input.isNullOrBlank()) return false
        
        val xssPatterns = listOf(
            "<script", "</script>", "javascript:", "onload=", "onerror=",
            "onclick=", "onmouseover=", "<img", "<iframe", "<object", "<embed"
        )
        
        val lowercaseInput = input.lowercase()
        return xssPatterns.any { pattern ->
            lowercaseInput.contains(pattern)
        }
    }
    
    /**
     * Validates content engagement type
     */
    fun validateEngagementType(engagementType: String?): ValidationResult {
        if (engagementType.isNullOrBlank()) {
            return ValidationResult.failure("Engagement type is required")
        }
        
        val validTypes = setOf("viewed", "completed", "liked", "shared", "skipped", "paused", "resumed")
        return if (validTypes.contains(engagementType.trim().lowercase())) {
            ValidationResult.success()
        } else {
            ValidationResult.failure("Engagement type must be one of: ${validTypes.joinToString(", ")}")
        }
    }
}

/**
 * Validation result wrapper
 */
@Serializable
data class ValidationResult(
    val isValid: Boolean,
    val errorMessage: String? = null
) {
    companion object {
        fun success() = ValidationResult(isValid = true)
        fun failure(message: String) = ValidationResult(isValid = false, errorMessage = message)
    }
}

/**
 * Multiple validation results wrapper
 */
@Serializable
data class ValidationResults(
    val isValid: Boolean,
    val errors: List<String> = emptyList()
) {
    companion object {
        fun success() = ValidationResults(isValid = true)
        fun failure(errors: List<String>) = ValidationResults(isValid = false, errors = errors)
        fun combine(vararg results: ValidationResult): ValidationResults {
            val errors = results.filter { !it.isValid }.mapNotNull { it.errorMessage }
            return if (errors.isEmpty()) {
                success()
            } else {
                failure(errors)
            }
        }
    }
}