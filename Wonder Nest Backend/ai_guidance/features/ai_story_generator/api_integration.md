# AI Story Generator - API Integration Documentation

## Overview

This document outlines how the AI story generation features integrate with WonderNest's existing API infrastructure, maximizing reuse of current endpoints while adding new AI-specific capabilities.

## API Architecture

### Base URL Structure
```
/api/v2/stories     # Existing story endpoints
/api/v2/ai          # New AI-specific endpoints
/api/v2/marketplace # Enhanced marketplace endpoints
/api/v2/files       # Enhanced file upload endpoints
```

## Enhanced Existing Endpoints

### 1. Story Templates Endpoint (Enhanced)

#### GET /api/v2/stories/templates
**Enhanced to include AI-generated stories**

```kotlin
// Request
GET /api/v2/stories/templates?creator_type=ai_generated&child_id={childId}

// Response additions
{
    "templates": [
        {
            "id": "uuid",
            "title": "The Magic Garden Adventure",
            "creator_type": "fully_ai", // NEW FIELD
            "ai_metadata": {             // NEW FIELD
                "generated_from_prompt": true,
                "source_images": ["image_id1", "image_id2"],
                "generation_date": "2024-01-15T10:30:00Z"
            },
            // ... existing fields
        }
    ]
}
```

### 2. Marketplace Listings (Enhanced)

#### GET /api/v2/marketplace/listings
**Enhanced to filter AI content**

```kotlin
// Request with new filters
GET /api/v2/marketplace/listings?content_source=ai_generated&allows_derivatives=true

// Response additions
{
    "listings": [
        {
            "id": "uuid",
            "content_source": "ai_generated",     // NEW FIELD
            "allows_derivatives": true,           // NEW FIELD
            "derivative_fee_percentage": 10.0,    // NEW FIELD
            "prompt_template_id": "uuid",         // NEW FIELD
            // ... existing fields
        }
    ]
}
```

### 3. File Upload (Enhanced)

#### POST /api/v2/files/upload
**Enhanced with AI analysis**

```kotlin
// Request (unchanged)
POST /api/v2/files/upload
Content-Type: multipart/form-data

// Response additions
{
    "file": {
        "id": "uuid",
        "url": "https://...",
        "ai_analysis": {                    // NEW FIELD
            "detected_objects": ["dog", "ball", "grass"],
            "detected_colors": ["green", "brown", "white"],
            "scene_description": "A dog playing with a ball in a grassy yard",
            "is_child_safe": true,
            "confidence_scores": {
                "objects": 0.95,
                "safety": 0.99
            }
        },
        // ... existing fields
    }
}
```

## New AI-Specific Endpoints

### 1. Generate Story from Prompt

#### POST /api/v2/ai/stories/generate

```kotlin
// Request
{
    "prompt": "Create a story about a brave little mouse who discovers a magical cheese",
    "child_id": "uuid",                    // Optional - for personalization
    "parameters": {
        "age_group": "3-5",
        "difficulty": "emerging",
        "page_count": 10,
        "themes": ["courage", "friendship"],
        "vocabulary_focus": ["brave", "discover", "magical"],
        "include_quiz": true
    },
    "prompt_template_id": "uuid",          // Optional - use existing template
    "require_parent_approval": true        // Default: true
}

// Response
{
    "generation_id": "uuid",
    "status": "processing",
    "estimated_completion_time": 30,       // seconds
    "preview_available": false,
    "parent_approval_required": true
}
```

#### GET /api/v2/ai/stories/generation/{generationId}

```kotlin
// Response when complete
{
    "generation_id": "uuid",
    "status": "completed",
    "story_template_id": "uuid",           // The generated story
    "story_preview": {
        "title": "The Brave Little Mouse",
        "first_page": "Once upon a time...",
        "page_count": 10,
        "vocabulary_words": ["brave", "discover", "magical"]
    },
    "parent_approval_status": "pending",
    "generation_metrics": {
        "time_taken_ms": 15000,
        "tokens_used": 1500,
        "cost": 0.045
    }
}
```

### 2. Generate Story from Images

#### POST /api/v2/ai/stories/generate-from-images

```kotlin
// Request
{
    "image_ids": ["uuid1", "uuid2", "uuid3"],  // Previously uploaded files
    "child_id": "uuid",
    "prompt_additions": "Include these images in a story about friendship",
    "parameters": {
        "use_image_sequence": true,            // Use images in order
        "detect_characters": true,             // Extract characters from images
        "maintain_scene_continuity": true
    }
}

// Response
{
    "generation_id": "uuid",
    "status": "analyzing_images",
    "image_analysis": {
        "detected_story_elements": {
            "characters": ["dog", "cat", "bird"],
            "settings": ["garden", "house"],
            "objects": ["ball", "tree", "flowers"],
            "suggested_themes": ["friendship", "play", "nature"]
        }
    }
}
```

### 3. AI Prompt Templates

#### GET /api/v2/ai/prompt-templates

```kotlin
// Request
GET /api/v2/ai/prompt-templates?age_group=3-5&is_public=true&sort=rating

// Response
{
    "templates": [
        {
            "id": "uuid",
            "title": "My Adventure Story",
            "description": "Create a personalized adventure...",
            "creator": {
                "id": "uuid",
                "name": "WonderNest Team",
                "type": "admin"
            },
            "variable_slots": [
                {
                    "name": "character_name",
                    "type": "text",
                    "label": "Child's Name",
                    "required": true
                }
            ],
            "rating": 4.8,
            "usage_count": 1250,
            "is_premium": false
        }
    ]
}
```

#### POST /api/v2/ai/prompt-templates

```kotlin
// Create custom prompt template
{
    "title": "Ocean Explorer Story",
    "description": "Dive deep into ocean adventures",
    "base_prompt": "Create a story about {character_name} exploring the ocean...",
    "variable_slots": [...],
    "is_public": false,                    // Keep private initially
    "age_group": "6-8"
}
```

### 4. Story Customization

#### POST /api/v2/ai/stories/{storyId}/customize

```kotlin
// Request
{
    "customizations": {
        "character_name": "Emma",
        "character_gender": "female",
        "setting_changes": {
            "forest": "jungle",
            "cottage": "treehouse"
        }
    },
    "maintain_original_plot": true,
    "create_as_derivative": true           // Track as derivative work
}

// Response
{
    "customized_story_id": "uuid",
    "derivative_relationship": {
        "original_story_id": "uuid",
        "derivative_type": "personalization",
        "attribution_required": true
    }
}
```

### 5. Parent Approval Workflow

#### GET /api/v2/ai/stories/pending-approval

```kotlin
// Get stories awaiting parent approval
{
    "pending_stories": [
        {
            "generation_id": "uuid",
            "story_template_id": "uuid",
            "child_id": "uuid",
            "child_name": "Emma",
            "generated_at": "2024-01-15T10:30:00Z",
            "preview": {
                "title": "The Magical Garden",
                "first_page": "...",
                "themes": ["nature", "friendship"]
            },
            "safety_check": {
                "passed": true,
                "concerns": []
            }
        }
    ]
}
```

#### POST /api/v2/ai/stories/{generationId}/approve

```kotlin
// Request
{
    "approved": true,
    "modifications": {
        "title": "Emma's Magical Garden",   // Optional edits
        "remove_pages": [5]                 // Remove specific pages
    },
    "make_available_to_child": true,
    "share_to_siblings": ["child_id2"]
}
```

### 6. Community Marketplace Integration

#### POST /api/v2/ai/stories/{storyId}/share-to-marketplace

```kotlin
// Share AI-generated story to marketplace
{
    "listing_details": {
        "marketing_title": "Personalized Ocean Adventure",
        "marketing_description": "A customizable ocean exploration story",
        "price": 2.99,
        "allows_derivatives": true,
        "derivative_fee_percentage": 15.0,
        "preview_pages": [1, 3, 5]
    },
    "attribution": {
        "show_ai_generated_badge": true,
        "prompt_template_id": "uuid"        // If based on template
    }
}
```

#### GET /api/v2/marketplace/ai-analytics

```kotlin
// Get AI content performance metrics
{
    "metrics": {
        "total_ai_stories": 450,
        "ai_stories_sold": 125,
        "revenue_from_ai": 374.50,
        "top_ai_creators": [...],
        "popular_prompt_templates": [...],
        "derivative_works_created": 45
    }
}
```

## Integration with Existing Services

### Content Workflow Integration

```kotlin
// AI stories automatically enter content workflow
class AIStoryService(
    private val contentWorkflowService: ContentWorkflowService
) {
    suspend fun generateStory(request: GenerateRequest): Story {
        val story = generateWithAI(request)
        
        // Submit to existing content workflow
        val workflowItem = ContentItem(
            content_type = "story",
            title = story.title,
            content_data = story.toJson(),
            creator_id = request.parentId,
            status = "in_review"  // Automatic review
        )
        
        contentWorkflowService.create(workflowItem)
        
        // Trigger parent approval
        contentWorkflowService.requestApproval(
            item_id = workflowItem.id,
            approval_stage = "parent_review"
        )
        
        return story
    }
}
```

### File Upload Integration

```kotlin
// Enhance existing file upload with AI analysis
class FileUploadService(
    private val aiAnalysisService: AIAnalysisService
) {
    suspend fun uploadFile(file: MultipartFile): UploadedFile {
        val uploaded = saveFile(file)
        
        // Trigger AI analysis for images
        if (file.contentType.startsWith("image/")) {
            val analysis = aiAnalysisService.analyzeImage(uploaded.url)
            
            uploaded.ai_analysis = analysis
            uploaded.detected_objects = analysis.objects
            uploaded.scene_description = analysis.description
            uploaded.is_child_safe = analysis.safety.passed
        }
        
        return uploaded
    }
}
```

## Authentication & Authorization

### Required Headers
```
Authorization: Bearer {jwt_token}
X-Family-ID: {family_uuid}
X-Child-ID: {child_uuid}        // When acting on behalf of child
```

### Permission Levels

1. **Parent Access**
   - Generate stories for their children
   - Approve/reject AI content
   - Share to marketplace
   - Create prompt templates

2. **Child Access**
   - View approved AI stories only
   - Cannot generate directly
   - Cannot access marketplace

3. **Admin Access**
   - Moderate all AI content
   - Create featured templates
   - View analytics
   - Manage safety filters

## Rate Limiting

```kotlin
// AI-specific rate limits
object AIRateLimits {
    const val GENERATIONS_PER_DAY = 10
    const val GENERATIONS_PER_MONTH = 100
    const val IMAGE_ANALYSIS_PER_DAY = 50
    const val TEMPLATE_CREATIONS_PER_MONTH = 20
}

// Response headers
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1705334400
```

## Error Handling

### AI-Specific Error Codes

```kotlin
enum class AIErrorCode {
    AI_SERVICE_UNAVAILABLE(5001),       // LLM provider down
    CONTENT_SAFETY_VIOLATION(5002),     // Failed safety check
    GENERATION_TIMEOUT(5003),           // Generation took too long
    INSUFFICIENT_AI_CREDITS(5004),      // Rate limit exceeded
    INVALID_PROMPT_TEMPLATE(5005),      // Template validation failed
    IMAGE_ANALYSIS_FAILED(5006),        // Vision API error
    PARENT_APPROVAL_REQUIRED(5007),     // Needs parent review
    DERIVATIVE_NOT_ALLOWED(5008)        // Original doesn't allow derivatives
}

// Error response format
{
    "error": {
        "code": 5002,
        "message": "Content safety violation detected",
        "details": {
            "concerns": ["mild_violence"],
            "suggestions": ["Modify the prompt to be more age-appropriate"]
        }
    }
}
```

## Webhooks

### AI Generation Events

```kotlin
// Webhook payloads for AI events
POST {webhook_url}

// Generation completed
{
    "event": "ai.story.generated",
    "data": {
        "generation_id": "uuid",
        "story_id": "uuid",
        "family_id": "uuid",
        "status": "completed"
    }
}

// Parent approval needed
{
    "event": "ai.story.approval_required",
    "data": {
        "generation_id": "uuid",
        "parent_id": "uuid",
        "child_name": "Emma"
    }
}
```

## Testing

### Mock AI Mode

```kotlin
// Enable mock AI for testing
X-AI-Mock-Mode: true
X-AI-Mock-Delay: 1000  // Simulate generation time

// Mock responses return predetermined content
{
    "story_template_id": "mock-uuid",
    "title": "[MOCK] Test Story",
    "content": "This is a mock AI-generated story for testing..."
}
```

## Migration Support

### Backwards Compatibility

All existing story endpoints continue to work unchanged. AI features are additive:

```kotlin
// Old endpoint still works
GET /api/v2/stories/templates

// Returns both human and AI stories
// Use filters to get only human-created:
GET /api/v2/stories/templates?creator_type=human
```

### Feature Flags

```kotlin
// Check AI feature availability
GET /api/v2/features

{
    "ai_story_generation": true,
    "ai_image_analysis": true,
    "prompt_marketplace": false,  // Coming soon
    "voice_generation": false     // Future feature
}
```

## Performance Considerations

### Async Generation

All AI generation is asynchronous to prevent blocking:

```kotlin
// Initial request returns immediately
POST /api/v2/ai/stories/generate
// Returns: { "generation_id": "uuid", "status": "processing" }

// Poll for status
GET /api/v2/ai/stories/generation/{id}/status

// Or use WebSocket for real-time updates
ws://api/v2/ai/stories/generation/{id}/stream
```

### Caching

```kotlin
// AI responses are cached to reduce costs
Cache-Control: private, max-age=86400
X-Cache-Hit: true  // Indicates cached response
```

## Security

### Prompt Injection Prevention

```kotlin
// All prompts are sanitized
class PromptSanitizer {
    fun sanitize(prompt: String): String {
        // Remove injection attempts
        // Validate against allowlist
        // Enforce length limits
        return sanitizedPrompt
    }
}
```

### Content Filtering

```kotlin
// Multi-layer content safety
1. Pre-generation prompt filtering
2. LLM safety settings
3. Post-generation content scan
4. Parent approval requirement
5. Community reporting system
```