# Sticker Book Creator - Aligned Implementation Plan

## Overview
This document provides a **corrected** implementation plan for the Sticker Book Creator that properly integrates with WonderNest's existing mini-game plugin architecture.

## Critical Alignment Changes

### 1. Game Registry Integration

```sql
-- Register sticker book as a plugin in the existing game registry
INSERT INTO games.game_registry (
    game_key,
    display_name,
    description,
    version,
    game_type_id,
    min_age_months,
    max_age_months,
    configuration,
    default_settings,
    implementation_type,
    entry_point,
    educational_objectives,
    skills_developed
) VALUES (
    'sticker_book_creator',
    'Sticker Book Creator',
    'Create amazing sticker books with drawings, stickers, and text',
    '1.0.0',
    (SELECT id FROM games.game_types WHERE name = 'creative'),
    36, -- 3 years
    144, -- 12 years
    '{
        "features": {
            "canvas_modes": ["infinite_canvas", "flip_book"],
            "max_books_per_child": 10,
            "max_pages_per_book": 50,
            "max_elements_per_page": 100,
            "supported_image_formats": ["png", "jpg", "webp"]
        },
        "sticker_packs": {
            "starter_pack_ids": ["animals_basic", "shapes_basic", "emotions_basic"],
            "max_custom_stickers": 50
        },
        "export": {
            "formats": ["pdf", "png"],
            "max_resolution": "2048x2048"
        }
    }'::JSONB,
    '{
        "canvas_mode": "infinite_canvas",
        "auto_save": true,
        "auto_save_interval_seconds": 30
    }'::JSONB,
    'native',
    '/games/sticker-book',
    '["creativity", "fine_motor_skills", "storytelling", "emotional_expression"]'::JSONB,
    '["drawing", "spatial_reasoning", "color_recognition", "narrative_building"]'::JSONB
);
```

### 2. Use Existing Child Game Instance Pattern

```sql
-- When a child first plays sticker book, create instance
-- This replaces the direct sticker_books table
INSERT INTO games.child_game_instances (
    child_id,
    game_id,
    settings,
    preferences
) VALUES (
    @child_id,
    (SELECT id FROM games.game_registry WHERE game_key = 'sticker_book_creator'),
    '{"auto_save": true}'::JSONB,
    '{"default_brush_size": 5, "default_color": "#000000"}'::JSONB
);
```

### 3. Store Sticker Book Data Using Flexible Pattern

```sql
-- Store sticker books in child_game_data using the flexible key-value pattern
-- Key: 'sticker_books' - Array of all books
INSERT INTO games.child_game_data (
    child_game_instance_id,
    data_key,
    data_version,
    data_value
) VALUES (
    @instance_id,
    'sticker_books',
    1,
    '[
        {
            "id": "book_1",
            "title": "My Safari Adventure",
            "canvas_mode": "infinite_canvas",
            "created_at": "2024-01-15T10:00:00Z",
            "pages": [
                {
                    "id": "page_1",
                    "elements": [
                        {
                            "type": "sticker",
                            "sticker_id": "lion_happy",
                            "x": 100,
                            "y": 200,
                            "scale": 1.5,
                            "rotation": 15
                        },
                        {
                            "type": "drawing",
                            "path_data": "M10,10 L20,20",
                            "color": "#FF0000",
                            "stroke_width": 3
                        }
                    ]
                }
            ]
        }
    ]'::JSONB
);

-- Key: 'sticker_collections' - Owned sticker packs
INSERT INTO games.child_game_data (
    child_game_instance_id,
    data_key,
    data_version,
    data_value
) VALUES (
    @instance_id,
    'sticker_collections',
    1,
    '{
        "owned_packs": ["animals_basic", "shapes_basic"],
        "custom_stickers": [
            {
                "id": "custom_1",
                "image_url": "s3://bucket/custom/uuid.png",
                "created_at": "2024-01-15T10:00:00Z",
                "approved": true
            }
        ]
    }'::JSONB
);
```

### 4. Reusable Asset System

```sql
-- Create shared asset system that other games can use
CREATE TABLE games.game_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_type VARCHAR(50) NOT NULL, -- 'sticker', 'background', 'sound', 'sprite'
    asset_category VARCHAR(100),
    name VARCHAR(200) NOT NULL,
    
    -- Asset data
    url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    metadata JSONB DEFAULT '{}',
    
    -- Monetization
    is_premium BOOLEAN DEFAULT FALSE,
    wonder_coin_price INTEGER DEFAULT 0,
    
    -- Age targeting
    min_age_months INTEGER DEFAULT 0,
    max_age_months INTEGER DEFAULT 999,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Link assets to games (many-to-many)
CREATE TABLE games.game_asset_registry (
    game_id UUID REFERENCES games.game_registry(id),
    asset_id UUID REFERENCES games.game_assets(id),
    usage_context JSONB, -- How this asset is used in this specific game
    is_starter BOOLEAN DEFAULT FALSE, -- Part of starter pack
    unlock_requirement JSONB, -- Achievement or level required
    PRIMARY KEY (game_id, asset_id)
);
```

### 5. Generic Approval Workflow

```sql
-- Reusable approval system for any game needing parent approval
CREATE TABLE games.parent_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES children(id),
    game_id UUID REFERENCES games.game_registry(id),
    
    -- Approval request
    approval_type VARCHAR(100) NOT NULL, -- 'custom_content', 'premium_purchase', 'sharing'
    request_context VARCHAR(500), -- What specifically needs approval
    request_data JSONB NOT NULL, -- Details of what needs approval
    
    -- Approval status
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    parent_id UUID REFERENCES parent_profiles(id),
    reviewed_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Auto-expiry
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoint Alignment

### Follow Standard Game Instance Pattern

```kotlin
// Standard game instance endpoints
@Get("/api/v1/games/children/{childId}/instances")
suspend fun getChildGameInstances(childId: UUID): List<GameInstance>

@Get("/api/v1/games/children/{childId}/instances/{gameId}")
suspend fun getGameInstance(childId: UUID, gameId: UUID): GameInstance

@Post("/api/v1/games/children/{childId}/instances/{gameId}/start")
suspend fun startGameSession(childId: UUID, gameId: UUID): GameSession

// Game data endpoints (flexible for any game)
@Get("/api/v1/games/children/{childId}/instances/{gameId}/data/{dataKey}")
suspend fun getGameData(childId: UUID, gameId: UUID, dataKey: String): JsonElement

@Put("/api/v1/games/children/{childId}/instances/{gameId}/data/{dataKey}")
suspend fun updateGameData(childId: UUID, gameId: UUID, dataKey: String, data: JsonElement)

// Sticker book specific operations become data updates
// Example: Creating a new book
PUT /api/v1/games/children/{childId}/instances/{stickerGameId}/data/sticker_books
{
    "action": "add_book",
    "book": {
        "title": "My New Book",
        "canvas_mode": "flip_book"
    }
}
```

## Flutter Architecture Alignment

### Use Standard Game Provider Pattern

```dart
// Standard game instance provider that all games use
final gameInstanceProvider = StateNotifierProvider.family<
    GameInstanceNotifier, 
    GameInstanceState, 
    GameInstanceParams
>((ref, params) {
  return GameInstanceNotifier(
    childId: params.childId,
    gameId: params.gameId,
    gameService: ref.read(gameServiceProvider),
  );
});

// Sticker book specific implementation
class StickerBookGame extends GameImplementation {
  static const String GAME_KEY = 'sticker_book_creator';
  
  @override
  Widget buildGameUI(GameInstanceState state) {
    final stickerBooks = state.getData<List<StickerBook>>('sticker_books');
    final collections = state.getData<StickerCollections>('sticker_collections');
    
    return StickerBookCanvas(
      books: stickerBooks,
      collections: collections,
      onUpdate: (key, value) => state.updateData(key, value),
    );
  }
  
  @override
  Map<String, dynamic> getAnalytics(GameInstanceState state) {
    return {
      'total_books': state.getData('sticker_books')?.length ?? 0,
      'total_stickers_placed': _countStickers(state),
      'creativity_score': _calculateCreativityScore(state),
    };
  }
}
```

## Session Tracking Integration

```sql
-- Use existing game_sessions table
INSERT INTO games.game_sessions (
    child_game_instance_id,
    started_at,
    session_data,
    events
) VALUES (
    @instance_id,
    CURRENT_TIMESTAMP,
    '{
        "initial_book_count": 2,
        "initial_sticker_count": 45
    }'::JSONB,
    '[]'::JSONB
);

-- Track events during session
UPDATE games.game_sessions 
SET events = events || '[{
    "type": "sticker_placed",
    "timestamp": "2024-01-15T10:05:00Z",
    "data": {
        "sticker_id": "lion_happy",
        "book_id": "book_1",
        "page": 1
    }
}]'::JSONB
WHERE id = @session_id;
```

## Achievement Integration

```sql
-- Register sticker book achievements in main achievement system
INSERT INTO games.achievements (
    game_id,
    name,
    description,
    criteria,
    points
) VALUES 
(
    (SELECT id FROM games.game_registry WHERE game_key = 'sticker_book_creator'),
    'first_masterpiece',
    'Complete your first sticker book',
    '{"books_completed": 1}'::JSONB,
    10
),
(
    (SELECT id FROM games.game_registry WHERE game_key = 'sticker_book_creator'),
    'sticker_collector',
    'Place 100 stickers',
    '{"stickers_placed": 100}'::JSONB,
    20
);
```

## Analytics Integration

```sql
-- Feed into unified daily_game_metrics
INSERT INTO games.daily_game_metrics (
    child_id,
    game_id,
    date,
    play_time_minutes,
    sessions_count,
    metrics
) VALUES (
    @child_id,
    (SELECT id FROM games.game_registry WHERE game_key = 'sticker_book_creator'),
    CURRENT_DATE,
    15,
    2,
    '{
        "books_created": 1,
        "stickers_placed": 23,
        "drawings_made": 5,
        "creativity_score": 85,
        "fine_motor_score": 72
    }'::JSONB
) ON CONFLICT (child_id, game_id, date) 
DO UPDATE SET 
    play_time_minutes = daily_game_metrics.play_time_minutes + EXCLUDED.play_time_minutes,
    sessions_count = daily_game_metrics.sessions_count + EXCLUDED.sessions_count,
    metrics = daily_game_metrics.metrics || EXCLUDED.metrics;
```

## Expandability Features

### 1. Sticker System as Service

```kotlin
// Reusable sticker service for any game
interface StickerService {
    suspend fun getAvailableStickers(gameId: UUID, childId: UUID): List<GameAsset>
    suspend fun unlockStickerPack(childId: UUID, packId: UUID): Result<StickerPack>
    suspend fun createCustomSticker(childId: UUID, imageData: ByteArray): PendingApproval
}

// Any game can use stickers
class MemoryGame : GameImplementation {
    @Inject lateinit var stickerService: StickerService
    
    override suspend fun onLevelComplete(childId: UUID, level: Int) {
        // Reward with sticker that can be used in sticker book
        stickerService.unlockStickerPack(childId, "memory_champion_pack")
    }
}
```

### 2. Cross-Game Asset Sharing

```dart
// Stickers earned in one game can be used in another
class CrossGameAssetProvider extends StateNotifier<List<GameAsset>> {
  List<GameAsset> getAssetsForGame(String gameKey) {
    return state.where((asset) => 
      asset.games.contains(gameKey) || asset.isUniversal
    ).toList();
  }
  
  // Sticker earned in puzzle game appears in sticker book
  void unlockAsset(String assetId, String fromGame) {
    final asset = _assetRepository.get(assetId);
    asset.unlockedFrom = fromGame;
    asset.games.add('sticker_book_creator'); // Auto-add to sticker book
    state = [...state, asset];
  }
}
```

### 3. Template for New Creative Games

```kotlin
// Base class for creative games following same pattern
abstract class CreativeGameBase : GameImplementation() {
    abstract fun getCanvasType(): CanvasType
    abstract fun getSupportedElements(): List<ElementType>
    
    // Shared functionality
    fun saveCreation(instanceId: UUID, creation: Creation) {
        gameDataRepository.updateData(
            instanceId, 
            "creations",
            addToArray(creation)
        )
    }
    
    fun exportCreation(format: ExportFormat): ByteArray {
        return when(format) {
            ExportFormat.PDF -> exportToPdf()
            ExportFormat.PNG -> exportToPng()
        }
    }
}

// New drawing game uses same pattern
class DrawingGame : CreativeGameBase() {
    override fun getCanvasType() = CanvasType.INFINITE
    override fun getSupportedElements() = listOf(
        ElementType.BRUSH_STROKE,
        ElementType.SHAPE,
        ElementType.TEXT
    )
}
```

## Migration Path

### Phase 1: Core Alignment (Week 1)
1. Register game in `game_registry`
2. Migrate to `child_game_instances` pattern
3. Convert data to `child_game_data` format
4. Update API endpoints to standard pattern

### Phase 2: Integration (Week 2)
1. Connect to unified achievement system
2. Integrate with virtual currency
3. Link to cross-game analytics
4. Implement standard session tracking

### Phase 3: Reusability (Week 3)
1. Extract sticker service
2. Create asset sharing system
3. Build approval workflow service
4. Document patterns for other games

### Phase 4: Launch (Week 4)
1. Testing with existing games
2. Verify analytics flow
3. Parent approval testing
4. Performance optimization

## Benefits of Aligned Architecture

1. **Consistency**: All games follow same patterns
2. **Discoverability**: Games appear in unified game library
3. **Analytics**: Automatic cross-game insights
4. **Achievements**: Unified achievement system
5. **Monetization**: Shared virtual currency
6. **Assets**: Stickers usable across games
7. **Approvals**: Reusable parent workflow
8. **Maintenance**: Single codebase for core features
9. **Scalability**: Easy to add new games
10. **Testing**: Shared test infrastructure

This aligned implementation ensures the Sticker Book Creator serves as a proper template for all future mini-games while maintaining the scalable, plugin-based architecture.