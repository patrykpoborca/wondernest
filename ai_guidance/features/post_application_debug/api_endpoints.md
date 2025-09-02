# Post Application System - API Documentation

## Current Status: NOT IMPLEMENTED

All endpoints listed below are **missing from the backend** and need to be implemented.

## Required Endpoints

### POST /api/v1/posts/{postId}/apply
**Status**: ❌ NOT IMPLEMENTED

Apply to a specific post.

**Authentication**: Required (JWT)

**Request**:
```http
POST /api/v1/posts/07f5aded-4bfe-485c-9958-14b1ad7a0cda/apply
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
    "message": "I'm interested in this opportunity...",
    "attachments": ["file_id_1", "file_id_2"],
    "availability": {
        "start_date": "2025-09-10",
        "end_date": "2025-12-15"
    }
}
```

**Success Response** (201 Created):
```json
{
    "success": true,
    "application_id": "12345678-1234-1234-1234-123456789abc",
    "message": "Application submitted successfully",
    "status": "pending",
    "applied_at": "2025-09-02T18:30:00Z"
}
```

**Error Responses**:
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required
- **404 Not Found**: Post doesn't exist
- **409 Conflict**: Already applied to this post
- **410 Gone**: Post expired or closed

### GET /api/v1/posts/{postId}/applications
**Status**: ❌ NOT IMPLEMENTED

Get applications for a post (creator only).

### GET /api/v1/users/me/applications
**Status**: ❌ NOT IMPLEMENTED  

Get user's application history.

### PUT /api/v1/posts/{postId}/applications/{applicationId}
**Status**: ❌ NOT IMPLEMENTED

Update application status (creator only).

## Notification Endpoints

### POST /api/v1/posts/{postId}/notifications
**Status**: ❌ NOT IMPLEMENTED

Configure notification preferences for a post.

## Database Schema Requirements

### posts Table
```sql
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES core.users(id),
    family_id UUID REFERENCES family.families(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    location JSONB,
    requirements JSONB,
    compensation JSONB,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN (
        'active', 'paused', 'closed', 'expired', 'draft'
    )),
    max_applicants INTEGER DEFAULT 10,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### post_applicants Table
```sql
CREATE TABLE post_applicants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    applicant_id UUID NOT NULL REFERENCES core.users(id),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending', 'accepted', 'rejected', 'withdrawn'
    )),
    message TEXT,
    attachments UUID[] DEFAULT '{}',
    availability JSONB,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE,
    response_message TEXT,
    
    UNIQUE(post_id, applicant_id)
);
```

### post_notifications Table
```sql  
CREATE TABLE post_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES core.users(id),
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN (
        'new_application', 'application_accepted', 'application_rejected', 'post_expired'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT,
    read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## Implementation Priority

### Phase 1: Basic Application System
1. Create database schema for posts and applications
2. Implement POST /api/v1/posts/{postId}/apply endpoint
3. Add duplicate application checking
4. Basic error handling and validation

### Phase 2: Application Management  
1. Add GET endpoints for viewing applications
2. Implement application status updates
3. Add application withdrawal functionality

### Phase 3: Notifications
1. Email notifications to post creators
2. In-app notifications
3. Push notifications (mobile)

### Phase 4: Advanced Features
1. Application filtering and search
2. Bulk application management
3. Application analytics and insights

## Error Handling Strategy

### Current Issue
```
POST /api/v1/posts/07f5aded-4bfe-485c-9958-14b1ad7a0cda/apply
→ 400 Bad Request (misleading "already applied" message)
```

### Improved Error Handling
```kotlin
route("/api/v1/posts/{postId}/apply") {
    post {
        try {
            val postId = call.parameters["postId"]?.toUUIDOrNull()
                ?: return@post call.respond(
                    HttpStatusCode.BadRequest,
                    ErrorResponse("Invalid post ID format")
                )
                
            val user = call.extractUser()
            
            // Check if post exists
            val post = postRepository.findById(postId)
                ?: return@post call.respond(
                    HttpStatusCode.NotFound,
                    ErrorResponse("Post not found")
                )
                
            // Check if already applied
            val existingApplication = postApplicationRepository
                .findByPostAndUser(postId, user.id)
            
            if (existingApplication != null) {
                return@post call.respond(
                    HttpStatusCode.Conflict,
                    ErrorResponse(
                        message = "You have already applied to this post",
                        code = "DUPLICATE_APPLICATION",
                        details = mapOf(
                            "application_id" to existingApplication.id,
                            "applied_at" to existingApplication.appliedAt,
                            "status" to existingApplication.status
                        )
                    )
                )
            }
            
            // Process application...
            
        } catch (e: Exception) {
            logger.error(e) { "Error processing post application" }
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse("Application failed to process")
            )
        }
    }
}
```

## Testing Requirements

### Unit Tests
- Application creation and validation
- Duplicate application prevention  
- Post existence validation
- User authentication validation

### Integration Tests  
- End-to-end application flow
- Notification delivery
- Error scenario handling
- Concurrent application handling

### Load Tests
- Multiple simultaneous applications
- Database performance under load
- Notification system scalability