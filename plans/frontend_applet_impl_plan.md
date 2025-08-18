# WonderNest Frontend Applet Implementation Plan
## Flutter Integration with Backend Mini-Game Architecture

---

# 1. Executive Summary

This document outlines the Flutter frontend implementation strategy for integrating with the backend's mini-game and applet architecture. The plan focuses on creating a scalable, performant, and child-safe gaming platform that seamlessly connects with the KTOR backend's comprehensive game management system.

## Core Implementation Principles

1. **Modular Game Architecture**: Plugin-based system for different game types
2. **Reactive State Management**: Riverpod-based state management for real-time game updates
3. **Offline-First Design**: Local caching with background sync capabilities
4. **Performance Optimization**: Lazy loading, asset caching, and efficient rendering
5. **Child Safety Integration**: Content monitoring and parental controls at UI level

---

# 2. Flutter Architecture Overview

## 2.1 Project Structure

```
lib/
├── features/
│   └── games/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── game_local_datasource.dart
│       │   │   └── game_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── game_instance_model.dart
│       │   │   ├── game_data_model.dart
│       │   │   ├── achievement_model.dart
│       │   │   └── session_model.dart
│       │   └── repositories/
│       │       └── game_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── game_entity.dart
│       │   │   ├── game_progress.dart
│       │   │   └── achievement.dart
│       │   ├── repositories/
│       │   │   └── game_repository.dart
│       │   └── usecases/
│       │       ├── load_games.dart
│       │       ├── save_progress.dart
│       │       └── unlock_achievement.dart
│       ├── presentation/
│       │   ├── providers/
│       │   │   ├── game_list_provider.dart
│       │   │   ├── game_session_provider.dart
│       │   │   └── achievement_provider.dart
│       │   ├── widgets/
│       │   │   ├── game_card.dart
│       │   │   ├── achievement_badge.dart
│       │   │   └── progress_indicator.dart
│       │   └── screens/
│       │       ├── game_library_screen.dart
│       │       ├── game_detail_screen.dart
│       │       └── game_play_screen.dart
│       └── plugins/
│           ├── base/
│           │   └── game_plugin_base.dart
│           ├── sticker_collection/
│           │   ├── sticker_game_plugin.dart
│           │   ├── models/
│           │   └── widgets/
│           ├── puzzle/
│           │   └── puzzle_game_plugin.dart
│           └── educational/
│               └── educational_game_plugin.dart
```

## 2.2 Core Dependencies

```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # Network & API
  dio: ^5.4.0
  retrofit: ^4.1.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  drift: ^2.15.0
  
  # Game Rendering
  flame: ^1.15.0  # For native Flutter games
  flutter_inappwebview: ^6.0.0  # For web-based games
  
  # Asset Management
  cached_network_image: ^3.3.1
  flutter_cache_manager: ^3.3.1
  
  # Animation & UI
  lottie: ^3.1.0
  shimmer: ^3.0.0
  flutter_animate: ^4.5.0
  
  # Utilities
  freezed: ^2.4.7
  json_annotation: ^4.8.1
  equatable: ^2.0.5
  
dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.0
```

---

# 3. State Management Architecture

## 3.1 Game State Providers

```dart
// lib/features/games/presentation/providers/game_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state_provider.freezed.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    required String childId,
    required List<GameInstance> availableGames,
    required Map<String, GameProgress> progressMap,
    required Map<String, List<Achievement>> achievements,
    @Default(false) bool isLoading,
    @Default(false) bool isOfflineMode,
    String? activeGameId,
    GameSession? currentSession,
    String? error,
  }) = _GameState;
}

@riverpod
class GameStateNotifier extends _$GameStateNotifier {
  late final GameRepository _repository;
  late final CacheManager _cacheManager;
  late final SyncService _syncService;
  
  @override
  Future<GameState> build(String childId) async {
    _repository = ref.watch(gameRepositoryProvider);
    _cacheManager = ref.watch(cacheManagerProvider);
    _syncService = ref.watch(syncServiceProvider);
    
    // Load initial state
    return await _loadGameState(childId);
  }
  
  Future<GameState> _loadGameState(String childId) async {
    try {
      // Try to load from network first
      final games = await _repository.getAvailableGames(childId);
      final progress = await _repository.getProgressForChild(childId);
      final achievements = await _repository.getAchievements(childId);
      
      // Cache for offline use
      await _cacheManager.cacheGameData(childId, games, progress, achievements);
      
      return GameState(
        childId: childId,
        availableGames: games,
        progressMap: progress,
        achievements: achievements,
      );
    } catch (e) {
      // Fallback to cached data
      final cachedData = await _cacheManager.getCachedGameData(childId);
      return GameState(
        childId: childId,
        availableGames: cachedData.games,
        progressMap: cachedData.progress,
        achievements: cachedData.achievements,
        isOfflineMode: true,
      );
    }
  }
  
  Future<void> startGameSession(String gameId) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.requireValue;
      
      // Start session on backend
      final session = await _repository.startGameSession(
        childId: currentState.childId,
        gameId: gameId,
      );
      
      return currentState.copyWith(
        activeGameId: gameId,
        currentSession: session,
      );
    });
  }
  
  Future<void> updateGameProgress(GameProgressUpdate update) async {
    final currentState = state.requireValue;
    
    // Update local state immediately for responsiveness
    state = AsyncValue.data(
      currentState.copyWith(
        progressMap: {
          ...currentState.progressMap,
          update.gameId: update.progress,
        },
      ),
    );
    
    // Queue for background sync
    await _syncService.queueProgressUpdate(
      childId: currentState.childId,
      gameId: update.gameId,
      progress: update.progress,
    );
  }
  
  Future<void> checkAchievements(String gameId, Map<String, dynamic> gameData) async {
    final currentState = state.requireValue;
    
    // Check achievements locally first
    final unlockedAchievements = await _repository.checkAchievements(
      childId: currentState.childId,
      gameId: gameId,
      currentProgress: gameData,
    );
    
    if (unlockedAchievements.isNotEmpty) {
      // Update UI immediately
      _showAchievementNotification(unlockedAchievements);
      
      // Update state
      state = AsyncValue.data(
        currentState.copyWith(
          achievements: {
            ...currentState.achievements,
            gameId: [
              ...(currentState.achievements[gameId] ?? []),
              ...unlockedAchievements,
            ],
          },
        ),
      );
    }
  }
}
```

## 3.2 Session Management Provider

```dart
// lib/features/games/presentation/providers/game_session_provider.dart

@riverpod
class GameSessionNotifier extends _$GameSessionNotifier {
  Timer? _syncTimer;
  Timer? _metricsTimer;
  
  @override
  GameSession? build() => null;
  
  Future<void> startSession(String childId, String gameId) async {
    final repository = ref.read(gameRepositoryProvider);
    
    // Create session
    final session = await repository.startGameSession(
      childId: childId,
      gameId: gameId,
      deviceInfo: await _getDeviceInfo(),
    );
    
    state = session;
    
    // Start periodic sync
    _startPeriodicSync();
    _startMetricsCollection();
  }
  
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncSessionData();
    });
  }
  
  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _collectMetrics();
    });
  }
  
  Future<void> _syncSessionData() async {
    if (state == null) return;
    
    final repository = ref.read(gameRepositoryProvider);
    
    try {
      await repository.updateSession(
        sessionId: state!.id,
        metrics: state!.metrics,
        progress: state!.progress,
      );
    } catch (e) {
      // Queue for offline sync
      ref.read(offlineSyncProvider.notifier).queueSessionUpdate(state!);
    }
  }
  
  void updateProgress(Map<String, dynamic> progressData) {
    if (state == null) return;
    
    state = state!.copyWith(
      progress: {...state!.progress, ...progressData},
      lastUpdated: DateTime.now(),
    );
  }
  
  void recordInteraction(String interactionType, Map<String, dynamic> data) {
    if (state == null) return;
    
    final updatedMetrics = state!.metrics.copyWith(
      interactionsCount: state!.metrics.interactionsCount + 1,
      interactionTypes: {
        ...state!.metrics.interactionTypes,
        interactionType: (state!.metrics.interactionTypes[interactionType] ?? 0) + 1,
      },
    );
    
    state = state!.copyWith(metrics: updatedMetrics);
  }
  
  Future<void> endSession() async {
    if (state == null) return;
    
    _syncTimer?.cancel();
    _metricsTimer?.cancel();
    
    final repository = ref.read(gameRepositoryProvider);
    
    try {
      await repository.endGameSession(
        sessionId: state!.id,
        finalMetrics: state!.metrics,
        finalProgress: state!.progress,
      );
    } catch (e) {
      // Queue for offline sync
      ref.read(offlineSyncProvider.notifier).queueSessionEnd(state!);
    }
    
    state = null;
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    _metricsTimer?.cancel();
    super.dispose();
  }
}
```

---

# 4. Plugin System Implementation

## 4.1 Base Plugin Interface

```dart
// lib/features/games/plugins/base/game_plugin_base.dart

abstract class GamePlugin {
  String get gameKey;
  String get displayName;
  String get version;
  GameType get gameType;
  
  /// Initialize the game plugin
  Future<void> initialize(GameConfiguration config);
  
  /// Build the game widget
  Widget buildGameWidget({
    required String childId,
    required String gameId,
    required GameInstance instance,
    required Function(GameProgress) onProgressUpdate,
    required Function(Achievement) onAchievementUnlocked,
  });
  
  /// Validate game data before saving
  bool validateGameData(Map<String, dynamic> data);
  
  /// Process game-specific achievements
  List<Achievement> checkAchievements(
    Map<String, dynamic> currentData,
    List<AchievementCriteria> criteria,
  );
  
  /// Generate game insights from session data
  GameInsights generateInsights(List<GameSession> sessions);
  
  /// Export game data for parent review
  Map<String, dynamic> exportGameData(GameProgress progress);
  
  /// Handle game-specific settings
  Widget buildSettingsWidget(GameSettings settings);
  
  /// Clean up resources
  Future<void> dispose();
}
```

## 4.2 Sticker Collection Plugin

```dart
// lib/features/games/plugins/sticker_collection/sticker_game_plugin.dart

class StickerCollectionPlugin extends GamePlugin {
  @override
  String get gameKey => 'sticker_collection';
  
  @override
  String get displayName => 'Sticker Collection';
  
  @override
  String get version => '1.0.0';
  
  @override
  GameType get gameType => GameType.collection;
  
  late StickerGameController _controller;
  
  @override
  Future<void> initialize(GameConfiguration config) async {
    _controller = StickerGameController(
      maxCollections: config.maxCollections,
      stickersPerCollection: config.stickersPerCollection,
      unlockMethod: config.unlockMethod,
    );
    
    await _controller.loadAssets();
  }
  
  @override
  Widget buildGameWidget({
    required String childId,
    required String gameId,
    required GameInstance instance,
    required Function(GameProgress) onProgressUpdate,
    required Function(Achievement) onAchievementUnlocked,
  }) {
    return StickerCollectionGame(
      controller: _controller,
      childId: childId,
      gameId: gameId,
      initialData: instance.gameData,
      onStickerCollected: (sticker) {
        _handleStickerCollected(
          sticker,
          instance,
          onProgressUpdate,
          onAchievementUnlocked,
        );
      },
      onCollectionComplete: (collection) {
        _handleCollectionComplete(
          collection,
          instance,
          onProgressUpdate,
          onAchievementUnlocked,
        );
      },
    );
  }
  
  void _handleStickerCollected(
    StickerItem sticker,
    GameInstance instance,
    Function(GameProgress) onProgressUpdate,
    Function(Achievement) onAchievementUnlocked,
  ) {
    // Update collection data
    final collections = instance.gameData['collections'] as Map<String, dynamic>;
    final targetCollection = collections[sticker.collectionId] as Map<String, dynamic>;
    
    targetCollection['stickers'][sticker.id] = {
      'collected': true,
      'collectedAt': DateTime.now().toIso8601String(),
      'rarity': sticker.rarity.name,
    };
    
    // Calculate progress
    final totalStickers = _controller.getTotalStickers();
    final collectedStickers = _controller.getCollectedCount(collections);
    final progress = (collectedStickers / totalStickers * 100).roundToDouble();
    
    // Update progress
    onProgressUpdate(GameProgress(
      gameId: instance.gameId,
      childId: instance.childId,
      completionPercentage: progress,
      gameData: collections,
      lastUpdated: DateTime.now(),
    ));
    
    // Check for achievements
    if (sticker.rarity == StickerRarity.legendary) {
      onAchievementUnlocked(Achievement(
        id: 'legendary_sticker',
        name: 'Legendary Find!',
        description: 'You found a legendary sticker!',
        iconUrl: 'assets/achievements/legendary.png',
        points: 100,
      ));
    }
  }
  
  @override
  List<Achievement> checkAchievements(
    Map<String, dynamic> currentData,
    List<AchievementCriteria> criteria,
  ) {
    final unlockedAchievements = <Achievement>[];
    
    for (final criterion in criteria) {
      switch (criterion.type) {
        case 'collection_complete':
          if (_isCollectionComplete(currentData, criterion.targetId)) {
            unlockedAchievements.add(criterion.achievement);
          }
          break;
        case 'sticker_count':
          final count = _getCollectedStickerCount(currentData);
          if (count >= criterion.threshold) {
            unlockedAchievements.add(criterion.achievement);
          }
          break;
        case 'rare_sticker_collected':
          if (_hasRareSticker(currentData, criterion.rarity)) {
            unlockedAchievements.add(criterion.achievement);
          }
          break;
      }
    }
    
    return unlockedAchievements;
  }
  
  @override
  GameInsights generateInsights(List<GameSession> sessions) {
    return GameInsights(
      favoriteCollection: _findFavoriteCollection(sessions),
      collectionSpeed: _calculateCollectionSpeed(sessions),
      tradingPatterns: _analyzeTradingPatterns(sessions),
      engagementLevel: _calculateEngagement(sessions),
    );
  }
}
```

---

# 5. Dynamic Game Loading

## 5.1 Game Loader Service

```dart
// lib/features/games/services/game_loader_service.dart

class GameLoaderService {
  final Map<String, GamePlugin> _loadedPlugins = {};
  final GameAssetManager _assetManager;
  final GameCacheManager _cacheManager;
  
  GameLoaderService(this._assetManager, this._cacheManager);
  
  Future<GamePlugin?> loadGame(String gameKey, String version) async {
    // Check if already loaded
    final cacheKey = '$gameKey:$version';
    if (_loadedPlugins.containsKey(cacheKey)) {
      return _loadedPlugins[cacheKey];
    }
    
    try {
      // Check for cached assets
      final hasCache = await _cacheManager.hasGameAssets(gameKey, version);
      
      if (!hasCache) {
        // Download game assets
        await _downloadGameAssets(gameKey, version);
      }
      
      // Load plugin dynamically
      final plugin = await _loadPlugin(gameKey);
      
      if (plugin != null) {
        // Initialize plugin
        final config = await _loadGameConfiguration(gameKey);
        await plugin.initialize(config);
        
        // Cache loaded plugin
        _loadedPlugins[cacheKey] = plugin;
      }
      
      return plugin;
    } catch (e) {
      debugPrint('Failed to load game $gameKey: $e');
      return null;
    }
  }
  
  Future<void> _downloadGameAssets(String gameKey, String version) async {
    final manifest = await _assetManager.getGameManifest(gameKey, version);
    
    // Download assets in parallel
    await Future.wait(
      manifest.assets.map((asset) => 
        _assetManager.downloadAsset(asset.url, asset.path)
      ),
    );
    
    // Cache manifest
    await _cacheManager.cacheGameManifest(gameKey, version, manifest);
  }
  
  Future<GamePlugin?> _loadPlugin(String gameKey) async {
    // Plugin registry - could be extended to load from remote
    switch (gameKey) {
      case 'sticker_collection':
        return StickerCollectionPlugin();
      case 'memory_game':
        return MemoryGamePlugin();
      case 'puzzle_solver':
        return PuzzleSolverPlugin();
      case 'math_adventure':
        return MathAdventurePlugin();
      default:
        // Try to load web-based game
        return WebGamePlugin(gameKey);
    }
  }
  
  Future<void> preloadGames(List<String> gameKeys) async {
    // Preload popular games for better performance
    for (final gameKey in gameKeys) {
      await loadGame(gameKey, 'latest');
    }
  }
  
  void unloadGame(String gameKey) {
    final keysToRemove = _loadedPlugins.keys
        .where((key) => key.startsWith('$gameKey:'))
        .toList();
    
    for (final key in keysToRemove) {
      _loadedPlugins[key]?.dispose();
      _loadedPlugins.remove(key);
    }
  }
  
  void dispose() {
    for (final plugin in _loadedPlugins.values) {
      plugin.dispose();
    }
    _loadedPlugins.clear();
  }
}
```

## 5.2 Asset Caching Strategy

```dart
// lib/features/games/services/game_cache_manager.dart

class GameCacheManager {
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const Duration cacheExpiry = Duration(days: 30);
  
  final Directory _cacheDir;
  final Database _metaDb;
  
  Future<void> cacheGameAssets(
    String gameKey,
    String version,
    List<GameAsset> assets,
  ) async {
    // Check cache size limit
    await _enforeCacheSizeLimit();
    
    final gameDir = Directory('${_cacheDir.path}/$gameKey/$version');
    await gameDir.create(recursive: true);
    
    // Cache each asset
    for (final asset in assets) {
      final file = File('${gameDir.path}/${asset.filename}');
      await file.writeAsBytes(asset.data);
    }
    
    // Update metadata
    await _metaDb.insert('game_cache', {
      'game_key': gameKey,
      'version': version,
      'cached_at': DateTime.now().toIso8601String(),
      'size_bytes': assets.fold(0, (sum, a) => sum + a.data.length),
      'last_accessed': DateTime.now().toIso8601String(),
    });
  }
  
  Future<List<GameAsset>?> getCachedAssets(
    String gameKey,
    String version,
  ) async {
    final gameDir = Directory('${_cacheDir.path}/$gameKey/$version');
    
    if (!await gameDir.exists()) {
      return null;
    }
    
    // Check if cache is expired
    final metadata = await _metaDb.query(
      'game_cache',
      where: 'game_key = ? AND version = ?',
      whereArgs: [gameKey, version],
    );
    
    if (metadata.isEmpty) {
      return null;
    }
    
    final cachedAt = DateTime.parse(metadata.first['cached_at'] as String);
    if (DateTime.now().difference(cachedAt) > cacheExpiry) {
      await _removeCachedGame(gameKey, version);
      return null;
    }
    
    // Load assets from cache
    final assets = <GameAsset>[];
    await for (final file in gameDir.list()) {
      if (file is File) {
        assets.add(GameAsset(
          filename: path.basename(file.path),
          data: await file.readAsBytes(),
        ));
      }
    }
    
    // Update last accessed time
    await _updateLastAccessed(gameKey, version);
    
    return assets;
  }
  
  Future<void> _enforeCacheSizeLimit() async {
    final totalSize = await _calculateTotalCacheSize();
    
    if (totalSize > maxCacheSize) {
      // Remove least recently used games
      final games = await _metaDb.query(
        'game_cache',
        orderBy: 'last_accessed ASC',
      );
      
      var freedSpace = 0;
      for (final game in games) {
        if (totalSize - freedSpace <= maxCacheSize * 0.8) {
          break;
        }
        
        await _removeCachedGame(
          game['game_key'] as String,
          game['version'] as String,
        );
        
        freedSpace += game['size_bytes'] as int;
      }
    }
  }
  
  Future<void> preloadCriticalAssets(String childId) async {
    // Preload assets for child's favorite games
    final favoriteGames = await _getFavoriteGames(childId);
    
    for (final gameKey in favoriteGames) {
      final assets = await _downloadCriticalAssets(gameKey);
      await cacheGameAssets(gameKey, 'latest', assets);
    }
  }
}
```

---

# 6. UI/UX Patterns

## 6.1 Game Library Screen

```dart
// lib/features/games/presentation/screens/game_library_screen.dart

class GameLibraryScreen extends ConsumerStatefulWidget {
  final String childId;
  
  const GameLibraryScreen({
    super.key,
    required this.childId,
  });
  
  @override
  ConsumerState<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends ConsumerState<GameLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider(widget.childId));
    
    return Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      body: CustomScrollView(
        slivers: [
          // Animated Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Game Library',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: _buildHeaderBackground(),
            ),
          ),
          
          // Category Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryTabDelegate(
              tabController: _tabController,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
          ),
          
          // Game Grid
          gameState.when(
            data: (state) => _buildGameGrid(state),
            loading: () => SliverFillRemaining(
              child: _buildLoadingState(),
            ),
            error: (error, _) => SliverFillRemaining(
              child: _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameGrid(GameState state) {
    final filteredGames = _filterGames(state.availableGames);
    
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = filteredGames[index];
            final progress = state.progressMap[game.id];
            
            return GameCard(
              game: game,
              progress: progress,
              onTap: () => _navigateToGame(game),
              onLongPress: () => _showGameDetails(game),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideY(
                begin: 0.2,
                end: 0,
                delay: Duration(milliseconds: index * 50),
              );
          },
          childCount: filteredGames.length,
        ),
      ),
    );
  }
  
  List<GameInstance> _filterGames(List<GameInstance> games) {
    if (_selectedCategory == 'all') return games;
    
    return games.where((game) {
      switch (_selectedCategory) {
        case 'favorites':
          return game.isFavorite;
        case 'recent':
          return game.lastPlayedAt != null &&
              DateTime.now().difference(game.lastPlayedAt!) < Duration(days: 7);
        case 'educational':
          return game.categories.contains('educational');
        default:
          return game.categories.contains(_selectedCategory);
      }
    }).toList();
  }
}
```

## 6.2 Game Card Widget

```dart
// lib/features/games/presentation/widgets/game_card.dart

class GameCard extends StatelessWidget {
  final GameInstance game;
  final GameProgress? progress;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const GameCard({
    super.key,
    required this.game,
    this.progress,
    required this.onTap,
    this.onLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _getGradientForCategory(game.primaryCategory),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Game Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: game.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.games, size: 50, color: Colors.grey),
                ),
              ),
            ),
            
            // Progress Overlay
            if (progress != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress.completionPercentage / 100,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(progress.completionPercentage),
                        ),
                        minHeight: 4,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${progress.completionPercentage.toInt()}% Complete',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Badges
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (game.isNew)
                    _buildBadge('NEW', Colors.green),
                  if (game.isPremium)
                    _buildBadge('PRO', Colors.amber),
                  if (progress?.hasAchievements ?? false)
                    _buildBadge('🏆', Colors.purple),
                ],
              ),
            ),
            
            // Favorite indicator
            if (game.isFavorite)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBadge(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(left: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

---

# 7. Performance Optimization

## 7.1 Game Rendering Optimization

```dart
// lib/features/games/services/game_performance_service.dart

class GamePerformanceService {
  static const int targetFPS = 60;
  static const int memoryWarningThreshold = 200 * 1024 * 1024; // 200MB
  
  final PerformanceMonitor _monitor = PerformanceMonitor();
  
  void startMonitoring(String gameId) {
    _monitor.startTracking(gameId);
    
    // Monitor frame rate
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final fps = 1000 / timing.totalSpan.inMilliseconds;
        if (fps < targetFPS * 0.8) {
          _handleLowFrameRate(gameId, fps);
        }
      }
    });
    
    // Monitor memory usage
    Timer.periodic(Duration(seconds: 5), (_) {
      _checkMemoryUsage(gameId);
    });
  }
  
  void _handleLowFrameRate(String gameId, double fps) {
    debugPrint('Low FPS detected in $gameId: ${fps.toStringAsFixed(1)}');
    
    // Reduce quality settings
    GameQualityManager.instance.reduceQuality(gameId);
    
    // Notify user if severe
    if (fps < targetFPS * 0.5) {
      _showPerformanceWarning();
    }
  }
  
  Future<void> _checkMemoryUsage(String gameId) async {
    final memoryInfo = await SysInfo.getMemoryInfo();
    
    if (memoryInfo.used > memoryWarningThreshold) {
      // Clear unnecessary caches
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // Reduce game asset quality
      GameAssetManager.instance.reduceCacheSize();
      
      // Log for analytics
      _logPerformanceIssue(gameId, 'high_memory', memoryInfo.used);
    }
  }
  
  void optimizeForDevice() {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      deviceInfo.androidInfo.then((info) {
        if (info.version.sdkInt < 28) {
          // Older Android device
          GameQualityManager.instance.setQualityPreset(QualityPreset.low);
        }
      });
    } else if (Platform.isIOS) {
      deviceInfo.iosInfo.then((info) {
        final model = info.utsname.machine;
        if (_isOlderDevice(model)) {
          GameQualityManager.instance.setQualityPreset(QualityPreset.low);
        }
      });
    }
  }
}
```

## 7.2 Asset Loading Optimization

```dart
// lib/features/games/services/game_asset_loader.dart

class OptimizedAssetLoader {
  final Map<String, Future<Uint8List>> _loadingAssets = {};
  final LRUCache<String, Uint8List> _memoryCache = LRUCache(maxSize: 50);
  
  Future<Uint8List> loadAsset(String assetPath, {bool priority = false}) async {
    // Check memory cache
    final cached = _memoryCache.get(assetPath);
    if (cached != null) {
      return cached;
    }
    
    // Check if already loading
    if (_loadingAssets.containsKey(assetPath)) {
      return _loadingAssets[assetPath]!;
    }
    
    // Start loading
    final future = _loadAssetData(assetPath, priority: priority);
    _loadingAssets[assetPath] = future;
    
    try {
      final data = await future;
      _memoryCache.put(assetPath, data);
      return data;
    } finally {
      _loadingAssets.remove(assetPath);
    }
  }
  
  Future<Uint8List> _loadAssetData(String assetPath, {bool priority = false}) async {
    if (assetPath.startsWith('http')) {
      // Network asset
      return _downloadAsset(assetPath, priority: priority);
    } else {
      // Local asset
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    }
  }
  
  Future<void> preloadAssets(List<String> assetPaths) async {
    // Load assets in parallel with limited concurrency
    final chunks = assetPaths.chunked(3);
    
    for (final chunk in chunks) {
      await Future.wait(
        chunk.map((path) => loadAsset(path, priority: false)),
      );
    }
  }
  
  void clearCache() {
    _memoryCache.clear();
    _loadingAssets.clear();
  }
}
```

---

# 8. Offline Capability

## 8.1 Offline Sync Service

```dart
// lib/features/games/services/offline_sync_service.dart

class OfflineSyncService {
  final Queue<SyncOperation> _syncQueue = Queue();
  final Database _localDb;
  final ConnectivityService _connectivity;
  Timer? _syncTimer;
  
  void startSyncService() {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((status) {
      if (status == ConnectivityStatus.online) {
        _processSyncQueue();
      }
    });
    
    // Periodic sync attempt
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      if (_connectivity.isOnline) {
        _processSyncQueue();
      }
    });
  }
  
  Future<void> queueGameProgress(GameProgressUpdate update) async {
    final operation = SyncOperation(
      id: Uuid().v4(),
      type: SyncType.gameProgress,
      data: update.toJson(),
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    
    _syncQueue.add(operation);
    await _persistQueue();
    
    // Try immediate sync if online
    if (_connectivity.isOnline) {
      _processSyncQueue();
    }
  }
  
  Future<void> _processSyncQueue() async {
    while (_syncQueue.isNotEmpty) {
      final operation = _syncQueue.removeFirst();
      
      try {
        await _syncOperation(operation);
        await _persistQueue();
      } catch (e) {
        // Re-queue with increased retry count
        operation.retryCount++;
        
        if (operation.retryCount < 3) {
          _syncQueue.addFirst(operation);
        } else {
          // Log failed sync for manual resolution
          await _logFailedSync(operation);
        }
        
        // Stop processing on error
        break;
      }
    }
  }
  
  Future<void> _syncOperation(SyncOperation operation) async {
    switch (operation.type) {
      case SyncType.gameProgress:
        final update = GameProgressUpdate.fromJson(operation.data);
        await _gameRepository.updateProgress(update);
        break;
      case SyncType.sessionEnd:
        final session = GameSession.fromJson(operation.data);
        await _gameRepository.endSession(session);
        break;
      case SyncType.achievement:
        final achievement = AchievementUnlock.fromJson(operation.data);
        await _gameRepository.unlockAchievement(achievement);
        break;
    }
  }
  
  Future<void> _persistQueue() async {
    await _localDb.transaction((txn) async {
      await txn.delete('sync_queue');
      
      for (final operation in _syncQueue) {
        await txn.insert('sync_queue', operation.toJson());
      }
    });
  }
  
  Future<void> loadQueueFromDisk() async {
    final operations = await _localDb.query('sync_queue', orderBy: 'timestamp');
    
    for (final row in operations) {
      _syncQueue.add(SyncOperation.fromJson(row));
    }
  }
}
```

---

# 9. Child Safety Implementation

## 9.1 Content Monitoring

```dart
// lib/features/games/services/game_safety_monitor.dart

class GameSafetyMonitor {
  final ContentFilterService _contentFilter;
  final ParentalControlService _parentalControls;
  
  void monitorGameContent(String gameId, Widget gameWidget) {
    // Monitor text content
    _monitorTextContent(gameId);
    
    // Monitor images
    _monitorImageContent(gameId);
    
    // Monitor external links
    _monitorExternalLinks(gameId);
    
    // Monitor play time
    _monitorPlayTime(gameId);
  }
  
  void _monitorTextContent(String gameId) {
    // Intercept all text displayed in game
    TextSpan.visitChildren = (span, visitor) {
      final text = span.toPlainText();
      
      if (_contentFilter.containsInappropriateContent(text)) {
        _handleInappropriateContent(gameId, 'text', text);
      }
      
      return true;
    };
  }
  
  void _monitorPlayTime(String gameId) {
    Timer.periodic(Duration(minutes: 1), (timer) {
      final sessionDuration = _getSessionDuration(gameId);
      final dailyLimit = _parentalControls.getDailyGameLimit();
      
      if (sessionDuration >= dailyLimit) {
        _showTimeLimit Warning(gameId);
        timer.cancel();
      } else if (sessionDuration >= dailyLimit - Duration(minutes: 5)) {
        _showTimeWarning(gameId, dailyLimit - sessionDuration);
      }
    });
  }
  
  void _handleInappropriateContent(
    String gameId,
    String contentType,
    String content,
  ) {
    // Log incident
    _logSafetyIncident(gameId, contentType, content);
    
    // Block content
    _blockContent(gameId);
    
    // Notify parent
    _notifyParent(gameId, contentType);
    
    // Exit game
    _exitGame(gameId);
  }
}
```

---

# 10. Parent Dashboard Integration

## 10.1 Game Insights Dashboard

```dart
// lib/features/games/presentation/screens/parent_game_dashboard.dart

class ParentGameDashboard extends ConsumerWidget {
  final String childId;
  
  const ParentGameDashboard({
    super.key,
    required this.childId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(gameAnalyticsProvider(childId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Activity Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _exportReport(context, ref),
          ),
        ],
      ),
      body: analytics.when(
        data: (data) => CustomScrollView(
          slivers: [
            // Summary Cards
            SliverToBoxAdapter(
              child: _buildSummaryCards(data),
            ),
            
            // Play Time Chart
            SliverToBoxAdapter(
              child: _buildPlayTimeChart(data),
            ),
            
            // Achievement Progress
            SliverToBoxAdapter(
              child: _buildAchievementProgress(data),
            ),
            
            // Game Recommendations
            SliverToBoxAdapter(
              child: _buildRecommendations(data),
            ),
            
            // Detailed Game List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGameDetailCard(
                  data.games[index],
                ),
                childCount: data.games.length,
              ),
            ),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Widget _buildSummaryCards(GameAnalytics data) {
    return Container(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(16),
        children: [
          _SummaryCard(
            title: 'Total Play Time',
            value: '${data.totalPlayTime.inHours}h',
            icon: Icons.timer,
            color: Colors.blue,
          ),
          _SummaryCard(
            title: 'Games Played',
            value: '${data.uniqueGamesPlayed}',
            icon: Icons.games,
            color: Colors.green,
          ),
          _SummaryCard(
            title: 'Achievements',
            value: '${data.achievementsUnlocked}',
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),
          _SummaryCard(
            title: 'Skill Level',
            value: data.overallSkillLevel,
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}
```

---

# 11. Implementation Roadmap

## Phase 1: Foundation (Weeks 1-2)
- Set up project structure and dependencies
- Implement base game plugin architecture
- Create game state management with Riverpod
- Build basic game library UI
- Integrate with existing backend APIs

## Phase 2: Core Games (Weeks 3-4)
- Implement sticker collection plugin
- Create memory game plugin
- Build puzzle game plugin
- Add educational game plugin
- Test game loading and initialization

## Phase 3: Advanced Features (Weeks 5-6)
- Implement offline sync service
- Add game asset caching
- Build achievement system UI
- Create game session tracking
- Add performance monitoring

## Phase 4: Safety & Analytics (Week 7)
- Implement content monitoring
- Add parental controls UI
- Build analytics dashboard
- Create export functionality
- Add time limit controls

## Phase 5: Optimization (Week 8)
- Performance optimization
- Memory usage optimization
- Asset loading optimization
- UI/UX polish
- Bug fixes and testing

## Phase 6: Launch Preparation (Week 9)
- Integration testing
- User acceptance testing
- Documentation
- Parent guide creation
- Final bug fixes

---

# 12. Testing Strategy

## 12.1 Unit Tests

```dart
// test/features/games/game_state_test.dart

void main() {
  group('GameStateNotifier', () {
    late ProviderContainer container;
    late MockGameRepository mockRepository;
    
    setUp(() {
      mockRepository = MockGameRepository();
      container = ProviderContainer(
        overrides: [
          gameRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });
    
    test('loads initial game state successfully', () async {
      when(mockRepository.getAvailableGames(any))
          .thenAnswer((_) async => testGames);
      
      final state = await container.read(
        gameStateProvider('child123').future,
      );
      
      expect(state.availableGames, equals(testGames));
      expect(state.isLoading, isFalse);
    });
    
    test('handles offline mode correctly', () async {
      when(mockRepository.getAvailableGames(any))
          .thenThrow(NetworkException());
      
      final state = await container.read(
        gameStateProvider('child123').future,
      );
      
      expect(state.isOfflineMode, isTrue);
      expect(state.availableGames, isNotEmpty);
    });
  });
}
```

## 12.2 Widget Tests

```dart
// test/features/games/widgets/game_card_test.dart

void main() {
  testWidgets('GameCard displays progress correctly', (tester) async {
    final game = GameInstance(
      id: 'game1',
      displayName: 'Test Game',
      thumbnailUrl: 'http://example.com/image.png',
      completionPercentage: 75.0,
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCard(
            game: game,
            progress: GameProgress(completionPercentage: 75.0),
            onTap: () {},
          ),
        ),
      ),
    );
    
    expect(find.text('Test Game'), findsOneWidget);
    expect(find.text('75% Complete'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
```

---

# 13. Conclusion

This comprehensive frontend implementation plan provides a robust foundation for integrating Flutter with the backend's mini-game architecture. The modular plugin system, combined with efficient state management and caching strategies, ensures scalability and performance. The focus on child safety, offline capabilities, and parent insights aligns with WonderNest's core values while delivering an engaging gaming experience for children.

Key success factors:
- **Modularity**: Plugin architecture allows easy addition of new games
- **Performance**: Optimized loading and caching for smooth gameplay
- **Safety**: Comprehensive monitoring and parental controls
- **Analytics**: Rich insights for parents and developmental tracking
- **Offline Support**: Seamless experience regardless of connectivity

The phased implementation approach ensures steady progress while maintaining quality and allowing for iterative improvements based on user feedback.