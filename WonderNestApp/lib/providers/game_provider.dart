import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/games/game_plugin.dart';
import '../core/games/game_registry.dart';
import '../models/child_profile.dart';
import '../core/services/api_service.dart';
import 'auth_provider.dart';

/// State for a single game session
class GameSessionState {
  final GameSession? session;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> gameData;
  final List<GameEvent> events;
  final List<GameAchievement> unlockedAchievements;
  final int virtualCurrencyEarned;

  const GameSessionState({
    this.session,
    this.isLoading = false,
    this.error,
    this.gameData = const {},
    this.events = const [],
    this.unlockedAchievements = const [],
    this.virtualCurrencyEarned = 0,
  });

  GameSessionState copyWith({
    GameSession? session,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? gameData,
    List<GameEvent>? events,
    List<GameAchievement>? unlockedAchievements,
    int? virtualCurrencyEarned,
  }) {
    return GameSessionState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      gameData: gameData ?? this.gameData,
      events: events ?? this.events,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      virtualCurrencyEarned: virtualCurrencyEarned ?? this.virtualCurrencyEarned,
    );
  }

  bool get hasActiveSession => session != null;
  Duration get sessionDuration => session?.duration ?? Duration.zero;
}

/// State for all games and game management
class GamesState {
  final bool isLoading;
  final String? error;
  final Map<String, GameSessionState> activeSessions;
  final Map<String, Map<String, dynamic>> savedGameData;
  final List<GameEvent> pendingSyncEvents;
  final DateTime? lastSyncTime;

  const GamesState({
    this.isLoading = false,
    this.error,
    this.activeSessions = const {},
    this.savedGameData = const {},
    this.pendingSyncEvents = const [],
    this.lastSyncTime,
  });

  GamesState copyWith({
    bool? isLoading,
    String? error,
    Map<String, GameSessionState>? activeSessions,
    Map<String, Map<String, dynamic>>? savedGameData,
    List<GameEvent>? pendingSyncEvents,
    DateTime? lastSyncTime,
  }) {
    return GamesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeSessions: activeSessions ?? this.activeSessions,
      savedGameData: savedGameData ?? this.savedGameData,
      pendingSyncEvents: pendingSyncEvents ?? this.pendingSyncEvents,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  GameSessionState? getSessionState(String sessionId) {
    return activeSessions[sessionId];
  }

  bool hasActiveSession(String gameId) {
    return activeSessions.values.any((state) => 
        state.session?.gameId == gameId);
  }

  List<GameSessionState> get allActiveSessions {
    return activeSessions.values.toList();
  }
}

/// Game session manager - handles individual game sessions
class GameSessionNotifier extends StateNotifier<GameSessionState> {
  final String sessionId;
  final String gameId;
  final String childId;
  final ApiService _apiService;
  final Ref _ref;

  GameSessionNotifier({
    required this.sessionId,
    required this.gameId,
    required this.childId,
    required ApiService apiService,
    required Ref ref,
  }) : _apiService = apiService,
       _ref = ref,
       super(const GameSessionState());

  /// Start a new game session
  Future<void> startSession() async {
    if (state.hasActiveSession) {
      throw StateError('Session already active');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = GameSession(
        sessionId: sessionId,
        gameId: gameId,
        childId: childId,
        startTime: DateTime.now(),
      );

      // Load existing game data if available
      final savedData = await _loadGameData();

      state = state.copyWith(
        session: session,
        gameData: savedData,
        isLoading: false,
      );

      // Notify the main game provider
      _ref.read(gamesNotifierProvider.notifier).onSessionStarted(sessionId, state);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start session: $e',
      );
    }
  }

  /// End the current game session
  Future<void> endSession({bool saveProgress = true}) async {
    if (!state.hasActiveSession) return;

    state = state.copyWith(isLoading: true);

    try {
      if (saveProgress) {
        await _saveGameData();
        await _syncGameEvents();
      }

      // Create completion event
      final completionEvent = GameCompletionEvent(
        gameId: gameId,
        childId: childId,
        sessionId: sessionId,
        finalScore: _extractScore(state.gameData),
        finalLevel: _extractLevel(state.gameData),
        playTime: state.sessionDuration,
        completed: _extractCompletionStatus(state.gameData),
      );

      await handleGameEvent(completionEvent);

      state = state.copyWith(
        session: null,
        isLoading: false,
      );

      // Notify the main game provider
      _ref.read(gamesNotifierProvider.notifier).onSessionEnded(sessionId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to end session: $e',
      );
    }
  }

  /// Update game data
  void updateGameData(Map<String, dynamic> updates) {
    if (!state.hasActiveSession) return;

    final newGameData = Map<String, dynamic>.from(state.gameData)
      ..addAll(updates);

    state = state.copyWith(gameData: newGameData);

    // Auto-save periodically
    _autoSaveGameData();
  }

  /// Handle a game event
  Future<void> handleGameEvent(GameEvent event) async {
    final newEvents = List<GameEvent>.from(state.events)..add(event);
    state = state.copyWith(events: newEvents);

    // Check for achievements
    await _checkAchievements(event);

    // Add virtual currency rewards
    await _processVirtualCurrencyRewards(event);

    // Queue for sync
    _ref.read(gamesNotifierProvider.notifier).queueEventForSync(event);

    try {
      // Attempt immediate sync if online
      await _apiService.saveGameEvent(event.toJson());
    } catch (e) {
      // Will be synced later
      print('Event sync failed, queued for later: $e');
    }
  }

  /// Load saved game data
  Future<Map<String, dynamic>> _loadGameData() async {
    try {
      final savedData = _ref.read(gamesNotifierProvider)
          .savedGameData[gameId] ?? {};
      return Map<String, dynamic>.from(savedData);
    } catch (e) {
      print('Failed to load game data: $e');
      return {};
    }
  }

  /// Save game data
  Future<void> _saveGameData() async {
    try {
      await _ref.read(gamesNotifierProvider.notifier)
          .saveGameData(gameId, state.gameData);
    } catch (e) {
      print('Failed to save game data: $e');
    }
  }

  /// Auto-save game data (debounced)
  void _autoSaveGameData() {
    // Implement debounced auto-save logic here
    // For now, just save immediately
    _saveGameData();
  }

  /// Sync game events to server
  Future<void> _syncGameEvents() async {
    for (final event in state.events) {
      try {
        await _apiService.saveGameEvent(event.toJson());
      } catch (e) {
        // Queue for later sync
        _ref.read(gamesNotifierProvider.notifier).queueEventForSync(event);
      }
    }
  }

  /// Check for newly unlocked achievements
  Future<void> _checkAchievements(GameEvent event) async {
    final registry = _ref.read(gameRegistryProvider);
    final game = registry.getGame(gameId);
    if (game == null) return;

    final availableAchievements = game.getAvailableAchievements();
    final alreadyUnlocked = state.unlockedAchievements.map((a) => a.id).toSet();

    for (final achievement in availableAchievements) {
      if (alreadyUnlocked.contains(achievement.id)) continue;

      if (_checkAchievementCriteria(achievement, event, state.gameData)) {
        final newAchievements = List<GameAchievement>.from(state.unlockedAchievements)
          ..add(achievement);

        state = state.copyWith(unlockedAchievements: newAchievements);

        // Create achievement event
        final achievementEvent = AchievementUnlockedEvent(
          gameId: gameId,
          childId: childId,
          sessionId: sessionId,
          achievementId: achievement.id,
          achievementName: achievement.name,
        );

        // Handle achievement event (but avoid infinite recursion)
        final newEvents = List<GameEvent>.from(state.events)..add(achievementEvent);
        state = state.copyWith(events: newEvents);
      }
    }
  }

  /// Process virtual currency rewards
  Future<void> _processVirtualCurrencyRewards(GameEvent event) async {
    final registry = _ref.read(gameRegistryProvider);
    final game = registry.getGame(gameId);
    if (game == null) return;

    final rewards = game.getVirtualCurrencyRewards();
    int earnedCurrency = 0;

    for (final reward in rewards) {
      if (_checkRewardConditions(reward, event, state.gameData)) {
        earnedCurrency += reward.amount;
      }
    }

    if (earnedCurrency > 0) {
      state = state.copyWith(
        virtualCurrencyEarned: state.virtualCurrencyEarned + earnedCurrency,
      );
    }
  }

  /// Check if achievement criteria are met
  bool _checkAchievementCriteria(
    GameAchievement achievement,
    GameEvent event,
    Map<String, dynamic> gameData,
  ) {
    // Implement achievement criteria checking logic
    // This would be game-specific and based on the criteria map
    final criteria = achievement.criteria;
    
    // Example criteria checks:
    if (criteria['type'] == 'score_threshold') {
      final threshold = criteria['value'] as int;
      final currentScore = _extractScore(gameData);
      return currentScore >= threshold;
    }
    
    if (criteria['type'] == 'level_reached') {
      final targetLevel = criteria['value'] as int;
      final currentLevel = _extractLevel(gameData);
      return currentLevel >= targetLevel;
    }
    
    if (criteria['type'] == 'play_time') {
      final targetMinutes = criteria['value'] as int;
      return state.sessionDuration.inMinutes >= targetMinutes;
    }
    
    return false;
  }

  /// Check if reward conditions are met
  bool _checkRewardConditions(
    VirtualCurrencyReward reward,
    GameEvent event,
    Map<String, dynamic> gameData,
  ) {
    // Implement reward condition checking logic
    final conditions = reward.conditions;
    
    // Example: reward for score updates
    if (reward.actionId == 'score_increase' && event is ScoreUpdateEvent) {
      final minIncrease = conditions['min_increase'] as int? ?? 0;
      return (event.newScore - event.previousScore) >= minIncrease;
    }
    
    // Example: reward for level completion
    if (reward.actionId == 'level_complete' && event is LevelProgressEvent) {
      return event.newLevel > event.previousLevel;
    }
    
    return false;
  }

  /// Extract score from game data
  int _extractScore(Map<String, dynamic> gameData) {
    return gameData['score'] as int? ?? 0;
  }

  /// Extract level from game data
  int _extractLevel(Map<String, dynamic> gameData) {
    return gameData['level'] as int? ?? 1;
  }

  /// Extract completion status from game data
  bool _extractCompletionStatus(Map<String, dynamic> gameData) {
    return gameData['completed'] as bool? ?? false;
  }
}

/// Main games state manager
class GamesNotifier extends StateNotifier<GamesState> {
  final ApiService _apiService;
  final Ref _ref;

  GamesNotifier(this._apiService, this._ref) : super(const GamesState()) {
    _initializeGames();
  }

  /// Initialize the games system
  Future<void> _initializeGames() async {
    state = state.copyWith(isLoading: true);

    try {
      // Initialize game registry
      await _ref.read(gameRegistryProvider).initialize();

      // Load saved game data
      await _loadSavedGameData();

      // Sync pending events
      await _syncPendingEvents();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize games: $e',
      );
    }
  }

  /// Start a new game session
  Future<String> startGameSession(String gameId, String childId) async {
    final sessionId = const Uuid().v4();
    
    // Check if game is already running
    if (state.hasActiveSession(gameId)) {
      throw StateError('Game $gameId already has an active session');
    }

    return sessionId;
  }

  /// Called when a session is started
  void onSessionStarted(String sessionId, GameSessionState sessionState) {
    final newSessions = Map<String, GameSessionState>.from(state.activeSessions)
      ..[sessionId] = sessionState;

    state = state.copyWith(activeSessions: newSessions);
  }

  /// Called when a session is ended
  void onSessionEnded(String sessionId) {
    final newSessions = Map<String, GameSessionState>.from(state.activeSessions)
      ..remove(sessionId);

    state = state.copyWith(activeSessions: newSessions);
  }

  /// Save game data for a specific game
  Future<void> saveGameData(String gameId, Map<String, dynamic> data) async {
    final newSavedData = Map<String, Map<String, dynamic>>.from(state.savedGameData)
      ..[gameId] = data;

    state = state.copyWith(savedGameData: newSavedData);

    // Persist to local storage (implementation depends on storage choice)
    try {
      // This would save to local database/storage
      await _persistGameData(gameId, data);
    } catch (e) {
      print('Failed to persist game data: $e');
    }
  }

  /// Queue event for sync
  void queueEventForSync(GameEvent event) {
    final newPendingEvents = List<GameEvent>.from(state.pendingSyncEvents)
      ..add(event);

    state = state.copyWith(pendingSyncEvents: newPendingEvents);
  }

  /// Sync all pending events
  Future<void> syncPendingEvents() async {
    if (state.pendingSyncEvents.isEmpty) return;

    final eventsToSync = List<GameEvent>.from(state.pendingSyncEvents);
    final remainingEvents = <GameEvent>[];

    for (final event in eventsToSync) {
      try {
        await _apiService.saveGameEvent(event.toJson());
      } catch (e) {
        // Keep failed events for retry
        remainingEvents.add(event);
      }
    }

    state = state.copyWith(
      pendingSyncEvents: remainingEvents,
      lastSyncTime: DateTime.now(),
    );
  }

  /// Load saved game data from storage
  Future<void> _loadSavedGameData() async {
    try {
      // Implementation would load from local storage
      // For now, just return empty data
      state = state.copyWith(savedGameData: {});
    } catch (e) {
      print('Failed to load saved game data: $e');
    }
  }

  /// Sync pending events
  Future<void> _syncPendingEvents() async {
    try {
      await syncPendingEvents();
    } catch (e) {
      print('Failed to sync pending events: $e');
    }
  }

  /// Persist game data to local storage
  Future<void> _persistGameData(String gameId, Map<String, dynamic> data) async {
    // Implementation would save to Hive, SQLite, or other local storage
    // For now, just log
    print('Persisting game data for $gameId: $data');
  }
}

/// Provider for the main games state
final gamesNotifierProvider = StateNotifierProvider<GamesNotifier, GamesState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return GamesNotifier(apiService, ref);
});

/// Provider for creating game sessions
final gameSessionProvider = StateNotifierProvider.family<GameSessionNotifier, GameSessionState, GameSessionParams>((ref, params) {
  final apiService = ref.read(apiServiceProvider);
  return GameSessionNotifier(
    sessionId: params.sessionId,
    gameId: params.gameId,
    childId: params.childId,
    apiService: apiService,
    ref: ref,
  );
});

/// Parameters for creating a game session
class GameSessionParams {
  final String sessionId;
  final String gameId;
  final String childId;

  const GameSessionParams({
    required this.sessionId,
    required this.gameId,
    required this.childId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionParams &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          gameId == other.gameId &&
          childId == other.childId;

  @override
  int get hashCode => sessionId.hashCode ^ gameId.hashCode ^ childId.hashCode;
}

/// Convenience providers
final activeGameSessionsProvider = Provider<List<GameSessionState>>((ref) {
  return ref.watch(gamesNotifierProvider).allActiveSessions;
});

final gameDataProvider = Provider.family<Map<String, dynamic>, String>((ref, gameId) {
  return ref.watch(gamesNotifierProvider).savedGameData[gameId] ?? {};
});

final pendingSyncEventsProvider = Provider<List<GameEvent>>((ref) {
  return ref.watch(gamesNotifierProvider).pendingSyncEvents;
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(gamesNotifierProvider).lastSyncTime;
});