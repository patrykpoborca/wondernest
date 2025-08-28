# Security Implementation Plan for WonderNest Website

## Overview

This security implementation plan ensures the WonderNest website maintains the highest standards of child safety, data protection, and COPPA compliance while providing secure multi-role access for parents, admins, and content managers.

## 1. Authentication & Authorization Architecture

### Multi-Tier Authentication System

#### Parent Authentication (Web Extension)
```kotlin
// Extend existing parent authentication for web use
class ParentWebAuthService(
    private val jwtService: JwtService,
    private val sessionRepository: ParentWebSessionRepository
) {
    suspend fun authenticateParentForWeb(credentials: LoginRequest): WebAuthResponse {
        // 1. Validate credentials against existing parent auth
        val parentAuth = parentAuthService.authenticate(credentials)
        
        // 2. Generate web-specific JWT with additional claims
        val webToken = jwtService.generateToken(
            userId = parentAuth.userId,
            sessionType = "web-parent",
            permissions = listOf("view_children", "manage_settings", "manage_bookmarks"),
            familyId = parentAuth.familyId,
            expiresIn = Duration.ofDays(7) // Longer session for web convenience
        )
        
        // 3. Create web session record
        val session = sessionRepository.createSession(
            parentId = parentAuth.userId,
            familyId = parentAuth.familyId,
            token = webToken.token,
            refreshToken = webToken.refreshToken,
            ipAddress = getClientIP(),
            userAgent = getUserAgent()
        )
        
        return WebAuthResponse(
            accessToken = webToken.token,
            refreshToken = webToken.refreshToken,
            expiresIn = webToken.expiresIn,
            sessionId = session.id
        )
    }
    
    suspend fun requirePinReauth(sessionId: UUID, pin: String): Boolean {
        // For sensitive operations, require PIN re-authentication
        val session = sessionRepository.findById(sessionId)
        val parent = userRepository.findById(session.parentId)
        
        return if (bcrypt.checkpw(pin, parent.pinHash)) {
            sessionRepository.updatePinReauth(sessionId, Instant.now())
            true
        } else {
            auditLog.logFailedPinAttempt(session.parentId, getClientIP())
            false
        }
    }
}
```

#### Admin Authentication (Separate System)
```kotlin
class AdminAuthService(
    private val adminRepository: AdminUserRepository,
    private val jwtService: JwtService,
    private val twoFactorService: TwoFactorService,
    private val sessionRepository: AdminSessionRepository
) {
    suspend fun authenticateAdmin(credentials: AdminLoginRequest): AdminAuthResponse {
        // 1. Rate limiting check
        rateLimiter.checkLoginAttempts(credentials.email, getClientIP())
        
        // 2. Validate credentials
        val admin = adminRepository.findByEmail(credentials.email)
            ?: throw AuthenticationException("Invalid credentials")
            
        if (!admin.isActive || !bcrypt.checkpw(credentials.password, admin.passwordHash)) {
            auditLog.logFailedLogin(credentials.email, getClientIP())
            throw AuthenticationException("Invalid credentials")
        }
        
        // 3. Check 2FA if enabled
        if (admin.twoFactorEnabled) {
            if (credentials.twoFactorCode.isNullOrBlank()) {
                return AdminAuthResponse(requiresTwoFactor = true)
            }
            
            if (!twoFactorService.validateCode(admin.twoFactorSecret, credentials.twoFactorCode)) {
                auditLog.logFailed2FA(admin.id, getClientIP())
                throw AuthenticationException("Invalid 2FA code")
            }
        }
        
        // 4. Generate admin JWT with role-based permissions
        val adminToken = jwtService.generateToken(
            userId = admin.id,
            sessionType = "admin",
            role = admin.role,
            permissions = admin.permissions,
            expiresIn = Duration.ofHours(4) // Short session for security
        )
        
        // 5. Create admin session
        val session = sessionRepository.createSession(
            adminUserId = admin.id,
            token = adminToken.token,
            refreshToken = adminToken.refreshToken,
            ipAddress = getClientIP(),
            userAgent = getUserAgent()
        )
        
        // 6. Update login tracking
        adminRepository.updateLastLogin(admin.id, Instant.now())
        auditLog.logSuccessfulLogin(admin.id, getClientIP())
        
        return AdminAuthResponse(
            accessToken = adminToken.token,
            refreshToken = adminToken.refreshToken,
            adminProfile = admin.toProfile(),
            permissions = admin.permissions,
            expiresIn = adminToken.expiresIn
        )
    }
}
```

#### Content Manager Authentication (Role-Based)
```kotlin
class ContentManagerAuthService(
    private val adminAuthService: AdminAuthService
) {
    suspend fun authenticateContentManager(credentials: LoginRequest): ContentManagerAuthResponse {
        // Content managers are admin users with specific roles
        val adminResponse = adminAuthService.authenticateAdmin(
            AdminLoginRequest(
                email = credentials.email,
                password = credentials.password,
                twoFactorCode = credentials.twoFactorCode
            )
        )
        
        // Verify content manager permissions
        val requiredPermissions = listOf("create_content", "edit_content")
        if (!adminResponse.permissions.any { it in requiredPermissions }) {
            throw AuthorizationException("Insufficient permissions for content management")
        }
        
        // Generate content-manager specific token
        return ContentManagerAuthResponse(
            accessToken = generateContentManagerToken(adminResponse),
            refreshToken = adminResponse.refreshToken,
            contentPermissions = filterContentPermissions(adminResponse.permissions),
            expiresIn = adminResponse.expiresIn
        )
    }
}
```

### JWT Token Structure

#### Parent Web Token Claims
```kotlin
data class ParentWebTokenClaims(
    val userId: UUID,           // Parent user ID
    val familyId: UUID,         // Family context
    val sessionType: String,    // "web-parent"
    val sessionId: UUID,        // Web session ID
    val permissions: List<String>, // ["view_children", "manage_bookmarks"]
    val iat: Long,              // Issued at
    val exp: Long,              // Expires at
    val aud: String,            // "wondernest-web"
    val iss: String             // "wondernest-api"
)
```

#### Admin Token Claims
```kotlin
data class AdminTokenClaims(
    val userId: UUID,           // Admin user ID
    val sessionType: String,    // "admin"
    val role: AdminRole,        // SUPER_ADMIN, CONTENT_MODERATOR, etc.
    val permissions: List<String>, // Role-based permissions
    val sessionId: UUID,        // Admin session ID
    val requiresReauth: Boolean, // For sensitive operations
    val iat: Long,
    val exp: Long,
    val aud: String,            // "wondernest-admin"
    val iss: String
)
```

## 2. Role-Based Access Control (RBAC)

### Permission System

#### Parent Permissions
```kotlin
enum class ParentPermission(val code: String) {
    VIEW_CHILD_PROGRESS("view_child_progress"),
    MANAGE_CHILD_SETTINGS("manage_child_settings"),
    MANAGE_BOOKMARKS("manage_bookmarks"),
    APPROVE_PURCHASES("approve_purchases"),
    VIEW_CHILD_CONTENT("view_child_content"),
    MANAGE_CONTENT_FILTERS("manage_content_filters"),
    VIEW_ANALYTICS("view_analytics"),
    MANAGE_FAMILY_SETTINGS("manage_family_settings")
}
```

#### Admin Permissions
```kotlin
enum class AdminPermission(val code: String) {
    // User Management
    MANAGE_USERS("manage_users"),
    VIEW_USER_DATA("view_user_data"),
    MODERATE_USER_CONTENT("moderate_user_content"),
    
    // Content Management
    CREATE_CONTENT("create_content"),
    EDIT_CONTENT("edit_content"),
    PUBLISH_CONTENT("publish_content"),
    MODERATE_CONTENT("moderate_content"),
    DELETE_CONTENT("delete_content"),
    
    // Analytics & Reporting
    VIEW_PLATFORM_ANALYTICS("view_platform_analytics"),
    EXPORT_DATA("export_data"),
    VIEW_FINANCIAL_DATA("view_financial_data"),
    
    // System Administration
    MANAGE_SYSTEM_SETTINGS("manage_system_settings"),
    VIEW_AUDIT_LOGS("view_audit_logs"),
    MANAGE_ADMIN_USERS("manage_admin_users"),
    
    // Security
    MANAGE_SECURITY_SETTINGS("manage_security_settings"),
    VIEW_SECURITY_LOGS("view_security_logs"),
    FORCE_PASSWORD_RESET("force_password_reset")
}
```

### Authorization Middleware

#### Kotlin/KTOR Authorization
```kotlin
fun Application.configureWebAuthorization() {
    install(Authentication) {
        // Parent web authorization
        bearer("parent-web-bearer") {
            authenticate { tokenCredential ->
                val token = tokenCredential.token
                try {
                    val claims = jwtService.validateToken(token)
                    if (claims.sessionType == "web-parent") {
                        val session = parentSessionRepository.findByToken(token)
                        if (session?.isActive == true && session.expiresAt > Instant.now()) {
                            ParentWebPrincipal(
                                parentId = claims.userId,
                                familyId = claims.familyId,
                                permissions = claims.permissions,
                                sessionId = claims.sessionId
                            )
                        } else null
                    } else null
                } catch (e: Exception) {
                    null
                }
            }
        }
        
        // Admin authorization with permission checking
        bearer("admin-bearer") {
            authenticate { tokenCredential ->
                val token = tokenCredential.token
                try {
                    val claims = jwtService.validateToken(token)
                    if (claims.sessionType == "admin") {
                        val session = adminSessionRepository.findByToken(token)
                        if (session?.isActive == true && session.expiresAt > Instant.now()) {
                            AdminPrincipal(
                                adminId = claims.userId,
                                role = claims.role,
                                permissions = claims.permissions,
                                sessionId = claims.sessionId
                            )
                        } else null
                    } else null
                } catch (e: Exception) {
                    null
                }
            }
        }
    }
}

// Authorization helper functions
fun Route.requireParentPermission(permission: ParentPermission, block: Route.() -> Unit) {
    authenticate("parent-web-bearer") {
        intercept(ApplicationCallPipeline.Call) {
            val principal = call.principal<ParentWebPrincipal>()
            if (principal == null || permission.code !in principal.permissions) {
                call.respond(HttpStatusCode.Forbidden, mapOf("error" to "Insufficient permissions"))
                return@intercept finish()
            }
        }
        block()
    }
}

fun Route.requireAdminPermission(permission: AdminPermission, block: Route.() -> Unit) {
    authenticate("admin-bearer") {
        intercept(ApplicationCallPipeline.Call) {
            val principal = call.principal<AdminPrincipal>()
            if (principal == null || permission.code !in principal.permissions) {
                auditLog.logUnauthorizedAccess(principal?.adminId, permission.code, getClientIP())
                call.respond(HttpStatusCode.Forbidden, mapOf("error" to "Insufficient permissions"))
                return@intercept finish()
            }
        }
        block()
    }
}
```

#### Frontend Authorization (React/TypeScript)
```typescript
// Permission checking hook
export const usePermissions = () => {
  const { user } = useAuth();
  
  const hasPermission = useCallback((permission: Permission): boolean => {
    if (!user || !user.permissions) return false;
    return user.permissions.includes(permission);
  }, [user]);
  
  const hasAnyPermission = useCallback((permissions: Permission[]): boolean => {
    return permissions.some(permission => hasPermission(permission));
  }, [hasPermission]);
  
  const hasAllPermissions = useCallback((permissions: Permission[]): boolean => {
    return permissions.every(permission => hasPermission(permission));
  }, [hasPermission]);
  
  return { hasPermission, hasAnyPermission, hasAllPermissions };
};

// Protected route component
export const ProtectedRoute: React.FC<{
  children: React.ReactNode;
  permission?: Permission;
  permissions?: Permission[];
  requireAll?: boolean;
  fallback?: React.ReactNode;
}> = ({ children, permission, permissions, requireAll = false, fallback }) => {
  const { hasPermission, hasAnyPermission, hasAllPermissions } = usePermissions();
  
  let hasAccess = true;
  
  if (permission) {
    hasAccess = hasPermission(permission);
  } else if (permissions) {
    hasAccess = requireAll 
      ? hasAllPermissions(permissions)
      : hasAnyPermission(permissions);
  }
  
  if (!hasAccess) {
    return fallback || <UnauthorizedAccess />;
  }
  
  return <>{children}</>;
};

// Usage in routes
const AdminRoutes = () => (
  <Routes>
    <Route path="/admin/users" element={
      <ProtectedRoute permission={AdminPermission.MANAGE_USERS}>
        <UserManagement />
      </ProtectedRoute>
    } />
    <Route path="/admin/content" element={
      <ProtectedRoute permission={AdminPermission.MODERATE_CONTENT}>
        <ContentModeration />
      </ProtectedRoute>
    } />
  </Routes>
);
```

## 3. Data Protection & Privacy

### COPPA Compliance Implementation

#### Child Data Access Controls
```kotlin
class ChildDataAccessService(
    private val auditLog: AuditLogService
) {
    suspend fun getChildData(
        requesterId: UUID,
        requesterType: UserType,
        childId: UUID,
        dataType: ChildDataType
    ): ChildDataResult {
        // Verify requester has permission to access this child's data
        when (requesterType) {
            UserType.PARENT -> {
                val family = familyRepository.findByChildId(childId)
                val isParent = family?.parentIds?.contains(requesterId) ?: false
                if (!isParent) {
                    auditLog.logUnauthorizedChildDataAccess(requesterId, childId, dataType)
                    throw UnauthorizedException("Not authorized to access this child's data")
                }
            }
            UserType.ADMIN -> {
                // Admins need specific permission and legitimate reason
                val adminUser = adminRepository.findById(requesterId)
                if (!adminUser.permissions.contains("view_child_data_with_cause")) {
                    auditLog.logUnauthorizedChildDataAccess(requesterId, childId, dataType)
                    throw UnauthorizedException("Admin access to child data not permitted")
                }
                // Log admin access with reason
                auditLog.logAdminChildDataAccess(requesterId, childId, dataType, "System maintenance")
            }
            else -> throw UnauthorizedException("Invalid user type for child data access")
        }
        
        // Log all child data access
        auditLog.logChildDataAccess(requesterId, requesterType, childId, dataType)
        
        return childDataRepository.getChildData(childId, dataType)
    }
}
```

#### Data Minimization
```kotlin
// Only collect and store necessary data
data class ChildProfileWeb(
    val id: UUID,
    val firstName: String,        // Required for personalization
    val ageInMonths: Int,        // Required for age-appropriate content
    val avatarUrl: String?,      // Optional, user-provided
    val preferences: UserPreferences, // Learning preferences only
    // Exclude: last_name, detailed personal info, location data
) {
    companion object {
        fun fromChildProfile(profile: ChildProfile): ChildProfileWeb {
            return ChildProfileWeb(
                id = profile.id,
                firstName = profile.firstName,
                ageInMonths = profile.ageInMonths,
                avatarUrl = profile.avatarUrl,
                preferences = profile.preferences
            )
        }
    }
}
```

#### Parental Consent Verification
```kotlin
class ParentalConsentService {
    suspend fun verifyParentalConsent(parentId: UUID, childId: UUID, action: ConsentAction): Boolean {
        val consent = coppaConsentRepository.findByChild(childId)
        
        // Verify parent is authorized for this child
        val family = familyRepository.findByChildId(childId)
        if (!family.parentIds.contains(parentId)) {
            return false
        }
        
        // Check if consent covers this action
        return when (action) {
            ConsentAction.VIEW_PROGRESS -> consent.allowProgressTracking
            ConsentAction.SHARE_ACHIEVEMENTS -> consent.allowSharingAchievements
            ConsentAction.COLLECT_USAGE_DATA -> consent.allowUsageAnalytics
            ConsentAction.THIRD_PARTY_INTEGRATION -> consent.allowThirdPartySharing
        }
    }
}
```

### Data Encryption & Security

#### Encryption at Rest
```kotlin
class EncryptionService {
    private val encryptionKey = System.getenv("ENCRYPTION_KEY") // 256-bit key
    private val cipher = Cipher.getInstance("AES/GCM/NoPadding")
    
    fun encryptSensitiveData(plaintext: String): EncryptedData {
        val iv = ByteArray(12).also { SecureRandom().nextBytes(it) }
        val keySpec = SecretKeySpec(Base64.getDecoder().decode(encryptionKey), "AES")
        
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, GCMParameterSpec(128, iv))
        val ciphertext = cipher.doFinal(plaintext.toByteArray())
        
        return EncryptedData(
            data = Base64.getEncoder().encodeToString(ciphertext),
            iv = Base64.getEncoder().encodeToString(iv)
        )
    }
    
    fun decryptSensitiveData(encryptedData: EncryptedData): String {
        val keySpec = SecretKeySpec(Base64.getDecoder().decode(encryptionKey), "AES")
        val iv = Base64.getDecoder().decode(encryptedData.iv)
        
        cipher.init(Cipher.DECRYPT_MODE, keySpec, GCMParameterSpec(128, iv))
        val plaintext = cipher.doFinal(Base64.getDecoder().decode(encryptedData.data))
        
        return String(plaintext)
    }
}
```

#### Secure File Upload
```kotlin
class SecureFileUploadService(
    private val virusScanner: VirusScannerService,
    private val contentAnalyzer: ContentAnalyzerService
) {
    suspend fun uploadFile(
        uploadRequest: FileUploadRequest,
        uploadedBy: UUID
    ): FileUploadResult {
        // 1. Validate file size and type
        if (uploadRequest.file.size > MAX_FILE_SIZE) {
            throw FileUploadException("File too large")
        }
        
        if (uploadRequest.mimeType !in ALLOWED_MIME_TYPES) {
            throw FileUploadException("File type not allowed")
        }
        
        // 2. Scan for viruses
        val scanResult = virusScanner.scanFile(uploadRequest.file)
        if (!scanResult.isClean) {
            auditLog.logVirusDetection(uploadedBy, scanResult.threatName)
            throw FileUploadException("File failed security scan")
        }
        
        // 3. Content analysis for inappropriate material
        if (uploadRequest.file.mimeType.startsWith("image/")) {
            val contentAnalysis = contentAnalyzer.analyzeImage(uploadRequest.file)
            if (contentAnalysis.hasInappropriateContent) {
                auditLog.logInappropriateContent(uploadedBy, contentAnalysis.reasons)
                throw FileUploadException("File contains inappropriate content")
            }
        }
        
        // 4. Generate secure filename and store
        val secureFilename = generateSecureFilename(uploadRequest.originalFilename)
        val storagePath = fileStorageService.store(uploadRequest.file, secureFilename)
        
        // 5. Create asset record
        val asset = contentAssetRepository.create(
            ContentAsset(
                originalFilename = uploadRequest.originalFilename,
                storedFilename = secureFilename,
                filePath = storagePath,
                fileSize = uploadRequest.file.size,
                mimeType = uploadRequest.mimeType,
                uploadedBy = uploadedBy,
                processingStatus = ProcessingStatus.APPROVED
            )
        )
        
        auditLog.logFileUpload(uploadedBy, asset.id, uploadRequest.originalFilename)
        
        return FileUploadResult(
            assetId = asset.id,
            url = generateAssetUrl(asset),
            thumbnailUrl = generateThumbnailUrl(asset)
        )
    }
}
```

## 4. Session Security

### Session Management
```kotlin
class SecureSessionManager {
    suspend fun createSession(userId: UUID, userType: UserType, ipAddress: String): Session {
        // Generate cryptographically secure tokens
        val sessionToken = generateSecureToken(32)
        val refreshToken = generateSecureToken(32)
        
        // Set appropriate expiry based on user type
        val expiresAt = when (userType) {
            UserType.PARENT -> Instant.now().plus(7, ChronoUnit.DAYS)
            UserType.ADMIN -> Instant.now().plus(4, ChronoUnit.HOURS)
            UserType.CONTENT_MANAGER -> Instant.now().plus(8, ChronoUnit.HOURS)
        }
        
        // Create session with security metadata
        val session = Session(
            userId = userId,
            userType = userType,
            sessionToken = hashToken(sessionToken),
            refreshToken = hashToken(refreshToken),
            ipAddress = ipAddress,
            expiresAt = expiresAt,
            createdAt = Instant.now()
        )
        
        sessionRepository.create(session)
        
        return session
    }
    
    suspend fun validateSession(token: String): SessionValidationResult {
        val hashedToken = hashToken(token)
        val session = sessionRepository.findByToken(hashedToken)
        
        return when {
            session == null -> SessionValidationResult.INVALID
            session.expiresAt < Instant.now() -> {
                sessionRepository.markExpired(session.id)
                SessionValidationResult.EXPIRED
            }
            !session.isActive -> SessionValidationResult.INACTIVE
            else -> {
                // Update last activity
                sessionRepository.updateLastActivity(session.id, Instant.now())
                SessionValidationResult.VALID(session)
            }
        }
    }
    
    private fun generateSecureToken(length: Int): String {
        val bytes = ByteArray(length)
        SecureRandom().nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }
    
    private fun hashToken(token: String): String {
        return BCrypt.hashpw(token, BCrypt.gensalt(12))
    }
}
```

### Session Monitoring
```kotlin
class SessionMonitoringService {
    suspend fun detectSuspiciousActivity(session: Session): List<SecurityAlert> {
        val alerts = mutableListOf<SecurityAlert>()
        
        // Check for concurrent sessions from different IPs
        val concurrentSessions = sessionRepository.findActiveSessionsForUser(session.userId)
        val distinctIPs = concurrentSessions.map { it.ipAddress }.distinct()
        
        if (distinctIPs.size > 3) {
            alerts.add(SecurityAlert(
                type = AlertType.MULTIPLE_CONCURRENT_SESSIONS,
                severity = Severity.HIGH,
                description = "User has active sessions from ${distinctIPs.size} different IP addresses"
            ))
        }
        
        // Check for rapid session creation
        val recentSessions = sessionRepository.findSessionsCreatedInLastHour(session.userId)
        if (recentSessions.size > 10) {
            alerts.add(SecurityAlert(
                type = AlertType.RAPID_SESSION_CREATION,
                severity = Severity.HIGH,
                description = "User created ${recentSessions.size} sessions in the last hour"
            ))
        }
        
        // Check for geographic anomalies (if geolocation is available)
        val userLocation = geoLocationService.getLocation(session.ipAddress)
        val recentLocations = sessionRepository.findRecentSessionLocations(session.userId, Duration.ofHours(24))
        
        if (recentLocations.any { location -> 
            geoLocationService.calculateDistance(userLocation, location) > 1000 // km
        }) {
            alerts.add(SecurityAlert(
                type = AlertType.GEOGRAPHIC_ANOMALY,
                severity = Severity.MEDIUM,
                description = "Session created from unusual geographic location"
            ))
        }
        
        return alerts
    }
}
```

## 5. Input Validation & Sanitization

### Request Validation
```kotlin
// Custom validation annotations
@Target(AnnotationTarget.FIELD)
@Retention(AnnotationRetention.RUNTIME)
annotation class SafeHtml

@Target(AnnotationTarget.FIELD) 
@Retention(AnnotationRetention.RUNTIME)
annotation class ChildSafeContent

class InputSanitationService {
    fun sanitizeHtml(input: String): String {
        val policy = PolicyFactory.newBuilder()
            .allowElements("p", "br", "strong", "em", "u")
            .allowAttributes("class").onElements("p")
            .toFactory()
        
        return policy.sanitize(input)
    }
    
    fun validateChildSafeContent(input: String): ValidationResult {
        val inappropriateWords = loadInappropriateWordList()
        val foundWords = inappropriateWords.filter { word ->
            input.lowercase().contains(word.lowercase())
        }
        
        return if (foundWords.isEmpty()) {
            ValidationResult.Valid
        } else {
            ValidationResult.Invalid("Content contains inappropriate language: ${foundWords.joinToString()}")
        }
    }
}

// Request DTOs with validation
@Serializable
data class CreateStoryRequest(
    @field:NotBlank
    @field:Size(min = 1, max = 255)
    val title: String,
    
    @field:NotBlank
    @field:Size(max = 2000)
    @field:SafeHtml
    @field:ChildSafeContent
    val description: String,
    
    @field:Valid
    val storyData: StoryData,
    
    @field:Min(12)
    @field:Max(216)
    val minAgeMonths: Int,
    
    @field:Min(12)
    @field:Max(216)  
    val maxAgeMonths: Int
) {
    fun validate(): List<ValidationError> {
        val errors = mutableListOf<ValidationError>()
        
        if (minAgeMonths > maxAgeMonths) {
            errors.add(ValidationError("minAgeMonths must be less than or equal to maxAgeMonths"))
        }
        
        return errors
    }
}
```

## 6. Rate Limiting & DDoS Protection

### Rate Limiting Implementation
```kotlin
class RateLimitingService {
    private val redisTemplate: RedisTemplate<String, String>
    
    suspend fun checkRateLimit(
        identifier: String,
        limitType: RateLimitType
    ): RateLimitResult {
        val key = "rate_limit:${limitType.name}:$identifier"
        val window = limitType.windowSeconds
        val maxRequests = limitType.maxRequests
        
        val script = """
            local key = KEYS[1]
            local window = tonumber(ARGV[1])
            local max_requests = tonumber(ARGV[2])
            local current_time = tonumber(ARGV[3])
            
            redis.call('ZREMRANGEBYSCORE', key, 0, current_time - window * 1000)
            local current_requests = redis.call('ZCARD', key)
            
            if current_requests < max_requests then
                redis.call('ZADD', key, current_time, current_time)
                redis.call('EXPIRE', key, window)
                return {1, max_requests - current_requests - 1}
            else
                return {0, 0}
            end
        """.trimIndent()
        
        val result = redisTemplate.execute { connection ->
            connection.eval(
                script,
                listOf(key),
                listOf(window.toString(), maxRequests.toString(), System.currentTimeMillis().toString())
            )
        } as List<Long>
        
        return if (result[0] == 1L) {
            RateLimitResult.Allowed(remaining = result[1].toInt())
        } else {
            RateLimitResult.Blocked
        }
    }
}

enum class RateLimitType(val maxRequests: Int, val windowSeconds: Int) {
    LOGIN_ATTEMPTS(5, 300),          // 5 attempts per 5 minutes
    API_CALLS_GENERAL(1000, 3600),   // 1000 calls per hour
    FILE_UPLOADS(10, 3600),          // 10 uploads per hour
    PASSWORD_RESET(3, 3600),         // 3 reset requests per hour
    CONTENT_CREATION(20, 3600),      // 20 content items per hour
    ADMIN_ACTIONS(100, 3600)         // 100 admin actions per hour
}
```

## 7. Audit Logging & Monitoring

### Comprehensive Audit Trail
```kotlin
class AuditLogService {
    suspend fun logSecurityEvent(event: SecurityEvent) {
        val auditEntry = AuditLogEntry(
            userId = event.userId,
            userType = event.userType,
            action = event.action,
            resourceType = event.resourceType,
            resourceId = event.resourceId,
            oldValues = event.oldValues,
            newValues = event.newValues,
            ipAddress = event.ipAddress,
            userAgent = event.userAgent,
            sessionId = event.sessionId,
            success = event.success,
            errorMessage = event.errorMessage,
            metadata = event.metadata,
            createdAt = Instant.now()
        )
        
        auditRepository.create(auditEntry)
        
        // Send critical security events to monitoring system
        if (event.severity >= SecuritySeverity.HIGH) {
            securityMonitoringService.sendAlert(event)
        }
    }
    
    suspend fun logChildDataAccess(
        requesterId: UUID,
        requesterType: UserType,
        childId: UUID,
        dataType: ChildDataType,
        justification: String? = null
    ) {
        logSecurityEvent(SecurityEvent(
            userId = requesterId,
            userType = requesterType,
            action = "access_child_data",
            resourceType = "child_profile",
            resourceId = childId,
            metadata = mapOf(
                "data_type" to dataType.name,
                "justification" to (justification ?: "parent_access"),
                "compliance_note" to "COPPA_regulated_access"
            ),
            severity = SecuritySeverity.MEDIUM,
            success = true
        ))
    }
}
```

This comprehensive security implementation plan ensures:

1. **Multi-tier Authentication**: Separate, secure authentication for parents, admins, and content managers
2. **Fine-grained Authorization**: Role-based permissions with audit trails
3. **COPPA Compliance**: Strict child data protection with parental consent verification
4. **Data Security**: Encryption at rest, secure file uploads, content scanning
5. **Session Security**: Secure token generation, session monitoring, suspicious activity detection
6. **Input Protection**: Comprehensive validation and sanitization
7. **DDoS Protection**: Rate limiting and monitoring
8. **Audit Compliance**: Complete audit trails for all sensitive operations

The implementation prioritizes child safety while maintaining usability for parents and efficiency for content managers and administrators.