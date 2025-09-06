# Content-Aware File Deletion

## Overview
Implement a sophisticated file deletion system that respects content dependencies and ensures data integrity. When users delete files from their uploads, the system should check for references to those files in stories, games, and other content before actually deleting them from storage.

## Problem Statement
Currently, the file deletion system (`delete_file` function) immediately removes files from both storage and database without checking if the files are referenced by other content. This can break:
- Stories that embed images or files
- Games that use uploaded assets
- Marketplace content that references files
- Any other content type that might reference user uploads

## User Stories
- **As a parent**, I want to "delete" files from my uploads view without breaking stories that use those images
- **As a parent**, I want to understand why some files can't be completely deleted when they're in use
- **As a child**, I want my stories to continue working even if parent "deletes" the images I used
- **As a developer**, I want a reliable system that maintains content integrity

## Acceptance Criteria
- [ ] Files referenced by active content are detached from user, not physically deleted
- [ ] Files not referenced by any content are completely deleted from storage
- [ ] Users receive clear feedback about deletion vs detachment
- [ ] Orphaned files (no references, no owner) are cleaned up periodically
- [ ] System maintains referential integrity across all content types
- [ ] API responses clearly indicate deletion type (hard delete vs soft detach)

## Content Types That May Reference Files
1. **Stories** (`content.stories`) - Images embedded in story content
2. **Games** - Asset files used in game content
3. **Marketplace Items** - Featured images, preview content
4. **User Profiles** - Profile pictures, avatars
5. **Child Profiles** - Avatar images
6. **Game Templates** - Background images, asset references

## Technical Constraints
- Must work with existing `content.file_references` table
- Must maintain COPPA compliance for child data
- Must support MinIO storage backend
- Should not break existing API contracts
- Must handle concurrent access scenarios
- Should provide audit trail for compliance

## Security Considerations
- Verify user ownership before any deletion operation
- Ensure detached files cannot be accessed by unauthorized users
- Maintain audit logs for deleted/detached files
- Protect against manipulation of reference counts
- Handle edge cases where references exist but are invalid

## Business Rules
1. **Hard Delete**: File has no references and belongs to user → Complete removal
2. **Soft Detach**: File has active references → Remove user ownership, keep file
3. **Protected**: System files or files with special flags → Cannot be deleted
4. **Orphaned Cleanup**: Files with no owner and no references → Periodic cleanup

## Implementation Strategy
### Phase 1: Reference Detection
- Query `content.file_references` for file usage
- Check direct references in stories, profiles, etc.
- Identify all content types that may reference files

### Phase 2: Smart Deletion Logic
- Implement business rules for delete vs detach
- Update file ownership instead of deletion for referenced files
- Maintain audit trail of operations

### Phase 3: User Feedback
- Clear API responses indicating operation type
- UI updates to show detached vs deleted status
- Warning messages for files that cannot be hard deleted

### Phase 4: Cleanup System
- Background job for orphaned file cleanup
- Metrics and monitoring for file lifecycle
- Admin tools for file management

## API Changes Required
```rust
// Enhanced response with operation details
pub struct FileOperationResponse {
    pub file_id: Uuid,
    pub operation: FileOperation, // HardDeleted, SoftDetached, Protected
    pub reason: Option<String>,
    pub references_count: Option<i32>,
    pub references_types: Option<Vec<String>>,
}

pub enum FileOperation {
    HardDeleted,    // Completely removed from storage
    SoftDetached,   // Ownership removed, file preserved
    Protected,      // Cannot be deleted
    AlreadyDeleted, // Was already processed
}
```

## Database Changes Required
### New columns for uploaded_files:
```sql
-- Track detachment vs deletion
ALTER TABLE core.uploaded_files 
ADD COLUMN detached_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN detached_by UUID REFERENCES core.users(id),
ADD COLUMN detachment_reason TEXT;

-- Index for orphaned file cleanup
CREATE INDEX idx_uploaded_files_orphaned 
ON core.uploaded_files (user_id, detached_at) 
WHERE user_id IS NULL AND detached_at IS NOT NULL;
```

## Risk Mitigation
1. **Data Loss Prevention**: Never delete referenced files
2. **Storage Bloat**: Implement orphaned file cleanup
3. **Performance**: Use efficient queries with proper indexes
4. **User Confusion**: Clear messaging about operation results
5. **Compliance**: Maintain audit trail for all operations

## Testing Strategy
1. **Unit Tests**: File reference detection logic
2. **Integration Tests**: End-to-end deletion scenarios
3. **Load Tests**: Concurrent deletion operations
4. **Manual Tests**: User experience validation
5. **Data Integrity**: Verify no broken references after operations

## Monitoring and Metrics
- Track deletion vs detachment ratios
- Monitor orphaned file growth
- Alert on broken references
- Storage usage trends
- User behavior patterns

## Future Enhancements
- Batch operations for multiple files
- Reference visualization for users
- Advanced cleanup policies
- File usage analytics
- Automated reference healing