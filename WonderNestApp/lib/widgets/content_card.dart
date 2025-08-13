import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/content_model.dart';

class ContentCard extends StatelessWidget {
  final ContentModel content;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showProgress;
  final bool isCompact;

  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.onFavorite,
    this.showProgress = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return _buildCompactCard(context, theme);
    }

    return _buildFullCard(context, theme);
  }

  Widget _buildFullCard(BuildContext context, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  _buildThumbnail(),
                  _buildContentTypeBadge(theme),
                  if (content.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.heart(PhosphorIconsStyle.fill),
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  if (showProgress && content.progress != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: content.progress!,
                        backgroundColor: Colors.black26,
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),
            // Content Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: PhosphorIcons.clock(),
                        label: content.durationDisplay,
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: PhosphorIcons.user(),
                        label: content.ageRangeDisplay,
                        theme: theme,
                      ),
                    ],
                  ),
                  if (content.educationalTopics?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: content.educationalTopics!
                          .take(3)
                          .map((topic) => Chip(
                                label: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 120,
              height: 90,
              child: Stack(
                children: [
                  _buildThumbnail(),
                  _buildContentTypeBadge(theme, isSmall: true),
                ],
              ),
            ),
            // Content Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.clock(),
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.durationDisplay,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          PhosphorIcons.user(),
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.ageRangeDisplay,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (onFavorite != null)
              IconButton(
                icon: Icon(
                  content.isFavorite
                      ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                      : PhosphorIcons.heart(),
                  color: content.isFavorite ? Colors.red : null,
                ),
                onPressed: onFavorite,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (content.thumbnailUrl == null || content.thumbnailUrl!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            _getContentTypeIcon(),
            size: 40,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: content.thumbnailUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            _getContentTypeIcon(),
            size: 40,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeBadge(ThemeData theme, {bool isSmall = false}) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 6 : 8,
          vertical: isSmall ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: _getContentTypeColor().withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getContentTypeIcon(),
              size: isSmall ? 12 : 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              content.typeDisplay,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _getContentTypeIcon() {
    switch (content.type) {
      case ContentType.video:
        return PhosphorIcons.videoCamera();
      case ContentType.audio:
        return PhosphorIcons.musicNote();
      case ContentType.game:
        return PhosphorIcons.gameController();
      case ContentType.book:
        return PhosphorIcons.book();
      case ContentType.activity:
        return PhosphorIcons.puzzle();
    }
  }

  Color _getContentTypeColor() {
    switch (content.type) {
      case ContentType.video:
        return Colors.red;
      case ContentType.audio:
        return Colors.purple;
      case ContentType.game:
        return Colors.green;
      case ContentType.book:
        return Colors.blue;
      case ContentType.activity:
        return Colors.orange;
    }
  }
}