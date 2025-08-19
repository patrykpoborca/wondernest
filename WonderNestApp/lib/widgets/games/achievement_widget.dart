import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/games/game_plugin.dart';
import '../../core/games/achievement_system.dart';
import '../../core/theme/app_colors.dart';

/// Widget for displaying achievements
class AchievementWidget extends ConsumerWidget {
  final GameAchievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool showAnimation;

  const AchievementWidget({
    super.key,
    required this.achievement,
    this.isUnlocked = false,
    this.unlockedAt,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: isUnlocked ? 4 : 2,
      color: isUnlocked ? Colors.amber[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContent(),
            ),
            if (isUnlocked) _buildReward(),
          ],
        ),
      ),
    ).animate(target: showAnimation ? 1 : 0)
     .slideX(begin: 1, duration: 300.ms)
     .fadeIn(duration: 300.ms);
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber : Colors.grey[400],
        borderRadius: BorderRadius.circular(24),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        achievement.icon,
        color: isUnlocked ? Colors.white : Colors.grey[600],
        size: 24,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          achievement.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isUnlocked ? AppColors.textPrimary : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          achievement.description,
          style: TextStyle(
            fontSize: 12,
            color: isUnlocked ? AppColors.textSecondary : Colors.grey[500],
          ),
        ),
        if (unlockedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Unlocked ${_formatDate(unlockedAt!)}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReward() {
    if (achievement.virtualCurrencyReward == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${achievement.virtualCurrencyReward}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Achievement unlock notification
class AchievementUnlockNotification extends StatefulWidget {
  final GameAchievement achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockNotification({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  @override
  State<AchievementUnlockNotification> createState() => _AchievementUnlockNotificationState();
}

class _AchievementUnlockNotificationState extends State<AchievementUnlockNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber[400]!,
                    Colors.amber[600]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      widget.achievement.icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎉 Achievement Unlocked!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.achievement.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.achievement.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                        if (widget.achievement.virtualCurrencyReward > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${widget.achievement.virtualCurrencyReward} points earned!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Achievement progress list
class AchievementList extends ConsumerWidget {
  final String gameId;
  final String childId;

  const AchievementList({
    super.key,
    required this.gameId,
    required this.childId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(childAchievementsProvider((
      gameId: gameId,
      childId: childId,
    )));

    return achievements.when(
      data: (achievementList) {
        if (achievementList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No achievements yet!\nStart playing to unlock them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: achievementList.length,
          itemBuilder: (context, index) {
            final achievement = achievementList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AchievementWidget(
                achievement: achievement,
                isUnlocked: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading achievements: $error'),
      ),
    );
  }
}

/// Achievement stats summary
class AchievementStatsWidget extends ConsumerWidget {
  final String gameId;
  final String childId;

  const AchievementStatsWidget({
    super.key,
    required this.gameId,
    required this.childId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(achievementStatsProvider((
      gameId: gameId,
      childId: childId,
    )));

    return stats.when(
      data: (achievementStats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Achievement Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Unlocked',
                      '${achievementStats.unlockedCount}/${achievementStats.totalAchievements}',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Points Earned',
                      '${achievementStats.totalPointsEarned}',
                      Icons.star,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: achievementStats.completionPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 8),
              Text(
                '${achievementStats.completionPercentage}% Complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}