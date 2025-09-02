-- Add tags support for uploaded files and images
-- This enables AI-powered story generation based on image content

-- Create tags table for storing unique tags
CREATE TABLE IF NOT EXISTS content.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tags_name ON content.tags(name);
CREATE INDEX IF NOT EXISTS idx_tags_usage ON content.tags(usage_count DESC);

-- Create file_tags junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS content.file_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID NOT NULL,
    tag_id UUID NOT NULL REFERENCES content.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES core.users(id),
    UNIQUE(file_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_file_tags_file ON content.file_tags(file_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_tag ON content.file_tags(tag_id);

-- Add tags column to uploaded_files table for quick access (denormalized for performance)
ALTER TABLE core.uploaded_files 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS tag_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_system_image BOOLEAN DEFAULT FALSE;

-- Create indexes for tag searching
CREATE INDEX IF NOT EXISTS idx_uploaded_files_tags ON core.uploaded_files USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_uploaded_files_tag_count ON core.uploaded_files(tag_count);
CREATE INDEX IF NOT EXISTS idx_uploaded_files_system ON core.uploaded_files(is_system_image);

-- Add validation constraint for minimum tags (removed - will handle in application layer)
-- Constraints on array length are complex in PostgreSQL

-- Create function to update tag usage counts
CREATE OR REPLACE FUNCTION content.update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE content.tags 
        SET usage_count = usage_count + 1 
        WHERE id = NEW.tag_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE content.tags 
        SET usage_count = usage_count - 1 
        WHERE id = OLD.tag_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for tag usage counting
DROP TRIGGER IF EXISTS update_tag_usage ON content.file_tags;
CREATE TRIGGER update_tag_usage
AFTER INSERT OR DELETE ON content.file_tags
FOR EACH ROW
EXECUTE FUNCTION content.update_tag_usage_count();

-- Create function to sync tags array in uploaded_files
CREATE OR REPLACE FUNCTION content.sync_file_tags()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the tags array and count in uploaded_files
    UPDATE core.uploaded_files
    SET tags = (
        SELECT COALESCE(array_agg(t.name ORDER BY t.name), '{}')
        FROM content.file_tags ft
        JOIN content.tags t ON ft.tag_id = t.id
        WHERE ft.file_id = COALESCE(NEW.file_id, OLD.file_id)
    ),
    tag_count = (
        SELECT COUNT(*)
        FROM content.file_tags
        WHERE file_id = COALESCE(NEW.file_id, OLD.file_id)
    )
    WHERE id = COALESCE(NEW.file_id, OLD.file_id);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to keep tags array in sync
DROP TRIGGER IF EXISTS sync_tags_array ON content.file_tags;
CREATE TRIGGER sync_tags_array
AFTER INSERT OR DELETE ON content.file_tags
FOR EACH ROW
EXECUTE FUNCTION content.sync_file_tags();

-- Pre-populate common tags for suggestions
INSERT INTO content.tags (name, usage_count) VALUES
    -- Animals
    ('animal', 0), ('bird', 0), ('dog', 0), ('cat', 0), ('fish', 0), ('butterfly', 0), ('dinosaur', 0),
    -- Colors
    ('red', 0), ('blue', 0), ('green', 0), ('yellow', 0), ('orange', 0), ('purple', 0), ('pink', 0), ('black', 0), ('white', 0), ('brown', 0),
    -- Sizes
    ('big', 0), ('small', 0), ('tiny', 0), ('large', 0), ('medium', 0),
    -- Nature
    ('tree', 0), ('flower', 0), ('sun', 0), ('moon', 0), ('star', 0), ('cloud', 0), ('mountain', 0), ('ocean', 0), ('river', 0), ('forest', 0),
    -- Objects
    ('car', 0), ('truck', 0), ('airplane', 0), ('train', 0), ('boat', 0), ('house', 0), ('building', 0), ('toy', 0), ('ball', 0), ('book', 0),
    -- People
    ('person', 0), ('child', 0), ('family', 0), ('friend', 0), ('baby', 0),
    -- Actions
    ('running', 0), ('jumping', 0), ('playing', 0), ('sleeping', 0), ('eating', 0), ('flying', 0), ('swimming', 0),
    -- Emotions
    ('happy', 0), ('sad', 0), ('excited', 0), ('calm', 0), ('funny', 0),
    -- Descriptive
    ('colorful', 0), ('bright', 0), ('dark', 0), ('shiny', 0), ('soft', 0), ('rough', 0), ('smooth', 0),
    -- Educational
    ('numbers', 0), ('letters', 0), ('shapes', 0), ('colors', 0), ('counting', 0),
    -- System tags
    ('background', 0), ('sticker', 0), ('character', 0), ('prop', 0), ('scene', 0), ('texture', 0), ('pattern', 0)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE content.tags IS 'Stores unique tags for categorizing uploaded files and images';
COMMENT ON TABLE content.file_tags IS 'Junction table linking files to their tags';
COMMENT ON COLUMN core.uploaded_files.tags IS 'Denormalized array of tag names for quick access';
COMMENT ON COLUMN core.uploaded_files.tag_count IS 'Number of tags associated with this file';
COMMENT ON COLUMN core.uploaded_files.is_system_image IS 'Whether this is a system-provided image (exempted from minimum tag requirement)';