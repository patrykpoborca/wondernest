// WonderNest Discovery Hub Screen
// Main marketplace browsing interface for parents

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/timber_wrapper.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_item_card.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/age_range_filter.dart';
import '../widgets/search_bar_widget.dart';
import '../../data/models/marketplace_models.dart';

class DiscoveryHubScreen extends ConsumerStatefulWidget {
  const DiscoveryHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscoveryHubScreen> createState() => _DiscoveryHubScreenState();
}

class _DiscoveryHubScreenState extends ConsumerState<DiscoveryHubScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  // Filter state
  List<String> _selectedCategories = [];
  RangeValues _ageRange = const RangeValues(3, 12);
  RangeValues _priceRange = const RangeValues(0, 50);
  String _sortBy = 'popularity';
  // String _searchQuery = ''; // TODO: Add search query support to MarketplaceBrowseRequest model

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    Timber.i('[DiscoveryHub] Loading initial marketplace data');
    ref.read(marketplaceBrowseProvider.notifier).loadFeaturedContent();
    ref.read(marketplaceBrowseProvider.notifier).loadNewReleases();
    _performSearch();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more items when user scrolls to bottom
      ref.read(marketplaceBrowseProvider.notifier).loadMoreItems();
    }
  }

  void _performSearch() {
    final request = MarketplaceBrowseRequest(
      contentType: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      ageRangeMin: _ageRange.start.round(),
      ageRangeMax: _ageRange.end.round(),
      priceMin: _priceRange.start,
      priceMax: _priceRange.end,
      sortBy: _sortBy,
      page: 1,
      limit: 20,
    );
    
    ref.read(marketplaceBrowseProvider.notifier).browseMarketplace(request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final browseState = ref.watch(marketplaceBrowseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Learning Content'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBarWidget(
                  controller: _searchController,
                  onChanged: (value) {
                    // TODO: Implement search when backend supports it
                    _performSearch();
                  },
                  onSubmitted: (value) => _performSearch(),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Discover'),
                  Tab(text: 'Categories'),
                  Tab(text: 'New'),
                ],
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
                indicatorColor: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(browseState),
          _buildCategoriesTab(browseState),
          _buildNewReleasesTab(browseState),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(MarketplaceBrowseState state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Featured Content Section
          if (state.featuredItems.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Featured Content',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.featuredItems.length,
                  itemBuilder: (context, index) {
                    final item = state.featuredItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 200,
                        child: MarketplaceItemCard(
                          item: item,
                          isFeatured: true,
                          onTap: () => _navigateToItemDetails(item.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          
          // Filters Section
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildFiltersSection(),
            ),
          ),
          
          // Browse Results Section
          if (state.browseResponse != null) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Browse Results (${state.browseResponse!.totalCount})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildSortDropdown(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = state.browseResponse!.items;
                    if (index >= items.length) {
                      // Show loading indicator for pagination
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    final item = items[index];
                    return MarketplaceItemCard(
                      item: item,
                      onTap: () => _navigateToItemDetails(item.id),
                    );
                  },
                  childCount: state.browseResponse!.items.length + 
                             (state.hasMore ? 1 : 0),
                ),
              ),
            ),
          ],
          
          // Loading State
          if (state.isLoading && state.browseResponse == null)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Error State
          if (state.error != null)
            SliverFillRemaining(
              child: Center(
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
                      state.error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadInitialData,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(MarketplaceBrowseState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Category',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CategoryFilterChips(
            selectedCategories: _selectedCategories,
            onSelectionChanged: (categories) {
              setState(() {
                _selectedCategories = categories;
              });
              _performSearch();
            },
          ),
          const SizedBox(height: 24),
          _buildFiltersSection(),
          const SizedBox(height: 24),
          if (state.browseResponse != null) ...[
            Text(
              'Results (${state.browseResponse!.totalCount})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Use a fixed height container instead of Expanded since we're in a ScrollView
            SizedBox(
              height: 400, // Reasonable height for grid results
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.browseResponse!.items.length,
                itemBuilder: (context, index) {
                  final item = state.browseResponse!.items[index];
                  return MarketplaceItemCard(
                    item: item,
                    onTap: () => _navigateToItemDetails(item.id),
                  );
                },
              ),
            ),
          ] else if (state.isLoading)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewReleasesTab(MarketplaceBrowseState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Releases',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (state.newReleases.isNotEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.newReleases.length,
                itemBuilder: (context, index) {
                  final item = state.newReleases[index];
                  return MarketplaceItemCard(
                    item: item,
                    isNew: true,
                    onTap: () => _navigateToItemDetails(item.id),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('No new releases available'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Age Range Filter
            AgeRangeFilter(
              ageRange: _ageRange,
              onChanged: (range) {
                setState(() {
                  _ageRange = range;
                });
                _performSearch();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Price Range Filter
            Text(
              'Price Range: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 100,
              divisions: 20,
              labels: RangeLabels(
                '\$${_priceRange.start.round()}',
                '\$${_priceRange.end.round()}',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _priceRange = values;
                });
              },
              onChangeEnd: (RangeValues values) {
                _performSearch();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Clear Filters Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategories.clear();
                    _ageRange = const RangeValues(3, 12);
                    _priceRange = const RangeValues(0, 50);
                    _sortBy = 'popularity';
                    _searchController.clear();
                  });
                  _performSearch();
                },
                child: const Text('Clear All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: _sortBy,
      items: const [
        DropdownMenuItem(value: 'popularity', child: Text('Popular')),
        DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
        DropdownMenuItem(value: 'price', child: Text('Price: Low to High')),
        DropdownMenuItem(value: 'newest', child: Text('Newest')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _sortBy = value;
          });
          _performSearch();
        }
      },
    );
  }

  void _navigateToItemDetails(String itemId) {
    Timber.i('[DiscoveryHub] Navigating to item details: $itemId');
    context.push('/marketplace/item/$itemId');
  }
}