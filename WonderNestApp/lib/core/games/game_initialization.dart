import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import '../../providers/auth_provider.dart';
import 'game_plugin.dart';
import 'game_registry.dart';
import 'game_persistence.dart';
import 'achievement_system.dart';

/// Initialize the game system and register all available games
class GameInitialization {
  static bool _initialized = false;

  static Future<void> initialize(Ref<Object?> ref) async {
    if (_initialized) return;

    try {
      // Initialize persistence manager
      final apiService = ref.read(apiServiceProvider);
      await GamePersistenceManager().initialize(apiService: apiService);

      // Initialize game registry (includes built-in game registration)
      final registry = ref.read(gameRegistryProvider);
      await registry.initialize();

      // Initialize achievement and currency managers
      _initializeAchievementSystem();

      _initialized = true;
      developer.log('Game system initialized successfully', name: 'GameInitialization');
    } catch (e) {
      developer.log('Failed to initialize game system', error: e, name: 'GameInitialization');
      rethrow;
    }
  }


  static void _initializeAchievementSystem() {
    // Set up achievement and currency system listeners
    final achievementManager = AchievementManager();
    final currencyManager = VirtualCurrencyManager();

    // Add achievement unlock listener to award currency
    achievementManager.addListener(CurrencyAchievementListener());

    // Add currency update listener for notifications
    currencyManager.addListener(CurrencyNotificationListener());
  }

  static bool get isInitialized => _initialized;
}

/// Listener that awards currency when achievements are unlocked
class CurrencyAchievementListener implements AchievementUnlockListener {
  @override
  Future<void> onAchievementUnlocked(String gameId, String childId, GameAchievement achievement) async {
    if (achievement.virtualCurrencyReward > 0) {
      final currencyManager = VirtualCurrencyManager();
      await currencyManager.addCurrency(
        childId: childId,
        amount: achievement.virtualCurrencyReward,
        reason: 'Achievement: ${achievement.name}',
      );
    }
  }
}

/// Listener for currency update notifications
class CurrencyNotificationListener implements CurrencyUpdateListener {
  @override
  Future<void> onCurrencyUpdated(String childId, int amount, String reason) async {
    // In a real app, this could show notifications or update UI
    developer.log('Currency updated for $childId: $amount ($reason)', name: 'CurrencyNotificationListener');
  }
}

/// Provider for game initialization status
final gameInitializationProvider = FutureProvider<bool>((ref) async {
  if (!GameInitialization.isInitialized) {
    await GameInitialization.initialize(ref);
  }
  return true;
});

/// Provider that ensures games are initialized before accessing registry
final initializedGameRegistryProvider = FutureProvider<GameRegistry>((ref) async {
  await ref.watch(gameInitializationProvider.future);
  return ref.read(gameRegistryProvider);
});

/// Provider for checking if a specific game is available
final gameAvailabilityProvider = FutureProvider.family<bool, String>((ref, gameId) async {
  final registry = await ref.watch(initializedGameRegistryProvider.future);
  return registry.getGame(gameId) != null;
});

/// Provider for getting initialized games for a child
final initializedGamesForChildProvider = FutureProvider.family<List<GamePlugin>, ChildProfile>((ref, child) async {
  final registry = await ref.watch(initializedGameRegistryProvider.future);
  return registry.getGamesForChild(child);
});

