# AI Story Generator - Technical Specification

## Architecture Overview

### System Components
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│   KTOR Backend   │────▶│   LLM Service   │
│  (Parent Mode)  │     │   (Orchestrator) │     │   (Gemini)      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                        │                         
         │                        ▼                         
         │              ┌──────────────────┐               
         │              │   PostgreSQL     │               
         │              │   (Storage)      │               
         │              └──────────────────┘               
         │                        │                         
         ▼                        ▼                         
┌─────────────────┐     ┌──────────────────┐               
│  Flutter App    │────▶│   Redis Cache    │               
│  (Child Mode)   │     │   (Generated)    │               
└─────────────────┘     └──────────────────┘               
```

### Data Flow
1. Parent selects images and enters prompt in Flutter app
2. Request sent to KTOR backend with JWT auth
3. Backend validates request and user permissions
4. Backend fetches image metadata and constructs LLM prompt
5. LLM service generates story content
6. Backend processes and validates generated content
7. Story saved to PostgreSQL with pending_approval status
8. Parent reviews and approves in app
9. Approved story available to child
10. Story cached in Redis for fast retrieval

## Database Schema

### New Tables (in games schema)

```sql
-- AI Generation Requests
CREATE TABLE games.ai_story_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id),
    family_id UUID NOT NULL REFERENCES core.families(id),
    
    -- Request inputs
    prompt TEXT NOT NULL,
    image_ids UUID[] NOT NULL, -- References to core.uploaded_files
    age_group VARCHAR(10) NOT NULL CHECK (age_group IN ('3-5', '6-8', '9-12')),
    difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('emerging', 'developing', 'fluent')),
    
    -- Generation parameters
    target_pages INTEGER DEFAULT 10,
    vocabulary_focus TEXT[], -- Specific words to include
    themes TEXT[], -- Educational themes to incorporate
    tone VARCHAR(50) DEFAULT 'friendly', -- friendly, adventurous, educational, calming
    
    -- LLM configuration
    llm_provider VARCHAR(50) DEFAULT 'gemini',
    llm_model VARCHAR(100) DEFAULT 'gemini-1.5-flash',
    temperature DECIMAL(3,2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 4000,
    
    -- Response tracking
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled'
    )),
    llm_request_id VARCHAR(255), -- External API request ID
    llm_response JSONB, -- Raw LLM response
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Cost tracking
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    estimated_cost DECIMAL(10,4),
    
    -- Timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    processing_time_ms INTEGER,
    
    CONSTRAINT ai_story_requests_retry_check CHECK (retry_count <= 3)
);

-- AI Generated Stories (extends story_templates)
CREATE TABLE games.ai_generated_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES games.ai_story_requests(id),
    template_id UUID REFERENCES games.story_templates(id), -- Created after approval
    
    -- Generated content
    generated_title VARCHAR(255) NOT NULL,
    generated_description TEXT,
    generated_content JSONB NOT NULL, -- Full story structure
    generated_vocabulary JSONB NOT NULL, -- Words with definitions
    
    -- Image mapping
    image_placements JSONB NOT NULL, -- Which images go on which pages
    image_analysis JSONB, -- LLM's understanding of each image
    
    -- Validation results
    safety_check_passed BOOLEAN DEFAULT false,
    safety_check_results JSONB,
    vocabulary_level_appropriate BOOLEAN DEFAULT false,
    content_warnings TEXT[],
    
    -- Approval workflow
    approval_status VARCHAR(50) DEFAULT 'pending_review' CHECK (approval_status IN (
        'pending_review', 'approved', 'rejected', 'edited'
    )),
    reviewed_by UUID REFERENCES core.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    
    -- Edited version (if parent makes changes)
    edited_content JSONB,
    edited_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- LLM Provider Configuration
CREATE TABLE games.llm_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name VARCHAR(50) UNIQUE NOT NULL,
    api_endpoint TEXT NOT NULL,
    api_version VARCHAR(20),
    
    -- Configuration
    default_model VARCHAR(100),
    default_temperature DECIMAL(3,2) DEFAULT 0.7,
    default_max_tokens INTEGER DEFAULT 4000,
    
    -- Rate limiting
    requests_per_minute INTEGER DEFAULT 60,
    requests_per_day INTEGER DEFAULT 1000,
    tokens_per_minute INTEGER DEFAULT 100000,
    
    -- Cost tracking
    cost_per_1k_prompt_tokens DECIMAL(10,6),
    cost_per_1k_completion_tokens DECIMAL(10,6),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_primary BOOLEAN DEFAULT false,
    health_check_url TEXT,
    last_health_check TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Generation Quotas
CREATE TABLE games.ai_generation_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id) UNIQUE,
    
    -- Quota limits
    daily_limit INTEGER DEFAULT 5,
    monthly_limit INTEGER DEFAULT 50,
    total_lifetime_limit INTEGER, -- NULL = unlimited
    
    -- Current usage
    daily_used INTEGER DEFAULT 0,
    monthly_used INTEGER DEFAULT 0,
    total_used INTEGER DEFAULT 0,
    
    -- Reset tracking
    daily_reset_at TIMESTAMP WITH TIME ZONE,
    monthly_reset_at TIMESTAMP WITH TIME ZONE,
    
    -- Subscription tier
    tier VARCHAR(50) DEFAULT 'free' CHECK (tier IN ('free', 'premium', 'unlimited')),
    bonus_credits INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Prompt Templates (for reusable prompts)
CREATE TABLE games.ai_prompt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES core.users(id), -- NULL for system templates
    
    -- Template details
    name VARCHAR(255) NOT NULL,
    description TEXT,
    prompt_template TEXT NOT NULL, -- With {placeholders}
    
    -- Categorization
    category VARCHAR(50),
    tags TEXT[],
    age_groups VARCHAR(10)[],
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    success_rate DECIMAL(5,2), -- Percentage of approved stories
    
    -- Sharing
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Image Analysis Cache
CREATE TABLE games.image_analysis_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID NOT NULL REFERENCES core.uploaded_files(id) UNIQUE,
    
    -- Analysis results
    description TEXT NOT NULL, -- LLM-generated description
    detected_objects JSONB, -- Objects/characters in image
    detected_colors JSONB, -- Dominant colors
    detected_mood VARCHAR(50), -- happy, calm, exciting, etc.
    is_character BOOLEAN DEFAULT false,
    is_background BOOLEAN DEFAULT false,
    
    -- Metadata
    analysis_provider VARCHAR(50),
    analysis_model VARCHAR(100),
    confidence_score DECIMAL(3,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '90 days')
);

-- Create indexes
CREATE INDEX idx_ai_requests_user_status ON games.ai_story_requests(user_id, status);
CREATE INDEX idx_ai_requests_created ON games.ai_story_requests(created_at DESC);
CREATE INDEX idx_ai_generated_approval ON games.ai_generated_stories(approval_status, created_at);
CREATE INDEX idx_ai_generated_request ON games.ai_generated_stories(request_id);
CREATE INDEX idx_generation_quotas_user ON games.ai_generation_quotas(user_id);
CREATE INDEX idx_prompt_templates_user ON games.ai_prompt_templates(user_id, is_public);
CREATE INDEX idx_image_analysis_file ON games.image_analysis_cache(file_id);
```

## API Endpoints

### Story Generation APIs

```kotlin
// Generate AI Story
POST /api/v2/ai/stories/generate
Headers: Authorization: Bearer {jwt}
Request:
{
    "prompt": "A story about a brave knight and a friendly dragon",
    "imageIds": ["uuid1", "uuid2"],
    "ageGroup": "6-8",
    "difficulty": "developing",
    "options": {
        "targetPages": 10,
        "vocabularyFocus": ["courage", "friendship"],
        "themes": ["bravery", "teamwork"],
        "tone": "adventurous"
    }
}
Response:
{
    "requestId": "uuid",
    "status": "processing",
    "estimatedTime": 30,
    "message": "Story generation in progress"
}

// Check Generation Status
GET /api/v2/ai/stories/status/{requestId}
Response:
{
    "requestId": "uuid",
    "status": "completed",
    "storyId": "uuid",
    "processingTime": 15000
}

// Get Generated Story for Review
GET /api/v2/ai/stories/{storyId}/preview
Response:
{
    "id": "uuid",
    "title": "The Brave Knight and the Friendly Dragon",
    "description": "An adventure about courage and friendship",
    "pages": [...],
    "vocabulary": [...],
    "warnings": [],
    "metadata": {...}
}

// Approve/Reject Story
POST /api/v2/ai/stories/{storyId}/review
Request:
{
    "action": "approve", // or "reject", "edit"
    "notes": "Looks great!",
    "editedContent": {...} // if action is "edit"
}

// Get Generation History
GET /api/v2/ai/stories/history
Query: ?page=1&limit=20&status=completed
Response:
{
    "stories": [...],
    "total": 45,
    "page": 1,
    "hasMore": true
}

// Get Generation Quota
GET /api/v2/ai/quotas
Response:
{
    "daily": { "used": 2, "limit": 5 },
    "monthly": { "used": 15, "limit": 50 },
    "bonusCredits": 0,
    "nextDailyReset": "2024-01-02T00:00:00Z",
    "tier": "premium"
}

// Get Prompt Templates
GET /api/v2/ai/templates
Query: ?category=adventure&ageGroup=6-8
Response:
{
    "templates": [...],
    "total": 25
}

// Save Prompt Template
POST /api/v2/ai/templates
Request:
{
    "name": "Dragon Adventure",
    "prompt": "A story about {character} who meets a {adjective} dragon",
    "tags": ["adventure", "fantasy"]
}
```

## LLM Integration Design

### Generic LLM Interface

```kotlin
interface LLMProvider {
    suspend fun generateStory(request: StoryGenerationRequest): StoryGenerationResponse
    suspend fun analyzeImage(imageUrl: String): ImageAnalysis
    suspend fun validateContent(content: String, ageGroup: String): ContentValidation
    fun getProviderName(): String
    fun estimateCost(tokens: TokenUsage): BigDecimal
}

data class StoryGenerationRequest(
    val prompt: String,
    val systemPrompt: String,
    val imageDescriptions: List<String>,
    val parameters: GenerationParameters
)

data class GenerationParameters(
    val temperature: Double = 0.7,
    val maxTokens: Int = 4000,
    val topP: Double = 0.9,
    val frequencyPenalty: Double = 0.3,
    val presencePenalty: Double = 0.3
)

data class StoryGenerationResponse(
    val success: Boolean,
    val story: GeneratedStory?,
    val error: String?,
    val usage: TokenUsage,
    val requestId: String
)

data class GeneratedStory(
    val title: String,
    val description: String,
    val pages: List<StoryPage>,
    val vocabulary: List<VocabularyWord>,
    val themes: List<String>,
    val readingTime: Int
)
```

### Gemini Implementation

```kotlin
class GeminiProvider : LLMProvider {
    private val client = GoogleGenerativeAI(apiKey)
    
    override suspend fun generateStory(request: StoryGenerationRequest): StoryGenerationResponse {
        val model = GenerativeModel(
            modelName = "gemini-1.5-flash",
            generationConfig = generationConfig {
                temperature = request.parameters.temperature
                topK = 40
                topP = request.parameters.topP
                maxOutputTokens = request.parameters.maxTokens
            }
        )
        
        // Include images if provided
        val content = content {
            text(request.systemPrompt)
            text(request.prompt)
            request.imageDescriptions.forEach { 
                text("Image: $it")
            }
        }
        
        val response = model.generateContent(content)
        return parseResponse(response)
    }
}
```

## Prompt Engineering

### System Prompt Template
```
You are a children's story writer for WonderNest, an educational platform.
Create an age-appropriate story with the following requirements:

AGE GROUP: {ageGroup}
READING LEVEL: {difficulty}
TARGET LENGTH: {pages} pages
TONE: {tone}

EDUCATIONAL GOALS:
{educationalGoals}

VOCABULARY TO INCLUDE:
{vocabularyWords}

IMAGES TO INCORPORATE:
{imageDescriptions}

STORY REQUIREMENTS:
1. Create a complete story with beginning, middle, and end
2. Include all provided images naturally in the narrative
3. Introduce vocabulary words in context
4. Ensure age-appropriate content (no violence, scary themes)
5. Include positive messages and learning opportunities
6. Format as JSON with structure provided below

OUTPUT FORMAT:
{
    "title": "Story Title",
    "description": "Brief story description",
    "pages": [
        {
            "pageNumber": 1,
            "text": "Page text here...",
            "imageId": "uuid or null",
            "vocabularyWords": ["word1", "word2"]
        }
    ],
    "vocabulary": [
        {
            "word": "courage",
            "definition": "Being brave when facing something difficult",
            "usage": "The knight showed courage when facing the dragon."
        }
    ],
    "themes": ["bravery", "friendship"],
    "educationalValue": "Teaches about courage and teamwork"
}

USER PROMPT: {userPrompt}
```

## Safety & Validation

### Content Safety Pipeline
1. **Pre-Generation Validation**
   - Sanitize user prompt for inappropriate content
   - Check image tags for appropriateness
   - Verify user quota availability

2. **LLM Safety Layer**
   - Include safety instructions in system prompt
   - Use LLM's built-in safety filters
   - Set appropriate content filters by age

3. **Post-Generation Validation**
   - Scan for personal information (names, addresses)
   - Check vocabulary difficulty against age group
   - Validate story structure and completeness
   - Scan for prohibited topics

4. **Human Review Gate**
   - Parent must review before child access
   - Option to edit or reject
   - Track approval patterns for ML training

### Prohibited Content List
- Violence or weapons
- Death or serious injury  
- Scary creatures (age-dependent)
- Complex emotional trauma
- Religious or political content
- Brand names or commercial content
- Personal information
- Inappropriate relationships

## Caching Strategy

### Redis Cache Layers
```
1. Image Analysis Cache (TTL: 90 days)
   Key: image_analysis:{file_id}
   Value: JSON analysis results

2. Generated Story Cache (TTL: 7 days)  
   Key: ai_story:{story_id}
   Value: Complete story JSON

3. User Quota Cache (TTL: 1 hour)
   Key: ai_quota:{user_id}
   Value: Current usage counts

4. LLM Response Cache (TTL: 24 hours)
   Key: llm_response:{request_hash}
   Value: Raw LLM response
```

## Error Handling

### Retry Strategy
```kotlin
class StoryGenerationService {
    suspend fun generateWithRetry(request: Request): Response {
        var lastError: Exception? = null
        
        repeat(3) { attempt ->
            try {
                delay(attempt * 1000L) // Exponential backoff
                return generate(request)
            } catch (e: Exception) {
                lastError = e
                when (e) {
                    is RateLimitException -> delay(60000)
                    is TimeoutException -> continue
                    is InvalidContentException -> throw e // Don't retry
                    else -> continue
                }
            }
        }
        
        throw GenerationFailedException(lastError)
    }
}
```

### Fallback Mechanisms
1. If primary LLM fails, try secondary provider
2. If all LLMs fail, offer template-based generation
3. If image analysis fails, use manual tags
4. If quota check fails, assume limit reached

## Performance Optimization

### Optimization Strategies
1. **Parallel Processing**
   - Analyze images in parallel
   - Pre-warm LLM connection
   - Async database writes

2. **Request Batching**
   - Batch image analyses
   - Combine quota checks
   - Group safety validations

3. **Precomputation**
   - Pre-analyze uploaded images
   - Cache common prompts
   - Pre-generate system prompts

4. **Resource Management**
   - Connection pooling for LLM APIs
   - Request queuing during peak times
   - Automatic scaling based on queue depth

## Monitoring & Analytics

### Key Metrics
```sql
-- Generation success rate
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE status = 'completed') as successful,
    AVG(processing_time_ms) as avg_time_ms,
    SUM(estimated_cost) as total_cost
FROM games.ai_story_requests
GROUP BY DATE(created_at);

-- Popular themes and vocabulary
SELECT 
    unnest(themes) as theme,
    COUNT(*) as usage_count
FROM games.ai_generated_stories
WHERE approval_status = 'approved'
GROUP BY theme
ORDER BY usage_count DESC;

-- User engagement with AI stories
SELECT 
    template_type,
    AVG(completion_rate) as avg_completion,
    AVG(reading_time) as avg_reading_time
FROM (
    SELECT 
        CASE WHEN ast.id IS NOT NULL THEN 'ai_generated' ELSE 'human_created' END as template_type,
        si.comprehension_score / 100.0 as completion_rate,
        si.total_reading_time
    FROM games.story_instances si
    LEFT JOIN games.ai_generated_stories ast ON ast.template_id = si.template_id
) t
GROUP BY template_type;
```

### Alerts
- Generation success rate < 90%
- Average generation time > 30 seconds
- Daily cost exceeds budget
- Quota violations detected
- Safety check failures > 1%