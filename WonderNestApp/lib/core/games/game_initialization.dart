import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import '../../providers/auth_provider.dart';
import 'game_plugin.dart';
import 'game_registry.dart';
import 'game_persistence.dart';
import 'achievement_system.dart';
import '../../games/sticker_book/sticker_book_plugin.dart';

/// Initialize the game system and register all available games
class GameInitialization {
  static bool _initialized = false;

  static Future<void> initialize(WidgetRef ref) async {
    if (_initialized) return;

    try {
      // Initialize persistence manager
      final apiService = ref.read(apiServiceProvider);
      await GamePersistenceManager().initialize(apiService: apiService);

      // Initialize game registry
      final registry = ref.read(gameRegistryProvider);
      await registry.initialize();

      // Register built-in games
      await _registerBuiltInGames(registry);

      // Initialize achievement and currency managers
      _initializeAchievementSystem();

      _initialized = true;
      print('✅ Game system initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize game system: $e');
      rethrow;
    }
  }

  static Future<void> _registerBuiltInGames(GameRegistry registry) async {
    // Register the sticker book plugin
    final stickerBookPlugin = StickerBookPlugin();
    await registry.registerGame(stickerBookPlugin);

    // Future games would be registered here:
    // await registry.registerGame(PuzzleGamePlugin());
    // await registry.registerGame(MathGamePlugin());
    // await registry.registerGame(MemoryGamePlugin());
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
    print('Currency updated for $childId: $amount ($reason)');
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

