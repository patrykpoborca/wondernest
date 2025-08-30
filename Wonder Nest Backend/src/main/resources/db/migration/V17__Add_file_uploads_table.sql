-- V17__Add_file_uploads_table.sql
-- Create table for tracking uploaded files

CREATE TABLE IF NOT EXISTS core.uploaded_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    
    -- File information
    file_key VARCHAR(500) NOT NULL UNIQUE,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    storage_provider VARCHAR(50) NOT NULL DEFAULT 'local',
    
    -- URL and access
    url TEXT,
    is_public BOOLEAN DEFAULT false,
    
    -- Categorization
    category VARCHAR(50) NOT NULL DEFAULT 'content',
    
    -- Metadata (JSON)
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    accessed_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Indexes
    CONSTRAINT uploaded_files_category_check CHECK (category IN ('profile_picture', 'content', 'document', 'game_asset', 'artwork'))
);

-- Create indexes for common queries
CREATE INDEX idx_uploaded_files_user_id ON core.uploaded_files(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_uploaded_files_child_id ON core.uploaded_files(child_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_uploaded_files_category ON core.uploaded_files(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_uploaded_files_uploaded_at ON core.uploaded_files(uploaded_at DESC) WHERE deleted_at IS NULL;

-- Note: Profile picture columns would be added here but require table ownership
-- These can be added manually if needed:
-- ALTER TABLE core.users ADD COLUMN IF NOT EXISTS profile_picture_file_id UUID REFERENCES core.uploaded_files(id) ON DELETE SET NULL;
-- ALTER TABLE family.child_profiles ADD COLUMN IF NOT EXISTS profile_picture_file_id UUID REFERENCES core.uploaded_files(id) ON DELETE SET NULL;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON core.uploaded_files TO wondernest_app;