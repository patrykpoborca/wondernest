import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import 'game_plugin.dart';

/// Manages registration and discovery of game plugins
class GameRegistry {
  static final GameRegistry _instance = GameRegistry._internal();
  factory GameRegistry() => _instance;
  GameRegistry._internal();

  final Map<String, GamePlugin> _registeredGames = {};
  final Map<GameCategory, List<String>> _gamesByCategory = {};
  final Map<String, List<String>> _gamesByEducationalTopic = {};
  
  bool _initialized = false;

  /// Register a game plugin
  Future<void> registerGame(GamePlugin game) async {
    if (_registeredGames.containsKey(game.gameId)) {
      debugPrint('Game ${game.gameId} already registered, skipping...');
      return;
    }

    try {
      await game.initialize();
      _registeredGames[game.gameId] = game;
      
      // Index by category
      _gamesByCategory.putIfAbsent(game.category, () => []);
      _gamesByCategory[game.category]!.add(game.gameId);
      
      // Index by educational topics
      for (final topic in game.educationalTopics) {
        _gamesByEducationalTopic.putIfAbsent(topic, () => []);
        _gamesByEducationalTopic[topic]!.add(game.gameId);
      }
      
      debugPrint('Successfully registered game: ${game.gameId}');
    } catch (e) {
      debugPrint('Failed to register game ${game.gameId}: $e');
      rethrow;
    }
  }

  /// Unregister a game plugin
  Future<void> unregisterGame(String gameId) async {
    final game = _registeredGames.remove(gameId);
    if (game == null) return;

    try {
      // Remove from category index
      _gamesByCategory[game.category]?.remove(gameId);
      
      // Remove from educational topic index
      for (final topic in game.educationalTopics) {
        _gamesByEducationalTopic[topic]?.remove(gameId);
      }
      
      await game.dispose();
      debugPrint('Successfully unregistered game: $gameId');
    } catch (e) {
      debugPrint('Error disposing game $gameId: $e');
    }
  }

  /// Get a specific game plugin by ID
  GamePlugin? getGame(String gameId) {
    return _registeredGames[gameId];
  }

  /// Get all registered games
  List<GamePlugin> getAllGames() {
    return _registeredGames.values.toList();
  }

  /// Get games by category
  List<GamePlugin> getGamesByCategory(GameCategory category) {
    final gameIds = _gamesByCategory[category] ?? [];
    return gameIds
        .map((id) => _registeredGames[id])
        .where((game) => game != null)
        .cast<GamePlugin>()
        .toList();
  }

  /// Get games by educational topic
  List<GamePlugin> getGamesByEducationalTopic(String topic) {
    final gameIds = _gamesByEducationalTopic[topic] ?? [];
    return gameIds
        .map((id) => _registeredGames[id])
        .where((game) => game != null)
        .cast<GamePlugin>()
        .toList();
  }

  /// Get games appropriate for a specific child
  List<GamePlugin> getGamesForChild(ChildProfile child) {
    return _registeredGames.values
        .where((game) => game.isAppropriateForChild(child))
        .toList();
  }

  /// Get games by age range
  List<GamePlugin> getGamesByAgeRange(int minAge, int maxAge) {
    return _registeredGames.values
        .where((game) => 
            game.minAge <= maxAge && game.maxAge >= minAge)
        .toList();
  }

  /// Search games by name or description
  List<GamePlugin> searchGames(String query) {
    final lowerQuery = query.toLowerCase();
    return _registeredGames.values
        .where((game) =>
            game.gameName.toLowerCase().contains(lowerQuery) ||
            game.gameDescription.toLowerCase().contains(lowerQuery) ||
            game.educationalTopics.any(
                (topic) => topic.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  /// Get games that require parent approval
  List<GamePlugin> getGamesRequiringApproval() {
    return _registeredGames.values
        .where((game) => game.requiresParentApproval)
        .toList();
  }

  /// Get games that support offline play
  List<GamePlugin> getOfflineGames() {
    return _registeredGames.values
        .where((game) => game.supportsOfflinePlay)
        .toList();
  }

  /// Get all available categories with games
  List<GameCategory> getAvailableCategories() {
    return _gamesByCategory.keys.toList();
  }

  /// Get all available educational topics
  List<String> getAvailableEducationalTopics() {
    return _gamesByEducationalTopic.keys.toList();
  }

  /// Get game count by category
  Map<GameCategory, int> getGameCountByCategory() {
    return _gamesByCategory.map((category, gameIds) => 
        MapEntry(category, gameIds.length));
  }

  /// Check if registry is initialized
  bool get isInitialized => _initialized;

  /// Initialize the registry with built-in games
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      debugPrint('Initializing Game Registry...');
      
      // Register built-in games here
      // This will be expanded as we add more games
      
      _initialized = true;
      debugPrint('Game Registry initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Game Registry: $e');
      rethrow;
    }
  }

  /// Dispose all registered games
  Future<void> dispose() async {
    final games = List<GamePlugin>.from(_registeredGames.values);
    
    for (final game in games) {
      try {
        await game.dispose();
      } catch (e) {
        debugPrint('Error disposing game ${game.gameId}: $e');
      }
    }
    
    _registeredGames.clear();
    _gamesByCategory.clear();
    _gamesByEducationalTopic.clear();
    _initialized = false;
  }
}

/// Game discovery filters
class GameDiscoveryFilter {
  final List<GameCategory>? categories;
  final List<String>? educationalTopics;
  final int? minAge;
  final int? maxAge;
  final bool? requiresParentApproval;
  final bool? supportsOfflinePlay;
  final String? searchQuery;

  const GameDiscoveryFilter({
    this.categories,
    this.educationalTopics,
    this.minAge,
    this.maxAge,
    this.requiresParentApproval,
    this.supportsOfflinePlay,
    this.searchQuery,
  });

  GameDiscoveryFilter copyWith({
    List<GameCategory>? categories,
    List<String>? educationalTopics,
    int? minAge,
    int? maxAge,
    bool? requiresParentApproval,
    bool? supportsOfflinePlay,
    String? searchQuery,
  }) {
    return GameDiscoveryFilter(
      categories: categories ?? this.categories,
      educationalTopics: educationalTopics ?? this.educationalTopics,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      requiresParentApproval: requiresParentApproval ?? this.requiresParentApproval,
      supportsOfflinePlay: supportsOfflinePlay ?? this.supportsOfflinePlay,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Apply this filter to a list of games
  List<GamePlugin> apply(List<GamePlugin> games) {
    return games.where((game) {
      // Category filter
      if (categories != null && categories!.isNotEmpty) {
        if (!categories!.contains(game.category)) return false;
      }

      // Educational topic filter
      if (educationalTopics != null && educationalTopics!.isNotEmpty) {
        if (!game.educationalTopics
            .any((topic) => educationalTopics!.contains(topic))) {
          return false;
        }
      }

      // Age filter
      if (minAge != null && game.maxAge < minAge!) return false;
      if (maxAge != null && game.minAge > maxAge!) return false;

      // Parent approval filter
      if (requiresParentApproval != null &&
          game.requiresParentApproval != requiresParentApproval!) {
        return false;
      }

      // Offline play filter
      if (supportsOfflinePlay != null &&
          game.supportsOfflinePlay != supportsOfflinePlay!) {
        return false;
      }

      // Search query filter
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        if (!game.gameName.toLowerCase().contains(query) &&
            !game.gameDescription.toLowerCase().contains(query) &&
            !game.educationalTopics
                .any((topic) => topic.toLowerCase().contains(query))) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

/// Game recommendation engine
class GameRecommendationEngine {
  static const int _maxRecommendations = 10;
  
  /// Get recommended games for a child based on their profile and history
  static List<GamePlugin> getRecommendations({
    required ChildProfile child,
    List<GamePlugin>? excludeGames,
    int maxRecommendations = _maxRecommendations,
  }) {
    final registry = GameRegistry();
    final allGames = registry.getGamesForChild(child);
    final excludeIds = excludeGames?.map((g) => g.gameId).toSet() ?? <String>{};
    
    final candidateGames = allGames
        .where((game) => !excludeIds.contains(game.gameId))
        .toList();
    
    // Score games based on various factors
    final scoredGames = candidateGames.map((game) {
      double score = 0.0;
      
      // Age appropriateness scoring
      final childAge = child.age;
      final ageRange = game.maxAge - game.minAge + 1;
      final agePosition = (childAge - game.minAge) / ageRange;
      score += _scoreAgeApproppriateness(agePosition);
      
      // Educational value scoring
      score += _scoreEducationalValue(game, child);
      
      // Category preference scoring (could be based on child's history)
      score += _scoreCategoryPreference(game, child);
      
      // Play time appropriateness
      score += _scorePlayTime(game, child);
      
      return MapEntry(game, score);
    }).toList();
    
    // Sort by score and return top recommendations
    scoredGames.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredGames
        .take(maxRecommendations)
        .map((entry) => entry.key)
        .toList();
  }
  
  static double _scoreAgeApproppriateness(double agePosition) {
    // Optimal age position is around 0.6 (60% through the age range)
    final optimal = 0.6;
    final deviation = (agePosition - optimal).abs();
    return (1.0 - deviation) * 30.0; // Max 30 points
  }
  
  static double _scoreEducationalValue(GamePlugin game, ChildProfile child) {
    // More educational topics = higher score
    double score = game.educationalTopics.length * 10.0;
    
    // Bonus for educational games
    if (game.category == GameCategory.educational) {
      score += 20.0;
    }
    
    return score.clamp(0.0, 50.0); // Max 50 points
  }
  
  static double _scoreCategoryPreference(GamePlugin game, ChildProfile child) {
    // This could be enhanced with actual play history
    // For now, just give moderate scores to all categories
    return 10.0;
  }
  
  static double _scorePlayTime(GamePlugin game, ChildProfile child) {
    // Prefer games with moderate play times for younger children
    final playTime = game.estimatedPlayTimeMinutes;
    
    if (child.age <= 5) {
      // Very young children: prefer shorter games (5-15 minutes)
      if (playTime >= 5 && playTime <= 15) return 10.0;
      if (playTime <= 20) return 5.0;
      return 0.0;
    } else if (child.age <= 8) {
      // Young children: prefer moderate games (10-30 minutes)
      if (playTime >= 10 && playTime <= 30) return 10.0;
      if (playTime <= 45) return 5.0;
      return 0.0;
    } else {
      // Older children: can handle longer games
      if (playTime >= 15 && playTime <= 60) return 10.0;
      if (playTime <= 90) return 5.0;
      return 0.0;
    }
  }
}

/// Provider for the game registry singleton
final gameRegistryProvider = Provider<GameRegistry>((ref) {
  return GameRegistry();
});

/// Provider for getting all available games
final availableGamesProvider = Provider<List<GamePlugin>>((ref) {
  final registry = ref.watch(gameRegistryProvider);
  return registry.getAllGames();
});

/// Provider for getting games by category
final gamesByCategoryProvider = Provider.family<List<GamePlugin>, GameCategory>((ref, category) {
  final registry = ref.watch(gameRegistryProvider);
  return registry.getGamesByCategory(category);
});

/// Provider for getting games appropriate for a child
final gamesForChildProvider = Provider.family<List<GamePlugin>, ChildProfile>((ref, child) {
  final registry = ref.watch(gameRegistryProvider);
  return registry.getGamesForChild(child);
});

/// Provider for game recommendations
final gameRecommendationsProvider = Provider.family<List<GamePlugin>, ChildProfile>((ref, child) {
  return GameRecommendationEngine.getRecommendations(child: child);
});

/// Provider for filtered games
final filteredGamesProvider = Provider.family<List<GamePlugin>, GameDiscoveryFilter>((ref, filter) {
  final allGames = ref.watch(availableGamesProvider);
  return filter.apply(allGames);
});