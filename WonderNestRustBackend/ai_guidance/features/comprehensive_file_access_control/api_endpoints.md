# API Endpoints: Comprehensive File Access Control

## Endpoint Overview

| Endpoint | Method | Auth Required | Purpose | Access Level |
|----------|---------|---------------|---------|--------------|
| `/api/v1/files/{id}/public` | GET | No | Public file access | Anyone |
| `/api/v1/files/{id}/family` | GET | Yes | Family file access | Family members |
| `/api/v1/files/{id}` | PUT | Yes | Update file metadata | Owner only |
| `/api/v1/files/{id}` | DELETE | Yes | Delete file | Owner only |
| `/api/v1/files/{id}/visibility` | PATCH | Yes | Toggle public/private | Owner only |
| `/api/v1/files` | GET | Yes | List user's files | User only |

## Detailed Endpoint Specifications

### 1. Public File Access
```
GET /api/v1/files/{id}/public
```

**Purpose**: Allow anyone to access public files without authentication

**Authentication**: None required

**Access Control**:
- Only serves files where `is_public = true`
- Returns 404 for private files (no information leakage)
- Returns 404 for non-existent files

**Response Codes**:
- `200 OK`: File found and served
- `404 Not Found`: File doesn't exist OR is private
- `429 Too Many Requests`: Rate limit exceeded

**Headers**:
- `Content-Type`: File's MIME type
- `Content-Disposition`: `inline; filename="original_name"`
- `Cache-Control`: `public, max-age=3600`
- `X-RateLimit-*`: Rate limiting headers

**Example**:
```bash
curl https://api.wondernest.com/api/v1/files/123e4567-e89b-12d3-a456-426614174000/public
# Returns file content if public, 404 if private or non-existent
```

---

### 2. Family File Access
```
GET /api/v1/files/{id}/family
```

**Purpose**: Allow family members (multi-account) to access private files of other family member accounts

**Authentication**: JWT Bearer token required

**Access Control**:
- Requires valid JWT token
- For public files: allows access to anyone with valid token
- For private files: verifies requesting user is in same family as file owner via `family.family_members` table
- Multi-account family support: Parent A can access Parent B's private files if both in same family
- Returns 404 for files not accessible to user (no information leakage)

**Response Codes**:
- `200 OK`: File found and user has access
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: File doesn't exist OR user lacks access

**Headers**:
- `Content-Type`: File's MIME type
- `Content-Disposition`: `inline; filename="original_name"`
- `Cache-Control`: `private, max-age=300`

**Example**:
```bash
curl -H "Authorization: Bearer jwt_token" \
  https://api.wondernest.com/api/v1/files/123e4567-e89b-12d3-a456-426614174000/family
```

---

### 3. Update File Metadata
```
PUT /api/v1/files/{id}
```

**Purpose**: Allow file owners to update file metadata (name, description, tags)

**Authentication**: JWT Bearer token required

**Access Control**: Only file owner can update metadata

**Request Body**:
```json
{
  "original_name": "new_filename.jpg",
  "description": "Updated description",
  "tags": ["tag1", "tag2"],
  "category": "content"
}
```

**Response Body**:
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "original_name": "new_filename.jpg",
    "description": "Updated description", 
    "tags": ["tag1", "tag2"],
    "category": "content",
    "updated_at": "2025-09-06T05:15:00Z"
  }
}
```

**Response Codes**:
- `200 OK`: Metadata updated successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: User is not file owner
- `404 Not Found`: File doesn't exist

---

### 4. Delete File
```
DELETE /api/v1/files/{id}
```

**Purpose**: Allow file owners to delete their files (with content-aware logic)

**Authentication**: JWT Bearer token required

**Access Control**: Only file owner can delete files

**Response Body**:
```json
{
  "success": true,
  "data": {
    "file_id": "123e4567-e89b-12d3-a456-426614174000",
    "operation": "hard_deleted",
    "reason": "File 'photo.jpg' completely removed",
    "storage_freed": 1048576,
    "timestamp": "2025-09-06T05:15:00Z"
  }
}
```

**Response Codes**:
- `200 OK`: File processed (deleted or detached)
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: User is not file owner
- `404 Not Found`: File doesn't exist

---

### 5. Toggle File Visibility
```
PATCH /api/v1/files/{id}/visibility
```

**Purpose**: Allow file owners to change files between public and private

**Authentication**: JWT Bearer token required

**Access Control**: Only file owner can change visibility

**Request Body**:
```json
{
  "is_public": false
}
```

**Response Body**:
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "is_public": false,
    "access_url": "https://api.wondernest.com/api/v1/files/123.../family",
    "updated_at": "2025-09-06T05:15:00Z"
  }
}
```

**Response Codes**:
- `200 OK`: Visibility updated successfully
- `400 Bad Request`: Invalid visibility value
- `401 Unauthorized`: Missing or invalid token  
- `403 Forbidden`: User is not file owner
- `404 Not Found`: File doesn't exist

---

### 6. List User Files (Enhanced)
```
GET /api/v1/files?category=content&limit=50&offset=0
```

**Purpose**: List files accessible to the user with permission information

**Authentication**: JWT Bearer token required

**Access Control**: Returns files based on user's access permissions

**Query Parameters**:
- `category`: Filter by file category
- `child_id`: Filter by child ID
- `limit`: Maximum number of results (default: 50)
- `offset`: Pagination offset (default: 0)
- `include_family`: Include family members' private files (default: true)
- `owner_filter`: "own" | "family" | "all" - filter by file ownership (default: "all")

**Response Body**:
```json
{
  "success": true,
  "data": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "original_name": "photo.jpg",
      "mime_type": "image/jpeg",
      "file_size": 1048576,
      "category": "content",
      "is_public": true,
      "owner_id": "user123",
      "owner_name": "John Smith",
      "is_owner": true,
      "uploaded_at": "2025-09-06T05:00:00Z",
      "access_url": "https://api.wondernest.com/api/v1/files/123.../public",
      "permissions": {
        "can_view": true,
        "can_edit": true,
        "can_delete": true,
        "can_change_visibility": true
      }
    },
    {
      "id": "456e7890-e12b-34c5-d678-901234567890",
      "original_name": "family_photo.jpg", 
      "mime_type": "image/jpeg",
      "file_size": 2048576,
      "category": "content",
      "is_public": false,
      "owner_id": "spouse123",
      "owner_name": "Jane Smith",
      "is_owner": false,
      "relationship": "spouse",
      "uploaded_at": "2025-09-05T10:30:00Z",
      "access_url": "https://api.wondernest.com/api/v1/files/456.../family",
      "permissions": {
        "can_view": true,
        "can_edit": false,
        "can_delete": false,
        "can_change_visibility": false
      }
    }
  ],
  "pagination": {
    "total": 25,
    "limit": 50,
    "offset": 0,
    "has_more": false
  }
}
```

**Response Codes**:
- `200 OK`: Files retrieved successfully
- `401 Unauthorized`: Missing or invalid token
- `400 Bad Request`: Invalid query parameters

## Error Response Format

All endpoints return errors in a consistent format:

```json
{
  "error": "Unauthorized",
  "status": 401,
  "message": "Invalid or expired authentication token",
  "timestamp": "2025-09-06T05:15:00Z"
}
```

## Security Considerations

### Information Leakage Prevention
- Private files return `404 Not Found` (never `403 Forbidden`) to unauthorized users
- Error messages don't reveal file existence or family relationships
- Public endpoint never reveals information about private files

### Rate Limiting
- Public endpoint: 100 requests per minute per IP
- Authenticated endpoints: 1000 requests per minute per user
- Rate limit headers included in all responses

### Audit Logging
- All file access attempts logged with user ID, file ID, and timestamp
- Failed access attempts logged with reason
- Owner-only operations logged for compliance

## Frontend Integration

### URL Generation Logic
```javascript
function getFileUrl(file, user) {
  if (file.is_public) {
    return `/api/v1/files/${file.id}/public`;
  } else {
    return `/api/v1/files/${file.id}/family`;
  }
}

function canPerformAction(file, user, action) {
  return file.permissions[`can_${action}`] || false;
}
```

### Error Handling
```javascript
// Handle different error scenarios
if (response.status === 404) {
  // File not found or no access
  showError("File not found or you don't have access");
} else if (response.status === 403) {
  // Authenticated but insufficient permissions  
  showError("You don't have permission to perform this action");
} else if (response.status === 401) {
  // Authentication required or expired
  redirectToLogin();
}
```