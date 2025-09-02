# AI Story Generator - Revised Architecture Plan

## Executive Summary

This plan maximizes reuse of WonderNest's existing story infrastructure while adding powerful AI generation capabilities and expanding the community marketplace. The approach treats AI as an enhancement layer rather than a separate system.

## Architecture Discovery Summary

### Existing Infrastructure We'll Leverage

1. **Story System (games schema)**
   - `story_templates` - Reusable story structures (will extend for AI)
   - `story_instances` - Child reading sessions (unchanged)
   - `vocabulary_progress` - Word learning tracking (unchanged)
   - `story_analytics` - Event tracking (unchanged)

2. **Marketplace System (games schema)**
   - `marketplace_listings` - Available content (will extend)
   - `story_purchases` - Purchase history (unchanged)
   - `marketplace_reviews` - User feedback (unchanged)

3. **Content Management (content_workflow schema)**
   - `content_items` - Master content table (will reference)
   - `content_versions` - Version tracking (will use)
   - `content_approvals` - Approval workflow (will use)
   - `content_assets` - Media assets (will reference)

4. **File Management (core schema)**
   - `uploaded_files` - User images with tags (will use)
   - `content.tags` - Tag system (will use)
   - `content.file_tags` - File-tag relationships (will use)

## Phase 1: Minimal New Tables (AI Generation Core)

### New Tables Required

```sql
-- AI generation configuration and tracking
CREATE TABLE games.ai_generation_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Provider configuration
    provider VARCHAR(50) NOT NULL DEFAULT 'openai' CHECK (provider IN ('openai', 'anthropic', 'gemini', 'local_llm')),
    model_name VARCHAR(100) NOT NULL DEFAULT 'gpt-4',
    api_endpoint TEXT,
    temperature DECIMAL(3,2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 2000,
    
    -- Safety and content filters
    content_filters JSONB DEFAULT '{"violence": "strict", "scary": "moderate", "educational": "required"}',
    age_appropriateness_check BOOLEAN DEFAULT true,
    
    -- Rate limiting
    daily_generation_limit INTEGER DEFAULT 10,
    monthly_generation_limit INTEGER DEFAULT 100,
    
    -- Feature flags
    allow_custom_characters BOOLEAN DEFAULT true,
    allow_image_generation BOOLEAN DEFAULT false,
    allow_voice_generation BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI generation requests tracking
CREATE TABLE games.ai_story_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Requester info
    parent_id UUID NOT NULL REFERENCES core.users(id),
    child_id UUID REFERENCES family.child_profiles(id),
    
    -- Generation input
    prompt TEXT NOT NULL,
    selected_image_ids UUID[] DEFAULT '{}', -- References core.uploaded_files
    generation_params JSONB NOT NULL DEFAULT '{}',
    
    -- Generation output
    generated_template_id UUID REFERENCES games.story_templates(id),
    generation_status VARCHAR(50) DEFAULT 'pending' CHECK (generation_status IN (
        'pending', 'processing', 'completed', 'failed', 'moderation_required', 'rejected'
    )),
    
    -- LLM interaction details
    llm_request JSONB, -- Store full request for debugging
    llm_response JSONB, -- Store full response
    tokens_used INTEGER,
    generation_cost DECIMAL(10,4),
    
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    generation_time_ms INTEGER,
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Community prompt templates
CREATE TABLE games.ai_prompt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Creator info
    creator_id UUID NOT NULL REFERENCES core.users(id),
    creator_type VARCHAR(20) DEFAULT 'parent' CHECK (creator_type IN ('parent', 'admin', 'community')),
    
    -- Template content
    title VARCHAR(255) NOT NULL,
    description TEXT,
    base_prompt TEXT NOT NULL,
    
    -- Customization slots
    variable_slots JSONB DEFAULT '[]', -- [{"name": "character_name", "type": "text", "required": true}]
    suggested_tags TEXT[] DEFAULT '{}',
    
    -- Categorization
    age_group VARCHAR(10) CHECK (age_group IN ('3-5', '6-8', '9-12')),
    story_type VARCHAR(50), -- 'adventure', 'educational', 'bedtime', etc.
    themes TEXT[] DEFAULT '{}',
    
    -- Community features
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    
    -- Marketplace integration
    is_premium BOOLEAN DEFAULT false,
    price DECIMAL(10,2) DEFAULT 0.00,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Extended Existing Tables

```sql
-- Extend story_templates with AI metadata
ALTER TABLE games.story_templates ADD COLUMN IF NOT EXISTS 
    creator_type VARCHAR(20) DEFAULT 'human' CHECK (creator_type IN ('human', 'ai_assisted', 'fully_ai')),
    ai_generation_id UUID REFERENCES games.ai_story_generations(id),
    source_prompt TEXT,
    generation_params JSONB,
    parent_template_id UUID REFERENCES games.story_templates(id), -- For derived stories
    is_ai_editable BOOLEAN DEFAULT false;

-- Extend marketplace_listings for AI content
ALTER TABLE games.marketplace_listings ADD COLUMN IF NOT EXISTS
    content_source VARCHAR(20) DEFAULT 'human' CHECK (content_source IN ('human', 'ai_generated', 'ai_assisted')),
    allows_derivatives BOOLEAN DEFAULT false,
    derivative_fee_percentage DECIMAL(5,2) DEFAULT 0.00, -- Revenue share for base template
    prompt_template_id UUID REFERENCES games.ai_prompt_templates(id);

-- Add AI image analysis results to uploaded_files
ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    ai_analysis JSONB DEFAULT '{}', -- Store vision API results
    detected_objects TEXT[] DEFAULT '{}',
    detected_colors TEXT[] DEFAULT '{}',
    scene_description TEXT,
    is_child_safe BOOLEAN DEFAULT true;
```

## Phase 2: API Integration Points

### Enhanced Existing Endpoints

```kotlin
// Extend existing story endpoints
route("/api/v2/stories") {
    // Existing endpoints remain unchanged
    
    // New AI endpoints
    post("/generate") {
        // Generate AI story from prompt
    }
    
    post("/generate-from-images") {
        // Generate story based on uploaded images
    }
    
    get("/prompt-templates") {
        // Browse community prompt templates
    }
    
    post("/customize/{templateId}") {
        // Create customized version of existing story
    }
}

// Extend marketplace endpoints
route("/api/v2/marketplace") {
    // Existing endpoints remain unchanged
    
    get("/ai-stories") {
        // Filter for AI-generated content
    }
    
    post("/share-ai-story") {
        // Share AI story to marketplace
    }
    
    get("/prompt-marketplace") {
        // Browse/purchase prompt templates
    }
}
```

### Service Layer Integration

```kotlin
class AIStoryService(
    private val storyTemplateRepository: StoryTemplateRepository,
    private val contentWorkflowService: ContentWorkflowService,
    private val fileUploadService: FileUploadService,
    private val llmProvider: LLMProvider
) {
    suspend fun generateStory(request: GenerateStoryRequest): StoryTemplate {
        // 1. Validate images if provided
        val images = fileUploadService.getFilesByIds(request.imageIds)
        
        // 2. Build enhanced prompt with image descriptions
        val enhancedPrompt = buildPromptWithImages(request.prompt, images)
        
        // 3. Call LLM provider
        val llmResponse = llmProvider.generateStory(enhancedPrompt)
        
        // 4. Create story_template entry with AI metadata
        val template = storyTemplateRepository.create(
            StoryTemplate(
                content = llmResponse.content,
                creatorType = CreatorType.FULLY_AI,
                sourcePrompt = request.prompt,
                // ... other fields
            )
        )
        
        // 5. Submit for parent approval via content_workflow
        contentWorkflowService.submitForApproval(template.id, request.parentId)
        
        return template
    }
}
```

## Phase 3: Progressive Enhancement Strategy

### Phase 3.1: Personal AI Stories (Months 1-2)
- Basic prompt-to-story generation
- Image-based story generation
- Parent approval workflow
- Personal library management

### Phase 3.2: Community Sharing (Months 3-4)
- Share AI stories to marketplace
- Creator attribution system
- Basic quality filters
- Community ratings

### Phase 3.3: Prompt Marketplace (Months 5-6)
- Sell/share prompt templates
- Template customization system
- Revenue sharing for templates
- Featured creator program

### Phase 3.4: Collaborative Creation (Months 7-8)
- Multi-parent story creation
- Story remixing with attribution
- Community challenges/themes
- Educational curriculum alignment

## Phase 4: Migration Strategy

### Data Migration Path

```sql
-- No data migration needed for existing tables
-- Only additive changes

-- Backfill creator_type for existing stories
UPDATE games.story_templates 
SET creator_type = 'human' 
WHERE creator_type IS NULL;

-- Create indexes for new queries
CREATE INDEX idx_story_templates_creator_type ON games.story_templates(creator_type);
CREATE INDEX idx_ai_generations_parent ON games.ai_story_generations(parent_id);
CREATE INDEX idx_ai_generations_status ON games.ai_story_generations(generation_status);
CREATE INDEX idx_prompt_templates_public ON games.ai_prompt_templates(is_public, rating DESC);
```

## Phase 5: Community Marketplace Expansion

### Creator Economy Features

1. **Revenue Models**
   - Direct story sales (existing)
   - Prompt template sales (new)
   - Derivative works revenue sharing (new)
   - Subscription tiers for creators (future)

2. **Quality Control**
   - Automated content safety checks
   - Community moderation queue
   - Parent approval for child access
   - Educational value scoring

3. **Discovery Features**
   - AI-generated vs human-created filters
   - Prompt template categories
   - Creator following system
   - Personalized recommendations

## Technical Considerations

### LLM Integration Architecture

```kotlin
interface LLMProvider {
    suspend fun generateStory(prompt: String, params: GenerationParams): StoryContent
    suspend fun analyzeImage(imageUrl: String): ImageAnalysis
    suspend fun validateContentSafety(content: String): SafetyCheck
}

class OpenAIProvider : LLMProvider { /* Implementation */ }
class AnthropicProvider : LLMProvider { /* Implementation */ }
class LocalLLMProvider : LLMProvider { /* Ollama integration */ }
```

### Safety and Moderation Pipeline

1. **Pre-generation**
   - Prompt safety check
   - Image content verification
   - Age-appropriateness validation

2. **Post-generation**
   - Content safety scan
   - Educational value assessment
   - Vocabulary level check

3. **Parent Review**
   - Preview before child access
   - Customization options
   - Approval/rejection workflow

## Success Metrics

### Phase 1 KPIs
- AI stories generated per day
- Parent approval rate
- Generation success rate
- Average generation time

### Phase 2 KPIs
- AI stories shared to marketplace
- Community engagement rate
- Prompt template usage
- Creator retention

### Phase 3 KPIs
- Marketplace revenue from AI content
- Derivative works created
- Community quality score
- Educational outcome improvements

## Risk Mitigation

### Technical Risks
- **LLM API failures**: Implement fallback providers and retry logic
- **Content safety**: Multiple validation layers, parent approval required
- **Performance**: Cache generated content, async processing
- **Cost management**: Token limits, rate limiting, usage monitoring

### Business Risks
- **Content quality**: Community ratings, moderation system
- **Creator attribution**: Clear tracking, revenue sharing
- **COPPA compliance**: No AI training on child data, parent controls
- **Market saturation**: Quality filters, featured content

## Implementation Priority

### Sprint 1-2: Core AI Generation
1. LLM provider abstraction
2. Basic story generation
3. Parent approval flow
4. Database schema updates

### Sprint 3-4: Image Integration
1. Image analysis pipeline
2. Tag-based story generation
3. Scene description extraction
4. Multi-image story creation

### Sprint 5-6: Community Features
1. Share to marketplace
2. Prompt templates
3. Creator profiles
4. Rating system

### Sprint 7-8: Advanced Features
1. Story customization
2. Derivative works
3. Revenue sharing
4. Analytics dashboard

## Conclusion

This revised architecture maximizes reuse of existing WonderNest infrastructure while adding powerful AI capabilities. By treating AI as an enhancement layer rather than a separate system, we can deliver value quickly while maintaining system coherence and reducing technical debt.

The phased approach allows for iterative development and market validation, while the community marketplace integration creates a sustainable creator economy that benefits both content creators and families using the platform.