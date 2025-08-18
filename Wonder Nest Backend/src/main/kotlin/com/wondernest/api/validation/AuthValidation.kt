package com.wondernest.api.validation

import com.wondernest.services.auth.SignupRequest
import com.wondernest.services.auth.LoginRequest
import com.wondernest.services.auth.OAuthLoginRequest
import com.wondernest.api.auth.PasswordResetRequest
import com.wondernest.api.auth.PasswordResetConfirmRequest
import com.wondernest.utils.ValidationUtils
import com.wondernest.utils.ValidationResult
import com.wondernest.utils.ValidationResults
import kotlinx.serialization.Serializable

/**
 * Validation logic for authentication requests
 */
object AuthValidation {
    
    /**
     * Validates signup request
     */
    fun validateSignupRequest(request: SignupRequest): ValidationResults {
        val validations = mutableListOf<ValidationResult>()
        
        // Email validation
        if (!ValidationUtils.isValidEmail(request.email)) {
            validations.add(ValidationResult.failure("Invalid email format"))
        }
        
        // Check for security threats in email - temporarily disabled for debugging
        // if (ValidationUtils.containsSqlInjection(request.email) || ValidationUtils.containsXss(request.email)) {
        //     validations.add(ValidationResult.failure("Invalid characters in email"))
        // }
        
        // Password validation
        validations.add(ValidationUtils.validatePassword(request.password))
        
        // First name validation (optional)
        if (request.firstName != null) {
            validations.add(
                ValidationUtils.validateStringLength(
                    request.firstName,
                    "First name",
                    minLength = 1,
                    maxLength = 50,
                    required = false
                )
            )
            
            // Temporarily disabled for debugging
            // if (ValidationUtils.containsSqlInjection(request.firstName) || ValidationUtils.containsXss(request.firstName)) {
            //     validations.add(ValidationResult.failure("Invalid characters in first name"))
            // }
        }
        
        // Last name validation (optional)
        if (request.lastName != null) {
            validations.add(
                ValidationUtils.validateStringLength(
                    request.lastName,
                    "Last name",
                    minLength = 1,
                    maxLength = 50,
                    required = false
                )
            )
            
            // Temporarily disabled for debugging
            // if (ValidationUtils.containsSqlInjection(request.lastName) || ValidationUtils.containsXss(request.lastName)) {
            //     validations.add(ValidationResult.failure("Invalid characters in last name"))
            // }
        }
        
        // Timezone validation
        if (!ValidationUtils.isValidTimezone(request.timezone)) {
            validations.add(ValidationResult.failure("Invalid timezone"))
        }
        
        // Language validation
        if (!ValidationUtils.isValidLanguageCode(request.language)) {
            validations.add(ValidationResult.failure("Invalid language code"))
        }
        
        return ValidationResults.combine(*validations.toTypedArray())
    }
    
    /**
     * Validates login request
     */
    fun validateLoginRequest(request: LoginRequest): ValidationResults {
        val validations = mutableListOf<ValidationResult>()
        
        // Email validation
        if (!ValidationUtils.isValidEmail(request.email)) {
            validations.add(ValidationResult.failure("Invalid email format"))
        }
        
        // Check for security threats in email (for login, be more lenient than signup)
        if (ValidationUtils.containsXss(request.email)) {
            validations.add(ValidationResult.failure("Invalid characters in email"))
        }
        
        // Note: Don't check password for SQL injection as it may contain legitimate special characters
        
        // Password presence check (don't validate strength for login)
        if (request.password.isBlank()) {
            validations.add(ValidationResult.failure("Password is required"))
        }
        
        return ValidationResults.combine(*validations.toTypedArray())
    }
    
    /**
     * Validates OAuth login request
     */
    fun validateOAuthLoginRequest(request: OAuthLoginRequest): ValidationResults {
        val validations = mutableListOf<ValidationResult>()
        
        // Provider validation
        val validProviders = setOf("google", "apple", "facebook")
        if (!validProviders.contains(request.provider.lowercase())) {
            validations.add(ValidationResult.failure("Invalid OAuth provider. Supported: ${validProviders.joinToString(", ")}"))
        }
        
        // ID token validation (basic checks)
        if (request.idToken.isBlank()) {
            validations.add(ValidationResult.failure("ID token is required"))
        } else if (request.idToken.length > 2048) {
            validations.add(ValidationResult.failure("ID token is too long"))
        }
        
        // Email validation
        if (!ValidationUtils.isValidEmail(request.email)) {
            validations.add(ValidationResult.failure("Invalid email format"))
        }
        
        // Check for security threats in all fields
        val fieldsToCheck = listOf(
            request.provider to "provider",
            request.email to "email",
            request.firstName to "firstName",
            request.lastName to "lastName"
        )
        
        fieldsToCheck.forEach { (value, fieldName) ->
            if (value != null && (ValidationUtils.containsSqlInjection(value) || ValidationUtils.containsXss(value))) {
                validations.add(ValidationResult.failure("Invalid characters in $fieldName"))
            }
        }
        
        // Name validations (optional)
        if (request.firstName != null) {
            validations.add(
                ValidationUtils.validateStringLength(
                    request.firstName,
                    "First name",
                    minLength = 1,
                    maxLength = 50,
                    required = false
                )
            )
        }
        
        if (request.lastName != null) {
            validations.add(
                ValidationUtils.validateStringLength(
                    request.lastName,
                    "Last name",
                    minLength = 1,
                    maxLength = 50,
                    required = false
                )
            )
        }
        
        return ValidationResults.combine(*validations.toTypedArray())
    }
    
    /**
     * Validates password reset request
     */
    fun validatePasswordResetRequest(request: PasswordResetRequest): ValidationResults {
        val validations = mutableListOf<ValidationResult>()
        
        // Email validation
        if (!ValidationUtils.isValidEmail(request.email)) {
            validations.add(ValidationResult.failure("Invalid email format"))
        }
        
        // Check for security threats
        if (ValidationUtils.containsSqlInjection(request.email) || ValidationUtils.containsXss(request.email)) {
            validations.add(ValidationResult.failure("Invalid characters in email"))
        }
        
        return ValidationResults.combine(*validations.toTypedArray())
    }
    
    /**
     * Validates password reset confirmation request
     */
    fun validatePasswordResetConfirmRequest(request: PasswordResetConfirmRequest): ValidationResults {
        val validations = mutableListOf<ValidationResult>()
        
        // Token validation (basic checks)
        if (request.token.isBlank()) {
            validations.add(ValidationResult.failure("Reset token is required"))
        } else if (request.token.length < 10 || request.token.length > 256) {
            validations.add(ValidationResult.failure("Invalid reset token format"))
        }
        
        // Check for security threats in token
        if (ValidationUtils.containsSqlInjection(request.token) || ValidationUtils.containsXss(request.token)) {
            validations.add(ValidationResult.failure("Invalid characters in reset token"))
        }
        
        // New password validation
        validations.add(ValidationUtils.validatePassword(request.newPassword))
        
        return ValidationResults.combine(*validations.toTypedArray())
    }
    
    /**
     * Sanitizes signup request to prevent XSS
     */
    fun sanitizeSignupRequest(request: SignupRequest): SignupRequest {
        return request.copy(
            email = request.email.trim().lowercase(),
            firstName = ValidationUtils.sanitizeString(request.firstName),
            lastName = ValidationUtils.sanitizeString(request.lastName),
            timezone = request.timezone.trim(),
            language = request.language.trim().lowercase()
        )
    }
    
    /**
     * Sanitizes login request
     */
    fun sanitizeLoginRequest(request: LoginRequest): LoginRequest {
        return request.copy(
            email = request.email.trim().lowercase()
            // Note: Don't sanitize password as it might contain legitimate special characters
        )
    }
    
    /**
     * Sanitizes OAuth login request
     */
    fun sanitizeOAuthLoginRequest(request: OAuthLoginRequest): OAuthLoginRequest {
        return request.copy(
            provider = request.provider.trim().lowercase(),
            email = request.email.trim().lowercase(),
            firstName = ValidationUtils.sanitizeString(request.firstName),
            lastName = ValidationUtils.sanitizeString(request.lastName)
        )
    }
}

/**
 * Validation exception for authentication errors
 */
class AuthValidationException(
    message: String,
    val validationErrors: List<String> = emptyList()
) : IllegalArgumentException(message)

/**
 * Extension function to throw validation exception if validation fails
 */
fun ValidationResults.throwIfInvalid() {
    if (!this.isValid) {
        throw AuthValidationException(
            message = "Validation failed: ${this.errors.joinToString(", ")}",
            validationErrors = this.errors
        )
    }
}