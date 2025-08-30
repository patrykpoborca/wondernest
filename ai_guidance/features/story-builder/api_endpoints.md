# Story Builder API Endpoints

## Base URL
`/api/v2/story-builder`

## Authentication
All endpoints require JWT authentication with parent or admin role.

## Draft Management

### Create Draft
**POST** `/drafts`
```json
Request:
{
  "title": "The Brave Little Bunny",
  "description": "A story about courage",
  "targetAge": [4, 6],
  "content": {} // Initially empty
}

Response: 201 Created
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "The Brave Little Bunny",
    "status": "draft",
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

### Update Draft
**PUT** `/drafts/{draftId}`
```json
Request:
{
  "title": "Updated Title",
  "content": {
    "version": "1.0",
    "pages": [
      {
        "pageNumber": 1,
        "background": "asset_id_123",
        "textBlocks": [
          {
            "id": "block_1",
            "position": { "x": 100, "y": 200 },
            "variants": {
              "easy": "The cat sat.",
              "medium": "The cat sat on the mat.",
              "hard": "The feline rested upon the woven mat."
            },
            "vocabularyWords": ["cat", "mat"]
          }
        ],
        "popupImages": [
          {
            "id": "popup_1",
            "triggerWord": "cat",
            "imageUrl": "https://cdn.wondernest.com/cat.png",
            "animation": "fadeIn"
          }
        ]
      }
    ]
  },
  "metadata": {
    "targetAge": [6, 8],
    "educationalGoals": ["vocabulary", "reading comprehension"],
    "estimatedReadTime": 300,
    "vocabularyList": ["cat", "mat", "sat"]
  }
}

Response: 200 OK
{
  "success": true,
  "data": {
    "id": "uuid",
    "lastModified": "2024-01-15T10:30:00Z"
  }
}
```

### List Drafts
**GET** `/drafts`

Query Parameters:
- `status`: draft|published|archived (optional)
- `limit`: number (default: 20)
- `offset`: number (default: 0)
- `sortBy`: created|modified|title (default: modified)
- `order`: asc|desc (default: desc)

```json
Response: 200 OK
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "The Brave Little Bunny",
      "status": "draft",
      "pageCount": 5,
      "lastModified": "2024-01-15T10:30:00Z",
      "createdAt": "2024-01-15T10:00:00Z",
      "thumbnail": "https://cdn.wondernest.com/thumb_123.jpg"
    }
  ],
  "pagination": {
    "total": 15,
    "limit": 20,
    "offset": 0
  }
}
```

### Get Draft Details
**GET** `/drafts/{draftId}`
```json
Response: 200 OK
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "The Brave Little Bunny",
    "content": { /* Full story content */ },
    "metadata": { /* Story metadata */ },
    "status": "draft",
    "collaborators": [],
    "version": 1,
    "lastModified": "2024-01-15T10:30:00Z",
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

### Delete Draft
**DELETE** `/drafts/{draftId}`
```json
Response: 200 OK
{
  "success": true,
  "message": "Draft deleted successfully"
}
```

## Publishing

### Publish Story
**POST** `/publish`
```json
Request:
{
  "draftId": "uuid",
  "publishTo": "private", // private|global (admin only)
  "childIds": ["child_uuid_1", "child_uuid_2"], // For private publishing
  "scheduledDate": null, // Optional future publish date
  "expiryDate": null // Optional expiry date
}

Response: 201 Created
{
  "success": true,
  "data": {
    "storyId": "uuid",
    "publishedAt": "2024-01-15T11:00:00Z",
    "visibility": "private",
    "assignedTo": ["child_uuid_1", "child_uuid_2"]
  }
}
```

### Unpublish Story
**POST** `/unpublish/{storyId}`
```json
Response: 200 OK
{
  "success": true,
  "message": "Story unpublished successfully"
}
```

## Preview

### Generate Preview
**POST** `/preview`
```json
Request:
{
  "content": { /* Story content object */ },
  "difficultyLevel": "medium",
  "childAge": 6
}

Response: 200 OK
{
  "success": true,
  "data": {
    "previewUrl": "https://preview.wondernest.com/temp/uuid",
    "expiresIn": 3600 // seconds
  }
}
```

## Asset Management

### Get Image Library
**GET** `/assets/images`

Query Parameters:
- `category`: animals|nature|objects|people|fantasy (optional)
- `tags`: comma-separated tags (optional)
- `search`: search term (optional)
- `isPremium`: true|false (optional)
- `limit`: number (default: 50)
- `offset`: number (default: 0)

```json
Response: 200 OK
{
  "success": true,
  "data": [
    {
      "id": "asset_123",
      "url": "https://cdn.wondernest.com/images/cat.png",
      "thumbnail": "https://cdn.wondernest.com/thumbs/cat.png",
      "category": "animals",
      "tags": ["cat", "pet", "animal"],
      "isPremium": false
    }
  ],
  "pagination": {
    "total": 523,
    "limit": 50,
    "offset": 0
  }
}
```

### Upload Custom Image
**POST** `/assets/upload`

Multipart form data:
- `file`: image file (max 5MB)
- `category`: string
- `tags`: comma-separated string
- `isPrivate`: boolean (default: true)

```json
Response: 201 Created
{
  "success": true,
  "data": {
    "id": "asset_456",
    "url": "https://cdn.wondernest.com/user-images/uuid.png",
    "thumbnail": "https://cdn.wondernest.com/user-thumbs/uuid.png"
  }
}
```

### Delete Custom Image
**DELETE** `/assets/{assetId}`
```json
Response: 200 OK
{
  "success": true,
  "message": "Asset deleted successfully"
}
```

## Templates

### Get Story Templates
**GET** `/templates`

Query Parameters:
- `category`: fairy-tale|adventure|educational|custom (optional)
- `ageRange`: 3-5|6-8|9-12 (optional)
- `limit`: number (default: 20)
- `offset`: number (default: 0)

```json
Response: 200 OK
{
  "success": true,
  "data": [
    {
      "id": "template_123",
      "name": "Classic Fairy Tale",
      "description": "A three-act story structure",
      "thumbnail": "https://cdn.wondernest.com/templates/fairy-tale.png",
      "pageCount": 10,
      "structure": {
        "acts": 3,
        "pages": [
          {
            "type": "introduction",
            "suggestedContent": "Once upon a time..."
          }
        ]
      }
    }
  ]
}
```

### Create From Template
**POST** `/templates/{templateId}/create`
```json
Request:
{
  "title": "My Fairy Tale",
  "customizations": {
    "characterName": "Luna",
    "setting": "magical forest"
  }
}

Response: 201 Created
{
  "success": true,
  "data": {
    "draftId": "uuid",
    "title": "My Fairy Tale",
    "content": { /* Pre-filled content from template */ }
  }
}
```

## Story Management

### Get My Published Stories
**GET** `/my-stories`

Query Parameters:
- `childId`: uuid (optional, filter by child)
- `limit`: number (default: 20)
- `offset`: number (default: 0)

```json
Response: 200 OK
{
  "success": true,
  "data": [
    {
      "id": "story_123",
      "title": "The Brave Little Bunny",
      "publishedAt": "2024-01-15T11:00:00Z",
      "assignedChildren": [
        {
          "id": "child_123",
          "name": "Emma",
          "lastRead": "2024-01-16T15:00:00Z",
          "completionRate": 0.75
        }
      ],
      "stats": {
        "totalReads": 5,
        "averageReadTime": 300,
        "vocabularyMastery": 0.8
      }
    }
  ]
}
```

### Get Story Analytics
**GET** `/stories/{storyId}/analytics`
```json
Response: 200 OK
{
  "success": true,
  "data": {
    "storyId": "story_123",
    "engagement": {
      "totalReads": 10,
      "uniqueReaders": 2,
      "averageCompletion": 0.85,
      "averageReadTime": 300
    },
    "vocabulary": {
      "wordsIntroduced": ["cat", "mat", "sat"],
      "masteryRate": 0.75,
      "mostDifficult": ["feline"]
    },
    "pageMetrics": [
      {
        "pageNumber": 1,
        "averageTimeSpent": 45,
        "dropOffRate": 0.05
      }
    ]
  }
}
```

## Admin Endpoints

### Review Queue (Admin Only)
**GET** `/admin/review-queue`
```json
Response: 200 OK
{
  "success": true,
  "data": [
    {
      "id": "submission_123",
      "storyId": "story_456",
      "title": "Community Story",
      "author": {
        "id": "user_123",
        "name": "John Doe"
      },
      "submittedAt": "2024-01-15T10:00:00Z",
      "status": "pending_review",
      "autoFlags": ["needs_manual_review"]
    }
  ]
}
```

### Approve Story (Admin Only)
**POST** `/admin/approve/{submissionId}`
```json
Request:
{
  "feedback": "Great educational content!",
  "publishScope": "global",
  "categories": ["educational", "adventure"]
}

Response: 200 OK
{
  "success": true,
  "data": {
    "storyId": "story_456",
    "approvedAt": "2024-01-15T12:00:00Z",
    "publishedTo": "global"
  }
}
```

### Reject Story (Admin Only)
**POST** `/admin/reject/{submissionId}`
```json
Request:
{
  "reason": "inappropriate_content",
  "feedback": "Please review our content guidelines",
  "allowResubmission": true
}

Response: 200 OK
{
  "success": true,
  "message": "Story rejected with feedback sent to author"
}
```

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Title is required",
    "field": "title"
  }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "You don't have permission to edit this story"
  }
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Story not found"
  }
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An error occurred while processing your request"
  }
}
```