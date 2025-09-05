# API Endpoints: AI-Enhanced Story Builder

## Overview
All AI story endpoints follow RESTful conventions and require JWT authentication with parent-level access. Endpoints use the `/api/v2/stories/ai` prefix to distinguish from existing story endpoints.

## Authentication
All endpoints require:
- `Authorization: Bearer {jwt_token}` header
- Parent role verification
- Valid family membership

## Core AI Endpoints

### 1. Generate Complete Story

**Endpoint:** `POST /api/v2/stories/ai/generate`

**Description:** Generates a complete multi-page story based on prompt and parameters.

**Request:**
```json
{
  "prompt": "A brave little mouse who discovers a magical garden",
  "childId": "uuid-string",
  "parameters": {
    "length": 5,  // Number of pages (1-10)
    "complexity": "simple", // simple | moderate | advanced
    "tone": "adventurous", // adventurous | educational | calming | funny
    "educationalFocus": ["vocabulary", "problem-solving"], // Optional
    "includeImages": true,
    "templateId": "uuid-string" // Optional, uses template if provided
  }
}
```

**Response:**
```json
{
  "storyId": "uuid-string",
  "title": "The Brave Mouse's Magical Discovery",
  "pages": [
    {
      "pageNumber": 1,
      "content": "Once upon a time, in a cozy little hole...",
      "suggestedImage": {
        "description": "A small brown mouse peeking out of a hole",
        "searchQuery": "cute mouse home illustration children",
        "libraryImageId": "uuid-string" // If match found
      },
      "metadata": {
        "wordCount": 45,
        "readingTime": 15,
        "vocabularyLevel": "K-2",
        "keyWords": ["mouse", "home", "adventure"]
      }
    }
  ],
  "metadata": {
    "totalWordCount": 245,
    "estimatedReadingTime": 120,
    "ageRange": "4-6",
    "educationalValue": {
      "vocabulary": ["discovered", "magical", "whispered"],
      "concepts": ["bravery", "exploration", "friendship"]
    },
    "aiConfidence": 0.92,
    "generationTime": 8500 // milliseconds
  }
}
```

**Error Responses:**
- `400` - Invalid parameters or prompt
- `402` - AI usage limit exceeded
- `503` - AI service temporarily unavailable

### 2. Enhance Text Selection

**Endpoint:** `POST /api/v2/stories/ai/enhance`

**Description:** Enhances or modifies selected text based on enhancement mode.

**Request:**
```json
{
  "text": "The rabbit went to the garden.",
  "mode": "enrich", // enrich | simplify | expand | rewrite
  "context": {
    "precedingText": "It was a sunny morning.",
    "followingText": "She was looking for carrots.",
    "storyId": "uuid-string",
    "pageNumber": 2,
    "targetAge": "4-6"
  }
}
```

**Response:**
```json
{
  "original": "The rabbit went to the garden.",
  "enhanced": "The fluffy rabbit hopped cheerfully into the blooming garden.",
  "alternatives": [
    "The curious rabbit bounded toward the vegetable garden.",
    "The little rabbit hippity-hopped to the sunny garden patch."
  ],
  "changes": {
    "addedWords": ["fluffy", "hopped", "cheerfully", "blooming"],
    "removedWords": ["went"],
    "complexityChange": "+2",
    "readabilityScore": "K-2"
  },
  "aiConfidence": 0.88
}
```

### 3. Get Contextual Suggestions

**Endpoint:** `POST /api/v2/stories/ai/suggest`

**Description:** Provides contextual suggestions for continuing the story.

**Request:**
```json
{
  "context": {
    "currentText": "The dragon landed on the mountain top and",
    "storyId": "uuid-string",
    "pageNumber": 3,
    "previousPages": ["page1_text", "page2_text"], // Optional
    "storyTone": "adventurous",
    "targetLength": "sentence" // word | sentence | paragraph
  }
}
```

**Response:**
```json
{
  "suggestions": [
    {
      "text": "roared mightily, announcing his arrival to all the creatures below.",
      "type": "continuation",
      "confidence": 0.91,
      "reasoning": "Maintains adventurous tone with dramatic action"
    },
    {
      "text": "discovered a hidden cave filled with glittering treasures.",
      "type": "plot_development",
      "confidence": 0.87,
      "reasoning": "Introduces new story element"
    },
    {
      "text": "noticed a small figure waving from a nearby peak.",
      "type": "character_introduction",
      "confidence": 0.83,
      "reasoning": "Sets up character interaction"
    }
  ],
  "metadata": {
    "contextAnalysis": {
      "currentMood": "exciting",
      "suggestedDirection": "discovery",
      "narrativePace": "building"
    }
  }
}
```

### 4. Validate Story Content

**Endpoint:** `POST /api/v2/stories/ai/validate`

**Description:** Validates story content for age-appropriateness, consistency, and educational value.

**Request:**
```json
{
  "storyId": "uuid-string",
  "pages": [
    {
      "pageNumber": 1,
      "content": "Story page text..."
    }
  ],
  "targetAge": "4-6",
  "checkFor": ["appropriateness", "consistency", "complexity", "educational"]
}
```

**Response:**
```json
{
  "valid": true,
  "issues": [
    {
      "type": "complexity",
      "severity": "warning",
      "pageNumber": 3,
      "description": "Vocabulary may be challenging for target age",
      "specifics": ["metamorphosis", "constellation"],
      "suggestion": "Consider simplifying to 'change' and 'stars'"
    }
  ],
  "scores": {
    "ageAppropriateness": 0.95,
    "consistency": 0.98,
    "educationalValue": 0.87,
    "engagement": 0.91
  },
  "recommendations": [
    "Add more descriptive language in page 2",
    "Consider adding a moral lesson conclusion"
  ]
}
```

### 5. Get Smart Templates

**Endpoint:** `GET /api/v2/stories/ai/templates`

**Description:** Retrieves AI-powered story templates based on child profile and preferences.

**Query Parameters:**
- `childId` (required) - Child's UUID
- `category` - Template category (bedtime, educational, adventure)
- `recentlyUsed` - Include recently used templates (boolean)

**Response:**
```json
{
  "templates": [
    {
      "id": "uuid-string",
      "name": "Bedtime in the Stars",
      "category": "bedtime",
      "description": "A calming journey through the night sky",
      "structure": {
        "pages": 5,
        "progression": "exciting -> calming",
        "endingType": "peaceful"
      },
      "prompts": {
        "opening": "A child looks up at the stars and wonders...",
        "development": "Each star tells a gentle story...",
        "conclusion": "As sleep comes, the stars sing a lullaby..."
      },
      "customizable": {
        "characterName": true,
        "setting": ["space", "ocean", "forest"],
        "companions": true
      },
      "metadata": {
        "usageCount": 156,
        "avgRating": 4.7,
        "ageRange": "3-6",
        "readingTime": 5
      }
    }
  ],
  "personalized": {
    "recommendedTemplates": ["uuid1", "uuid2"],
    "reason": "Based on recent bedtime story preferences"
  }
}
```

### 6. Suggest Images

**Endpoint:** `POST /api/v2/stories/ai/images/suggest`

**Description:** Suggests appropriate images from the library based on story content.

**Request:**
```json
{
  "pageContent": "The little fox played in the autumn leaves",
  "existingImages": ["uuid1", "uuid2"], // To avoid duplicates
  "style": "illustration", // illustration | photograph | cartoon
  "mood": "playful"
}
```

**Response:**
```json
{
  "suggestions": [
    {
      "imageId": "uuid-string",
      "url": "/images/library/fox-autumn-play.jpg",
      "relevanceScore": 0.94,
      "tags": ["fox", "autumn", "playful", "leaves"],
      "altText": "A young fox jumping in colorful fall leaves"
    },
    {
      "imageId": "uuid-string2",
      "url": "/images/library/forest-autumn-scene.jpg",
      "relevanceScore": 0.81,
      "tags": ["autumn", "forest", "leaves"],
      "altText": "Autumn forest with fallen leaves"
    }
  ],
  "searchQueries": [
    "fox playing autumn leaves illustration",
    "cute fox fall season children book"
  ],
  "generationPrompt": {
    "description": "A playful young fox jumping through orange and red autumn leaves",
    "style": "children's book illustration",
    "colorPalette": ["orange", "red", "brown", "forest green"]
  }
}
```

### 7. Save AI Interaction History

**Endpoint:** `POST /api/v2/stories/ai/history`

**Description:** Saves AI interaction for learning and improvement.

**Request:**
```json
{
  "storyId": "uuid-string",
  "interaction": {
    "type": "generation", // generation | enhancement | suggestion
    "input": "User's prompt or selection",
    "output": "AI's response",
    "accepted": true,
    "modifications": "User's edits after accepting",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

**Response:**
```json
{
  "historyId": "uuid-string",
  "saved": true
}
```

### 8. Get AI Usage Statistics

**Endpoint:** `GET /api/v2/stories/ai/usage`

**Description:** Retrieves AI usage statistics for the parent account.

**Query Parameters:**
- `period` - Time period (today | week | month | all)
- `childId` - Filter by specific child (optional)

**Response:**
```json
{
  "usage": {
    "totalGenerations": 45,
    "totalEnhancements": 128,
    "totalSuggestions": 256,
    "tokensUsed": 45000,
    "tokensRemaining": 955000,
    "resetDate": "2024-02-01T00:00:00Z"
  },
  "insights": {
    "mostUsedFeature": "enhance",
    "averageStoryLength": 5.2,
    "preferredTone": "educational",
    "peakUsageTime": "19:00-20:00"
  },
  "limits": {
    "dailyGenerations": 50,
    "monthlyTokens": 1000000,
    "concurrentRequests": 3
  }
}
```

## WebSocket Endpoints

### 1. Real-time Story Generation

**Endpoint:** `WS /api/v2/stories/ai/stream`

**Description:** Streams story generation in real-time for better UX.

**Connection Flow:**
```javascript
// Client connects
ws.connect("/api/v2/stories/ai/stream", {
  headers: { "Authorization": "Bearer {token}" }
});

// Client sends generation request
ws.send({
  type: "generate",
  data: {
    prompt: "Story prompt",
    parameters: { /* ... */ }
  }
});

// Server streams response
ws.onMessage({
  type: "chunk",
  data: {
    pageNumber: 1,
    content: "Once upon a time...",
    progress: 0.15
  }
});

// Server sends completion
ws.onMessage({
  type: "complete",
  data: {
    storyId: "uuid-string",
    totalPages: 5
  }
});
```

### 2. Live Suggestions

**Endpoint:** `WS /api/v2/stories/ai/suggestions/live`

**Description:** Provides real-time suggestions as user types.

**Message Format:**
```javascript
// Client sends current context
ws.send({
  type: "context_update",
  data: {
    currentText: "The hero walked into the",
    cursorPosition: 24
  }
});

// Server responds with suggestions
ws.onMessage({
  type: "suggestions",
  data: {
    inline: ["dark forest", "castle", "village"],
    nextWord: ["dark", "mysterious", "ancient"],
    confidence: 0.89
  }
});
```

## Error Handling

### Standard Error Response Format
```json
{
  "error": {
    "code": "AI_SERVICE_ERROR",
    "message": "User-friendly error message",
    "details": {
      "reason": "rate_limit_exceeded",
      "retryAfter": 60,
      "suggestion": "Try again in 1 minute"
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Error Codes
| Code | HTTP Status | Description |
|------|------------|-------------|
| `AI_SERVICE_UNAVAILABLE` | 503 | AI service temporarily down |
| `AI_RATE_LIMIT` | 429 | Too many requests |
| `AI_CONTENT_VIOLATION` | 422 | Generated content violates policies |
| `AI_QUOTA_EXCEEDED` | 402 | Monthly AI usage limit reached |
| `AI_INVALID_PROMPT` | 400 | Prompt contains invalid content |
| `AI_TIMEOUT` | 504 | AI generation timed out |
| `AI_CONTEXT_TOO_LARGE` | 413 | Context exceeds token limit |

## Rate Limiting

### Limits per Endpoint
| Endpoint | Requests/Minute | Requests/Hour | Requests/Day |
|----------|----------------|---------------|--------------|
| `/generate` | 5 | 30 | 100 |
| `/enhance` | 20 | 200 | 1000 |
| `/suggest` | 30 | 500 | 2000 |
| `/validate` | 10 | 100 | 500 |
| `/templates` | 30 | 300 | 1000 |

### Response Headers
```
X-RateLimit-Limit: 30
X-RateLimit-Remaining: 25
X-RateLimit-Reset: 1642255200
```

## Caching Strategy

### Cache Headers
```
Cache-Control: private, max-age=3600
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
Last-Modified: Mon, 15 Jan 2024 10:30:00 GMT
```

### Cached Endpoints
- `/templates` - 1 hour
- `/images/suggest` - 30 minutes
- `/usage` - 5 minutes

## Monitoring & Analytics

### Required Metrics
- Response time per endpoint
- AI service latency
- Token usage per request
- Error rates by type
- Cache hit ratios
- User adoption rates

### Logging Format
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "endpoint": "/api/v2/stories/ai/generate",
  "userId": "uuid-string",
  "requestId": "uuid-string",
  "duration": 8543,
  "tokensUsed": 1250,
  "status": 200,
  "aiProvider": "openai",
  "aiModel": "gpt-4"
}
```

## Security Considerations

### Input Validation
- Sanitize all prompts before AI processing
- Validate child age ranges
- Check content against blocklist
- Verify JWT token validity
- Enforce parent-only access

### Output Filtering
- Screen for inappropriate content
- Remove personal information
- Check against COPPA guidelines
- Validate educational appropriateness

### Data Privacy
- No storage of raw prompts with PII
- Anonymized interaction logging
- Encrypted transmission
- Local processing option available
- Clear data retention policies