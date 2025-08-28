-- =============================================================================
-- WonderNest Web Platform Database Schema
-- Migration V7: Core web platform tables
-- =============================================================================

-- Create web admin schema for admin users and management
CREATE SCHEMA IF NOT EXISTS web_admin;

-- Admin users table (separate from parent users)
CREATE TABLE web_admin.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    
    -- Personal information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    
    -- Role and permissions
    role VARCHAR(50) NOT NULL CHECK (role IN (
        'super_admin', 
        'content_moderator', 
        'content_creator',
        'analytics_viewer',
        'support_agent'
    )),
    permissions JSONB NOT NULL DEFAULT '[]',
    
    -- Security
    two_fa_enabled BOOLEAN DEFAULT false,
    two_fa_secret VARCHAR(32),
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_by UUID REFERENCES web_admin.admin_users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Admin sessions table for web authentication
CREATE TABLE web_admin.admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES web_admin.admin_users(id) ON DELETE CASCADE,
    
    -- Token information
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    
    -- Session metadata
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    
    -- Session lifecycle
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content workflow schema for story/game creation and approval
CREATE SCHEMA IF NOT EXISTS content_workflow;

-- Content items table (stories, games, activities)
CREATE TABLE content_workflow.content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Content identification
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN (
        'story', 
        'game', 
        'activity',
        'educational_video',
        'interactive_book'
    )),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    summary TEXT, -- Short description for listings
    
    -- Content data (flexible JSON structure)
    content_data JSONB NOT NULL DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    
    -- Creator information
    creator_id UUID NOT NULL REFERENCES web_admin.admin_users(id),
    
    -- Workflow status
    status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft',
        'in_review', 
        'needs_revision',
        'approved',
        'published',
        'archived',
        'deleted'
    )),
    
    -- Version control
    version INTEGER DEFAULT 1,
    parent_version_id UUID REFERENCES content_workflow.content_items(id),
    
    -- Publishing information
    published_at TIMESTAMP WITH TIME ZONE,
    published_by UUID REFERENCES web_admin.admin_users(id),
    scheduled_publish_at TIMESTAMP WITH TIME ZONE,
    
    -- Age and educational targeting
    min_age_months INTEGER DEFAULT 24 CHECK (min_age_months >= 12),
    max_age_months INTEGER DEFAULT 144 CHECK (max_age_months <= 216),
    
    -- Educational metadata
    educational_objectives JSONB DEFAULT '[]',
    skills_developed JSONB DEFAULT '[]',
    learning_categories JSONB DEFAULT '[]',
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    
    -- Content classification
    tags JSONB DEFAULT '[]',
    keywords JSONB DEFAULT '[]',
    content_rating VARCHAR(20) DEFAULT 'everyone' CHECK (content_rating IN (
        'everyone',
        'early_childhood',
        'preschool',
        'school_age'
    )),
    
    -- Localization
    language_code VARCHAR(10) DEFAULT 'en-US',
    localized_versions JSONB DEFAULT '{}',
    
    -- Analytics and engagement
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    engagement_metrics JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content versions table for change tracking
CREATE TABLE content_workflow.content_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID NOT NULL REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    
    -- Version information
    version_number INTEGER NOT NULL,
    version_name VARCHAR(100), -- e.g., "Initial Draft", "Review Fixes"
    
    -- Version data
    content_data JSONB NOT NULL,
    change_summary TEXT,
    change_details JSONB DEFAULT '{}',
    
    -- Version metadata
    created_by UUID NOT NULL REFERENCES web_admin.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_content_version UNIQUE(content_item_id, version_number)
);

-- Content approval workflow table
CREATE TABLE content_workflow.content_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID NOT NULL REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    
    -- Approval details
    approval_stage VARCHAR(50) NOT NULL CHECK (approval_stage IN (
        'initial_review',
        'educational_review',
        'safety_review',
        'final_approval'
    )),
    
    -- Reviewer information
    reviewer_id UUID NOT NULL REFERENCES web_admin.admin_users(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Review outcome
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'approved',
        'rejected',
        'needs_changes',
        'escalated'
    )),
    
    -- Review details
    comments TEXT,
    feedback_data JSONB DEFAULT '{}',
    
    -- Review completion
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_duration_minutes INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content assets table (images, audio, video, documents)
CREATE TABLE content_workflow.content_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE CASCADE,
    
    -- Asset identification
    asset_type VARCHAR(50) NOT NULL CHECK (asset_type IN (
        'image',
        'audio', 
        'video',
        'document',
        'animation',
        'interactive_element'
    )),
    asset_category VARCHAR(50), -- e.g., 'character', 'background', 'sound_effect'
    
    -- File information
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes > 0),
    mime_type VARCHAR(100) NOT NULL,
    file_hash VARCHAR(64), -- SHA-256 hash for deduplication
    
    -- Asset metadata
    metadata JSONB DEFAULT '{}',
    alt_text TEXT, -- For accessibility
    caption TEXT,
    
    -- Processing status
    processing_status VARCHAR(50) DEFAULT 'uploaded' CHECK (processing_status IN (
        'uploaded',
        'processing',
        'processed',
        'failed',
        'virus_scan_pending',
        'virus_scan_failed',
        'approved'
    )),
    
    -- Thumbnails and previews
    thumbnail_path VARCHAR(500),
    preview_path VARCHAR(500),
    
    -- Asset usage
    usage_context JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT false,
    is_reusable BOOLEAN DEFAULT true,
    
    -- Upload information
    uploaded_by UUID NOT NULL REFERENCES web_admin.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web sessions schema for session management
CREATE SCHEMA IF NOT EXISTS web_sessions;

-- Parent web sessions (extends mobile app sessions for web use)
CREATE TABLE web_sessions.parent_web_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User identification
    parent_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES family.families(id) ON DELETE CASCADE,
    
    -- Session tokens
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    
    -- Session metadata
    device_info JSONB DEFAULT '{}',
    ip_address INET NOT NULL,
    user_agent TEXT,
    browser_fingerprint VARCHAR(255),
    
    -- Session lifecycle
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    
    -- Security
    requires_pin_reauth BOOLEAN DEFAULT false,
    pin_reauth_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web activity logging for audit and analytics
CREATE TABLE web_sessions.web_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Session information
    session_id UUID, -- Can reference any session table
    user_id UUID NOT NULL,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN (
        'parent',
        'admin',
        'content_manager'
    )),
    
    -- Activity details
    activity_type VARCHAR(100) NOT NULL,
    activity_category VARCHAR(50), -- e.g., 'authentication', 'content_creation', 'child_management'
    activity_data JSONB DEFAULT '{}',
    
    -- Request information
    ip_address INET,
    user_agent TEXT,
    request_method VARCHAR(10),
    request_path VARCHAR(500),
    response_status INTEGER,
    
    -- Performance metrics
    response_time_ms INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Bookmarks schema for parent-managed child bookmarks
CREATE SCHEMA IF NOT EXISTS bookmarks;

-- Bookmark categories for organization (create first to avoid foreign key dependency)
CREATE TABLE bookmarks.bookmark_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family.families(id) ON DELETE CASCADE,
    
    -- Category details
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50),
    color_hex VARCHAR(7) CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
    
    -- Category management
    is_system_category BOOLEAN DEFAULT false, -- Pre-defined categories
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_family_category UNIQUE(family_id, name)
);

-- Child game bookmarks table
CREATE TABLE bookmarks.child_game_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Ownership
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    
    -- Bookmark target
    game_id UUID REFERENCES games.game_registry(id) ON DELETE SET NULL,
    content_item_id UUID REFERENCES content_workflow.content_items(id) ON DELETE SET NULL,
    
    -- Bookmark details
    bookmark_type VARCHAR(50) NOT NULL DEFAULT 'game' CHECK (bookmark_type IN (
        'game',
        'story', 
        'activity',
        'educational_video',
        'external_link'
    )),
    
    -- Display information
    title VARCHAR(255) NOT NULL,
    description TEXT,
    thumbnail_url VARCHAR(500),
    external_url VARCHAR(500), -- For external content
    
    -- Categorization and organization
    category_id UUID REFERENCES bookmarks.bookmark_categories(id) ON DELETE SET NULL,
    custom_category VARCHAR(100),
    
    -- Parent management
    age_appropriate BOOLEAN DEFAULT true,
    parent_notes TEXT,
    parent_rating INTEGER CHECK (parent_rating BETWEEN 1 AND 5),
    
    -- Bookmark status
    is_active BOOLEAN DEFAULT true,
    is_favorite BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    
    -- Access tracking
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure no duplicate bookmarks
    CONSTRAINT unique_child_bookmark UNIQUE NULLS NOT DISTINCT (child_id, game_id, content_item_id, external_url)
);

-- Notification system for web platform
CREATE SCHEMA IF NOT EXISTS web_notifications;

-- Web notifications table
CREATE TABLE web_notifications.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Recipient
    user_id UUID NOT NULL,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('parent', 'admin', 'content_manager')),
    
    -- Notification details
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    
    -- Notification data
    data JSONB DEFAULT '{}',
    action_url VARCHAR(500),
    
    -- Priority and category
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    category VARCHAR(50), -- e.g., 'approval', 'system', 'content', 'security'
    
    -- Status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    is_dismissed BOOLEAN DEFAULT false,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    
    -- Expiry
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web platform settings
CREATE SCHEMA IF NOT EXISTS web_settings;

-- Platform configuration table
CREATE TABLE web_settings.platform_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Configuration key-value pairs
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    
    -- Configuration metadata
    description TEXT,
    is_sensitive BOOLEAN DEFAULT false, -- Encrypted in application layer
    is_system BOOLEAN DEFAULT false, -- Cannot be modified via UI
    
    -- Validation
    validation_schema JSONB, -- JSON schema for value validation
    
    -- Modification tracking
    modified_by UUID REFERENCES web_admin.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User preferences for web interface
CREATE TABLE web_settings.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User identification
    user_id UUID NOT NULL,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('parent', 'admin', 'content_manager')),
    
    -- Preferences
    preferences JSONB NOT NULL DEFAULT '{}',
    
    -- Preference metadata
    last_sync_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_preferences UNIQUE(user_id, user_type)
);

-- Audit trail for important actions
CREATE SCHEMA IF NOT EXISTS web_audit;

-- Audit log table
CREATE TABLE web_audit.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Who performed the action
    user_id UUID NOT NULL,
    user_type VARCHAR(50) NOT NULL,
    user_email VARCHAR(255),
    
    -- What action was performed
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50), -- e.g., 'content_item', 'user', 'bookmark'
    resource_id UUID,
    
    -- Action details
    action_data JSONB DEFAULT '{}',
    old_values JSONB,
    new_values JSONB,
    
    -- Context information
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    
    -- Result
    success BOOLEAN NOT NULL,
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Comment: All tables created successfully
-- The schema supports:
-- 1. Admin user management with role-based permissions
-- 2. Content creation and approval workflow
-- 3. Asset management with security scanning
-- 4. Web session management for different user types
-- 5. Parent-managed child bookmarking system
-- 6. Notification system for web platform
-- 7. Configuration and user preferences
-- 8. Comprehensive audit logging