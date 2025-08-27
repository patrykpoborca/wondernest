# Implementation Todo: Story Adventure

## 🚨 ARCHITECTURAL REFACTORING STATUS

**Current State**: Story Adventure violates WonderNest's plugin architecture  
**Required Action**: Refactor to hybrid approach following established patterns  
**Target**: Use games.child_game_data for child data, keep platform tables  
**Timeline**: Complete before feature launch

### Refactoring Checklist
- [ ] Create V6 migration to drop child-specific tables
- [ ] Update services to use games.child_game_data with JSONB
- [ ] Register game in games.game_registry
- [ ] Refactor API routes to standard plugin endpoints
- [ ] Maintain backward compatibility during transition
- [ ] Update tests for new architecture
- [ ] Document new data structure and keys

## Pre-Implementation Phase

### Research & Design
- [ ] Analyze competitor storytelling apps (Epic!, Khan Kids, etc.)
- [ ] Create UI/UX mockups for story reader interface
- [ ] Design story creation tool wireframes
- [ ] Define story template JSON schema
- [ ] Research text-to-speech libraries for narration
- [ ] Identify image asset sources and licensing
- [ ] Create content moderation guidelines

### Architecture Planning
- [ ] Design plugin architecture integration
- [ ] Plan database schema extensions
- [ ] Define API contract with backend
- [ ] Design offline storage strategy
- [ ] Plan CDN architecture for media assets
- [ ] Design marketplace payment flow

## Backend Implementation

### 🚧 ARCHITECTURAL REFACTORING REQUIRED
**Status**: Story Adventure currently violates WonderNest's plugin architecture
**Required Changes**: Refactor to follow hybrid approach with proper plugin registration

### Database Schema Refactoring
- [x] ~~Create story_instances table for child-specific saves~~ **DEPRECATED** 
- [x] ~~Create vocabulary_targets table for learning goals~~ **DEPRECATED**
- [x] ~~Create story_analytics table~~ **DEPRECATED**
- [ ] **NEW**: Drop child-specific tables (story_instances, vocabulary_progress, story_analytics)
- [ ] **NEW**: Migrate child data to games.child_game_data with JSONB storage
- [x] Create story_templates table in games schema ✅ (Keep - platform feature)
- [x] Create marketplace_listings table ✅ (Keep - platform feature) 
- [x] Create story_purchases table ✅ (Keep - platform feature)
- [x] Create marketplace_reviews table ✅ (Keep - platform feature)
- [ ] **NEW**: Register Story Adventure in games.game_registry
- [ ] **NEW**: Add JSONB indexes for child_game_data queries
- [ ] **NEW**: Create migration V6__Refactor_Story_Adventure_Plugin.sql

### Core Services
- [x] ~~Implement StoryTemplateService for CRUD operations~~ ✅ (Keep - platform feature)
- [ ] **REFACTOR**: StoryInstanceService to use games.child_game_data instead of story_instances
- [ ] **REFACTOR**: VocabularyService to store data in JSONB instead of vocabulary_progress table
- [ ] **NEW**: Create StoryAdventurePlugin implementing proper plugin interface
- [ ] Implement StoryGeneratorService for dynamic content
- [x] ~~Create MarketplaceService for transactions~~ (Covered by existing services)
- [ ] Build ContentModerationService for safety

### API Routes

#### Platform Routes (Keep Custom - Non-Child Data)
- [x] ~~GET /api/v2/games/story-adventure/templates~~ ✅ (Keep)
- [x] ~~GET /api/v2/games/story-adventure/templates/{id}~~ ✅ (Keep)
- [x] ~~POST /api/v2/games/story-adventure/templates (parent only)~~ ✅ (Keep)
- [x] ~~PUT /api/v2/games/story-adventure/templates/{id} (parent only)~~ ✅ (Keep)
- [x] ~~DELETE /api/v2/games/story-adventure/templates/{id} (parent only)~~ ✅ (Keep)
- [x] ~~GET /api/v2/games/story-adventure/marketplace/browse~~ ✅ (Keep)
- [x] ~~POST /api/v2/games/story-adventure/marketplace/purchase~~ ✅ (Keep)

#### Child Data Routes (Refactor to Plugin Pattern)
- [ ] **REFACTOR**: Use GET /api/v2/games/children/{childId}/data with game_name="story-adventure"
- [ ] **REFACTOR**: Use PUT /api/v2/games/children/{childId}/data for all child progress/instances
- [ ] **NEW**: Data keys like "story_instance:{templateId}", "vocabulary_progress", "story_analytics"
- [x] ~~GET /api/v2/games/story-adventure/instances/{childId}~~ **DEPRECATED**
- [x] ~~POST /api/v2/games/story-adventure/instances/{childId}/start~~ **DEPRECATED**
- [x] ~~PUT /api/v2/games/story-adventure/instances/{childId}/progress~~ **DEPRECATED**
- [x] ~~GET /api/v2/games/story-adventure/analytics/{childId}~~ **DEPRECATED**

### Validation & Security
- [ ] Implement content validation rules
- [ ] Add profanity filter
- [ ] Create age-appropriate content checker
- [ ] Implement rate limiting for API endpoints
- [ ] Add marketplace transaction validation
- [ ] Create audit logging for all operations

### Integration Points
- [ ] Integrate with existing authentication system
- [ ] Connect to analytics pipeline
- [ ] Link with payment processing system
- [ ] Integrate with CDN for media delivery
- [ ] Connect to notification system for achievements

## Frontend Implementation

### Core Components

#### Story Reader Module
- [ ] Create StoryReaderScreen widget
- [ ] Implement PageView for story navigation
- [ ] Build StoryPage widget with image/text overlay
- [ ] Create VocabularyHighlighter component
- [ ] Implement AudioNarrationPlayer
- [ ] Add PageTransitionAnimations
- [ ] Create ProgressIndicator widget
- [ ] Build ComprehensionQuiz component

#### Story Creator Module (Parent Mode)
- [ ] Create StoryCreatorScreen
- [ ] Build TemplateSelector widget
- [ ] Implement DragDropStoryBuilder
- [ ] Create VocabularyWordPicker
- [ ] Build ImageGalleryPicker
- [ ] Implement StoryPreviewMode
- [ ] Create PublishToMarketplace flow
- [ ] Add StoryValidation feedback

#### Marketplace Module
- [ ] Create MarketplaceBrowseScreen
- [ ] Build StoryCard preview widget
- [ ] Implement FilterAndSearch components
- [ ] Create PurchaseFlow screens
- [ ] Build CreatorProfile page
- [ ] Implement RatingAndReview system
- [ ] Add DownloadManager for offline

#### Analytics Dashboard
- [ ] Create ReadingProgressChart
- [ ] Build VocabularyGrowthGraph
- [ ] Implement DifficultyWordsList
- [ ] Create SessionTimeTracker
- [ ] Build ExportReportButton
- [ ] Add AchievementNotifications

### State Management (Riverpod)
- [ ] Create storyTemplateProvider
- [ ] Implement storyInstanceProvider
- [ ] Build marketplaceProvider
- [ ] Create offlineStorageProvider
- [ ] Implement analyticsProvider
- [ ] Add audioNarrationProvider

### Services
- [ ] Create StoryApiService
- [ ] Implement OfflineStoryService
- [ ] Build TextToSpeechService
- [ ] Create MediaCacheService
- [ ] Implement AnalyticsTrackingService
- [ ] Add PurchaseService

### Platform-Specific Features
- [ ] iOS: Implement native TTS integration
- [ ] Android: Add Google TTS support
- [ ] Desktop: Keyboard navigation support
- [ ] Tablet: Optimize layout for larger screens
- [ ] Handle platform-specific storage limits

## Testing

### Unit Tests
- [ ] Test story template validation logic
- [ ] Test vocabulary matching algorithms
- [ ] Test progress tracking calculations
- [ ] Test content moderation filters
- [ ] Test marketplace transaction logic
- [ ] Test offline sync mechanisms

### Integration Tests
- [ ] Test complete story reading flow
- [ ] Test story creation and publishing
- [ ] Test marketplace purchase flow
- [ ] Test offline/online synchronization
- [ ] Test analytics data collection
- [ ] Test multi-device progress sync

### Widget Tests
- [ ] Test StoryReaderScreen interactions
- [ ] Test StoryCreator drag-and-drop
- [ ] Test vocabulary word highlighting
- [ ] Test audio playback controls
- [ ] Test marketplace filtering
- [ ] Test responsive layouts

### Platform Testing
- [ ] Test on iOS devices (iPhone, iPad)
- [ ] Test on Android devices (phones, tablets)
- [ ] Test on desktop (macOS, Windows, Linux)
- [ ] Test offline mode on all platforms
- [ ] Test performance with large stories
- [ ] Test accessibility features

### User Acceptance Testing
- [ ] Parent story creation flow
- [ ] Child reading experience
- [ ] Marketplace browsing and purchasing
- [ ] Analytics dashboard usability
- [ ] Content moderation effectiveness
- [ ] Age-appropriate content verification

## Performance Optimization

### Frontend Optimization
- [ ] Implement lazy loading for images
- [ ] Add story prefetching logic
- [ ] Optimize animation performance
- [ ] Implement efficient text rendering
- [ ] Add memory management for media
- [ ] Create smooth page transitions

### Backend Optimization
- [ ] Add database query optimization
- [ ] Implement caching strategies
- [ ] Optimize media delivery pipeline
- [ ] Add CDN configuration
- [ ] Implement rate limiting
- [ ] Create efficient search indexing

## Documentation

### User Documentation
- [ ] Create parent guide for story creation
- [ ] Write marketplace seller guidelines
- [ ] Document privacy and safety features
- [ ] Create troubleshooting guide
- [ ] Write API documentation
- [ ] Create video tutorials

### Developer Documentation
- [ ] Document plugin architecture
- [ ] Write API endpoint specifications
- [ ] Create database schema documentation
- [ ] Document state management patterns
- [ ] Write testing guidelines
- [ ] Create deployment procedures

## Deployment & Launch

### Beta Testing
- [ ] Deploy to staging environment
- [ ] Recruit beta testing families
- [ ] Collect and analyze feedback
- [ ] Fix critical issues
- [ ] Iterate on UX based on feedback
- [ ] Prepare for production launch

### Production Launch
- [ ] Deploy backend services
- [ ] Configure CDN for media
- [ ] Release mobile app updates
- [ ] Enable marketplace features
- [ ] Launch marketing campaign
- [ ] Monitor system performance

### Post-Launch
- [ ] Monitor error rates and crashes
- [ ] Analyze user engagement metrics
- [ ] Collect user feedback
- [ ] Plan feature iterations
- [ ] Optimize based on usage patterns
- [ ] Scale infrastructure as needed

## Compliance & Legal

### COPPA Compliance  
- [x] ~~Implement age verification~~ ✅ (Handled by core system)
- [x] ~~Add parental consent flows~~ ✅ (Handled by core system)
- [x] ~~Create data retention policies~~ ✅ (Now enforced via games.child_game_data)
- [ ] Document compliance measures for Story Adventure
- [ ] Verify plugin architecture maintains COPPA compliance
- [x] ~~Schedule compliance audit~~ (Core system responsibility)
- [x] ~~Train support staff~~ (Core system responsibility)

### Plugin Architecture Compliance
- [ ] Ensure all child data flows through games.child_game_data
- [ ] Verify no direct child data collection outside plugin system
- [ ] Document data keys and JSONB structure for auditing
- [ ] Test data retention policies work with JSONB storage

### Content Rights
- [ ] Establish content licensing terms
- [ ] Create DMCA procedures
- [ ] Implement copyright detection
- [ ] Document creator agreements
- [ ] Set up revenue sharing system
- [ ] Create dispute resolution process