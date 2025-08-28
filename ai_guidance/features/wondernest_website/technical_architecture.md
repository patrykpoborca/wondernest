# WonderNest Website Technical Architecture

## Tech Stack Recommendations

### Frontend Web Application
**Primary Technology**: React 18 with TypeScript
- **Rationale**: Mature ecosystem, excellent TypeScript support, extensive component libraries
- **State Management**: Redux Toolkit with RTK Query for API state management
- **UI Framework**: Material-UI (MUI) v5 with custom WonderNest theme
- **Routing**: React Router v6 with protected routes and role-based access
- **Forms**: React Hook Form with Zod validation
- **File Uploads**: React Dropzone with chunked upload support
- **Rich Text Editor**: TipTap or Draft.js for story/content creation
- **Charts/Analytics**: Chart.js or Recharts for parent dashboard analytics

### Alternative Consideration: Next.js 13+
**If server-side rendering is required**:
- **Benefits**: Better SEO, faster initial page loads, API routes
- **Trade-offs**: More complex deployment, potential over-engineering for admin tools
- **Recommendation**: Use React SPA for faster development, consider Next.js for future marketing site

### Backend Integration
**Extend Existing KTOR 3.0 Backend**:
- Add web-specific route modules under `/api/web/v1/`
- Implement role-based authentication middleware
- Add file upload handling with content scanning
- Extend existing JWT authentication for web sessions

### Database Architecture
**Extend Existing PostgreSQL 16 with New Schemas**:
```sql
-- New schemas to add:
- web_admin (admin users, roles, permissions)
- content_workflow (content creation, approval, versioning)  
- web_sessions (web-specific session management)
- bookmarks (parent-managed child bookmarks)
```

### Infrastructure
**Development/Deployment**:
- **Development**: Vite dev server with KTOR backend proxy
- **Production**: Nginx reverse proxy serving React build + KTOR backend
- **CDN**: CloudFlare for static assets and content delivery
- **File Storage**: AWS S3 or MinIO for story assets and user uploads

## Architecture Patterns

### Frontend Architecture
```
src/
├── app/                          # Redux store, providers
├── components/                   # Reusable UI components
│   ├── common/                   # Generic components (buttons, inputs)
│   ├── layout/                   # Layout components (header, sidebar)
│   └── domain/                   # Domain-specific components
├── features/                     # Feature-based modules
│   ├── auth/                     # Authentication (login, logout)
│   ├── parent-portal/            # Parent dashboard features
│   ├── admin-portal/             # Admin management features
│   ├── content-manager/          # Content creation tools
│   └── game-browser/             # Game discovery and bookmarking
├── hooks/                        # Custom React hooks
├── services/                     # API clients and utilities
├── types/                        # TypeScript type definitions
├── utils/                        # Utility functions
└── assets/                       # Static assets
```

### Backend Route Structure
```kotlin
// Extend existing KTOR backend with:
route("/api/web/v1") {
    // Authentication routes
    route("/auth") {
        post("/admin/login")           // Admin-specific login
        post("/web/login")             // Web parent login
        get("/session/verify")         // Session verification
    }
    
    // Parent portal routes  
    authenticate("parent-web") {
        route("/parent") {
            get("/dashboard")          // Dashboard data
            get("/children/{id}/analytics") // Child analytics
            post("/bookmarks")         // Game bookmarks
            put("/child/{id}/settings") // Child settings
            get("/approvals/pending")  // Pending approvals
            post("/approvals/{id}/decision") // Approval decisions
        }
    }
    
    // Admin portal routes
    authenticate("admin-web") {
        route("/admin") {
            get("/users")              // User management
            get("/analytics/platform") // Platform analytics
            post("/content/moderate")  // Content moderation
            get("/system/health")      // System monitoring
        }
    }
    
    // Content manager routes
    authenticate("content-manager-web") {
        route("/content") {
            post("/stories")           // Create story
            put("/stories/{id}")       // Update story
            get("/stories/draft")      // Draft stories
            post("/stories/{id}/publish") // Publish story
            post("/assets/upload")     // Asset upload
            get("/workflow/queue")     // Approval queue
        }
    }
    
    // File upload routes (multipart support)
    route("/upload") {
        post("/story-assets")          // Story images/audio
        post("/game-assets")           // Game resources
        post("/avatar-images")         // Profile avatars
    }
}
```

### Authentication Strategy

#### Multi-Tier Authentication System
```kotlin
// 1. Parent Web Authentication
// Uses existing JWT but with additional web-specific claims
data class WebParentToken(
    val parentId: UUID,
    val familyId: UUID,
    val sessionType: String = "web-parent",
    val permissions: List<String>, // ["view_children", "manage_settings"]
    val expiresAt: Instant
)

// 2. Admin Authentication  
// Separate authentication system with elevated privileges
data class AdminToken(
    val adminId: UUID,
    val role: AdminRole, // SUPER_ADMIN, CONTENT_MODERATOR, SUPPORT
    val sessionType: String = "admin",
    val permissions: List<String>, // ["manage_users", "moderate_content"]
    val expiresAt: Instant
)

// 3. Content Manager Authentication
// Role-based access within admin system
data class ContentManagerToken(
    val managerId: UUID,
    val role: ContentRole, // CREATOR, EDITOR, PUBLISHER
    val sessionType: String = "content-manager", 
    val permissions: List<String>, // ["create_stories", "publish_content"]
    val expiresAt: Instant
)
```

#### Session Management
- **Parent Sessions**: 7-day expiry, shared with mobile app
- **Admin Sessions**: 4-hour expiry, web-only, requires 2FA
- **Content Manager Sessions**: 8-hour expiry, auto-extend on activity

### Database Schema Extensions

#### Web Admin Schema
```sql
CREATE SCHEMA IF NOT EXISTS web_admin;

-- Admin users (separate from parents)
CREATE TABLE web_admin.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL, -- 'super_admin', 'content_moderator', 'support'
    permissions JSONB NOT NULL DEFAULT '[]',
    two_fa_enabled BOOLEAN DEFAULT false,
    two_fa_secret VARCHAR(32),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Admin sessions
CREATE TABLE web_admin.admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES web_admin.admin_users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content managers (subset of admin users)
CREATE TABLE web_admin.content_managers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES web_admin.admin_users(id) ON DELETE CASCADE,
    specializations JSONB NOT NULL DEFAULT '[]', -- ['story_creation', 'game_design']
    content_permissions JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### Content Workflow Schema
```sql
CREATE SCHEMA IF NOT EXISTS content_workflow;

-- Content items (stories, games, etc.)
CREATE TABLE content_workflow.content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(50) NOT NULL, -- 'story', 'game', 'activity'
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_data JSONB NOT NULL DEFAULT '{}',
    
    -- Creator information
    creator_id UUID NOT NULL, -- References web_admin.admin_users
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Workflow status
    status VARCHAR(50) NOT NULL DEFAULT 'draft', -- 'draft', 'review', 'approved', 'published', 'archived'
    version INTEGER DEFAULT 1,
    
    -- Age targeting
    min_age_months INTEGER DEFAULT 24,
    max_age_months INTEGER DEFAULT 144,
    
    -- Educational metadata
    educational_objectives JSONB DEFAULT '[]',
    skills_developed JSONB DEFAULT '[]',
    tags JSONB DEFAULT '[]'
);

-- Content versions (for tracking changes)
CREATE TABLE content_workflow.content_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    content_data JSONB NOT NULL,
    change_summary TEXT,
    created_by UUID NOT NULL, -- References web_admin.admin_users
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content approval workflow
CREATE TABLE content_workflow.content_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL, -- References web_admin.admin_users
    status VARCHAR(50) NOT NULL, -- 'pending', 'approved', 'rejected', 'needs_changes'
    comments TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content assets (images, audio, etc.)
CREATE TABLE content_workflow.content_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    asset_type VARCHAR(50) NOT NULL, -- 'image', 'audio', 'video', 'document'
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    metadata JSONB DEFAULT '{}',
    uploaded_by UUID NOT NULL, -- References web_admin.admin_users
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### Web Sessions Schema
```sql  
CREATE SCHEMA IF NOT EXISTS web_sessions;

-- Web-specific parent sessions
CREATE TABLE web_sessions.parent_web_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL, -- References core.users
    family_id UUID NOT NULL, -- References core.families  
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web activity tracking
CREATE TABLE web_sessions.web_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID, -- Can reference any session table
    user_id UUID NOT NULL,
    user_type VARCHAR(50) NOT NULL, -- 'parent', 'admin', 'content_manager'
    activity_type VARCHAR(100) NOT NULL,
    activity_data JSONB DEFAULT '{}',
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### Bookmarks Schema
```sql
CREATE SCHEMA IF NOT EXISTS bookmarks;

-- Parent-managed child bookmarks
CREATE TABLE bookmarks.child_game_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- References core.child_profiles
    parent_id UUID NOT NULL, -- References core.users (who created bookmark)
    game_id UUID, -- References games.game_registry (nullable for external games)
    
    -- Bookmark details
    bookmark_type VARCHAR(50) NOT NULL DEFAULT 'game', -- 'game', 'story', 'activity'
    title VARCHAR(255) NOT NULL,
    description TEXT,
    url VARCHAR(500), -- For external content
    thumbnail_url VARCHAR(500),
    
    -- Categorization
    category VARCHAR(100), -- 'educational', 'creative', 'problem_solving'
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

-- Bookmark categories for organization
CREATE TABLE bookmarks.bookmark_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL, -- References core.families
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color_hex VARCHAR(7), -- For UI theming
    icon_name VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_family_category UNIQUE(family_id, name)
);
```

## Security Implementation

### Role-Based Access Control (RBAC)
```typescript
// Frontend role definitions
export enum UserRole {
  PARENT = 'parent',
  ADMIN = 'admin', 
  CONTENT_MANAGER = 'content_manager',
  SUPER_ADMIN = 'super_admin'
}

export enum Permission {
  // Parent permissions
  VIEW_CHILD_PROGRESS = 'view_child_progress',
  MANAGE_CHILD_SETTINGS = 'manage_child_settings',
  APPROVE_PURCHASES = 'approve_purchases',
  MANAGE_BOOKMARKS = 'manage_bookmarks',
  
  // Admin permissions
  MANAGE_USERS = 'manage_users',
  VIEW_PLATFORM_ANALYTICS = 'view_platform_analytics',
  MODERATE_CONTENT = 'moderate_content',
  MANAGE_SYSTEM_SETTINGS = 'manage_system_settings',
  
  // Content manager permissions
  CREATE_CONTENT = 'create_content',
  EDIT_CONTENT = 'edit_content',
  PUBLISH_CONTENT = 'publish_content',
  MANAGE_ASSETS = 'manage_assets'
}
```

### Authentication Flow
```typescript
// Authentication service
export class AuthService {
  async loginParent(credentials: ParentLoginRequest): Promise<AuthResponse> {
    // 1. Validate credentials against existing parent auth
    // 2. Generate web-specific JWT with parent permissions
    // 3. Create web session record
    // 4. Return tokens + user data
  }
  
  async loginAdmin(credentials: AdminLoginRequest): Promise<AdminAuthResponse> {
    // 1. Validate admin credentials (separate from parent system)
    // 2. Check 2FA if enabled  
    // 3. Generate admin JWT with role-based permissions
    // 4. Create admin session record
    // 5. Return tokens + admin profile
  }
  
  async refreshToken(refreshToken: string): Promise<AuthResponse> {
    // Works for both parent and admin tokens
    // Validates against appropriate session table
  }
}
```

### Content Security Policy
```typescript
// CSP Configuration for content creation tools
export const contentSecurityPolicy = {
  'default-src': ["'self'"],
  'script-src': ["'self'", "'unsafe-inline'", 'https://cdn.jsdelivr.net'],
  'style-src': ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
  'img-src': ["'self'", 'data:', 'https:'],
  'media-src': ["'self'", 'https:'],
  'connect-src': ["'self'", 'wss:', 'https:'],
  'font-src': ["'self'", 'https://fonts.gstatic.com'],
  'frame-ancestors': ["'none'"],
  'base-uri': ["'self'"],
  'form-action': ["'self'"]
};
```

## Integration Points

### Mobile App Integration
```kotlin
// Backend: Shared services between web and mobile
class SharedGameService {
    // Used by both mobile app and web portal
    suspend fun getChildBookmarks(childId: UUID): List<BookmarkedGame>
    suspend fun addBookmark(parentId: UUID, childId: UUID, gameId: UUID): BookmarkResult
    suspend fun syncChildSettings(childId: UUID): ChildSettings
}

class SharedAnalyticsService {
    // Used by both parent mobile view and web dashboard
    suspend fun getChildDevelopmentInsights(childId: UUID, period: TimePeriod): DevelopmentInsights
    suspend fun getGameUsageStats(childId: UUID): GameUsageStats
}
```

### API Compatibility Layer
```typescript
// Frontend: API client that works with existing backend
export class WonderNestApiClient {
  // Parent portal methods
  async getChildAnalytics(childId: string): Promise<ChildAnalytics> {
    // Calls same endpoint as mobile app: GET /api/v1/analytics/children/{childId}
  }
  
  async getGameBookmarks(childId: string): Promise<BookmarkedGame[]> {
    // New web endpoint: GET /api/web/v1/parent/children/{childId}/bookmarks
  }
  
  // Admin methods
  async getPlatformMetrics(): Promise<PlatformMetrics> {
    // New admin endpoint: GET /api/web/v1/admin/analytics/platform  
  }
  
  async moderateContent(contentId: string, decision: ModerationDecision): Promise<void> {
    // New admin endpoint: POST /api/web/v1/admin/content/{contentId}/moderate
  }
}
```

## Development Approach

### Phase 1: Foundation (Weeks 1-2)
- Set up React application with TypeScript
- Implement basic authentication for parents (reusing existing JWT)
- Create responsive layout components  
- Set up Redux store with RTK Query
- Basic parent dashboard with mock data

### Phase 2: Parent Portal (Weeks 3-4) 
- Child profile management interface
- Activity analytics dashboard with charts
- Game bookmarking system
- Content filtering controls
- Approval queue for purchase requests

### Phase 3: Admin Foundation (Weeks 5-6)
- Admin authentication system (separate from parent auth)
- Admin user management
- Basic platform analytics dashboard
- User account management tools

### Phase 4: Content Management (Weeks 7-8)
- Story/content creation tools
- File upload system with asset management
- Content approval workflow
- Publishing pipeline

### Phase 5: Polish & Integration (Weeks 9-10)
- Mobile app integration testing
- Performance optimization
- Security audit
- User acceptance testing

## Performance Considerations

### Frontend Optimization
- **Code Splitting**: Route-based and component-based splitting
- **Lazy Loading**: Dashboard charts and content editor components  
- **Caching**: Redux persist for offline dashboard viewing
- **Bundle Analysis**: Webpack bundle analyzer for size optimization

### Backend Optimization
- **Database Indexing**: Proper indexes on web-specific queries
- **Caching**: Redis caching for dashboard analytics
- **Connection Pooling**: Dedicated connection pool for web API
- **File Upload**: Chunked uploads with resumability

### Monitoring
- **Error Tracking**: Sentry for frontend error monitoring
- **Performance**: Web Vitals monitoring for user experience
- **API Monitoring**: Existing KTOR monitoring extended for web routes
- **Analytics**: User behavior tracking (COPPA-compliant)

This technical architecture leverages your existing KTOR backend and PostgreSQL database while adding the necessary components for a comprehensive web platform that serves parents, admins, and content managers efficiently.