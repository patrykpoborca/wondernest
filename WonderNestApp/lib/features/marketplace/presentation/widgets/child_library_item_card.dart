// WonderNest Child Library Item Card Widget
// Child-friendly content cards with large touch targets and visual appeal

import 'package:flutter/material.dart';
import '../../data/models/marketplace_models.dart';

class ChildLibraryItemCard extends StatelessWidget {
  final ChildLibrary item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChildLibraryItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Progress Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Background Image/Icon
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _getContentTypeGradient(item.marketplaceItemId),
                    ),
                    child: Center(
                      child: Icon(
                        _getContentTypeIcon(item.marketplaceItemId),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Progress Overlay
                  if (item.completionPercentage > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: item.completionPercentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getProgressColor(item.completionPercentage),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onFavoriteToggle,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            item.favorite ? Icons.favorite : Icons.favorite_border,
                            color: item.favorite ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Play/Continue Button Overlay
                  if (item.completionPercentage > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CONTINUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content Information
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      _getDisplayTitle(item.marketplaceItemId),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Play Time
                        if (item.totalPlayTimeMinutes > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatPlayTime(item.totalPlayTimeMinutes),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        
                        // Progress Percentage
                        if (item.completionPercentage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getProgressColor(item.completionPercentage).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(item.completionPercentage * 100).round()}%',
                              style: TextStyle(
                                color: _getProgressColor(item.completionPercentage),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getContentTypeGradient(String contentId) {
    // Generate consistent gradient based on content ID
    final hash = contentId.hashCode;
    final colors = [
      [Colors.blue[400]!, Colors.blue[600]!],
      [Colors.purple[400]!, Colors.purple[600]!],
      [Colors.green[400]!, Colors.green[600]!],
      [Colors.orange[400]!, Colors.orange[600]!],
      [Colors.pink[400]!, Colors.pink[600]!],
      [Colors.teal[400]!, Colors.teal[600]!],
      [Colors.indigo[400]!, Colors.indigo[600]!],
      [Colors.amber[400]!, Colors.amber[600]!],
    ];
    
    final colorIndex = hash.abs() % colors.length;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors[colorIndex],
    );
  }

  IconData _getContentTypeIcon(String contentId) {
    // Generate consistent icon based on content ID
    final hash = contentId.hashCode;
    final icons = [
      Icons.book,
      Icons.games,
      Icons.music_note,
      Icons.palette,
      Icons.calculate,
      Icons.science,
      Icons.sports_soccer,
      Icons.pets,
      Icons.nature,
      Icons.rocket_launch,
    ];
    
    final iconIndex = hash.abs() % icons.length;
    return icons[iconIndex];
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.blue;
  }

  String _getDisplayTitle(String contentId) {
    // In a real app, this would come from the marketplace item data
    // For now, generate a friendly title based on the ID
    return 'Learning Adventure ${contentId.substring(0, 6)}';
  }

  String _formatPlayTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }
}