import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/games/game_plugin.dart';
import '../../core/games/game_registry.dart';
import '../../models/child_profile.dart';
import 'game_card.dart';

/// A grid widget for displaying games with filtering and sorting
class GameGrid extends ConsumerStatefulWidget {
  final ChildProfile child;
  final GameDiscoveryFilter? filter;
  final Function(GamePlugin)? onGameTap;
  final int crossAxisCount;
  final bool showRecommendations;

  const GameGrid({
    super.key,
    required this.child,
    this.filter,
    this.onGameTap,
    this.crossAxisCount = 2,
    this.showRecommendations = false,
  });

  @override
  ConsumerState<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends ConsumerState<GameGrid> {
  @override
  Widget build(BuildContext context) {
    final games = widget.showRecommendations
        ? ref.watch(gameRecommendationsProvider(widget.child))
        : widget.filter != null
            ? ref.watch(filteredGamesProvider(widget.filter!))
            : ref.watch(gamesForChildProvider(widget.child));

    if (games.isEmpty) {
      return _buildEmptyState();
    }

    return MasonryGridView.count(
      crossAxisCount: widget.crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCard(
          game: game,
          child: widget.child,
          onTap: () => widget.onGameTap?.call(game),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (widget.filter != null) {
      message = 'No games match your filters.\nTry adjusting your search criteria.';
      icon = Icons.filter_list_off;
    } else if (widget.showRecommendations) {
      message = 'No recommendations available yet.\nPlay some games to get personalized suggestions!';
      icon = Icons.lightbulb_outline;
    } else {
      message = 'No games available.\nCheck back soon for new content!';
      icon = Icons.games;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal scrolling list of games
class GameHorizontalList extends ConsumerWidget {
  final ChildProfile child;
  final String title;
  final GameDiscoveryFilter? filter;
  final Function(GamePlugin)? onGameTap;
  final VoidCallback? onSeeAllTap;
  final bool showRecommendations;

  const GameHorizontalList({
    super.key,
    required this.child,
    required this.title,
    this.filter,
    this.onGameTap,
    this.onSeeAllTap,
    this.showRecommendations = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = showRecommendations
        ? ref.watch(gameRecommendationsProvider(child))
        : filter != null
            ? ref.watch(filteredGamesProvider(filter!))
            : ref.watch(gamesForChildProvider(child));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onSeeAllTap != null)
                TextButton(
                  onPressed: onSeeAllTap,
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: GameCard(
                  game: game,
                  child: child,
                  onTap: () => onGameTap?.call(game),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}