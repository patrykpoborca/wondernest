-- Migration: Add soft delete support for uploaded files
-- This allows files to be removed from user's library while preserving them for existing stories

-- Add soft delete columns to uploaded_files table
ALTER TABLE core.uploaded_files
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Create index for efficient querying of non-deleted files
CREATE INDEX IF NOT EXISTS idx_uploaded_files_not_deleted 
ON core.uploaded_files(user_id, is_deleted) 
WHERE is_deleted = FALSE;

-- Create table to track file references in stories
CREATE TABLE IF NOT EXISTS content.file_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID NOT NULL REFERENCES core.uploaded_files(id) ON DELETE CASCADE,
    reference_type VARCHAR(50) NOT NULL, -- 'story', 'profile_picture', etc.
    reference_id UUID NOT NULL, -- ID of the story, profile, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_file_reference UNIQUE(file_id, reference_type, reference_id)
);

-- Create index for efficient lookup
CREATE INDEX IF NOT EXISTS idx_file_references_file_id ON content.file_references(file_id);
CREATE INDEX IF NOT EXISTS idx_file_references_reference ON content.file_references(reference_type, reference_id);

-- Function to check if a file is in use
CREATE OR REPLACE FUNCTION content.is_file_in_use(p_file_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM content.file_references 
        WHERE file_id = p_file_id
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql;

-- Function to add a file reference
CREATE OR REPLACE FUNCTION content.add_file_reference(
    p_file_id UUID,
    p_reference_type VARCHAR(50),
    p_reference_id UUID
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO content.file_references (file_id, reference_type, reference_id)
    VALUES (p_file_id, p_reference_type, p_reference_id)
    ON CONFLICT (file_id, reference_type, reference_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Function to remove a file reference
CREATE OR REPLACE FUNCTION content.remove_file_reference(
    p_file_id UUID,
    p_reference_type VARCHAR(50),
    p_reference_id UUID
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM content.file_references 
    WHERE file_id = p_file_id 
    AND reference_type = p_reference_type 
    AND reference_id = p_reference_id;
END;
$$ LANGUAGE plpgsql;

-- Add comment for documentation
COMMENT ON COLUMN core.uploaded_files.is_deleted IS 'Soft delete flag - when true, file is hidden from user but preserved for existing content';
COMMENT ON COLUMN core.uploaded_files.deleted_at IS 'Timestamp when file was soft deleted';
COMMENT ON TABLE content.file_references IS 'Tracks where uploaded files are being used to prevent breaking content on deletion';