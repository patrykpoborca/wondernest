import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/games/game_plugin.dart';
import '../../core/games/parent_approval.dart';
import '../../models/child_profile.dart';
import '../../core/theme/app_colors.dart';

/// A card widget for displaying game information
class GameCard extends ConsumerWidget {
  final GamePlugin game;
  final ChildProfile child;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool showApprovalStatus;

  const GameCard({
    super.key,
    required this.game,
    required this.child,
    this.onTap,
    this.showProgress = true,
    this.showApprovalStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 4),
                    _buildDescription(),
                    const Spacer(),
                    if (showProgress) _buildProgressBar(ref),
                    if (showApprovalStatus) _buildApprovalStatus(ref),
                    _buildMetadata(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [
            game.category.color.withValues(alpha: 0.8),
            game.category.color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background image or icon
          if (game.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: game.thumbnailUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildIconPlaceholder(),
              errorWidget: (context, url, error) => _buildIconPlaceholder(),
            )
          else if (game.thumbnailAssetPath != null)
            Image.asset(
              game.thumbnailAssetPath!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildIconPlaceholder(),
            )
          else
            _buildIconPlaceholder(),
          
          // Category badge
          Positioned(
            top: 8,
            right: 8,
            child: _buildCategoryBadge(),
          ),
          
          // Age indicator
          Positioned(
            top: 8,
            left: 8,
            child: _buildAgeIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [
            game.category.color.withValues(alpha: 0.8),
            game.category.color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          game.gameIcon,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            game.category.icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            game.category.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeIndicator() {
    final isAppropriate = game.isAppropriateForChild(child);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAppropriate 
            ? Colors.green.withValues(alpha: 0.9)
            : Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${game.minAge}-${game.maxAge}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      game.gameName,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      game.gameDescription,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressBar(WidgetRef ref) {
    final gameData = ref.watch(gameDataProvider(game.gameId));
    final level = gameData['level'] as int? ?? 1;
    final score = gameData['score'] as int? ?? 0;
    
    if (level == 1 && score == 0) {
      return const SizedBox(height: 4); // No progress to show
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Score: $score',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: (level - 1) / 10, // Assuming 10 levels max
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(game.category.color),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildApprovalStatus(WidgetRef ref) {
    if (!game.requiresParentApproval) {
      return const SizedBox.shrink();
    }

    final approvalStatus = ref.watch(gameApprovalStatusProvider((
      gameId: game.gameId,
      childId: child.id,
    )));

    return approvalStatus.when(
      data: (isApproved) {
        if (isApproved) {
          return Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              const Text(
                'Approved',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Icon(
                Icons.pending,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              const Text(
                'Needs Approval',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }
      },
      loading: () => const SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '${game.estimatedPlayTimeMinutes}min',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        if (game.supportsOfflinePlay)
          Icon(
            Icons.offline_bolt,
            size: 12,
            color: Colors.green[600],
          ),
      ],
    );
  }
}

/// Provider for game data
final gameDataProvider = Provider.family<Map<String, dynamic>, String>((ref, gameId) {
  // This would typically come from the game provider
  // For now, return empty data
  return {};
});