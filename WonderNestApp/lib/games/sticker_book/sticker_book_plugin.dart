import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/games/game_plugin.dart';
import '../../models/child_profile.dart';
import 'sticker_book_game.dart';

/// Sticker Book Game Plugin - First implementation of the game plugin system
class StickerBookPlugin extends GamePlugin {
  @override
  String get gameId => 'sticker_book';

  @override
  String get gameName => 'Sticker Book Adventure';

  @override
  String get gameDescription => 
      'Collect colorful stickers by completing fun activities! Match shapes, colors, and patterns to fill your sticker books.';

  @override
  String get gameVersion => '1.0.0';

  @override
  GameCategory get category => GameCategory.creative;

  @override
  List<String> get educationalTopics => [
    'Colors',
    'Shapes',
    'Patterns',
    'Counting',
    'Fine Motor Skills',
    'Visual Recognition',
  ];

  @override
  int get minAge => 3;

  @override
  int get maxAge => 8;

  @override
  int get estimatedPlayTimeMinutes => 15;

  @override
  bool get requiresParentApproval => false;

  @override
  bool get supportsOfflinePlay => true;

  @override
  IconData get gameIcon => Icons.auto_awesome;

  @override
  String? get thumbnailAssetPath => 'assets/images/sticker_book_thumbnail.png';

  @override
  String? get thumbnailUrl => null;

  @override
  Widget createGameWidget({
    required ChildProfile child,
    required GameSession session,
    required WidgetRef ref,
  }) {
    return StickerBookGame(
      child: child,
      session: session,
      plugin: this,
    );
  }

  @override
  Widget? createSettingsWidget({
    required ChildProfile child,
    required WidgetRef ref,
  }) {
    return StickerBookSettings(child: child);
  }

  @override
  Future<void> initialize() async {
    // Initialize any resources needed for the sticker book game
    await _loadStickerAssets();
  }

  @override
  Future<void> dispose() async {
    // Clean up resources
  }

  @override
  bool isAppropriateForChild(ChildProfile child) {
    return child.age >= minAge && child.age <= maxAge;
  }

  @override
  Map<String, dynamic> getGameDataSchema() {
    return {
      'version': '1.0',
      'stickerBooks': <Map<String, dynamic>>[],
      'unlockedStickers': <String>[],
      'completedPages': <String>[],
      'totalStickersCollected': 0,
      'level': 1,
      'score': 0,
      'sessionCount': 0,
      'totalPlayTimeMinutes': 0,
      'lastPlayDate': null,
      'currentBook': null,
      'currentPage': null,
      'achievements': <String>[],
      'preferences': {
        'soundEnabled': true,
        'animationsEnabled': true,
        'difficulty': 'easy',
      },
    };
  }

  @override
  bool validateSaveData(Map<String, dynamic> data) {
    try {
      // Validate required fields
      if (!data.containsKey('version')) return false;
      if (!data.containsKey('stickerBooks')) return false;
      if (!data.containsKey('unlockedStickers')) return false;
      if (!data.containsKey('level')) return false;
      if (!data.containsKey('score')) return false;

      // Validate data types
      if (data['unlockedStickers'] is! List) return false;
      if (data['level'] is! int) return false;
      if (data['score'] is! int) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> handleGameEvent(GameEvent event) async {
    // Handle specific sticker book events
    if (event is StickerCollectedEvent) {
      await _handleStickerCollected(event);
    } else if (event is BookCompletedEvent) {
      await _handleBookCompleted(event);
    } else if (event is PageCompletedEvent) {
      await _handlePageCompleted(event);
    }
  }

  @override
  List<GameAchievement> getAvailableAchievements() {
    return [
      GameAchievement(
        id: 'first_sticker',
        name: 'First Sticker',
        description: 'Collect your very first sticker!',
        icon: Icons.star,
        virtualCurrencyReward: 5,
        criteria: {'type': 'stickers_collected', 'value': 1},
      ),
      GameAchievement(
        id: 'sticker_collector',
        name: 'Sticker Collector',
        description: 'Collect 10 stickers',
        icon: Icons.collections,
        virtualCurrencyReward: 15,
        criteria: {'type': 'stickers_collected', 'value': 10},
      ),
      GameAchievement(
        id: 'page_master',
        name: 'Page Master',
        description: 'Complete your first sticker book page',
        icon: Icons.check_circle,
        virtualCurrencyReward: 20,
        criteria: {'type': 'pages_completed', 'value': 1},
      ),
      GameAchievement(
        id: 'book_completionist',
        name: 'Book Completionist',
        description: 'Complete an entire sticker book',
        icon: Icons.menu_book,
        virtualCurrencyReward: 50,
        criteria: {'type': 'books_completed', 'value': 1},
      ),
      GameAchievement(
        id: 'daily_player',
        name: 'Daily Player',
        description: 'Play sticker book for 3 days in a row',
        icon: Icons.calendar_today,
        virtualCurrencyReward: 30,
        criteria: {'type': 'daily_play_streak', 'value': 3},
      ),
      GameAchievement(
        id: 'pattern_expert',
        name: 'Pattern Expert',
        description: 'Complete 5 pattern matching activities',
        icon: Icons.grid_view,
        virtualCurrencyReward: 25,
        criteria: {'type': 'pattern_activities_completed', 'value': 5},
      ),
      GameAchievement(
        id: 'color_master',
        name: 'Color Master',
        description: 'Successfully match colors 20 times',
        icon: Icons.palette,
        virtualCurrencyReward: 35,
        criteria: {'type': 'color_matches', 'value': 20},
      ),
      GameAchievement(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete a page in under 2 minutes',
        icon: Icons.speed,
        virtualCurrencyReward: 40,
        criteria: {'type': 'fast_completion', 'maxTimeMinutes': 2},
      ),
    ];
  }

  @override
  List<VirtualCurrencyReward> getVirtualCurrencyRewards() {
    return [
      VirtualCurrencyReward(
        actionId: 'sticker_collected',
        actionName: 'Sticker Collected',
        amount: 2,
      ),
      VirtualCurrencyReward(
        actionId: 'page_completed',
        actionName: 'Page Completed',
        amount: 10,
      ),
      VirtualCurrencyReward(
        actionId: 'book_completed',
        actionName: 'Book Completed',
        amount: 25,
      ),
      VirtualCurrencyReward(
        actionId: 'perfect_match',
        actionName: 'Perfect Match',
        amount: 5,
        conditions: {'accuracy': 100},
      ),
      VirtualCurrencyReward(
        actionId: 'daily_bonus',
        actionName: 'Daily Play Bonus',
        amount: 10,
      ),
      VirtualCurrencyReward(
        actionId: 'streak_bonus',
        actionName: 'Activity Streak Bonus',
        amount: 3,
        conditions: {'streak': 5},
      ),
    ];
  }

  /// Private methods

  Future<void> _loadStickerAssets() async {
    // Load sticker images and data
    // In a real implementation, this would load from assets or API
  }

  Future<void> _handleStickerCollected(StickerCollectedEvent event) async {
    // Handle sticker collection logic
    // This could trigger achievements, update progress, etc.
  }

  Future<void> _handleBookCompleted(BookCompletedEvent event) async {
    // Handle book completion
    // Unlock new books, award bonuses, etc.
  }

  Future<void> _handlePageCompleted(PageCompletedEvent event) async {
    // Handle page completion
    // Move to next page, check for book completion, etc.
  }
}

/// Custom game events for sticker book
class StickerCollectedEvent extends GameEvent {
  final String stickerId;
  final String stickerType;

  StickerCollectedEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.stickerId,
    required this.stickerType,
  }) : super(data: {
    'stickerId': stickerId,
    'stickerType': stickerType,
  });

  @override
  String get eventType => 'sticker_collected';
}

class PageCompletedEvent extends GameEvent {
  final String pageId;
  final int stickersOnPage;
  final double completionAccuracy;

  PageCompletedEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.pageId,
    required this.stickersOnPage,
    required this.completionAccuracy,
  }) : super(data: {
    'pageId': pageId,
    'stickersOnPage': stickersOnPage,
    'completionAccuracy': completionAccuracy,
  });

  @override
  String get eventType => 'page_completed';
}

class BookCompletedEvent extends GameEvent {
  final String bookId;
  final int totalPages;
  final int totalStickers;

  BookCompletedEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.bookId,
    required this.totalPages,
    required this.totalStickers,
  }) : super(data: {
    'bookId': bookId,
    'totalPages': totalPages,
    'totalStickers': totalStickers,
  });

  @override
  String get eventType => 'book_completed';
}

/// Settings widget for the sticker book
class StickerBookSettings extends StatefulWidget {
  final ChildProfile child;

  const StickerBookSettings({
    super.key,
    required this.child,
  });

  @override
  State<StickerBookSettings> createState() => _StickerBookSettingsState();
}

class _StickerBookSettingsState extends State<StickerBookSettings> {
  bool soundEnabled = true;
  bool animationsEnabled = true;
  String difficulty = 'easy';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sticker Book Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sound settings
          SwitchListTile(
            title: const Text('Sound Effects'),
            subtitle: const Text('Play sounds when collecting stickers'),
            value: soundEnabled,
            onChanged: (value) {
              setState(() {
                soundEnabled = value;
              });
            },
          ),
          
          // Animation settings
          SwitchListTile(
            title: const Text('Animations'),
            subtitle: const Text('Show sticker collection animations'),
            value: animationsEnabled,
            onChanged: (value) {
              setState(() {
                animationsEnabled = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Difficulty setting
          const Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'easy',
                label: Text('Easy'),
                icon: Icon(Icons.sentiment_very_satisfied),
              ),
              ButtonSegment(
                value: 'medium',
                label: Text('Medium'),
                icon: Icon(Icons.sentiment_satisfied),
              ),
              ButtonSegment(
                value: 'hard',
                label: Text('Hard'),
                icon: Icon(Icons.sentiment_neutral),
              ),
            ],
            selected: {difficulty},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                difficulty = newSelection.first;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Reset progress button
          OutlinedButton.icon(
            onPressed: _showResetDialog,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Progress'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'Are you sure you want to reset all sticker book progress? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetProgress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetProgress() {
    // Reset all game progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress reset successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}