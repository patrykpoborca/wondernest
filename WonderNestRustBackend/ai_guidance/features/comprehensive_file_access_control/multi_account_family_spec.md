# Multi-Account Family File Access Specification

## Overview
WonderNest supports multiple user accounts per family, enabling shared access to family content while maintaining individual ownership rights. This specification details how the file access control system handles multi-account family scenarios.

## Existing Database Architecture

### Family Tables
```sql
-- Family entity
family.families (
  id UUID PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_by UUID NOT NULL REFERENCES core.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)

-- Family membership with roles
family.family_members (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES family.families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES core.users(id),
  role VARCHAR(20) DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(family_id, user_id)
)
```

### Indexes Available
- `idx_family_members_family_id` - for family membership queries
- `idx_family_members_user_id` - for user family lookup
- Unique constraint on `(family_id, user_id)`

## Multi-Account Scenarios

### Typical Family Configurations
1. **Two-Parent Family**
   - Parent A (admin role) - family creator
   - Parent B (member role) - invited family member

2. **Extended Family**
   - Parent A (admin)
   - Parent B (member)  
   - Grandparent (member)
   - Caregiver (member)

3. **Single Parent with Support**
   - Parent (admin)
   - Babysitter (member)
   - Family friend (member)

## File Access Rules

### Access Matrix by Relationship
| File Type | Owner | Family Member | Public User | Notes |
|-----------|-------|---------------|-------------|-------|
| Public File | View, Edit, Delete | View | View | Owner controls all modifications |
| Private File | View, Edit, Delete | View | 404 | Family members can view but not modify |
| System File | View | View | 404/403 | Cannot be deleted by anyone |

### Family Membership Verification Query
```sql
-- Check if two users are in the same family
SELECT COUNT(*) > 0 as are_family_members
FROM family.family_members fm1
JOIN family.family_members fm2 ON fm1.family_id = fm2.family_id
WHERE fm1.user_id = $1 AND fm2.user_id = $2;
```

### Get Family Members Query
```sql
-- Get all family members for a user
SELECT fm2.user_id, u.name, fm2.role
FROM family.family_members fm1
JOIN family.family_members fm2 ON fm1.family_id = fm2.family_id
JOIN core.users u ON fm2.user_id = u.id
WHERE fm1.user_id = $1;
```

## API Response Enhancements

### Enhanced File Response Model
```rust
pub struct FileDto {
    pub id: Uuid,
    pub original_name: String,
    pub mime_type: String,
    pub file_size: i64,
    pub category: String,
    pub is_public: bool,
    
    // Owner information
    pub owner_id: Uuid,
    pub owner_name: String,
    pub is_owner: bool,
    
    // Family relationship (for non-owned files)
    pub relationship: Option<String>, // "spouse", "parent", "caregiver", etc.
    
    // Access information
    pub access_url: String,
    pub permissions: FilePermissions,
    
    pub uploaded_at: DateTime<Utc>,
}

pub struct FilePermissions {
    pub can_view: bool,
    pub can_edit: bool,
    pub can_delete: bool,
    pub can_change_visibility: bool,
}
```

## Implementation Considerations

### Database Performance
- **Existing Indexes**: Current indexes should handle family membership queries efficiently
- **Query Optimization**: JOIN operations on indexed columns (family_id, user_id)
- **Caching Strategy**: Consider caching family relationships for active users

### Security Implications
- **Information Leakage**: Private files must return 404 (not 403) to non-family members
- **Audit Logging**: Track file access attempts across family members
- **Role-Based Access**: Currently roles are informational; consider future admin privileges

### Frontend UX Patterns

#### File Ownership Indicators
```typescript
interface FileDisplayProps {
  file: FileDto;
  currentUserId: string;
}

function FileCard({ file, currentUserId }: FileDisplayProps) {
  const isOwner = file.owner_id === currentUserId;
  
  return (
    <Card>
      <FilePreview src={file.access_url} />
      <FileInfo>
        <FileName>{file.original_name}</FileName>
        {!isOwner && (
          <OwnerBadge>
            <Avatar src={file.owner_avatar} />
            <span>by {file.owner_name}</span>
            {file.relationship && <RelationshipTag>{file.relationship}</RelationshipTag>}
          </OwnerBadge>
        )}
      </FileInfo>
      <FileActions>
        <ViewButton disabled={!file.permissions.can_view} />
        <EditButton disabled={!file.permissions.can_edit} />
        <DeleteButton disabled={!file.permissions.can_delete} />
      </FileActions>
    </Card>
  );
}
```

#### Filter Controls
```typescript
enum FileOwnerFilter {
  ALL = 'all',      // All accessible files
  OWN = 'own',      // Only files I uploaded
  FAMILY = 'family' // Only files from family members
}

interface FileFilters {
  owner: FileOwnerFilter;
  category?: string;
  isPublic?: boolean;
}
```

## Error Handling Patterns

### Information Leakage Prevention
```rust
pub async fn family_download(
    file_id: Uuid,
    requesting_user_id: Uuid,
) -> Result<FileResponse, AppError> {
    // Get file with owner info
    let file = get_file_with_owner(file_id).await?
        .ok_or(AppError::NotFound("File not found".to_string()))?;
    
    // Check access permissions
    if file.is_public {
        return Ok(serve_file(file).await?);
    }
    
    // For private files, verify family relationship
    if !are_family_members(requesting_user_id, file.owner_id).await? {
        // Return 404 (not 403) to prevent information leakage
        return Err(AppError::NotFound("File not found".to_string()));
    }
    
    Ok(serve_file(file).await?)
}
```

### User-Friendly Error Messages
- **404 for private files**: "File not found" (no mention of access restrictions)
- **403 for owned files**: "You don't have permission to perform this action"
- **401 for auth issues**: "Please log in to access this file"

## Testing Scenarios

### Multi-Account Test Cases
1. **Family File Sharing**
   - Parent A uploads private photo
   - Parent B can view but not edit/delete
   - Non-family member gets 404

2. **Ownership Permissions**
   - Only file owner can change visibility
   - Only file owner can edit metadata  
   - Only file owner can delete file

3. **Public File Access**
   - Anyone can view public files
   - Only owner can modify public files
   - Family relationship irrelevant for public files

4. **Family Structure Changes**
   - User leaves family → loses access to private files
   - User joins family → gains access to existing private files
   - Family deletion → all relationships severed

5. **Edge Cases**
   - File owner leaves family but files remain accessible to family
   - Orphaned files when user account deleted
   - Multiple family memberships (if supported in future)

## Migration Considerations

### Existing Data Compatibility
- Current files with `user_id` owners should work seamlessly
- No database schema changes required for core functionality
- Enhanced responses can be added incrementally

### Rollout Strategy
1. **Phase 1**: Backend API enhancements (transparent to existing clients)
2. **Phase 2**: Frontend updates to show owner information
3. **Phase 3**: Advanced filtering and family relationship features
4. **Phase 4**: Role-based permissions (future enhancement)

## Future Enhancements

### Role-Based Permissions
- **Family Admin**: Can manage family files across all members
- **Family Member**: Current behavior (view family files, own their uploads)
- **Limited Member**: View only, cannot upload

### Advanced Family Features
- Family shared albums
- Family file quotas and usage tracking
- Family-wide content moderation settings
- Cross-family content sharing (extended family networks)

---

**Status**: Ready for implementation
**Dependencies**: Existing family tables, JWT authentication system
**Complexity**: Medium-High (database joins, security considerations)
**Estimated Timeline**: 1-2 weeks for core functionality