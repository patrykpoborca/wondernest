import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/content_model.dart';
import '../../providers/content_provider.dart';
import '../../widgets/content_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_card.dart';

class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  ConsumerState<ContentLibraryScreen> createState() =>
      _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentAsync = ref.watch(contentLibraryProvider);
    final viewMode = ref.watch(contentViewModeProvider);
    final selectedType = ref.watch(contentTypeFilterProvider);
    final selectedCategories = ref.watch(contentCategoryFilterProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(theme),
            _buildFilterChips(theme, selectedType, selectedCategories),
          ],
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(contentLibraryProvider.notifier).refresh();
            },
            child: contentAsync.when(
              data: (content) => _buildContentGrid(
                context,
                content,
                viewMode,
              ),
              loading: () => _buildLoadingState(viewMode),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search content...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: theme.textTheme.titleLarge,
              onSubmitted: (query) {
                ref.read(contentLibraryProvider.notifier).search(query);
              },
            )
          : const Text('Content Library'),
      actions: [
        if (_isSearching) ...[
          IconButton(
            icon: Icon(PhosphorIcons.x()),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
              ref.read(contentLibraryProvider.notifier).search('');
            },
          ),
        ] else ...[
          IconButton(
            icon: Icon(PhosphorIcons.magnifyingGlass()),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
          IconButton(
            icon: Icon(
              ref.watch(contentViewModeProvider) == ContentViewMode.grid
                  ? PhosphorIcons.list()
                  : PhosphorIcons.gridFour(),
            ),
            onPressed: () {
              ref.read(contentViewModeProvider.notifier).update((state) =>
                  state == ContentViewMode.grid
                      ? ContentViewMode.list
                      : ContentViewMode.grid);
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.funnel()),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChips(
    ThemeData theme,
    ContentType? selectedType,
    List<ContentCategory> selectedCategories,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        height: selectedType != null || selectedCategories.isNotEmpty ? 60 : 0,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (selectedType != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(_getTypeDisplayName(selectedType)),
                  onDeleted: () {
                    ref
                        .read(contentLibraryProvider.notifier)
                        .filterByType(null);
                  },
                  avatar: Icon(
                    _getTypeIcon(selectedType),
                    size: 18,
                  ),
                ),
              ),
            ...selectedCategories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(_getCategoryDisplayName(category)),
                    onDeleted: () {
                      final updated = [...selectedCategories]..remove(category);
                      ref
                          .read(contentLibraryProvider.notifier)
                          .filterByCategories(updated);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContentGrid(
    BuildContext context,
    List<ContentModel> content,
    ContentViewMode viewMode,
  ) {
    if (content.isEmpty) {
      return EmptyStateWidget(
        title: 'No Content Found',
        subtitle: 'Try adjusting your filters or search terms',
        icon: PhosphorIcons.magnifyingGlass(),
        onActionPressed: () => _showFilterBottomSheet(context),
        actionLabel: 'Adjust Filters',
      );
    }

    if (viewMode == ContentViewMode.list) {
      return AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: content.length,
          itemBuilder: (context, index) {
            final item = content[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ContentCard(
                      content: item,
                      isCompact: true,
                      onTap: () => _openContent(context, item),
                      onFavorite: () {
                        ref
                            .read(contentLibraryProvider.notifier)
                            .toggleFavorite(item.id);
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return AnimationLimiter(
      child: MasonryGridView.count(
        controller: _scrollController,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        itemCount: content.length,
        itemBuilder: (context, index) {
          final item = content[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: ContentCard(
                  content: item,
                  onTap: () => _openContent(context, item),
                  onFavorite: () {
                    ref
                        .read(contentLibraryProvider.notifier)
                        .toggleFavorite(item.id);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ContentViewMode viewMode) {
    if (viewMode == ContentViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => const LoadingCard(
          height: 100,
          showActions: true,
        ),
      );
    }

    return const LoadingGrid(
      itemCount: 6,
      crossAxisCount: 2,
      childAspectRatio: 0.75,
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.wifiSlash(),
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(contentLibraryProvider.notifier).refresh();
              },
              icon: Icon(PhosphorIcons.arrowClockwise()),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ContentFilterSheet(),
    );
  }

  void _openContent(BuildContext context, ContentModel content) {
    switch (content.type) {
      case ContentType.video:
      case ContentType.audio:
        context.push('/player/${content.id}');
        break;
      case ContentType.game:
        context.push('/game', extra: {
          'id': content.id,
          'name': content.title,
          'description': content.description,
          'thumbnailUrl': content.thumbnailUrl,
          'gameUrl': content.contentUrl,
          'minAge': content.minAge,
          'maxAge': content.maxAge,
          'categories': content.categories.map((c) => c.toString()).toList(),
          'educationalTopics': content.educationalTopics,
        });
        break;
      default:
        // Handle other content types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${content.title}'),
          ),
        );
    }
  }

  String _getTypeDisplayName(ContentType type) {
    switch (type) {
      case ContentType.video:
        return 'Videos';
      case ContentType.audio:
        return 'Audio';
      case ContentType.game:
        return 'Games';
      case ContentType.book:
        return 'Books';
      case ContentType.activity:
        return 'Activities';
    }
  }

  IconData _getTypeIcon(ContentType type) {
    switch (type) {
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

  String _getCategoryDisplayName(ContentCategory category) {
    switch (category) {
      case ContentCategory.educational:
        return 'Educational';
      case ContentCategory.entertainment:
        return 'Entertainment';
      case ContentCategory.music:
        return 'Music';
      case ContentCategory.stories:
        return 'Stories';
      case ContentCategory.science:
        return 'Science';
      case ContentCategory.math:
        return 'Math';
      case ContentCategory.language:
        return 'Language';
      case ContentCategory.art:
        return 'Art';
      case ContentCategory.physical:
        return 'Physical';
      case ContentCategory.social:
        return 'Social';
    }
  }
}

// Filter Bottom Sheet
class ContentFilterSheet extends ConsumerStatefulWidget {
  const ContentFilterSheet({super.key});

  @override
  ConsumerState<ContentFilterSheet> createState() =>
      _ContentFilterSheetState();
}

class _ContentFilterSheetState extends ConsumerState<ContentFilterSheet> {
  ContentType? _selectedType;
  final Set<ContentCategory> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _selectedType = ref.read(contentTypeFilterProvider);
    _selectedCategories.addAll(ref.read(contentCategoryFilterProvider));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Content',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedCategories.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Content Type
                  Text(
                    'Content Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ContentType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(_getTypeLabel(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Categories
                  Text(
                    'Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ContentCategory.values.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(_getCategoryLabel(category)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Apply Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(contentLibraryProvider.notifier)
                        .filterByType(_selectedType);
                    ref
                        .read(contentLibraryProvider.notifier)
                        .filterByCategories(_selectedCategories.toList());
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.video:
        return 'Video';
      case ContentType.audio:
        return 'Audio';
      case ContentType.game:
        return 'Game';
      case ContentType.book:
        return 'Book';
      case ContentType.activity:
        return 'Activity';
    }
  }

  String _getCategoryLabel(ContentCategory category) {
    switch (category) {
      case ContentCategory.educational:
        return 'Educational';
      case ContentCategory.entertainment:
        return 'Entertainment';
      case ContentCategory.music:
        return 'Music';
      case ContentCategory.stories:
        return 'Stories';
      case ContentCategory.science:
        return 'Science';
      case ContentCategory.math:
        return 'Math';
      case ContentCategory.language:
        return 'Language';
      case ContentCategory.art:
        return 'Art';
      case ContentCategory.physical:
        return 'Physical';
      case ContentCategory.social:
        return 'Social';
    }
  }
}