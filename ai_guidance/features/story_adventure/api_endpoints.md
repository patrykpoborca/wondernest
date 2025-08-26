# Story Adventure API Endpoints

## Overview
This document defines all API endpoints for the Story Adventure feature, including request/response formats, authentication requirements, and error handling.

## Base URL
```
/api/v2/games/story-adventure
```

## Authentication
All endpoints require JWT authentication except where noted. Parent-only endpoints additionally require PIN verification.

## Story Templates

### GET /templates
Retrieve available story templates for a child.

**Query Parameters:**
- `childId` (UUID, required): Child's ID
- `includeMarketplace` (boolean, optional): Include marketplace templates
- `ageGroup` (enum, optional): Filter by age group (3-5, 6-8, 9-12)
- `category` (string, optional): Filter by category
- `difficulty` (enum, optional): emerging, developing, fluent
- `limit` (int, optional): Max results (default: 20)
- `offset` (int, optional): Pagination offset

**Response:**
```json
{
  "templates": [
    {
      "id": "uuid",
      "title": "The Magic Garden",
      "description": "An adventure through a magical garden",
      "ageGroup": "6-8",
      "difficulty": "developing",
      "pageCount": 12,
      "vocabularyWords": ["garden", "flower", "butterfly"],
      "thumbnailUrl": "https://cdn.wondernest.com/stories/thumb.jpg",
      "isPremium": false,
      "isOwned": true,
      "creatorId": "uuid",
      "creatorName": "WonderNest Team",
      "rating": 4.8,
      "reviewCount": 234,
      "price": null,
      "tags": ["nature", "adventure", "vocabulary"],
      "estimatedReadTime": "10 minutes"
    }
  ],
  "totalCount": 150,
  "hasMore": true
}
```

### GET /templates/{templateId}
Get detailed story template information.

**Response:**
```json
{
  "id": "uuid",
  "title": "The Magic Garden",
  "description": "An adventure through a magical garden",
  "content": {
    "pages": [
      {
        "pageNumber": 1,
        "imageUrl": "https://cdn.wondernest.com/stories/page1.jpg",
        "text": "Once upon a time, in a {adjective} garden...",
        "audioUrl": "https://cdn.wondernest.com/stories/page1.mp3",
        "vocabularyWords": [
          {
            "word": "garden",
            "definition": "A place where plants grow",
            "pronunciation": "gar-den",
            "audioUrl": "https://cdn.wondernest.com/words/garden.mp3"
          }
        ],
        "interactiveElements": [
          {
            "type": "tap_animation",
            "position": {"x": 100, "y": 200},
            "action": "butterfly_fly"
          }
        ]
      }
    ],
    "variables": [
      {
        "key": "characterName",
        "type": "text",
        "default": "Alex"
      },
      {
        "key": "adjective",
        "type": "vocabulary",
        "options": ["magical", "beautiful", "mysterious"]
      }
    ]
  },
  "metadata": {
    "createdAt": "2024-01-15T10:00:00Z",
    "updatedAt": "2024-01-20T15:30:00Z",
    "version": "1.2",
    "language": "en",
    "educationalGoals": ["vocabulary", "reading comprehension"],
    "themes": ["nature", "adventure"]
  }
}
```

### POST /templates (Parent Only)
Create a new story template.

**Request Body:**
```json
{
  "title": "My Custom Story",
  "description": "A personalized adventure",
  "ageGroup": "6-8",
  "difficulty": "developing",
  "pages": [
    {
      "imageId": "image-library-id",
      "text": "The {characterName} went to the {place}",
      "vocabularyWords": ["adventure", "explore"],
      "narrationText": "Optional different text for audio"
    }
  ],
  "variables": {
    "characterName": {
      "type": "text",
      "default": "Hero"
    },
    "place": {
      "type": "vocabulary",
      "options": ["forest", "ocean", "mountain"]
    }
  },
  "tags": ["custom", "adventure"],
  "isPrivate": true,
  "targetVocabulary": ["specific", "words", "to", "practice"]
}
```

**Response:**
```json
{
  "id": "uuid",
  "status": "created",
  "message": "Story template created successfully"
}
```

### PUT /templates/{templateId} (Parent Only)
Update an existing story template.

**Request Body:**
Same as POST /templates

**Response:**
```json
{
  "id": "uuid",
  "status": "updated",
  "version": "1.3"
}
```

### DELETE /templates/{templateId} (Parent Only)
Delete a story template.

**Response:**
```json
{
  "status": "deleted",
  "message": "Story template deleted successfully"
}
```

## Story Instances (Reading Sessions)

### GET /instances/{childId}
Get all story instances for a child.

**Query Parameters:**
- `status` (enum, optional): in_progress, completed, abandoned
- `templateId` (UUID, optional): Filter by template

**Response:**
```json
{
  "instances": [
    {
      "id": "uuid",
      "templateId": "uuid",
      "templateTitle": "The Magic Garden",
      "status": "in_progress",
      "currentPage": 5,
      "totalPages": 12,
      "progress": 41.67,
      "startedAt": "2024-02-01T10:00:00Z",
      "lastAccessedAt": "2024-02-01T10:15:00Z",
      "completedAt": null,
      "readingTime": 900,
      "customizations": {
        "characterName": "Emma",
        "place": "forest"
      },
      "vocabularyProgress": {
        "wordsEncountered": 15,
        "wordsLearned": 12,
        "wordsMissed": 3
      }
    }
  ]
}
```

### POST /instances/{childId}/start
Start a new reading session.

**Request Body:**
```json
{
  "templateId": "uuid",
  "customizations": {
    "characterName": "Emma",
    "adjective": "magical"
  },
  "readingMode": "self_paced",
  "audioEnabled": true
}
```

**Response:**
```json
{
  "instanceId": "uuid",
  "status": "started",
  "firstPageUrl": "/api/v2/games/story-adventure/instances/uuid/page/1"
}
```

### GET /instances/{instanceId}/page/{pageNumber}
Get a specific page of a story instance.

**Response:**
```json
{
  "pageNumber": 3,
  "totalPages": 12,
  "imageUrl": "https://cdn.wondernest.com/stories/customized/page3.jpg",
  "text": "Emma walked through the magical forest",
  "audioUrl": "https://cdn.wondernest.com/stories/customized/page3.mp3",
  "highlightedWords": [
    {
      "word": "magical",
      "startIndex": 24,
      "endIndex": 31,
      "isVocabulary": true,
      "definition": "Having special powers"
    }
  ],
  "interactions": [],
  "nextPageAvailable": true,
  "previousPageAvailable": true
}
```

### PUT /instances/{instanceId}/progress
Update reading progress.

**Request Body:**
```json
{
  "currentPage": 5,
  "readingTime": 120,
  "vocabularyInteractions": [
    {
      "word": "garden",
      "action": "tapped",
      "timestamp": "2024-02-01T10:15:30Z"
    }
  ],
  "comprehensionAnswers": [
    {
      "questionId": "q1",
      "answer": "The butterfly",
      "isCorrect": true,
      "timeSpent": 15
    }
  ]
}
```

**Response:**
```json
{
  "status": "updated",
  "progress": 41.67,
  "achievements": [
    {
      "type": "vocabulary_master",
      "title": "Word Explorer",
      "description": "Learned 10 new words!"
    }
  ]
}
```

### POST /instances/{instanceId}/complete
Mark a story as completed.

**Request Body:**
```json
{
  "totalReadingTime": 900,
  "comprehensionScore": 85,
  "vocabularyScore": 92,
  "rating": 5,
  "feedback": "optional child feedback"
}
```

**Response:**
```json
{
  "status": "completed",
  "rewards": {
    "points": 100,
    "badges": ["speed_reader", "vocabulary_star"],
    "unlockedContent": ["new_story_id"]
  },
  "summary": {
    "wordsRead": 500,
    "newWordsLearned": 8,
    "readingSpeed": 55,
    "comprehension": 85
  }
}
```

## Marketplace

### GET /marketplace/browse
Browse marketplace templates.

**Query Parameters:**
- `category` (string, optional): adventure, educational, fairy-tale
- `ageGroup` (string, optional): 3-5, 6-8, 9-12
- `priceRange` (string, optional): free, under-5, 5-10, over-10
- `sortBy` (string, optional): popular, newest, rating, price
- `searchTerm` (string, optional): Text search
- `limit` (int, optional): Results per page
- `offset` (int, optional): Pagination offset

**Response:**
```json
{
  "listings": [
    {
      "id": "uuid",
      "templateId": "uuid",
      "title": "Ocean Adventure",
      "creator": {
        "id": "uuid",
        "name": "StoryCreator123",
        "rating": 4.9,
        "totalSales": 1500
      },
      "price": 4.99,
      "originalPrice": 7.99,
      "discount": 38,
      "rating": 4.7,
      "reviewCount": 234,
      "purchaseCount": 892,
      "preview": {
        "thumbnailUrl": "url",
        "samplePages": [1, 2, 3],
        "description": "Dive into an ocean adventure"
      },
      "tags": ["ocean", "animals", "science"],
      "lastUpdated": "2024-01-15T10:00:00Z"
    }
  ],
  "totalResults": 500,
  "facets": {
    "categories": {
      "adventure": 150,
      "educational": 200,
      "fairy-tale": 150
    },
    "priceRanges": {
      "free": 100,
      "under-5": 250,
      "5-10": 150
    }
  }
}
```

### POST /marketplace/purchase (Parent Only)
Purchase a marketplace template.

**Request Body:**
```json
{
  "listingId": "uuid",
  "paymentMethod": "saved_card_id",
  "applyCredits": true,
  "giftToChild": "child_uuid"
}
```

**Response:**
```json
{
  "transactionId": "uuid",
  "status": "completed",
  "purchasedTemplateId": "uuid",
  "receipt": {
    "itemName": "Ocean Adventure",
    "price": 4.99,
    "tax": 0.40,
    "total": 5.39,
    "creditsUsed": 2.00,
    "charged": 3.39,
    "date": "2024-02-01T10:00:00Z"
  },
  "downloadUrl": "/api/v2/games/story-adventure/templates/uuid"
}
```

### POST /marketplace/publish (Parent Only)
Publish a template to the marketplace.

**Request Body:**
```json
{
  "templateId": "uuid",
  "pricing": {
    "price": 4.99,
    "allowDiscounts": true,
    "minimumPrice": 2.99
  },
  "listing": {
    "title": "Enhanced Story Title for Marketing",
    "description": "Detailed description for buyers",
    "category": "educational",
    "tags": ["vocabulary", "science", "fun"],
    "previewPages": [1, 3, 5]
  },
  "creatorInfo": {
    "displayName": "StoryCreator123",
    "bio": "Parent and educator creating fun learning stories"
  },
  "terms": {
    "acceptRevenueSplit": true,
    "acceptContentGuidelines": true,
    "acceptLiability": true
  }
}
```

**Response:**
```json
{
  "listingId": "uuid",
  "status": "pending_review",
  "estimatedReviewTime": "24-48 hours",
  "message": "Your story has been submitted for review"
}
```

### GET /marketplace/creator/{creatorId}/stories
Get all stories by a specific creator.

**Response:**
```json
{
  "creator": {
    "id": "uuid",
    "name": "StoryCreator123",
    "rating": 4.9,
    "totalStories": 25,
    "totalSales": 5000,
    "joinedDate": "2023-01-01",
    "bio": "Creating educational stories",
    "verified": true
  },
  "stories": [
    {
      "id": "uuid",
      "title": "Ocean Adventure",
      "rating": 4.7,
      "sales": 892,
      "price": 4.99
    }
  ]
}
```

## Analytics

### GET /analytics/{childId}/reading-progress
Get reading progress analytics for a child.

**Query Parameters:**
- `startDate` (ISO date, optional): Start of date range
- `endDate` (ISO date, optional): End of date range
- `groupBy` (enum, optional): day, week, month

**Response:**
```json
{
  "summary": {
    "totalStoriesRead": 45,
    "totalReadingTime": 25200,
    "averageSessionTime": 560,
    "currentStreak": 7,
    "longestStreak": 15,
    "favoriteCategory": "adventure"
  },
  "progress": [
    {
      "date": "2024-02-01",
      "storiesRead": 2,
      "readingTime": 1800,
      "wordsRead": 1000,
      "newWords": 12
    }
  ],
  "vocabulary": {
    "totalWordsLearned": 250,
    "masteredWords": 180,
    "learningWords": 50,
    "difficultWords": 20,
    "recentWords": ["ocean", "adventure", "explore"]
  },
  "achievements": {
    "total": 15,
    "recent": [
      {
        "type": "reading_streak",
        "title": "7 Day Streak!",
        "earnedAt": "2024-02-01T20:00:00Z"
      }
    ]
  }
}
```

### GET /analytics/{childId}/vocabulary-growth
Track vocabulary development over time.

**Response:**
```json
{
  "currentVocabularySize": 850,
  "growthRate": 15.5,
  "timeline": [
    {
      "month": "2024-01",
      "wordsLearned": 45,
      "wordsRetained": 42,
      "totalKnown": 805
    },
    {
      "month": "2024-02",
      "wordsLearned": 50,
      "wordsRetained": 45,
      "totalKnown": 850
    }
  ],
  "categories": {
    "animals": 120,
    "nature": 95,
    "actions": 200,
    "emotions": 85,
    "objects": 350
  },
  "difficultyDistribution": {
    "easy": 500,
    "medium": 300,
    "hard": 50
  }
}
```

### GET /analytics/{childId}/comprehension-scores
Get comprehension test results.

**Response:**
```json
{
  "averageScore": 82,
  "trend": "improving",
  "scores": [
    {
      "storyId": "uuid",
      "storyTitle": "The Magic Garden",
      "date": "2024-02-01",
      "score": 85,
      "questionsAnswered": 5,
      "questionsCorrect": 4,
      "timeSpent": 120
    }
  ],
  "strengths": ["main idea", "sequencing"],
  "needsWork": ["inference", "vocabulary context"]
}
```

## Media Management

### GET /media/images
Get available images for story creation.

**Query Parameters:**
- `category` (string, optional): characters, backgrounds, objects
- `style` (string, optional): cartoon, realistic, watercolor
- `searchTerm` (string, optional): Text search

**Response:**
```json
{
  "images": [
    {
      "id": "img-uuid",
      "url": "https://cdn.wondernest.com/images/forest.jpg",
      "thumbnailUrl": "https://cdn.wondernest.com/images/forest-thumb.jpg",
      "category": "backgrounds",
      "tags": ["forest", "nature", "trees"],
      "style": "watercolor",
      "dimensions": {
        "width": 1920,
        "height": 1080
      }
    }
  ]
}
```

### POST /media/upload (Parent Only)
Upload custom image for stories.

**Request:**
Multipart form data with image file

**Response:**
```json
{
  "imageId": "img-uuid",
  "url": "https://cdn.wondernest.com/user-images/uuid.jpg",
  "status": "uploaded",
  "moderationStatus": "pending"
}
```

## Error Responses

All endpoints return standard error responses:

```json
{
  "error": {
    "code": "STORY_NOT_FOUND",
    "message": "The requested story template was not found",
    "details": {
      "templateId": "invalid-uuid"
    }
  },
  "timestamp": "2024-02-01T10:00:00Z",
  "requestId": "req-uuid"
}
```

### Error Codes
- `AUTHENTICATION_REQUIRED`: User not authenticated
- `INSUFFICIENT_PERMISSIONS`: User lacks required permissions
- `STORY_NOT_FOUND`: Story template or instance not found
- `INVALID_AGE_GROUP`: Age group not appropriate for child
- `PURCHASE_FAILED`: Marketplace transaction failed
- `CONTENT_MODERATION_FAILED`: Content violates guidelines
- `QUOTA_EXCEEDED`: User exceeded usage limits
- `INVALID_REQUEST`: Request validation failed
- `SERVER_ERROR`: Internal server error