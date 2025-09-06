// WonderNest Collection Carousel Widget
// Displays child's collections in a horizontal scrollable carousel

import 'package:flutter/material.dart';
import '../../data/models/marketplace_models.dart';

class CollectionCarousel extends StatelessWidget {
  final List<ChildCollection> collections;
  final Function(ChildCollection) onCollectionTap;

  const CollectionCarousel({
    Key? key,
    required this.collections,
    required this.onCollectionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collection = collections[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CollectionCard(
              collection: collection,
              onTap: () => onCollectionTap(collection),
            ),
          );
        },
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final ChildCollection collection;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getCollectionColor(collection.colorTheme);
    
    return SizedBox(
      width: 100,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Collection Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCollectionIcon(collection.iconName),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Collection Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    collection.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // System Collection Badge
                if (collection.isSystemCollection)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AUTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCollectionColor(String colorTheme) {
    switch (colorTheme.toLowerCase()) {
      case 'blue':
        return Colors.blue[400]!;
      case 'purple':
        return Colors.purple[400]!;
      case 'green':
        return Colors.green[400]!;
      case 'orange':
        return Colors.orange[400]!;
      case 'pink':
        return Colors.pink[400]!;
      case 'teal':
        return Colors.teal[400]!;
      case 'indigo':
        return Colors.indigo[400]!;
      case 'amber':
        return Colors.amber[400]!;
      case 'red':
        return Colors.red[400]!;
      default:
        return Colors.blue[400]!;
    }
  }

  IconData _getCollectionIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'book':
      case 'books':
        return Icons.menu_book;
      case 'star':
      case 'stars':
        return Icons.star;
      case 'heart':
      case 'favorite':
        return Icons.favorite;
      case 'game':
      case 'games':
        return Icons.sports_esports;
      case 'music':
        return Icons.music_note;
      case 'art':
      case 'palette':
        return Icons.palette;
      case 'science':
        return Icons.science;
      case 'math':
        return Icons.calculate;
      case 'recent':
      case 'clock':
        return Icons.schedule;
      case 'trophy':
        return Icons.emoji_events;
      case 'puzzle':
        return Icons.extension;
      case 'rocket':
        return Icons.rocket_launch;
      case 'pet':
      case 'pets':
        return Icons.pets;
      case 'nature':
        return Icons.nature;
      case 'camera':
        return Icons.camera_alt;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.folder;
    }
  }
}