# Story Adventure Architecture Notes

## Plugin Architecture Design

### Overview
Story Adventure follows WonderNest's modular plugin architecture, allowing it to be dynamically loaded and integrated with the core platform while maintaining isolation and reusability.

## System Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Frontend                      │
├─────────────────────────────────────────────────────────┤
│  Story Reader │ Story Creator │ Marketplace │ Analytics │
├─────────────────────────────────────────────────────────┤
│              Story Adventure Plugin Layer                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Renderer │ │  Audio   │ │ Offline  │ │Analytics │  │
│  │  Engine  │ │ Narrator │ │  Cache   │ │ Tracker  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
├─────────────────────────────────────────────────────────┤
│                  Core Services Layer                     │
│   Auth │ User Management │ Payment │ Notifications      │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    KTOR Backend                          │
├─────────────────────────────────────────────────────────┤
│              Story Adventure Services                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Template │ │Vocabulary│ │Marketplace│ │Analytics │  │
│  │  Service │ │ Service  │ │  Service  │ │ Service  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
├─────────────────────────────────────────────────────────┤
│                   Data Access Layer                      │
│         PostgreSQL │ Redis │ CDN │ Blob Storage         │
└─────────────────────────────────────────────────────────┘
```

## Plugin Integration Pattern

### Plugin Registration
```kotlin
// Backend: StoryAdventurePlugin.kt
class StoryAdventurePlugin : GamePlugin {
    override val gameId = "story-adventure"
    override val version = "1.0.0"
    override val minAge = 3
    override val maxAge = 12
    
    override fun register(registry: GameRegistry) {
        registry.registerGame(
            gameId = gameId,
            displayName = "Story Adventure",
            description = "Interactive storytelling for vocabulary development",
            category = GameCategory.EDUCATIONAL,
            routes = StoryAdventureRoutes(),
            services = StoryAdventureServices(),
            migrations = listOf("V4__Add_Story_Adventure.sql")
        )
    }
}
```

### Frontend Plugin Integration
```dart
// Frontend: story_adventure_plugin.dart
class StoryAdventurePlugin extends GamePlugin {
  @override
  String get gameId => 'story-adventure';
  
  @override
  Widget buildGameWidget(BuildContext context, String childId) {
    return StoryAdventureHome(childId: childId);
  }
  
  @override
  List<Permission> get requiredPermissions => [
    Permission.storage,  // For offline content
    Permission.audio,    // For narration
  ];
  
  @override
  GameConfig get config => GameConfig(
    supportsOffline: true,
    requiresParentSetup: false,
    hasInAppPurchases: true,
    analyticsEnabled: true,
  );
}
```

## Database Schema Design

### Core Tables (games schema)

```sql
-- Story templates master table
CREATE TABLE games.story_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_id UUID REFERENCES core.users(id),
    age_group VARCHAR(10) CHECK (age_group IN ('3-5', '6-8', '9-12')),
    difficulty VARCHAR(20) CHECK (difficulty IN ('emerging', 'developing', 'fluent')),
    content JSONB NOT NULL, -- Flexible story structure
    vocabulary_words TEXT[] DEFAULT '{}',
    is_premium BOOLEAN DEFAULT false,
    is_marketplace BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    version VARCHAR(10) DEFAULT '1.0.0',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Story instances for each child's reading session
CREATE TABLE games.story_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES core.children(id) ON DELETE CASCADE,
    template_id UUID REFERENCES games.story_templates(id),
    status VARCHAR(20) CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    current_page INTEGER DEFAULT 1,
    customizations JSONB DEFAULT '{}',
    progress_data JSONB DEFAULT '{}', -- Detailed progress tracking
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    total_reading_time INTEGER DEFAULT 0, -- in seconds
    UNIQUE(child_id, template_id, started_at)
);

-- Vocabulary tracking
CREATE TABLE games.vocabulary_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES core.children(id) ON DELETE CASCADE,
    word VARCHAR(100) NOT NULL,
    encounters INTEGER DEFAULT 1,
    correct_uses INTEGER DEFAULT 0,
    last_seen_in UUID REFERENCES games.story_templates(id),
    mastery_level INTEGER DEFAULT 0, -- 0-100
    first_encountered TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_encountered TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(child_id, word)
);

-- Marketplace listings
CREATE TABLE games.marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES games.story_templates(id) UNIQUE,
    seller_id UUID REFERENCES core.users(id),
    price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
    rating DECIMAL(2, 1) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    purchase_count INTEGER DEFAULT 0,
    revenue_total DECIMAL(10, 2) DEFAULT 0.00,
    listing_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Purchase history
CREATE TABLE games.story_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID REFERENCES core.users(id),
    listing_id UUID REFERENCES games.marketplace_listings(id),
    child_id UUID REFERENCES core.children(id),
    price_paid DECIMAL(10, 2) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    payment_method VARCHAR(50),
    purchased_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Analytics events
CREATE TABLE games.story_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES core.children(id),
    instance_id UUID REFERENCES games.story_instances(id),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB NOT NULL,
    session_id UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_story_templates_creator ON games.story_templates(creator_id);
CREATE INDEX idx_story_templates_age_difficulty ON games.story_templates(age_group, difficulty);
CREATE INDEX idx_story_instances_child ON games.story_instances(child_id, status);
CREATE INDEX idx_vocabulary_child_word ON games.vocabulary_progress(child_id, word);
CREATE INDEX idx_marketplace_status_rating ON games.marketplace_listings(status, rating DESC);
CREATE INDEX idx_story_analytics_child_date ON games.story_analytics(child_id, created_at DESC);
```

## Content Storage Architecture

### Media Asset Management
```
CDN Structure:
/stories/
  /templates/{template-id}/
    /images/
      /pages/
        page-{n}.jpg         # Full resolution
        page-{n}-thumb.jpg   # Thumbnail
      /characters/
        {character-id}.png   # With transparency
    /audio/
      /narration/
        page-{n}.mp3        # Full narration
        page-{n}-slow.mp3   # Slower version
      /words/
        {word}.mp3          # Individual word pronunciation
    /metadata.json          # Template metadata
    
/user-content/
  /{user-id}/
    /images/
    /audio/
```

### Offline Storage Strategy
```dart
// Offline cache structure
class OfflineStoryCache {
  static const String cacheDir = 'story_adventure_cache';
  
  // Priority-based caching
  static const Map<String, int> cachePriority = {
    'in_progress': 1,      // Currently reading
    'favorites': 2,        // Marked as favorite
    'recent': 3,           // Recently accessed
    'popular': 4,          // Frequently read
    'preload': 5,          // Predictive preload
  };
  
  // Storage limits
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int maxStoriesOffline = 20;
  static const Duration cacheExpiry = Duration(days: 30);
}
```

## State Management Architecture

### Frontend State Structure (Riverpod)
```dart
// Main state providers
final storyAdventureProvider = StateNotifierProvider<StoryAdventureNotifier, StoryAdventureState>((ref) {
  return StoryAdventureNotifier(
    apiService: ref.read(apiServiceProvider),
    offlineService: ref.read(offlineServiceProvider),
    analyticsService: ref.read(analyticsServiceProvider),
  );
});

// State model
class StoryAdventureState {
  final List<StoryTemplate> availableTemplates;
  final List<StoryInstance> activeInstances;
  final StoryInstance? currentReading;
  final Map<String, double> downloadProgress;
  final VocabularyProgress vocabularyProgress;
  final bool isOfflineMode;
  final String? error;
  
  // Computed properties
  bool get hasActiveStory => currentReading != null;
  int get totalWordsLearned => vocabularyProgress.masteredWords.length;
}

// Sub-providers for specific features
final marketplaceProvider = FutureProvider<MarketplaceListing>((ref) async {
  // Marketplace-specific logic
});

final storyCreatorProvider = StateNotifierProvider<StoryCreatorNotifier, StoryCreatorState>((ref) {
  // Story creation logic
});
```

## Service Layer Architecture

### Backend Services
```kotlin
// Template management service
class StoryTemplateService(
    private val templateRepository: StoryTemplateRepository,
    private val validationService: ContentValidationService,
    private val mediaService: MediaManagementService
) {
    suspend fun createTemplate(request: CreateTemplateRequest): StoryTemplate {
        // Validate content
        validationService.validateStoryContent(request)
        
        // Process media assets
        val processedMedia = mediaService.processStoryMedia(request.media)
        
        // Create template
        return templateRepository.create(
            request.toTemplate(processedMedia)
        )
    }
}

// Dynamic story generation
class StoryGeneratorService(
    private val templateService: StoryTemplateService,
    private val vocabularyService: VocabularyService,
    private val aiService: AIContentService
) {
    suspend fun generatePersonalizedStory(
        childId: UUID,
        templateId: UUID,
        customizations: Map<String, Any>
    ): PersonalizedStory {
        val template = templateService.getTemplate(templateId)
        val childVocabulary = vocabularyService.getChildVocabulary(childId)
        
        // Apply customizations and vocabulary targets
        return PersonalizedStory(
            template = template,
            customizations = customizations,
            targetVocabulary = childVocabulary.currentTargets,
            generatedContent = generateDynamicContent(template, customizations)
        )
    }
}
```

## Real-time Features

### WebSocket Events
```kotlin
// Real-time reading progress sync
class StoryProgressWebSocket {
    fun establishConnection(childId: UUID) {
        webSocket("/ws/story-progress/$childId") {
            // Send progress updates
            incoming.consumeEach { frame ->
                when (frame) {
                    is Frame.Text -> {
                        val update = Json.decodeFromString<ProgressUpdate>(frame.readText())
                        handleProgressUpdate(update)
                    }
                }
            }
        }
    }
}
```

### Event Types
```typescript
// WebSocket event definitions
interface StoryWebSocketEvents {
  // Progress tracking
  'progress:page': { childId: string; page: number; totalPages: number };
  'progress:word': { childId: string; word: string; action: 'tapped' | 'pronounced' };
  
  // Achievements
  'achievement:unlocked': { childId: string; achievement: Achievement };
  
  // Marketplace
  'marketplace:new_review': { templateId: string; review: Review };
  'marketplace:purchase': { templateId: string; buyerId: string };
}
```

## Security Architecture

### Content Security
```kotlin
// Content moderation pipeline
class ContentModerationPipeline {
    private val filters = listOf(
        ProfanityFilter(),
        AgeAppropriatenessFilter(),
        CopyrightDetector(),
        ImageModerationFilter()
    )
    
    suspend fun moderateContent(content: StoryContent): ModerationResult {
        return filters.fold(ModerationResult.approved()) { result, filter ->
            if (result.isRejected) return result
            filter.check(content)
        }
    }
}
```

### Data Privacy
```kotlin
// Privacy-preserving analytics
class PrivacyAwareAnalytics {
    fun trackReadingProgress(event: ReadingEvent) {
        // Anonymize child data
        val anonymizedEvent = event.copy(
            childId = hashChildId(event.childId),
            sessionId = generateSessionId(),
            // Remove any PII
            metadata = event.metadata.filterKeys { 
                it !in PERSONALLY_IDENTIFIABLE_FIELDS 
            }
        )
        
        analyticsService.track(anonymizedEvent)
    }
}
```

## Performance Optimizations

### Caching Strategy
```kotlin
// Multi-level caching
class StoryCache {
    // L1: In-memory cache for active stories
    private val memoryCache = LRUCache<UUID, StoryTemplate>(maxSize = 20)
    
    // L2: Redis cache for frequently accessed
    private val redisCache = RedisCache(ttl = 1.hour)
    
    // L3: CDN for static assets
    private val cdnCache = CDNCache(
        provider = "cloudflare",
        ttl = 7.days
    )
    
    suspend fun getStory(templateId: UUID): StoryTemplate? {
        return memoryCache.get(templateId)
            ?: redisCache.get(templateId)?.also { memoryCache.put(templateId, it) }
            ?: database.get(templateId)?.also { 
                redisCache.put(templateId, it)
                memoryCache.put(templateId, it)
            }
    }
}
```

### Image Optimization
```kotlin
// Responsive image delivery
class ImageOptimizationService {
    fun getOptimizedImageUrl(
        originalUrl: String,
        deviceProfile: DeviceProfile
    ): String {
        val params = when (deviceProfile.screenDensity) {
            ScreenDensity.LOW -> "w=800&q=70"
            ScreenDensity.MEDIUM -> "w=1200&q=80"
            ScreenDensity.HIGH -> "w=1920&q=85"
            ScreenDensity.ULTRA -> "w=2560&q=90"
        }
        
        return "$CDN_BASE_URL/optimize?url=$originalUrl&$params&format=webp"
    }
}
```

## Testing Architecture

### Test Data Factories
```kotlin
// Test data generation
object StoryTestDataFactory {
    fun createTestTemplate(
        ageGroup: String = "6-8",
        difficulty: String = "developing",
        pageCount: Int = 10
    ): StoryTemplate {
        return StoryTemplate(
            id = UUID.randomUUID(),
            title = "Test Story ${Random.nextInt()}",
            pages = (1..pageCount).map { createTestPage(it) },
            vocabularyWords = generateVocabularyWords(difficulty),
            // ... other fields
        )
    }
    
    fun createTestInstance(
        childId: UUID,
        templateId: UUID,
        progress: Int = 0
    ): StoryInstance {
        // Generate test instance
    }
}
```

### Integration Test Setup
```kotlin
// Integration test configuration
class StoryAdventureIntegrationTest {
    @Test
    fun `complete story reading flow`() = testApplication {
        // Setup
        val child = createTestChild()
        val template = createTestTemplate()
        
        // Start reading
        val instance = client.post("/api/v2/games/story-adventure/instances/${child.id}/start") {
            contentType(ContentType.Application.Json)
            setBody(StartReadingRequest(templateId = template.id))
        }
        
        // Progress through pages
        repeat(template.pageCount) { page ->
            client.put("/api/v2/games/story-adventure/instances/${instance.id}/progress") {
                setBody(ProgressUpdate(currentPage = page + 1))
            }
        }
        
        // Complete and verify
        val completion = client.post("/api/v2/games/story-adventure/instances/${instance.id}/complete")
        
        assertEquals(HttpStatusCode.OK, completion.status)
        // ... additional assertions
    }
}
```

## Deployment Architecture

### Container Configuration
```yaml
# docker-compose.yml extension
services:
  story-adventure-worker:
    image: wondernest/story-adventure-worker:latest
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - CDN_API_KEY=${CDN_API_KEY}
      - AI_SERVICE_KEY=${AI_SERVICE_KEY}
    depends_on:
      - postgres
      - redis
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

### Migration Strategy
```sql
-- V4__Add_Story_Adventure.sql
BEGIN;

-- Create tables with proper schema
SET search_path TO games, public;

-- Create all tables (as defined above)
-- ...

-- Seed initial content
INSERT INTO story_templates (title, description, age_group, difficulty, content)
VALUES 
  ('Welcome to Story Adventure', 'Your first story', '3-5', 'emerging', '{}'),
  ('The Alphabet Garden', 'Learn letters in a magical garden', '3-5', 'emerging', '{}');

COMMIT;
```

## Monitoring & Observability

### Key Metrics
```kotlin
// Metrics collection
class StoryAdventureMetrics {
    val readingSessionsStarted = Counter("story.sessions.started")
    val readingSessionsCompleted = Counter("story.sessions.completed")
    val averageReadingTime = Histogram("story.reading.time")
    val vocabularyWordsLearned = Counter("story.vocabulary.learned")
    val marketplacePurchases = Counter("story.marketplace.purchases")
    val templateCreationTime = Histogram("story.template.creation.time")
    
    fun recordReadingSession(session: ReadingSession) {
        readingSessionsStarted.increment()
        if (session.completed) {
            readingSessionsCompleted.increment()
            averageReadingTime.record(session.duration)
        }
    }
}
```

### Health Checks
```kotlin
// Health check endpoints
class StoryAdventureHealthCheck : HealthCheck {
    override suspend fun check(): HealthStatus {
        return HealthStatus(
            service = "story-adventure",
            checks = listOf(
                checkDatabase(),
                checkCDN(),
                checkMediaStorage(),
                checkMarketplaceAPI()
            )
        )
    }
}
```