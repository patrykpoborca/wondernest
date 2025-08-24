# Game Architecture Implementation Plan

**Document Version**: 1.0  
**Date**: 2025-08-24  
**Status**: Draft  

## Executive Summary

This document outlines the comprehensive plan to transition from the current `SimpleGameData` architecture to the proper **GameRegistry → ChildGameInstances → ChildGameData** pattern. The current implementation uses a simplified table structure that bypasses the robust game management architecture already defined in the database schema.

## Problem Statement

### Current State Issues

1. **Architecture Bypass**: The current implementation uses `SimpleGameData` table directly, bypassing the comprehensive game architecture
2. **Missing Game Registry**: Games like "sticker_book" exist only as string constants, not as proper registered games
3. **No Child Game Instances**: No proper per-child game instance management with settings, preferences, and progress tracking
4. **Limited Metadata**: Missing game versioning, age appropriateness, educational objectives, and safety reviews
5. **No Session Tracking**: No game session management or analytics integration
6. **Missing Achievement System**: No achievement tracking or reward mechanisms

### Why This Matters

The current `SimpleGameData` approach works for basic data persistence but lacks:
- **COPPA Compliance**: Proper data categorization and retention policies per game
- **Parental Controls**: Game-specific permissions and content filtering
- **Educational Insights**: Meaningful progress tracking and developmental analytics
- **Scalability**: Easy addition of new games with proper configuration management
- **Child Safety**: Age-appropriate content filtering and safety reviews

## Architecture Overview

### Target Architecture Flow

```
GameRegistry (games catalog)
    ↓ (child selects/unlocks game)
ChildGameInstances (per-child game setup)
    ↓ (child plays and generates data)
ChildGameData (actual save data)
```

### Key Components

1. **GameRegistry**: Central catalog of all available games
   - Game metadata, versioning, age targeting
   - Safety reviews and content ratings
   - Educational objectives and skills developed
   - Default configurations and settings

2. **ChildGameInstances**: Per-child game instances
   - Child-specific game settings and preferences
   - Progress tracking and statistics
   - Unlock status and play history
   - Personalized configurations

3. **ChildGameData**: Actual game save data
   - Project saves (sticker books, drawings, etc.)
   - Versioned data with proper key structure
   - Links to parent game instance for context

4. **GameSessions**: Play session tracking
   - Session duration and timing
   - Events and interactions
   - Performance metrics for analytics

## Implementation Phases

### Phase 1: Database Foundation (COMPLETED)

- [x] Database schema defined in `Games.kt`
- [x] Migration `V3__Add_Games_Schema.sql` created
- [x] Backend tables available: `GameRegistry`, `ChildGameInstances`, `ChildGameData`
- [x] Current `SimpleGameData` table exists as temporary solution

### Phase 2: Game Registry Population

#### 2.1 Create Game Type and Category Seeds
- [ ] Define base game types (creative, educational, puzzle, etc.)
- [ ] Create game categories hierarchy
- [ ] Set up sticker_book game category

#### 2.2 Register Sticker Book Game
- [ ] Create sticker_book game entry in GameRegistry
- [ ] Define sticker book configuration schema
- [ ] Set age targeting (24-144 months)
- [ ] Define educational objectives and skills developed
- [ ] Set up default settings structure

#### 2.3 Game Registry Service Layer
- [ ] Create GameRegistryService for CRUD operations
- [ ] Add game lookup and validation methods
- [ ] Implement game availability checking
- [ ] Add age-appropriate game filtering

### Phase 3: Child Game Instance Management

#### 3.1 Instance Creation Service
- [ ] Create ChildGameInstanceService
- [ ] Implement automatic instance creation on first play
- [ ] Add instance configuration management
- [ ] Set up progress tracking initialization

#### 3.2 Instance Settings Management
- [ ] Child-specific game preferences
- [ ] Personalized difficulty settings
- [ ] UI customizations per child
- [ ] Parental control integration

#### 3.3 Progress and Statistics
- [ ] Play time tracking
- [ ] Session counting
- [ ] Achievement progress
- [ ] Completion percentage calculation

### Phase 4: Backend API Enhancement

#### 4.1 New Game Data Routes
Current route needs enhancement to use proper architecture:

**From**: `PUT /api/v1/games/children/{childId}/data`  
**To**: `PUT /api/v1/games/children/{childId}/instances/{gameKey}/data`

#### 4.2 Enhanced Endpoints

```kotlin
// Game Discovery
GET /api/v1/games                                    // Available games
GET /api/v1/games/{gameKey}                         // Game details
GET /api/v1/games?ageMonths={age}&category={cat}    // Filtered games

// Child Game Instance Management  
GET /api/v1/games/children/{childId}/instances       // Child's game instances
POST /api/v1/games/children/{childId}/instances      // Create/unlock game instance
GET /api/v1/games/children/{childId}/instances/{gameKey} // Instance details
PUT /api/v1/games/children/{childId}/instances/{gameKey} // Update instance settings

// Game Data (Enhanced)
PUT /api/v1/games/children/{childId}/instances/{gameKey}/data    // Save data
GET /api/v1/games/children/{childId}/instances/{gameKey}/data    // Load data  
DELETE /api/v1/games/children/{childId}/instances/{gameKey}/data/{dataKey} // Delete

// Game Sessions
POST /api/v1/games/children/{childId}/instances/{gameKey}/sessions // Start session
PUT /api/v1/games/children/{childId}/instances/{gameKey}/sessions/{sessionId} // End session
```

#### 4.3 Service Layer Refactoring
- [ ] Create GameRegistryService
- [ ] Create ChildGameInstanceService  
- [ ] Create GameDataService (enhanced)
- [ ] Create GameSessionService
- [ ] Update route handlers to use services

### Phase 5: Frontend Integration

#### 5.1 API Service Updates
- [ ] Add game registry endpoints to ApiService
- [ ] Add child game instance management
- [ ] Update existing saveGameData to use proper architecture
- [ ] Add game session tracking

#### 5.2 Sticker Book Service Migration
- [ ] Update SavedProjectsService to use proper game architecture
- [ ] Migrate from direct SimpleGameData to ChildGameInstance pattern
- [ ] Ensure backward compatibility during transition
- [ ] Add proper game session tracking

#### 5.3 Game Provider Enhancement
- [ ] Create GameRegistryProvider for available games
- [ ] Create ChildGameInstanceProvider for instance management
- [ ] Update StickerGameProvider to use new architecture
- [ ] Add game session management

### Phase 6: Data Migration and Cleanup

#### 6.1 Data Migration Strategy
- [ ] Create migration script for existing SimpleGameData
- [ ] Map existing sticker_book data to proper architecture
- [ ] Create ChildGameInstances for existing data
- [ ] Migrate game data with proper ChildGameData structure

#### 6.2 Backward Compatibility
- [ ] Maintain SimpleGameData table temporarily
- [ ] Add dual-write mechanism during transition
- [ ] Gradual migration approach
- [ ] Fallback mechanisms for failed migrations

#### 6.3 Cleanup Phase
- [ ] Remove SimpleGameData dependencies
- [ ] Update all services to use new architecture
- [ ] Remove temporary compatibility layers
- [ ] Archive SimpleGameData table

## Detailed Implementation Specifications

### Game Registry Entry for Sticker Book

```kotlin
// GameRegistry entry for sticker_book
GameRegistryEntry(
    gameKey = "sticker_book",
    displayName = "Sticker Book",
    description = "Create amazing sticker scenes and tell your own stories",
    version = "1.0.0",
    gameType = "creative",
    category = "art_and_creativity",
    minAgeMonths = 24, // 2 years
    maxAgeMonths = 144, // 12 years
    configuration = mapOf(
        "maxProjectsPerChild" to 50,
        "maxStickersPerProject" to 200,
        "maxDrawingStrokes" to 1000,
        "autoSaveIntervalMs" to 30000,
        "thumbnailResolution" to "256x256"
    ),
    defaultSettings = mapOf(
        "ageMode" to "auto", // "littleKid", "bigKid", "auto"
        "soundEnabled" to true,
        "autoAdvancePages" to false,
        "showTutorial" to true,
        "maxUndoSteps" to 20
    ),
    educationalObjectives = listOf(
        "Fine motor skills development",
        "Creative expression and imagination",
        "Storytelling and narrative skills",
        "Color recognition and artistic composition",
        "Digital literacy and touch interface skills"
    ),
    skillsDeveloped = listOf(
        "creativity", "fine_motor", "storytelling", "digital_literacy"
    ),
    contentRating = "everyone",
    isActive = true,
    isPremium = false
)
```

### Child Game Instance Structure

```kotlin
// ChildGameInstance for a specific child + sticker_book
ChildGameInstanceEntry(
    childId = "child-uuid",
    gameId = "sticker_book-game-uuid",
    settings = mapOf(
        "ageMode" to "bigKid", // Personalized based on child's age/preferences
        "soundEnabled" to true,
        "preferredStickerCategories" to listOf("animals", "nature"),
        "difficulty" to "medium"
    ),
    preferences = mapOf(
        "lastUsedBackground" to "forest_scene",
        "favoriteStickers" to listOf("sticker_123", "sticker_456"),
        "customColors" to listOf("#FF6B9D", "#4ECDC4")
    ),
    isUnlocked = true,
    firstPlayedAt = "2025-08-24T10:00:00Z",
    lastPlayedAt = "2025-08-24T15:30:00Z",
    totalPlayTimeMinutes = 180,
    sessionCount = 12,
    completionPercentage = 75.5
)
```

### Game Data Structure

```kotlin
// ChildGameData entries for sticker projects
ChildGameDataEntry(
    childGameInstanceId = "child-instance-uuid",
    dataKey = "sticker_project_12345",
    dataVersion = 1,
    dataValue = mapOf(
        "projectData" to savedProject.toJson(),
        "metadata" to mapOf(
            "createdAt" to "2025-08-24T10:00:00Z",
            "lastModified" to "2025-08-24T15:30:00Z",
            "version" to "1.0.0",
            "stickerCount" to 15,
            "drawingStrokes" to 45
        )
    )
)
```

## API Design Specifications

### Enhanced Game Data Routes

```kotlin
// Enhanced GameDataRoutes.kt

fun Route.gameDataRoutes() {
    route("/games") {
        authenticate("auth-jwt") {
            
            // =============================================================================
            // GAME REGISTRY ENDPOINTS
            // =============================================================================
            
            // Get available games for a child (age-filtered)
            get("/children/{childId}/available") {
                // Returns games appropriate for child's age
                // Excludes premium games if not subscribed
                // Includes unlock requirements
            }
            
            // =============================================================================
            // CHILD GAME INSTANCE MANAGEMENT
            // =============================================================================
            
            // Get child's game instances (unlocked games)
            get("/children/{childId}/instances") {
                // Returns all game instances for child
                // Includes progress, settings, statistics
            }
            
            // Create/unlock game instance for child
            post("/children/{childId}/instances") {
                // Creates new ChildGameInstance
                // Applies default settings from GameRegistry
                // Initializes progress tracking
            }
            
            // Get specific game instance
            get("/children/{childId}/instances/{gameKey}") {
                // Returns specific game instance details
                // Includes current settings and progress
            }
            
            // Update game instance settings
            put("/children/{childId}/instances/{gameKey}") {
                // Updates child-specific settings
                // Validates against game configuration
            }
            
            // =============================================================================
            // ENHANCED GAME DATA PERSISTENCE
            // =============================================================================
            
            // Save game data (enhanced)
            put("/children/{childId}/instances/{gameKey}/data") {
                // Validates game instance exists
                // Creates data linked to instance
                // Supports versioning and metadata
            }
            
            // Load game data (enhanced) 
            get("/children/{childId}/instances/{gameKey}/data") {
                // Loads data for specific game instance
                // Supports filtering and pagination
                // Returns data with metadata
            }
            
            // Delete game data (enhanced)
            delete("/children/{childId}/instances/{gameKey}/data/{dataKey}") {
                // Deletes specific data item
                // Updates instance statistics
            }
            
            // =============================================================================
            // GAME SESSION TRACKING
            // =============================================================================
            
            // Start game session
            post("/children/{childId}/instances/{gameKey}/sessions") {
                // Creates GameSession record
                // Returns session ID for tracking
            }
            
            // Update/end game session
            put("/children/{childId}/instances/{gameKey}/sessions/{sessionId}") {
                // Records session end time
                // Updates play statistics
                // Processes session events
            }
        }
    }
}
```

### Service Layer Architecture

```kotlin
// GameRegistryService.kt
class GameRegistryService {
    suspend fun getAvailableGames(childAgeMonths: Int? = null): List<GameRegistryEntry>
    suspend fun getGame(gameKey: String): GameRegistryEntry?
    suspend fun isGameAvailable(gameKey: String, childAgeMonths: Int): Boolean
    suspend fun getGamesByCategory(category: String): List<GameRegistryEntry>
}

// ChildGameInstanceService.kt  
class ChildGameInstanceService {
    suspend fun getChildInstances(childId: UUID): List<ChildGameInstanceEntry>
    suspend fun createInstance(childId: UUID, gameKey: String): ChildGameInstanceEntry
    suspend fun getInstance(childId: UUID, gameKey: String): ChildGameInstanceEntry?
    suspend fun updateInstanceSettings(childId: UUID, gameKey: String, settings: Map<String, Any>)
    suspend fun recordPlaySession(instanceId: UUID, sessionData: GameSessionData)
}

// Enhanced GameDataService.kt
class GameDataService {
    suspend fun saveData(instanceId: UUID, dataKey: String, data: Map<String, Any>)
    suspend fun loadData(instanceId: UUID, dataKey: String? = null): List<GameDataEntry>  
    suspend fun deleteData(instanceId: UUID, dataKey: String)
    suspend fun migrateFromSimpleGameData(childId: UUID, gameType: String)
}
```

## Testing Strategy

### Unit Tests

#### Backend Service Tests
- [ ] GameRegistryService CRUD operations
- [ ] ChildGameInstanceService instance management
- [ ] Enhanced GameDataService with proper architecture
- [ ] GameSessionService session tracking

#### API Route Tests  
- [ ] Enhanced game data routes
- [ ] Game registry endpoints
- [ ] Child game instance management
- [ ] Error handling and validation

### Integration Tests

#### Database Integration
- [ ] GameRegistry table operations
- [ ] ChildGameInstances table operations  
- [ ] ChildGameData with proper foreign keys
- [ ] Cross-table relationships and constraints

#### API Integration
- [ ] End-to-end game instance creation
- [ ] Game data save/load with proper architecture
- [ ] Session tracking integration
- [ ] Migration from SimpleGameData

### Frontend Tests

#### Service Tests
- [ ] Updated SavedProjectsService with new architecture
- [ ] ApiService enhanced endpoints
- [ ] Game registry and instance providers

#### Integration Tests
- [ ] Sticker book save/load with new architecture
- [ ] Game session tracking
- [ ] Backward compatibility during migration

## Migration Strategy

### Phase A: Dual Write (Safe Migration)

1. **Backend Changes**:
   - Keep existing SimpleGameData routes functional
   - Add new architecture routes alongside
   - Implement dual-write to both systems
   - Add migration flags for gradual rollout

2. **Frontend Changes**:
   - Update SavedProjectsService to support both architectures
   - Add feature flag for new architecture usage
   - Implement fallback mechanisms

3. **Data Validation**:
   - Compare data between old and new systems
   - Validate proper game instance creation
   - Ensure data integrity during transition

### Phase B: Migration (Data Movement)

1. **Background Migration**:
   - Create migration script for existing SimpleGameData
   - Populate GameRegistry with sticker_book entry
   - Create ChildGameInstances for existing children
   - Migrate game data to proper ChildGameData structure

2. **Validation and Testing**:
   - Verify migrated data integrity
   - Test new architecture functionality
   - Confirm backward compatibility

### Phase C: Cleanup (Old System Removal)

1. **Frontend Migration**:
   - Switch to new architecture exclusively
   - Remove old SimpleGameData dependencies
   - Update all services to use ChildGameInstance pattern

2. **Backend Cleanup**:
   - Remove SimpleGameData routes
   - Archive SimpleGameData table
   - Clean up temporary migration code

## Success Metrics

### Technical Metrics
- [ ] All sticker book saves/loads use proper GameRegistry → ChildGameInstance → ChildGameData flow
- [ ] Zero data loss during migration from SimpleGameData
- [ ] Game session tracking captures play behavior
- [ ] New game addition requires only GameRegistry entry

### User Experience Metrics  
- [ ] Sticker book functionality remains unchanged for children
- [ ] Load/save performance maintained or improved
- [ ] Offline/online sync continues working seamlessly
- [ ] Parental dashboard shows enhanced game insights

### Architecture Quality Metrics
- [ ] Proper separation of concerns between game registry, instances, and data
- [ ] COPPA-compliant data categorization and retention
- [ ] Age-appropriate game filtering works correctly
- [ ] Educational objectives tracking available for analytics

## Risk Assessment and Mitigation

### High Risk: Data Loss During Migration
**Mitigation**: 
- Dual-write system during transition
- Comprehensive backup before migration
- Rollback procedures for failed migrations
- Extensive testing with production-like data

### Medium Risk: Performance Degradation
**Mitigation**:
- Database indexing optimization
- Connection pooling and query optimization
- Load testing with new architecture
- Gradual rollout with monitoring

### Low Risk: Frontend Compatibility Issues
**Mitigation**:
- Backward compatibility layers
- Feature flagging for gradual rollout
- Comprehensive integration testing
- Fallback to mock service if needed

## Implementation Timeline

### Week 1: Foundation Setup
- [ ] Game registry population (sticker_book entry)
- [ ] Service layer creation (GameRegistryService, ChildGameInstanceService)
- [ ] Enhanced GameDataRoutes implementation

### Week 2: Backend Integration
- [ ] API route testing and validation
- [ ] Database integration testing
- [ ] Game session tracking implementation

### Week 3: Frontend Migration
- [ ] SavedProjectsService update for new architecture
- [ ] ApiService enhanced endpoints
- [ ] Dual-write implementation for safety

### Week 4: Testing and Migration
- [ ] Comprehensive testing of new architecture
- [ ] Data migration script development and testing
- [ ] Performance optimization and monitoring

### Week 5: Rollout and Cleanup
- [ ] Gradual rollout with feature flags
- [ ] Data migration execution
- [ ] Old system cleanup and archival

## Conclusion

This implementation plan transitions from the current SimpleGameData shortcut to a proper, scalable game architecture that supports:

1. **Child Safety**: Age-appropriate content filtering and parental controls
2. **Educational Value**: Proper tracking of learning objectives and skill development  
3. **Scalability**: Easy addition of new games with proper configuration management
4. **COPPA Compliance**: Structured data categorization and retention policies
5. **Analytics**: Meaningful insights into child development and play patterns

The phased approach ensures minimal risk while providing substantial architectural improvements that will benefit the platform's long-term growth and educational effectiveness.

---

**Document Status**: Ready for Review and Implementation  
**Next Steps**: Begin Phase 2.1 - Game Registry Population