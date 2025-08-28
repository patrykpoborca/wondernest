# Backend API Updates for WonderNest Website

## Required Backend Modifications

### File Structure Updates
```
Wonder Nest Backend/src/main/kotlin/com/wondernest/
├── api/
│   ├── web/                          # NEW: Web-specific API routes
│   │   ├── admin/
│   │   │   ├── AdminAuthRoutes.kt    # Admin authentication
│   │   │   ├── AdminUserRoutes.kt    # User management  
│   │   │   ├── AdminAnalyticsRoutes.kt # Platform analytics
│   │   │   └── ContentModerationRoutes.kt # Content moderation
│   │   ├── parent/
│   │   │   ├── ParentWebRoutes.kt    # Parent web portal
│   │   │   ├── ChildAnalyticsRoutes.kt # Child analytics
│   │   │   └── BookmarkRoutes.kt     # Game bookmarking
│   │   ├── content/
│   │   │   ├── ContentCreationRoutes.kt # Story/content creation
│   │   │   ├── ContentWorkflowRoutes.kt # Approval workflow
│   │   │   └── AssetUploadRoutes.kt   # File upload handling
│   │   └── WebRoutingConfig.kt       # Web route configuration
├── services/
│   ├── web/                          # NEW: Web-specific services
│   │   ├── admin/
│   │   │   ├── AdminAuthService.kt   # Admin authentication logic
│   │   │   ├── AdminUserService.kt   # Admin user management
│   │   │   └── PlatformAnalyticsService.kt # Platform metrics
│   │   ├── content/
│   │   │   ├── ContentCreationService.kt # Content creation logic
│   │   │   ├── ContentWorkflowService.kt # Approval workflows
│   │   │   └── AssetManagementService.kt # File/asset management
│   │   └── BookmarkService.kt        # Bookmark management
├── data/
│   ├── database/
│   │   ├── table/
│   │   │   ├── WebAdmin.kt           # EXTEND: Web admin tables
│   │   │   ├── ContentWorkflow.kt    # NEW: Content workflow tables
│   │   │   ├── WebSessions.kt        # NEW: Web session tables
│   │   │   └── Bookmarks.kt          # NEW: Bookmark tables
│   │   └── repository/
│   │       ├── AdminUserRepository.kt # NEW: Admin user data access
│   │       ├── ContentRepository.kt   # NEW: Content data access
│   │       └── BookmarkRepository.kt  # NEW: Bookmark data access
└── domain/
    └── web/                          # NEW: Web domain models
        ├── AdminUser.kt              # Admin user models
        ├── ContentItem.kt            # Content models
        └── Bookmark.kt               # Bookmark models
```

### 1. Web Admin Authentication Routes

**File**: `/api/web/admin/AdminAuthRoutes.kt`
```kotlin
package com.wondernest.api.web.admin

import com.wondernest.services.web.admin.AdminAuthService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject

@Serializable
data class AdminLoginRequest(
    val email: String,
    val password: String,
    val twoFactorCode: String? = null
)

@Serializable
data class AdminLoginResponse(
    val accessToken: String,
    val refreshToken: String,
    val adminUser: AdminUserProfile,
    val permissions: List<String>,
    val expiresIn: Long
)

@Serializable
data class AdminUserProfile(
    val id: String,
    val email: String,
    val firstName: String,
    val lastName: String,
    val role: String,
    val permissions: List<String>,
    val twoFactorEnabled: Boolean
)

fun Route.adminAuthRoutes() {
    val adminAuthService by inject<AdminAuthService>()

    route("/admin/auth") {
        // Admin login
        post("/login") {
            try {
                val request = call.receive<AdminLoginRequest>()
                
                // Validate admin credentials
                val response = adminAuthService.loginAdmin(request)
                call.respond(HttpStatusCode.OK, response)
                
            } catch (e: SecurityException) {
                call.respond(HttpStatusCode.Unauthorized, mapOf("error" to "Invalid credentials"))
            } catch (e: IllegalArgumentException) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to e.message))
            }
        }
        
        // Admin refresh token
        post("/refresh") {
            try {
                val refreshToken = call.request.headers["Authorization"]?.removePrefix("Bearer ")
                    ?: throw IllegalArgumentException("Refresh token required")
                
                val response = adminAuthService.refreshAdminToken(refreshToken)
                call.respond(HttpStatusCode.OK, response)
                
            } catch (e: SecurityException) {
                call.respond(HttpStatusCode.Unauthorized, mapOf("error" to "Invalid refresh token"))
            }
        }
        
        // Admin logout
        authenticate("admin-jwt") {
            post("/logout") {
                try {
                    val token = call.request.headers["Authorization"]?.removePrefix("Bearer ")
                    if (token != null) {
                        adminAuthService.logoutAdmin(token)
                    }
                    call.respond(HttpStatusCode.OK, mapOf("message" to "Logged out successfully"))
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Logout failed"))
                }
            }
        }
    }
}
```

### 2. Parent Web Portal Routes

**File**: `/api/web/parent/ParentWebRoutes.kt`
```kotlin
package com.wondernest.api.web.parent

import com.wondernest.services.web.BookmarkService
import com.wondernest.services.analytics.AnalyticsService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.util.*

@Serializable
data class ParentDashboardData(
    val children: List<ChildDashboardSummary>,
    val recentActivity: List<ActivitySummary>,
    val pendingApprovals: List<PendingApproval>,
    val systemNotifications: List<SystemNotification>
)

@Serializable
data class ChildDashboardSummary(
    val childId: String,
    val name: String,
    val age: Int,
    val avatarUrl: String?,
    val weeklyPlayTimeMinutes: Int,
    val achievementsThisWeek: Int,
    val favoriteGames: List<String>,
    val developmentalInsights: List<String>
)

@Serializable
data class BookmarkRequest(
    val childId: String,
    val gameId: String?,
    val title: String,
    val description: String?,
    val url: String?,
    val category: String,
    val parentNotes: String?
)

fun Route.parentWebRoutes() {
    val bookmarkService by inject<BookmarkService>()
    val analyticsService by inject<AnalyticsService>()

    authenticate("parent-web-jwt") {
        route("/parent") {
            // Parent dashboard data
            get("/dashboard") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val parentId = principal?.payload?.getClaim("userId")?.asString()
                        ?: throw IllegalArgumentException("Invalid token")
                    
                    val dashboardData = parentWebService.getDashboardData(UUID.fromString(parentId))
                    call.respond(HttpStatusCode.OK, dashboardData)
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to load dashboard"))
                }
            }
            
            // Child-specific analytics
            get("/children/{childId}/analytics") {
                try {
                    val childId = call.parameters["childId"] 
                        ?: throw IllegalArgumentException("Child ID required")
                    val timeRange = call.request.queryParameters["timeRange"] ?: "week"
                    
                    val analytics = analyticsService.getChildAnalytics(UUID.fromString(childId), timeRange)
                    call.respond(HttpStatusCode.OK, analytics)
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to load analytics"))
                }
            }
            
            // Bookmark management
            route("/bookmarks") {
                get("/children/{childId}") {
                    try {
                        val childId = call.parameters["childId"] 
                            ?: throw IllegalArgumentException("Child ID required")
                        
                        val bookmarks = bookmarkService.getChildBookmarks(UUID.fromString(childId))
                        call.respond(HttpStatusCode.OK, bookmarks)
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to load bookmarks"))
                    }
                }
                
                post("/") {
                    try {
                        val request = call.receive<BookmarkRequest>()
                        val principal = call.principal<JWTPrincipal>()
                        val parentId = principal?.payload?.getClaim("userId")?.asString()
                            ?: throw IllegalArgumentException("Invalid token")
                        
                        val bookmark = bookmarkService.createBookmark(UUID.fromString(parentId), request)
                        call.respond(HttpStatusCode.Created, bookmark)
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to create bookmark"))
                    }
                }
                
                delete("/{bookmarkId}") {
                    try {
                        val bookmarkId = call.parameters["bookmarkId"] 
                            ?: throw IllegalArgumentException("Bookmark ID required")
                        
                        bookmarkService.deleteBookmark(UUID.fromString(bookmarkId))
                        call.respond(HttpStatusCode.OK, mapOf("message" to "Bookmark deleted"))
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to delete bookmark"))
                    }
                }
            }
            
            // Approval management
            route("/approvals") {
                get("/pending") {
                    try {
                        val principal = call.principal<JWTPrincipal>()
                        val parentId = principal?.payload?.getClaim("userId")?.asString()
                            ?: throw IllegalArgumentException("Invalid token")
                        
                        val approvals = approvalService.getPendingApprovals(UUID.fromString(parentId))
                        call.respond(HttpStatusCode.OK, approvals)
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to load approvals"))
                    }
                }
                
                post("/{approvalId}/decision") {
                    try {
                        val approvalId = call.parameters["approvalId"] 
                            ?: throw IllegalArgumentException("Approval ID required")
                        val decision = call.receive<ApprovalDecision>()
                        
                        approvalService.processApproval(UUID.fromString(approvalId), decision)
                        call.respond(HttpStatusCode.OK, mapOf("message" to "Approval processed"))
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to process approval"))
                    }
                }
            }
        }
    }
}
```

### 3. Content Creation Routes

**File**: `/api/web/content/ContentCreationRoutes.kt`
```kotlin
package com.wondernest.api.web.content

import com.wondernest.services.web.content.ContentCreationService
import com.wondernest.services.web.content.AssetManagementService
import io.ktor.http.*
import io.ktor.http.content.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.util.*

@Serializable
data class CreateStoryRequest(
    val title: String,
    val description: String,
    val storyData: Map<String, String>, // JSON structure for story content
    val minAgeMonths: Int,
    val maxAgeMonths: Int,
    val educationalObjectives: List<String>,
    val skillsDeveloped: List<String>,
    val tags: List<String>
)

@Serializable
data class StoryResponse(
    val id: String,
    val title: String,
    val description: String,
    val status: String,
    val version: Int,
    val createdAt: String,
    val updatedAt: String,
    val creatorId: String
)

@Serializable
data class AssetUploadResponse(
    val assetId: String,
    val filename: String,
    val url: String,
    val thumbnailUrl: String?,
    val fileSize: Long,
    val mimeType: String
)

fun Route.contentCreationRoutes() {
    val contentCreationService by inject<ContentCreationService>()
    val assetManagementService by inject<AssetManagementService>()

    authenticate("content-manager-jwt") {
        route("/content") {
            // Create new story
            post("/stories") {
                try {
                    val request = call.receive<CreateStoryRequest>()
                    val principal = call.principal<JWTPrincipal>()
                    val creatorId = principal?.payload?.getClaim("userId")?.asString()
                        ?: throw IllegalArgumentException("Invalid token")
                    
                    val story = contentCreationService.createStory(UUID.fromString(creatorId), request)
                    call.respond(HttpStatusCode.Created, story)
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to create story"))
                }
            }
            
            // Update existing story
            put("/stories/{storyId}") {
                try {
                    val storyId = call.parameters["storyId"] 
                        ?: throw IllegalArgumentException("Story ID required")
                    val request = call.receive<CreateStoryRequest>()
                    val principal = call.principal<JWTPrincipal>()
                    val editorId = principal?.payload?.getClaim("userId")?.asString()
                        ?: throw IllegalArgumentException("Invalid token")
                    
                    val story = contentCreationService.updateStory(
                        UUID.fromString(storyId), 
                        UUID.fromString(editorId), 
                        request
                    )
                    call.respond(HttpStatusCode.OK, story)
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to update story"))
                }
            }
            
            // Get stories for content manager
            get("/stories") {
                try {
                    val principal = call.principal<JWTPrincipal>()
                    val managerId = principal?.payload?.getClaim("userId")?.asString()
                        ?: throw IllegalArgumentException("Invalid token")
                    val status = call.request.queryParameters["status"] // filter by status
                    
                    val stories = contentCreationService.getStoriesForManager(UUID.fromString(managerId), status)
                    call.respond(HttpStatusCode.OK, stories)
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to load stories"))
                }
            }
            
            // Submit story for review
            post("/stories/{storyId}/submit") {
                try {
                    val storyId = call.parameters["storyId"] 
                        ?: throw IllegalArgumentException("Story ID required")
                    
                    contentCreationService.submitForReview(UUID.fromString(storyId))
                    call.respond(HttpStatusCode.OK, mapOf("message" to "Story submitted for review"))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to submit story"))
                }
            }
            
            // Asset upload endpoint
            post("/assets/upload") {
                try {
                    val multipart = call.receiveMultipart()
                    val principal = call.principal<JWTPrincipal>()
                    val uploaderId = principal?.payload?.getClaim("userId")?.asString()
                        ?: throw IllegalArgumentException("Invalid token")
                    
                    var storyId: String? = null
                    var assetType: String? = null
                    val uploadedAssets = mutableListOf<AssetUploadResponse>()
                    
                    multipart.forEachPart { part ->
                        when (part) {
                            is PartData.FormItem -> {
                                when (part.name) {
                                    "storyId" -> storyId = part.value
                                    "assetType" -> assetType = part.value
                                }
                            }
                            is PartData.FileItem -> {
                                if (part.originalFileName != null) {
                                    val asset = assetManagementService.uploadAsset(
                                        uploaderId = UUID.fromString(uploaderId),
                                        storyId = storyId?.let { UUID.fromString(it) },
                                        assetType = assetType ?: "image",
                                        filename = part.originalFileName!!,
                                        contentType = part.contentType?.toString() ?: "application/octet-stream",
                                        inputStream = part.streamProvider()
                                    )
                                    uploadedAssets.add(asset)
                                }
                            }
                            else -> {}
                        }
                        part.dispose()
                    }
                    
                    call.respond(HttpStatusCode.OK, mapOf("assets" to uploadedAssets))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to upload assets"))
                }
            }
        }
        
        // Content approval workflow (for admins/reviewers)
        authenticate("admin-jwt") {
            route("/content/moderate") {
                get("/queue") {
                    try {
                        val status = call.request.queryParameters["status"] ?: "pending"
                        val contentItems = contentModerationService.getContentQueue(status)
                        call.respond(HttpStatusCode.OK, contentItems)
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to load content queue"))
                    }
                }
                
                post("/{contentId}/approve") {
                    try {
                        val contentId = call.parameters["contentId"] 
                            ?: throw IllegalArgumentException("Content ID required")
                        val principal = call.principal<JWTPrincipal>()
                        val reviewerId = principal?.payload?.getClaim("userId")?.asString()
                            ?: throw IllegalArgumentException("Invalid token")
                        
                        contentModerationService.approveContent(
                            UUID.fromString(contentId), 
                            UUID.fromString(reviewerId)
                        )
                        call.respond(HttpStatusCode.OK, mapOf("message" to "Content approved"))
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to approve content"))
                    }
                }
                
                post("/{contentId}/reject") {
                    try {
                        val contentId = call.parameters["contentId"] 
                            ?: throw IllegalArgumentException("Content ID required")
                        val rejectionData = call.receive<ContentRejectionRequest>()
                        val principal = call.principal<JWTPrincipal>()
                        val reviewerId = principal?.payload?.getClaim("userId")?.asString()
                            ?: throw IllegalArgumentException("Invalid token")
                        
                        contentModerationService.rejectContent(
                            UUID.fromString(contentId), 
                            UUID.fromString(reviewerId),
                            rejectionData.reason,
                            rejectionData.comments
                        )
                        call.respond(HttpStatusCode.OK, mapOf("message" to "Content rejected"))
                        
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to reject content"))
                    }
                }
            }
        }
    }
}
```

### 4. Database Migration Files

**File**: `/src/main/resources/db/migration/V7__Add_Web_Platform_Tables.sql`
```sql
-- Web Admin Schema
CREATE SCHEMA IF NOT EXISTS web_admin;

-- Admin users table
CREATE TABLE web_admin.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('super_admin', 'content_moderator', 'support')),
    permissions JSONB NOT NULL DEFAULT '[]',
    two_fa_enabled BOOLEAN DEFAULT false,
    two_fa_secret VARCHAR(32),
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Admin sessions table  
CREATE TABLE web_admin.admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES web_admin.admin_users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content Workflow Schema
CREATE SCHEMA IF NOT EXISTS content_workflow;

-- Content items table
CREATE TABLE content_workflow.content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('story', 'game', 'activity')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_data JSONB NOT NULL DEFAULT '{}',
    
    -- Creator information  
    creator_id UUID NOT NULL REFERENCES web_admin.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Workflow status
    status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'approved', 'published', 'archived')),
    version INTEGER DEFAULT 1,
    
    -- Age targeting
    min_age_months INTEGER DEFAULT 24,
    max_age_months INTEGER DEFAULT 144,
    
    -- Educational metadata
    educational_objectives JSONB DEFAULT '[]',
    skills_developed JSONB DEFAULT '[]',  
    tags JSONB DEFAULT '[]',
    
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content versions table
CREATE TABLE content_workflow.content_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    content_data JSONB NOT NULL,
    change_summary TEXT,
    created_by UUID NOT NULL REFERENCES web_admin.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content approvals table
CREATE TABLE content_workflow.content_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES web_admin.admin_users(id),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'needs_changes')),
    comments TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content assets table
CREATE TABLE content_workflow.content_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    asset_type VARCHAR(50) NOT NULL CHECK (asset_type IN ('image', 'audio', 'video', 'document')),
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    metadata JSONB DEFAULT '{}',
    uploaded_by UUID NOT NULL REFERENCES web_admin.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web Sessions Schema
CREATE SCHEMA IF NOT EXISTS web_sessions;

-- Parent web sessions table
CREATE TABLE web_sessions.parent_web_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES core.families(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web activity log table
CREATE TABLE web_sessions.web_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID, -- References various session tables
    user_id UUID NOT NULL,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('parent', 'admin', 'content_manager')),
    activity_type VARCHAR(100) NOT NULL,
    activity_data JSONB DEFAULT '{}',
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Bookmarks Schema
CREATE SCHEMA IF NOT EXISTS bookmarks;

-- Child game bookmarks table
CREATE TABLE bookmarks.child_game_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES core.child_profiles(id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games.game_registry(id) ON DELETE SET NULL,
    
    -- Bookmark details
    bookmark_type VARCHAR(50) NOT NULL DEFAULT 'game' CHECK (bookmark_type IN ('game', 'story', 'activity')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    
    -- Categorization
    category VARCHAR(100),
    age_appropriate BOOLEAN DEFAULT true,
    parent_notes TEXT,
    
    -- Management
    is_active BOOLEAN DEFAULT true,
    is_favorite BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_child_game_bookmark UNIQUE(child_id, game_id, url)
);

-- Bookmark categories table
CREATE TABLE bookmarks.bookmark_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES core.families(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color_hex VARCHAR(7),
    icon_name VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_family_category UNIQUE(family_id, name)
);

-- Indexes for performance
CREATE INDEX idx_admin_users_email ON web_admin.admin_users(email);
CREATE INDEX idx_admin_users_role ON web_admin.admin_users(role);
CREATE INDEX idx_admin_sessions_token ON web_admin.admin_sessions(session_token);
CREATE INDEX idx_content_items_status ON content_workflow.content_items(status);
CREATE INDEX idx_content_items_creator ON content_workflow.content_items(creator_id);
CREATE INDEX idx_content_assets_content_item ON content_workflow.content_assets(content_item_id);
CREATE INDEX idx_parent_web_sessions_token ON web_sessions.parent_web_sessions(session_token);
CREATE INDEX idx_parent_web_sessions_parent ON web_sessions.parent_web_sessions(parent_id);
CREATE INDEX idx_child_bookmarks_child ON bookmarks.child_game_bookmarks(child_id);
CREATE INDEX idx_child_bookmarks_parent ON bookmarks.child_game_bookmarks(parent_id);
CREATE INDEX idx_web_activity_user ON web_sessions.web_activity_log(user_id, user_type);

-- Insert default admin user (password should be changed immediately)
INSERT INTO web_admin.admin_users (email, password_hash, first_name, last_name, role, permissions) 
VALUES (
    'admin@wondernest.com', 
    '$2a$10$N9qo8uLOickgx2ZMRZoMye1NGQZo.B1QcYYtJ4Y5TnINKkVPH7qJW', -- 'password123'  
    'System',
    'Administrator',
    'super_admin',
    '["manage_users", "moderate_content", "view_platform_analytics", "manage_system_settings"]'
);
```

### 5. Web Route Configuration

**File**: `/config/WebRoutingConfig.kt`
```kotlin
package com.wondernest.config

import com.wondernest.api.web.admin.adminAuthRoutes
import com.wondernest.api.web.parent.parentWebRoutes  
import com.wondernest.api.web.content.contentCreationRoutes
import io.ktor.server.application.*
import io.ktor.server.routing.*

fun Application.configureWebRouting() {
    routing {
        route("/api/web/v1") {
            // Admin routes
            adminAuthRoutes()
            adminUserRoutes()
            adminAnalyticsRoutes()
            
            // Parent web portal routes
            parentWebRoutes()
            
            // Content management routes
            contentCreationRoutes()
            contentModerationRoutes()
            
            // Asset upload routes
            assetUploadRoutes()
        }
    }
}
```

### 6. Authentication Configuration Updates

**File**: `/config/Authentication.kt` (extend existing)
```kotlin
// Add to existing authentication configuration

fun Application.configureWebAuthentication() {
    authentication {
        // Extend existing JWT config with web-specific authentication
        
        jwt("parent-web-jwt") {
            realm = "WonderNest Parent Web Portal"
            verifier(
                JWT.require(algorithm)
                    .withAudience(jwtConfig.audience)
                    .withIssuer(jwtConfig.issuer)
                    .withClaim("sessionType", "web-parent")  // Ensure web session
                    .build()
            )
            validate { credential ->
                val userId = credential.payload.getClaim("userId").asString()
                val sessionType = credential.payload.getClaim("sessionType").asString()
                
                if (userId != null && sessionType == "web-parent") {
                    JWTPrincipal(credential.payload)
                } else null
            }
        }
        
        jwt("admin-jwt") {
            realm = "WonderNest Admin Portal"
            verifier(
                JWT.require(algorithm)
                    .withAudience(jwtConfig.audience)
                    .withIssuer(jwtConfig.issuer)
                    .withClaim("sessionType", "admin")
                    .build()
            )
            validate { credential ->
                val userId = credential.payload.getClaim("userId").asString()
                val sessionType = credential.payload.getClaim("sessionType").asString()
                val role = credential.payload.getClaim("role").asString()
                
                if (userId != null && sessionType == "admin" && role in listOf("super_admin", "content_moderator", "support")) {
                    JWTPrincipal(credential.payload)
                } else null
            }
        }
        
        jwt("content-manager-jwt") {
            realm = "WonderNest Content Manager Portal"
            verifier(
                JWT.require(algorithm)
                    .withAudience(jwtConfig.audience)
                    .withIssuer(jwtConfig.issuer)
                    .withClaim("sessionType", "content-manager")
                    .build()
            )
            validate { credential ->
                val userId = credential.payload.getClaim("userId").asString()
                val sessionType = credential.payload.getClaim("sessionType").asString()
                val permissions = credential.payload.getClaim("permissions").asList(String::class.java)
                
                if (userId != null && sessionType == "content-manager" && 
                    permissions.any { it in listOf("create_content", "edit_content") }) {
                    JWTPrincipal(credential.payload)
                } else null
            }
        }
    }
}
```

These backend API updates provide:

1. **Admin Authentication**: Separate admin login system with role-based access
2. **Parent Web Portal**: Dashboard, analytics, bookmarking, and approval management
3. **Content Management**: Story/game creation, workflow, and asset management
4. **Database Schema**: New tables for web functionality without breaking existing mobile app
5. **Security**: Proper authentication middleware for different user types
6. **File Uploads**: Multipart file upload handling for content assets

The implementation maintains backward compatibility with your existing mobile app while adding comprehensive web functionality.