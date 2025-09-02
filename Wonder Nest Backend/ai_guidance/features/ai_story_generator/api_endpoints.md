# Integrated AI Story Platform - Complete API Documentation

## Overview

This API documentation covers all endpoints for the integrated AI Story Platform, including AI generation, community marketplace, creator economy, and personal library features. All endpoints maintain backward compatibility with existing WonderNest APIs.

### API Versioning and Base Path
- **Base URL**: `/api/v2/`
- **Authentication**: JWT Bearer tokens required for all endpoints
- **Content-Type**: `application/json`
- **Rate Limiting**: Varies by subscription tier and endpoint

---

## 📝 AI Story Generation APIs

### Generate AI Story
Creates a new AI-generated story based on user prompt and images.

```http
POST /api/v2/ai/stories/generate
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "prompt": "A story about a brave knight and a friendly dragon",
    "imageIds": ["uuid1", "uuid2"],
    "childId": "child-uuid", // Optional: target child
    "ageGroup": "6-8", // 3-5, 6-8, 9-12
    "readingLevel": "developing", // emerging, developing, fluent, advanced
    "options": {
        "targetPages": 10,
        "vocabularyFocus": ["courage", "friendship"],
        "educationalGoals": ["social skills", "problem solving"],
        "themes": ["bravery", "teamwork"],
        "tone": "adventurous" // friendly, adventurous, educational, calming, exciting
    },
    "templateId": "optional-template-uuid" // Use existing prompt template
}
```

**Response (202 Accepted):**
```json
{
    "success": true,
    "data": {
        "requestId": "generation-uuid",
        "status": "processing",
        "estimatedTimeSeconds": 30,
        "message": "Story generation in progress",
        "queuePosition": 2
    }
}
```

**Error Responses:**
```json
// Quota exceeded (429)
{
    "error": {
        "code": "QUOTA_EXCEEDED",
        "message": "Daily generation limit reached",
        "details": {
            "dailyUsed": 5,
            "dailyLimit": 5,
            "resetTime": "2024-01-02T00:00:00Z"
        }
    }
}

// Invalid parameters (400)
{
    "error": {
        "code": "INVALID_PARAMETERS",
        "message": "Age group and reading level mismatch",
        "field": "readingLevel"
    }
}
```

### Check Generation Status
Monitor the progress of AI story generation.

```http
GET /api/v2/ai/stories/status/{requestId}
Authorization: Bearer {jwt}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "requestId": "generation-uuid",
        "status": "completed", // pending, processing, completed, failed, cancelled
        "storyId": "story-uuid",
        "processingTimeMs": 15000,
        "tokensUsed": 2500,
        "estimatedCost": 0.08,
        "completedAt": "2024-01-01T12:30:00Z"
    }
}
```

### Get Generated Story for Review
Retrieve generated story for parent review before child access.

```http
GET /api/v2/ai/stories/{storyId}/preview
Authorization: Bearer {jwt}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "id": "story-uuid",
        "generationRequestId": "generation-uuid",
        "title": "The Brave Knight and the Friendly Dragon",
        "description": "An adventure about courage and friendship",
        "pages": [
            {
                "pageNumber": 1,
                "text": "Once upon a time, in a kingdom far away...",
                "imageId": "image-uuid",
                "vocabularyWords": ["courage", "kingdom"],
                "readingTimeSeconds": 45
            }
        ],
        "vocabulary": [
            {
                "word": "courage",
                "definition": "Being brave when facing something difficult",
                "usage": "The knight showed courage when facing the dragon.",
                "difficulty": "grade-3"
            }
        ],
        "metadata": {
            "themes": ["bravery", "friendship"],
            "educationalValue": "Teaches about courage and teamwork",
            "readingLevel": "developing",
            "estimatedReadingTime": 450,
            "generatedWith": "gemini-1.5-flash",
            "safetyChecksPassed": true
        },
        "approvalStatus": "pending_review",
        "contentWarnings": [],
        "createdAt": "2024-01-01T12:30:00Z"
    }
}
```

### Approve/Reject/Edit Story
Parent review and approval workflow for generated stories.

```http
POST /api/v2/ai/stories/{storyId}/review
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "action": "approve", // approve, reject, edit
    "notes": "Looks great! Perfect for bedtime reading.",
    "editedContent": { 
        // Only required if action is "edit"
        "title": "Modified title",
        "pages": [...] // Modified pages array
    },
    "shareToMarketplace": false, // Optional: share approved story
    "marketplaceSettings": {
        "price": 2.99,
        "allowsDerivatives": true,
        "derivativeFeePercentage": 10.0
    }
}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "storyId": "story-uuid",
        "approvalStatus": "approved",
        "storyTemplateId": "template-uuid", // Created story template
        "sharedToMarketplace": false,
        "availableToChild": true,
        "approvedAt": "2024-01-01T12:45:00Z"
    }
}
```

### Get Generation History
Retrieve user's AI story generation history.

```http
GET /api/v2/ai/stories/history
Authorization: Bearer {jwt}
Query Parameters:
  - page: int (default: 1)
  - limit: int (default: 20, max: 100)
  - status: string (optional filter)
  - childId: uuid (optional filter)
  - dateFrom: date (optional)
  - dateTo: date (optional)
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "stories": [
            {
                "id": "story-uuid",
                "title": "The Brave Knight",
                "status": "approved",
                "childName": "Emma",
                "createdAt": "2024-01-01T12:00:00Z",
                "approvedAt": "2024-01-01T12:45:00Z",
                "tokensUsed": 2500,
                "processingTime": 15000,
                "sharedToMarketplace": true
            }
        ],
        "pagination": {
            "total": 45,
            "page": 1,
            "limit": 20,
            "hasNext": true,
            "hasPrevious": false
        }
    }
}
```

### Get Generation Quotas
Check user's current AI generation quotas and usage.

```http
GET /api/v2/ai/quotas
Authorization: Bearer {jwt}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "subscriptionTier": "family",
        "daily": {
            "used": 2,
            "limit": 15,
            "remaining": 13,
            "resetTime": "2024-01-02T00:00:00Z"
        },
        "monthly": {
            "used": 18,
            "limit": 100,
            "remaining": 82,
            "resetTime": "2024-02-01T00:00:00Z"
        },
        "bonusCredits": 5,
        "creditsExpireAt": "2024-03-01T00:00:00Z",
        "upgradeBenefits": {
            "creatorTier": {
                "dailyLimit": 50,
                "monthlyLimit": 500,
                "price": "$19.99/month"
            }
        }
    }
}
```

---

## 🛠️ Prompt Template APIs

### Browse Prompt Templates
Discover and search available prompt templates.

```http
GET /api/v2/ai/templates
Authorization: Bearer {jwt}
Query Parameters:
  - category: string (adventure, bedtime, educational)
  - ageGroup: string (3-5, 6-8, 9-12)
  - featured: boolean
  - creatorId: uuid
  - search: string
  - sort: string (popularity, rating, newest, price)
  - page: int
  - limit: int
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "templates": [
            {
                "id": "template-uuid",
                "name": "Dragon Adventure",
                "description": "Create exciting adventures with friendly dragons",
                "creatorName": "StorytellerMom",
                "creatorVerified": true,
                "basePrompt": "A story about {character} who meets a {adjective} dragon...",
                "variableSlots": [
                    {
                        "name": "character",
                        "type": "text",
                        "required": true,
                        "description": "Main character name"
                    }
                ],
                "ageGroups": ["6-8", "9-12"],
                "genres": ["adventure", "fantasy"],
                "themes": ["courage", "friendship"],
                "pricing": {
                    "model": "free", // free, one_time, usage_based
                    "price": 0.00
                },
                "stats": {
                    "usageCount": 156,
                    "successRate": 92.5,
                    "averageRating": 4.6,
                    "reviewCount": 23
                },
                "isPublic": true,
                "isFeatured": false
            }
        ],
        "pagination": {
            "total": 25,
            "page": 1,
            "hasNext": true
        }
    }
}
```

### Get Template Details
Get complete details for a specific template.

```http
GET /api/v2/ai/templates/{templateId}
Authorization: Bearer {jwt}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "id": "template-uuid",
        "name": "Dragon Adventure",
        "description": "Create exciting adventures with friendly dragons",
        "basePrompt": "A story about {character} who meets a {adjective} dragon in {setting}. Together they learn about {lesson}...",
        "creator": {
            "id": "creator-uuid",
            "displayName": "StorytellerMom",
            "isVerified": true,
            "specialties": ["adventure", "fantasy"],
            "totalStories": 45,
            "averageRating": 4.7
        },
        "variableSlots": [
            {
                "name": "character",
                "type": "text",
                "required": true,
                "description": "Name of the main character",
                "placeholder": "Emma the Explorer"
            },
            {
                "name": "adjective",
                "type": "select",
                "required": true,
                "description": "Dragon personality",
                "options": ["friendly", "wise", "playful", "magical"]
            }
        ],
        "exampleGenerations": [
            {
                "title": "Emma and the Wise Dragon",
                "description": "Sample story showing template results"
            }
        ],
        "reviews": [
            {
                "userId": "reviewer-uuid",
                "displayName": "ParentReviewer",
                "rating": 5,
                "comment": "Amazing template! My kids love the dragon stories.",
                "createdAt": "2024-01-01T10:00:00Z"
            }
        ],
        "stats": {
            "usageCount": 156,
            "successRate": 92.5,
            "averageParentRating": 4.6,
            "averageChildEngagement": 87.2
        }
    }
}
```

### Create/Save Prompt Template
Create a new prompt template or save a custom one.

```http
POST /api/v2/ai/templates
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "name": "Magical Forest Adventure",
    "description": "Adventures in enchanted forests with magical creatures",
    "basePrompt": "Create a story where {character} explores a magical forest and meets {creature}. They learn about {lesson} together.",
    "variableSlots": [
        {
            "name": "character",
            "type": "text",
            "required": true,
            "description": "Main character name"
        },
        {
            "name": "creature",
            "type": "select",
            "required": true,
            "description": "Magical creature to meet",
            "options": ["unicorn", "fairy", "talking tree", "forest sprite"]
        }
    ],
    "ageGroups": ["3-5", "6-8"],
    "genres": ["fantasy", "adventure"],
    "themes": ["nature", "friendship", "magic"],
    "isPublic": false, // Start private, can be made public later
    "pricing": {
        "model": "free"
    }
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "templateId": "new-template-uuid",
        "name": "Magical Forest Adventure",
        "isPublic": false,
        "canMakePublic": true,
        "createdAt": "2024-01-01T12:00:00Z"
    }
}
```

### Use Template for Generation
Generate a story using a specific template.

```http
POST /api/v2/ai/templates/{templateId}/generate
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "customization": {
        "character": "Emma",
        "creature": "unicorn",
        "lesson": "being kind to nature"
    },
    "childId": "child-uuid",
    "ageGroup": "6-8",
    "readingLevel": "developing",
    "imageIds": ["image1-uuid", "image2-uuid"]
}
```

**Response (202 Accepted):**
```json
{
    "success": true,
    "data": {
        "requestId": "generation-uuid",
        "templateId": "template-uuid",
        "templateName": "Magical Forest Adventure",
        "status": "processing",
        "estimatedTimeSeconds": 25
    }
}
```

---

## 🏪 Enhanced Marketplace APIs

### Browse Marketplace Content
Enhanced marketplace with AI content filtering and creator features.

```http
GET /api/v2/marketplace/stories
Authorization: Bearer {jwt}
Query Parameters:
  - contentSource: string (human, ai_generated, ai_assisted, collaborative)
  - ageGroup: string
  - genre: string
  - priceMin: decimal
  - priceMax: decimal
  - creatorId: uuid
  - featured: boolean
  - verified: boolean
  - sort: string (newest, popular, rating, price_low, price_high)
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "listings": [
            {
                "id": "listing-uuid",
                "storyId": "story-uuid",
                "title": "The Brave Little Robot",
                "description": "A heartwarming story about courage and friendship",
                "price": 2.99,
                "contentSource": "ai_assisted",
                "creator": {
                    "id": "creator-uuid",
                    "displayName": "TechTeacherMom",
                    "isVerified": true,
                    "badges": ["educator", "top_seller"]
                },
                "metadata": {
                    "ageGroups": ["6-8"],
                    "themes": ["technology", "friendship"],
                    "readingLevel": "developing",
                    "pageCount": 12,
                    "vocabularyWords": 8
                },
                "stats": {
                    "rating": 4.7,
                    "reviewCount": 34,
                    "purchaseCount": 156,
                    "completionRate": 89.2
                },
                "features": {
                    "allowsDerivatives": true,
                    "derivativeFeePercentage": 15.0,
                    "hasAudio": true,
                    "hasInteractiveElements": false
                },
                "createdAt": "2024-01-01T10:00:00Z"
            }
        ],
        "filters": {
            "availableGenres": ["adventure", "educational", "fantasy"],
            "priceRange": {"min": 0.99, "max": 9.99},
            "contentSources": ["human", "ai_generated", "ai_assisted"]
        },
        "pagination": {
            "total": 245,
            "page": 1,
            "hasNext": true
        }
    }
}
```

### Share AI Story to Marketplace
Publish an approved AI story to the community marketplace.

```http
POST /api/v2/marketplace/share-ai-story
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "storyId": "ai-story-uuid",
    "price": 1.99,
    "description": "A delightful AI-generated story perfect for bedtime",
    "tags": ["bedtime", "animals", "friendship"],
    "settings": {
        "allowsDerivatives": true,
        "derivativeFeePercentage": 10.0,
        "commercialUse": true,
        "ageRating": "all_ages"
    },
    "attribution": {
        "acknowledgeAIGeneration": true,
        "includePromptCredit": true
    }
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "listingId": "listing-uuid",
        "status": "published",
        "marketplaceUrl": "/marketplace/listings/listing-uuid",
        "contentSource": "ai_generated",
        "publishedAt": "2024-01-01T12:00:00Z"
    }
}
```

---

## 👤 Creator Profile and Community APIs

### Get Creator Profile
Retrieve detailed creator profile information.

```http
GET /api/v2/creators/{creatorId}
Authorization: Bearer {jwt}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "id": "creator-uuid",
        "userId": "user-uuid",
        "displayName": "StorytellerMom",
        "bio": "Passionate about creating educational stories for children",
        "specialties": ["adventure", "educational", "STEM"],
        "verification": {
            "isVerified": true,
            "verificationType": "educator",
            "verifiedAt": "2024-01-01T00:00:00Z"
        },
        "badges": ["top_creator", "ai_pioneer", "educator", "collaborative"],
        "stats": {
            "totalStoriesCreated": 67,
            "totalTemplatesCreated": 23,
            "totalEarnings": 1247.83,
            "averageStoryRating": 4.6,
            "averageTemplateRating": 4.8,
            "totalDownloads": 3456,
            "followersCount": 234,
            "followingCount": 89
        },
        "recentActivity": [
            {
                "type": "story_published",
                "title": "The Robot's Garden",
                "timestamp": "2024-01-01T10:00:00Z"
            }
        ],
        "preferences": {
            "acceptsCollaborations": true,
            "commissionRate": 25.00,
            "preferredAgeGroups": ["6-8", "9-12"],
            "contentCreationMethods": ["ai_assisted", "collaborative"]
        },
        "socialLinks": {
            "twitter": "@storytellermom",
            "blog": "https://storyteller-mom.com"
        }
    }
}
```

### Follow/Unfollow Creator
Manage creator following relationships.

```http
POST /api/v2/creators/{creatorId}/follow
Authorization: Bearer {jwt}

# Unfollow
DELETE /api/v2/creators/{creatorId}/follow
Authorization: Bearer {jwt}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "creatorId": "creator-uuid",
        "following": true,
        "followersCount": 235,
        "followedAt": "2024-01-01T12:00:00Z"
    }
}
```

### Get Creator's Content
Browse all content from a specific creator.

```http
GET /api/v2/creators/{creatorId}/content
Authorization: Bearer {jwt}
Query Parameters:
  - type: string (stories, templates, collaborations)
  - sort: string (newest, popular, rating)
  - page: int
  - limit: int
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "creator": {
            "displayName": "StorytellerMom",
            "isVerified": true
        },
        "content": {
            "stories": [
                {
                    "id": "story-uuid",
                    "title": "The Brave Little Robot",
                    "contentSource": "ai_assisted",
                    "price": 2.99,
                    "rating": 4.7,
                    "purchaseCount": 156
                }
            ],
            "templates": [
                {
                    "id": "template-uuid",
                    "name": "Robot Adventures",
                    "usageCount": 89,
                    "successRate": 94.2,
                    "price": 0.99
                }
            ],
            "collaborations": [
                {
                    "id": "collab-uuid",
                    "title": "Space Explorers Series",
                    "collaborators": ["CreatorA", "CreatorB"],
                    "status": "active"
                }
            ]
        }
    }
}
```

---

## 🤝 Collaboration APIs

### Create Collaboration Project
Start a new collaborative story project.

```http
POST /api/v2/collaborations/projects
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "title": "Underwater Adventures Series",
    "description": "A series of stories about ocean exploration and marine life",
    "targetAgeGroups": ["6-8", "9-12"],
    "targetThemes": ["ocean", "science", "adventure"],
    "estimatedPages": 15,
    "collaborationType": "open", // open, invite_only, curated
    "maxCollaborators": 4,
    "isPublic": true,
    "projectGoals": ["educational", "entertaining", "series_potential"],
    "timeline": {
        "plannedStartDate": "2024-01-15T00:00:00Z",
        "estimatedCompletionDate": "2024-02-15T00:00:00Z"
    }
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "projectId": "collab-uuid",
        "title": "Underwater Adventures Series",
        "status": "planning",
        "creatorRole": "owner",
        "inviteCode": "UNDERWATER2024",
        "projectUrl": "/collaborations/projects/collab-uuid",
        "createdAt": "2024-01-01T12:00:00Z"
    }
}
```

### Join Collaboration Project
Request to join an existing collaboration.

```http
POST /api/v2/collaborations/projects/{projectId}/join
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "message": "I'd love to contribute to this project! I have experience with educational ocean stories.",
    "proposedContributions": ["writing", "fact-checking", "editing"],
    "portfolio": ["story-uuid-1", "story-uuid-2"],
    "availabilityHours": 10 // per week
}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "requestId": "request-uuid",
        "status": "pending_approval",
        "message": "Your join request has been sent to the project owner",
        "expectedResponseTime": "3-5 business days"
    }
}
```

---

## 📚 Personal Library APIs

### Get Child's Library
Retrieve a child's complete personal library with collections.

```http
GET /api/v2/library/children/{childId}
Authorization: Bearer {jwt}
Query Parameters:
  - includeCollections: boolean (default: true)
  - includeProgress: boolean (default: true)
  - sort: string (recent, alphabetical, progress)
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "child": {
            "id": "child-uuid",
            "firstName": "Emma",
            "age": 7
        },
        "summary": {
            "totalStories": 45,
            "totalCollections": 8,
            "completedStories": 23,
            "averageProgress": 67.5,
            "readingStreak": 12,
            "vocabularyWordsLearned": 156,
            "totalReadingTimeMinutes": 2340
        },
        "collections": [
            {
                "id": "collection-uuid",
                "name": "Bedtime Favorites",
                "type": "bedtime",
                "storiesCount": 12,
                "coverImage": "image-uuid",
                "lastAccessed": "2024-01-01T20:00:00Z",
                "averageProgress": 89.2
            }
        ],
        "recentStories": [
            {
                "id": "story-uuid",
                "title": "The Brave Little Robot",
                "contentSource": "ai_generated",
                "progress": 75.0,
                "lastRead": "2024-01-01T19:30:00Z",
                "collection": "Adventures"
            }
        ],
        "recommendations": [
            {
                "id": "rec-uuid",
                "storyId": "story-uuid",
                "title": "Robot Friends",
                "reason": "Similar to stories you enjoyed",
                "score": 95.2
            }
        ]
    }
}
```

### Create Personal Collection
Create a new story collection for a child.

```http
POST /api/v2/library/children/{childId}/collections
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "name": "Space Adventures",
    "description": "Stories about exploring space and meeting aliens",
    "type": "custom", // custom, favorites, bedtime, learning, adventures
    "coverImageId": "image-uuid",
    "themeColor": "#4A90E2",
    "icon": "rocket",
    "isPrivate": true,
    "autoAddCriteria": {
        "themes": ["space", "aliens", "rockets"],
        "contentSource": ["ai_generated", "human"],
        "maxAutoAdd": 10
    },
    "sortOrder": "reading_level" // date_added, alphabetical, reading_level, custom
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "collectionId": "collection-uuid",
        "name": "Space Adventures",
        "storiesCount": 0,
        "autoAddEnabled": true,
        "createdAt": "2024-01-01T12:00:00Z"
    }
}
```

### Add Story to Collection
Add a story to a child's personal collection.

```http
POST /api/v2/library/collections/{collectionId}/stories
Authorization: Bearer {jwt}
Content-Type: application/json

{
    "storyId": "story-uuid",
    "notes": "Emma's favorite robot story",
    "tags": ["favorite", "bedtime_ok"],
    "sortPosition": 5 // Optional custom position
}
```

### Get Reading Recommendations
Get personalized story recommendations for a child.

```http
GET /api/v2/library/children/{childId}/recommendations
Authorization: Bearer {jwt}
Query Parameters:
  - limit: int (default: 10, max: 50)
  - type: string (all, similar_content, reading_level, interests)
  - excludeOwned: boolean (default: true)
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "recommendations": [
            {
                "id": "rec-uuid",
                "story": {
                    "id": "story-uuid",
                    "title": "The Friendly Robot Helper",
                    "creator": "TechMom",
                    "contentSource": "ai_assisted",
                    "price": 1.99,
                    "rating": 4.6
                },
                "recommendationType": "similar_content",
                "score": 94.5,
                "reasons": [
                    "Similar to 'Brave Little Robot' which Emma completed",
                    "Matches reading level progression",
                    "Contains vocabulary words for current learning goals"
                ],
                "confidence": "high",
                "generatedAt": "2024-01-01T12:00:00Z"
            }
        ],
        "metadata": {
            "basedOnStories": ["story-uuid-1", "story-uuid-2"],
            "learningGoals": ["technology vocabulary", "social skills"],
            "readingLevel": "developing",
            "interests": ["robots", "friendship", "problem-solving"]
        }
    }
}
```

---

## 📊 Analytics and Reporting APIs

### Creator Analytics Dashboard
Comprehensive analytics for content creators.

```http
GET /api/v2/analytics/creator/dashboard
Authorization: Bearer {jwt}
Query Parameters:
  - timeRange: string (7d, 30d, 90d, 1y, all)
  - metrics: string[] (earnings, views, engagement, ratings)
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "timeRange": "30d",
        "summary": {
            "totalEarnings": 145.67,
            "totalViews": 2456,
            "totalPurchases": 78,
            "averageRating": 4.6,
            "newFollowers": 23
        },
        "earnings": {
            "bySource": {
                "stories": 89.45,
                "templates": 34.22,
                "derivatives": 12.00,
                "collaborations": 10.00
            },
            "byTimeframe": [
                {"date": "2024-01-01", "amount": 12.34},
                {"date": "2024-01-02", "amount": 8.90}
            ]
        },
        "contentPerformance": {
            "topStories": [
                {
                    "id": "story-uuid",
                    "title": "Robot Adventures",
                    "views": 456,
                    "purchases": 23,
                    "earnings": 45.77,
                    "rating": 4.8
                }
            ],
            "topTemplates": [
                {
                    "id": "template-uuid",
                    "name": "Space Explorer",
                    "uses": 67,
                    "successRate": 92.5,
                    "earnings": 23.45
                }
            ]
        }
    }
}
```

### Platform Usage Analytics
High-level platform metrics for administrators.

```http
GET /api/v2/analytics/platform/metrics
Authorization: Bearer {jwt}
Permissions: admin_analytics
Query Parameters:
  - timeRange: string
  - breakdown: string (daily, weekly, monthly)
```

---

## 🔐 Authentication and Permissions

### Subscription Tier Requirements

| Tier | Daily AI Generations | Monthly Limit | Template Creation | Marketplace Selling | Collaborations |
|------|---------------------|---------------|------------------|-------------------|----------------|
| Free | 3 | 15 | View only | No | View only |
| Family | 15 | 100 | 5 custom | No | Join only |
| Creator | 50 | 500 | Unlimited | Yes | Full access |
| Educator | 100 | 1000 | Unlimited | Yes | Full access |
| Enterprise | Unlimited | Unlimited | Unlimited | Yes | Full access |

### Required Permissions

- **AI Generation**: Active subscription, quota available, valid parent account
- **Marketplace Selling**: Creator tier+, verified creator profile, payment info
- **Template Creation**: Family tier+ for private, Creator tier+ for public
- **Collaborations**: Creator tier+ to initiate, Family tier+ to participate
- **Child Library Management**: Parent/guardian of child account

---

## 🚨 Error Handling

### Common Error Codes

```json
{
    "error": {
        "code": "QUOTA_EXCEEDED",
        "message": "Daily generation limit reached",
        "details": {
            "currentUsage": 15,
            "limit": 15,
            "resetTime": "2024-01-02T00:00:00Z",
            "upgradeOptions": [...]
        },
        "timestamp": "2024-01-01T12:00:00Z"
    }
}
```

**Error Codes:**
- `QUOTA_EXCEEDED` - Generation limits reached
- `INVALID_PROMPT` - Unsafe or invalid prompt content
- `PAYMENT_REQUIRED` - Premium feature requires subscription
- `CONTENT_MODERATION` - Generated content failed safety checks
- `PROVIDER_UNAVAILABLE` - AI service temporarily unavailable
- `INSUFFICIENT_PERMISSIONS` - User lacks required permissions
- `RESOURCE_NOT_FOUND` - Requested resource doesn't exist
- `VALIDATION_ERROR` - Request data validation failed

---

## 📝 API Changelog

### Version 2.0 (Current)
- Added complete AI story generation system
- Enhanced marketplace with creator economy features
- Introduced personal library and collections
- Added collaboration and community features
- Implemented comprehensive analytics

### Migration from v1
All v1 endpoints remain functional with backward compatibility. New features are available exclusively in v2.

---

This comprehensive API documentation provides complete coverage of the integrated AI Story Platform, supporting all phases from basic AI generation through the full creator economy ecosystem.