// WonderNest Progress Indicator Widget
// Shows child's learning progress and achievements

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/marketplace_models.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final LibraryStatsResponse stats;
  final bool isChildView;
  final bool showDetails;

  const ProgressIndicatorWidget({
    Key? key,
    required this.stats,
    this.isChildView = false,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isChildView) {
      return _buildChildFriendlyProgress(theme);
    } else {
      return _buildParentDetailedProgress(theme);
    }
  }

  Widget _buildChildFriendlyProgress(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Fun Progress Circle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: stats.completionRate / 100,
                      strokeWidth: 8,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(stats.completionRate),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${stats.completionRate.round()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Complete!',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(width: 20),
              
              // Achievement Badges
              Column(
                children: [
                  _buildAchievementBadge(
                    Icons.emoji_events,
                    Colors.amber,
                    'Learning\nStar!',
                    stats.completionRate > 75,
                  ),
                  const SizedBox(height: 8),
                  _buildAchievementBadge(
                    Icons.favorite,
                    Colors.red,
                    'Content\nLover!',
                    stats.favoritesCount > 5,
                  ),
                ],
              ),
            ],
          ),
          
          if (showDetails) ...[
            const SizedBox(height: 16),
            _buildDetailedStats(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildParentDetailedProgress(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Progress',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Progress Chart
          SizedBox(
            height: 200,
            child: _buildProgressChart(),
          ),
          
          const SizedBox(height: 16),
          
          // Detailed Stats Grid
          _buildDetailedStats(theme),
          
          const SizedBox(height: 16),
          
          // Recent Activities
          if (stats.recentActivities.isNotEmpty) ...[
            Text(
              'Recent Activities',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...stats.recentActivities.take(3).map(
              (activity) => _buildActivityItem(activity, theme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final titles = ['Completion', 'Play Time', 'Engagement'];
                if (value.toInt() < titles.length) {
                  return Text(
                    titles[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: stats.completionRate,
                color: _getProgressColor(stats.completionRate),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: (stats.totalPlayTimeHours / 10 * 100).clamp(0, 100),
                color: Colors.blue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: (stats.favoritesCount / stats.totalItems * 100).clamp(0, 100),
                color: Colors.purple,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn(
          Icons.library_books,
          '${stats.totalItems}',
          'Total Items',
          theme,
        ),
        _buildStatColumn(
          Icons.favorite,
          '${stats.favoritesCount}',
          'Favorites',
          theme,
        ),
        _buildStatColumn(
          Icons.schedule,
          '${stats.totalPlayTimeHours.toStringAsFixed(1)}h',
          'Play Time',
          theme,
        ),
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(IconData icon, Color color, String label, bool earned) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: earned ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: earned ? color : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: earned ? color : Colors.grey,
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: earned ? color : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(LibraryActivity activity, ThemeData theme) {
    final icon = _getActivityIcon(activity.activityType);
    final timeAgo = _getTimeAgo(activity.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${activity.itemTitle} - ${activity.activityType}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.blue;
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'purchased':
        return Icons.shopping_bag;
      case 'completed':
        return Icons.check_circle;
      case 'favorite_added':
        return Icons.favorite;
      case 'started':
        return Icons.play_circle;
      default:
        return Icons.circle;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}