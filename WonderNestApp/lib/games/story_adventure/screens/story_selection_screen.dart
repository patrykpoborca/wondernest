import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/games/game_plugin.dart';
import '../../../core/services/timber_wrapper.dart';
import '../../../models/child_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../models/story_models.dart';
import '../story_adventure_plugin.dart';
import 'story_reader_screen.dart';

/// Story selection screen - main entry point for Story Adventure
class StorySelectionScreen extends ConsumerStatefulWidget {
  final ChildProfile childProfile;
  final GameSession gameSession;

  const StorySelectionScreen({
    super.key,
    required this.childProfile,
    required this.gameSession,
  });

  @override
  ConsumerState<StorySelectionScreen> createState() => _StorySelectionScreenState();
}

class _StorySelectionScreenState extends ConsumerState<StorySelectionScreen> {
  bool _isLoading = true;
  List<StoryTemplate> _availableStories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableStories();
  }

  Future<void> _loadAvailableStories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final service = ref.read(storyAdventureServiceProvider);
      
      // Get age-appropriate stories
      final ageGroup = _getAgeGroup(widget.childProfile.age);
      final stories = await service.getAvailableStories(
        ageGroup: ageGroup,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _availableStories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      Timber.e('Error loading available stories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load stories. Please try again.';
        });
      }
    }
  }

  String _getAgeGroup(int age) {
    if (age <= 5) return '3-5';
    if (age <= 8) return '6-8';
    return '9-12';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              Expanded(
                child: Text(
                  'Story Adventure',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hi ${widget.childProfile.name}! Choose a story to read',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_availableStories.isEmpty) {
      return _buildEmptyState();
    }

    return _buildStoriesList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Loading stories...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAvailableStories,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'No stories available right now',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Check back later for new adventures!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _availableStories.length,
      itemBuilder: (context, index) {
        final story = _availableStories[index];
        return _buildStoryCard(story);
      },
    );
  }

  Widget _buildStoryCard(StoryTemplate story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectStory(story),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Story thumbnail placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: 40,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                // Story details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${story.estimatedReadTime} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.book,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${story.pageCount} pages',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (story.isPremium) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Play button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStory(StoryTemplate story) async {
    try {
      Timber.d('Selected story: ${story.title}');
      
      // Initialize the game for this child if needed
      final service = ref.read(storyAdventureServiceProvider);
      await service.initializeForChild(widget.childProfile.id);

      // Start a reading session
      final session = await service.startStory(
        childId: widget.childProfile.id,
        templateId: story.id,
      );

      if (session != null && mounted) {
        // Navigate to story reader
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryReaderScreen(
              childProfile: widget.childProfile,
              storyTemplate: story,
              storySession: session,
            ),
          ),
        );
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not start story. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      Timber.e('Error selecting story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }
}