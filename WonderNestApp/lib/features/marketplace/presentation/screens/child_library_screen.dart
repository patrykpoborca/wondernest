// WonderNest Child Library Home Screen
// Simplified interface for children to access their purchased content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/services/timber_wrapper.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/child_library_item_card.dart';
import '../widgets/collection_carousel.dart';
import '../widgets/progress_indicator_widget.dart';
import '../../data/models/marketplace_models.dart';

class ChildLibraryScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;

  const ChildLibraryScreen({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  ConsumerState<ChildLibraryScreen> createState() => _ChildLibraryScreenState();
}

class _ChildLibraryScreenState extends ConsumerState<ChildLibraryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  
  String _selectedFilter = 'all'; // 'all', 'favorites', 'recent', 'continue'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Load child library data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibraryData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLibraryData() {
    Timber.i('[ChildLibrary] Loading library for child: ${widget.childId}');
    ref.read(childLibraryProvider.notifier).loadChildLibrary(widget.childId);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final libraryState = ref.watch(childLibraryProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(childLibraryProvider.notifier).refreshLibrary();
        },
        child: _buildBody(context, libraryState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi ${widget.childName}! 👋',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Ready to learn and play?',
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
      toolbarHeight: 80,
      actions: [
        // Achievement/Progress Button
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () => _showProgressDialog(),
            icon: Icon(
              Icons.stars,
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ChildLibraryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return _buildLoadingState();
    }
    
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }
    
    if (state.items.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Welcome Section with Stats
        SliverToBoxAdapter(
          child: _buildWelcomeSection(state),
        ),
        
        // Collections Carousel
        if (state.collections.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildCollectionsSection(state),
          ),
        
        // Quick Access Filters
        SliverToBoxAdapter(
          child: _buildQuickFilters(),
        ),
        
        // Library Content Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: _buildLibraryGrid(state),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(ChildLibraryState state) {
    return AnimationLimiter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 500),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.library_books,
                    '${state.items.length}',
                    'Books & Games',
                  ),
                  _buildStatItem(
                    Icons.favorite,
                    '${state.items.where((item) => item.favorite).length}',
                    'Favorites',
                  ),
                  _buildStatItem(
                    Icons.schedule,
                    '${(state.stats?.totalPlayTimeHours ?? 0).round()}h',
                    'Play Time',
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Progress Indicator
              if (state.stats != null)
                ProgressIndicatorWidget(
                  stats: state.stats!,
                  isChildView: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsSection(ChildLibraryState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'My Collections 📚',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CollectionCarousel(
          collections: state.collections,
          onCollectionTap: (collection) => _navigateToCollection(collection),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Show me: ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Everything', Icons.apps),
                  const SizedBox(width: 8),
                  _buildFilterChip('continue', 'Continue Playing', Icons.play_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip('favorites', 'Favorites', Icons.favorite),
                  const SizedBox(width: 8),
                  _buildFilterChip('recent', 'Recent', Icons.schedule),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected 
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      backgroundColor: theme.colorScheme.surfaceVariant,
      selectedColor: theme.colorScheme.secondaryContainer,
    );
  }

  Widget _buildLibraryGrid(ChildLibraryState state) {
    final filteredItems = _getFilteredItems(state.items);
    
    if (filteredItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getEmptyStateIcon(),
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return AnimationLimiter(
      child: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: ChildLibraryItemCard(
                    item: filteredItems[index],
                    onTap: () => _launchContent(filteredItems[index]),
                    onFavoriteToggle: () => _toggleFavorite(filteredItems[index]),
                  ),
                ),
              ),
            );
          },
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  List<ChildLibrary> _getFilteredItems(List<ChildLibrary> items) {
    switch (_selectedFilter) {
      case 'favorites':
        return items.where((item) => item.favorite).toList();
      case 'recent':
        final sortedItems = [...items];
        sortedItems.sort((a, b) {
          final aLastAccessed = a.lastAccessed ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bLastAccessed = b.lastAccessed ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bLastAccessed.compareTo(aLastAccessed);
        });
        return sortedItems.take(10).toList();
      case 'continue':
        return items.where((item) => 
          item.completionPercentage > 0 && item.completionPercentage < 1.0).toList();
      default:
        return items;
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case 'favorites': return Icons.favorite_border;
      case 'recent': return Icons.schedule;
      case 'continue': return Icons.play_circle_outline;
      default: return Icons.library_books;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'favorites': return 'No favorites yet!\nTap the heart to add some.';
      case 'recent': return 'No recent activities.\nStart playing something!';
      case 'continue': return 'Nothing to continue.\nStart a new adventure!';
      default: return 'Your library is empty.\nAsk a grown-up to add content!';
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your library...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadLibraryData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Your library is empty!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask a grown-up to add some\nfun learning content for you!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _launchContent(ChildLibrary item) {
    Timber.i('[ChildLibrary] Launching content: ${item.marketplaceItemId}');
    
    // Show launch animation/loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Starting ${item.marketplaceItemId}...'),
          ],
        ),
      ),
    );
    
    // Simulate launch delay then navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      // TODO: Navigate to actual content/game
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content launching feature coming soon!'),
        ),
      );
    });
  }

  void _toggleFavorite(ChildLibrary item) {
    // TODO: Implement favorite toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.favorite 
              ? 'Removed from favorites' 
              : 'Added to favorites',
        ),
      ),
    );
  }

  void _navigateToCollection(ChildCollection collection) {
    Timber.i('[ChildLibrary] Opening collection: ${collection.name}');
    // TODO: Navigate to collection view
  }

  void _showProgressDialog() {
    final libraryState = ref.read(childLibraryProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Progress! ⭐'),
        content: libraryState.stats != null
            ? ProgressIndicatorWidget(
                stats: libraryState.stats!,
                isChildView: true,
                showDetails: true,
              )
            : const Text('No progress data available yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cool!'),
          ),
        ],
      ),
    );
  }
}