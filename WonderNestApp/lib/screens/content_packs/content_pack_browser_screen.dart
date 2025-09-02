import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../models/content_pack.dart';
import '../../providers/content_pack_provider.dart';

class ContentPackBrowserScreen extends ConsumerStatefulWidget {
  const ContentPackBrowserScreen({super.key});

  @override
  ConsumerState<ContentPackBrowserScreen> createState() => _ContentPackBrowserScreenState();
}

class _ContentPackBrowserScreenState extends ConsumerState<ContentPackBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  bool _showFreeOnly = false;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentPackProvider.notifier).loadCategories();
      ref.read(contentPackProvider.notifier).loadFeaturedPacks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final searchRequest = ContentPackSearchRequest(
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: _selectedCategory,
      isFree: _showFreeOnly ? true : null,
      page: 0,
      size: 20,
    );

    ref.read(contentPackProvider.notifier).searchPacks(searchRequest);
  }

  @override
  Widget build(BuildContext context) {
    final contentPackState = ref.watch(contentPackProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Content Packs',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: contentPackState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Section
                  _buildSearchSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Categories Section
                  if (contentPackState.categories.isNotEmpty)
                    _buildCategoriesSection(contentPackState.categories),
                  
                  const SizedBox(height: 24),
                  
                  // Featured Packs Section
                  if (contentPackState.featuredPacks.isNotEmpty) ...[
                    _buildSectionTitle('Featured Packs'),
                    const SizedBox(height: 12),
                    _buildFeaturedPacks(contentPackState.featuredPacks),
                    const SizedBox(height: 24),
                  ],
                  
                  // Search Results Section
                  if (contentPackState.searchResults != null) ...[
                    _buildSectionTitle('Search Results'),
                    const SizedBox(height: 12),
                    _buildSearchResults(contentPackState.searchResults!),
                  ],
                  
                  // Error Display
                  if (contentPackState.error != null)
                    _buildErrorCard(contentPackState.error!),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search content packs...',
              prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          
          const SizedBox(height: 12),
          
          // Filters Row
          Row(
            children: [
              // Free Only Checkbox
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _showFreeOnly,
                    onChanged: (value) {
                      setState(() {
                        _showFreeOnly = value ?? false;
                      });
                    },
                    activeColor: AppColors.primaryBlue,
                  ),
                  Text(
                    'Free Only',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Search Button
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildCategoriesSection(List<ContentPackCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Browse by Category'),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category.name;
              
              return Padding(
                padding: EdgeInsets.only(right: index < categories.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected ? null : category.name;
                    });
                    _performSearch();
                  },
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primaryBlue 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primaryBlue 
                            : AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white.withValues(alpha: 0.2) 
                                : Color(int.parse(category.colorHex?.replaceAll('#', '0xFF') ?? '0xFF4CAF50')).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getCategoryIcon(category.name),
                            color: isSelected 
                                ? Colors.white 
                                : Color(int.parse(category.colorHex?.replaceAll('#', '0xFF') ?? '0xFF4CAF50')),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.name.split(' ').first, // First word only
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 100 * index))
                  .fadeIn()
                  .slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPacks(List<ContentPack> packs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final pack = packs[index];
          
          return Padding(
            padding: EdgeInsets.only(right: index < packs.length - 1 ? 16 : 0),
            child: _buildPackCard(pack, isFeatured: true),
          ).animate(delay: Duration(milliseconds: 150 * index))
              .fadeIn()
              .slideX(begin: 0.3);
        },
      ),
    );
  }

  Widget _buildSearchResults(ContentPackSearchResponse results) {
    if (results.packs.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.packs.length,
      itemBuilder: (context, index) {
        final pack = results.packs[index];
        return _buildPackCard(pack);
      },
    );
  }

  Widget _buildPackCard(ContentPack pack, {bool isFeatured = false}) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to pack details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pack details for: ${pack.name}')),
        );
      },
      child: Container(
        width: isFeatured ? 160 : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(pack.colorPalette?['primary']?.replaceAll('#', '0xFF') ?? '0xFF4CAF50')).withValues(alpha: 0.3),
                      Color(int.parse(pack.colorPalette?['secondary']?.replaceAll('#', '0xFF') ?? '0xFFFFA726')).withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getPackTypeIcon(pack.packType),
                        size: isFeatured ? 48 : 36,
                        color: Color(int.parse(pack.colorPalette?['primary']?.replaceAll('#', '0xFF') ?? '0xFF4CAF50')),
                      ),
                    ),
                    if (pack.isFeatured)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FEATURED',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (pack.isFree)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FREE',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      pack.name,
                      style: GoogleFonts.poppins(
                        fontSize: isFeatured ? 14 : 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Description
                    Text(
                      pack.shortDescription ?? pack.description ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: isFeatured ? 11 : 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Price and stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pack.priceDisplay,
                          style: GoogleFonts.poppins(
                            fontSize: isFeatured ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: pack.isFree ? AppColors.successGreen : AppColors.primaryBlue,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.warningOrange,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              pack.ratingAverage.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No packs found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'animals & nature':
        return Icons.pets;
      case 'fantasy & magic':
        return Icons.auto_fix_high;
      case 'transportation':
        return Icons.directions_car;
      case 'space & science':
        return Icons.rocket;
      case 'educational':
        return Icons.school;
      case 'seasonal':
        return Icons.wb_sunny;
      default:
        return Icons.category;
    }
  }

  IconData _getPackTypeIcon(String packType) {
    switch (packType.toLowerCase()) {
      case 'character_bundle':
        return Icons.person;
      case 'backdrop_collection':
        return Icons.landscape;
      case 'sticker_pack':
        return Icons.star;
      case 'sound_effects':
        return Icons.volume_up;
      case 'music_collection':
        return Icons.music_note;
      case 'voice_pack':
        return Icons.record_voice_over;
      case 'emoji_pack':
        return Icons.emoji_emotions;
      default:
        return Icons.collections;
    }
  }
}