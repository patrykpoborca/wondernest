import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_mode_provider.dart';
import '../../models/child_profile.dart';
import '../../models/app_mode.dart';

class ChildHome extends ConsumerStatefulWidget {
  const ChildHome({Key? key}) : super(key: key);

  @override
  ConsumerState<ChildHome> createState() {
    print('[WIDGET] ChildHome.createState() called at ${DateTime.now()}');
    return _ChildHomeState();
  }
}

class _ChildHomeState extends ConsumerState<ChildHome> {
  late String todaysSurprise;
  late List<ActivityItem> todaysActivities;

  @override
  void initState() {
    super.initState();
    print('[WIDGET] ChildHome.initState() START at ${DateTime.now()}');
    print('[WIDGET] ChildHome widget hash: ${this.hashCode}');
    print('[WIDGET] Context available: ${context != null}');
    
    try {
      final activeChild = ref.read(activeChildProvider);
      print('[INIT] activeChild in initState: ${activeChild?.name ?? 'null'} (id: ${activeChild?.id ?? 'null'})');
      _generateDailyContent();
      print('[WIDGET] ChildHome.initState() COMPLETE');
    } catch (e, stack) {
      print('[ERROR] Failed in initState: $e');
      print('[ERROR] Stack: $stack');
    }
  }

  @override
  void dispose() {
    print('[WIDGET] ChildHome.dispose() called at ${DateTime.now()}');
    super.dispose();
  }

  void _generateDailyContent() {
    // Generate daily surprise based on current date
    final day = DateTime.now().day;
    final surprises = [
      '🎁 New sticker unlocked!',
      '🌟 Star Challenge!',
      '🎨 Art Mode unlocked!',
      '🎵 Music Box open!',
      '🦋 Butterfly friend!',
      '🌈 Rainbow quest!',
      '🎪 Circus time!',
    ];
    todaysSurprise = surprises[day % surprises.length];

    // Generate varied activities for the toy box
    todaysActivities = _generateActivities();
  }

  // Removed automatic redirect - let parent handle navigation
  // The router should handle redirects if needed

  List<ActivityItem> _generateActivities() {
    return [
      ActivityItem(
        id: 'story_adventure',
        title: 'Story Adventure',
        subtitle: 'Choose your own tale!',
        emoji: '📖',
        color: AppColors.accentPurple,
        type: ActivityType.interactiveStory,
        progress: 0.6,
        description: 'Interactive stories where you decide what happens next!',
      ),
      ActivityItem(
        id: 'puzzle_game',
        title: 'Puzzle Fun',
        subtitle: 'Solve colorful puzzles!',
        emoji: '🧩',
        color: AppColors.kidSafeBlue,
        type: ActivityType.game,
        progress: 0.4,
        description: 'Fun puzzles that help you think and learn!',
      ),
      ActivityItem(
        id: 'audio_adventure',
        title: 'Sound Safari',
        subtitle: 'Listen & discover!',
        emoji: '🎧',
        color: AppColors.accentGreen,
        type: ActivityType.audioExperience,
        progress: 0.8,
        description: 'Amazing sounds from around the world!',
      ),
      ActivityItem(
        id: 'creative_corner',
        title: 'Creative Corner',
        subtitle: 'Draw & create!',
        emoji: '🎨',
        color: AppColors.warningOrange,
        type: ActivityType.creative,
        progress: 0.3,
        description: 'Use colors and shapes to make beautiful art!',
      ),
      ActivityItem(
        id: 'animal_friends',
        title: 'Animal Friends',
        subtitle: 'Meet cute animals!',
        emoji: '🦁',
        color: AppColors.successGreen,
        type: ActivityType.educational,
        progress: 0.5,
        description: 'Learn about amazing animals and their homes!',
      ),
      ActivityItem(
        id: 'dance_party',
        title: 'Dance Party',
        subtitle: 'Move and groove!',
        emoji: '💃',
        color: AppColors.accentPurple,
        type: ActivityType.physical,
        progress: 0.2,
        description: 'Dance along to fun music and get moving!',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('[WIDGET] ChildHome.build() START at ${DateTime.now()}');
    print('[WIDGET] Build context: $context');
    print('[WIDGET] Widget mounted: $mounted');
    
    // Watch the entire appModeProvider state, not just activeChildProvider
    // This ensures we get updates when the state changes
    final appModeState = ref.watch(appModeProvider);
    final activeChild = appModeState.activeChild;
    
    print('[CHECK] activeChild: ${activeChild?.name ?? 'null'} (id: ${activeChild?.id ?? 'null'}');
    print('[CHECK] currentMode: ${appModeState.currentMode}');
    print('[CHECK] isLocked: ${appModeState.isLocked}');
    print('[CHECK] activeChild from appModeState: ${appModeState.activeChild?.name ?? 'null'}');
    
    // If no active child, we need to wait a bit to see if state is being updated
    // This handles the race condition during navigation
    if (activeChild == null) {
      print('[CHECK] activeChild is null - checking if this is temporary');
      print('[CHECK] Current app mode: ${appModeState.currentMode}');
      
      // If we're in kid mode but no child is selected, redirect to selection
      // Use a post-frame callback to avoid navigation during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && activeChild == null) {
          print('[REDIRECT] No active child after frame - going to child selection');
          context.go('/child-selection');
        }
      });
      
      // Show a brief loading state while we wait
      return Scaffold(
        backgroundColor: AppColors.kidBackgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎮',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your toy box...',
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kidSafeBlue,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.kidSafeBlue),
              ),
            ],
          ),
        ),
      );
    }
    
    print('[RENDER] Rendering full child home for: ${activeChild.name}');
    
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.comicNeue().fontFamily,
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: AppColors.kidBackgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(activeChild),
                const SizedBox(height: 20),
                _buildDailySurprise(),
                const SizedBox(height: 24),
                _buildToyBoxSection(),
                const SizedBox(height: 24),
                _buildAchievementsSection(activeChild),
                const SizedBox(height: 24),
                _buildParentHelpSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ChildProfile? activeChild) {
    final childName = activeChild?.name ?? 'Explorer';
    final childAvatar = _getChildAvatar(activeChild);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.kidGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.kidSafeBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              childAvatar,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $childName!',
                  style: GoogleFonts.comicNeue(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getPersonalizedGreeting(activeChild),
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: AppColors.warningOrange,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_calculateStars(activeChild)}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kidSafeBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }

  Widget _buildDailySurprise() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warningOrange, AppColors.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warningOrange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🎁',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Surprise!',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  todaysSurprise,
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildToyBoxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '🧸 My Toy Box',
              style: GoogleFonts.comicNeue(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.kidSafeBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${todaysActivities.length} toys',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kidSafeBlue,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),
        
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: todaysActivities.length,
          itemBuilder: (context, index) {
            final activity = todaysActivities[index];
            return _buildActivityCard(activity, index);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityItem activity, int index) {
    return GestureDetector(
      onTap: () => _launchActivity(activity),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: activity.color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    activity.color.withValues(alpha: 0.8),
                    activity.color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activity.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  activity.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                activity.title,
                style: GoogleFonts.comicNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                activity.subtitle,
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: activity.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: activity.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (400 + index * 100).ms).scale(),
    );
  }

  Widget _buildAchievementsSection(ChildProfile? activeChild) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Your Achievements',
          style: GoogleFonts.comicNeue(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.3),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.successGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getAchievementTitle(activeChild),
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _getAchievementDescription(activeChild),
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getAchievementEmoji(activeChild),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildParentHelpSection() {
    return Column(
      children: [
        // Switch Profile Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton(
            onPressed: () {
              print('[TAP] Switch Profile button tapped at ${DateTime.now()}');
              print('[NAV] Navigating to /child-selection from ChildHome');
              context.go('/child-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🔄',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Switch Profile',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.3),
        
        // Parent Help Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.kidSafeBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '👨‍👩‍👧‍👦',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                'Ask a grown-up to help!',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get help or switch back to parent mode',
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
      ],
    );
  }

  String _getChildAvatar(ChildProfile? child) {
    if (child?.avatarUrl != null) return child!.avatarUrl!;
    
    final avatars = ['🐻', '🦄', '🐼', '🦋', '🌟', '🐸', '🦊', '🐨'];
    final index = child?.name.hashCode.abs() ?? 0;
    return avatars[index % avatars.length];
  }

  String _getPersonalizedGreeting(ChildProfile? child) {
    if (child == null) return 'Ready to explore and play?';
    
    final age = child.age;
    if (age <= 3) return 'Let\'s play and learn together!';
    if (age <= 5) return 'Ready for some amazing adventures?';
    if (age <= 8) return 'Time to discover new things!';
    return 'Ready to explore and create?';
  }

  int _calculateStars(ChildProfile? child) {
    // Simple calculation based on child's name and current day
    if (child == null) return 125;
    final base = child.name.hashCode.abs() % 100;
    final dayBonus = DateTime.now().day * 5;
    return base + dayBonus;
  }

  String _getAchievementTitle(ChildProfile? child) {
    final titles = [
      'Great Job Today!',
      'Amazing Explorer!',
      'Creative Genius!',
      'Learning Star!',
      'Adventure Hero!',
    ];
    final index = child?.name.hashCode.abs() ?? 0;
    return titles[index % titles.length];
  }

  String _getAchievementDescription(ChildProfile? child) {
    final descriptions = [
      'You completed 3 activities and learned 5 new words!',
      'You solved 2 puzzles and made a beautiful drawing!',
      'You listened to 3 stories and discovered new animals!',
      'You danced to 4 songs and helped a friend!',
      'You explored new sounds and created music!',
    ];
    final index = child?.name.hashCode.abs() ?? 0;
    return descriptions[index % descriptions.length];
  }

  String _getAchievementEmoji(ChildProfile? child) {
    final emojis = ['🌟', '🎨', '🧩', '💃', '🎵'];
    final index = child?.name.hashCode.abs() ?? 0;
    return emojis[index % emojis.length];
  }

  void _launchActivity(ActivityItem activity) {
    // For now, just show a simple dialog
    // In a real app, this would launch different activities based on type
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activity.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              activity.description,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundLight,
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Here you would launch the actual activity
                      _startActivity(activity);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activity.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Let\'s Play!',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startActivity(ActivityItem activity) {
    // Placeholder for launching different activity types
    // In a real implementation, this would route to different screens/experiences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting ${activity.title}... 🎮',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: activity.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Activity data models
enum ActivityType {
  interactiveStory,
  game,
  audioExperience,
  creative,
  educational,
  physical,
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final ActivityType type;
  final double progress;
  final String description;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.type,
    required this.progress,
    required this.description,
  });
}