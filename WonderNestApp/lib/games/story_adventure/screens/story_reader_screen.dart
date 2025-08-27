import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/services/timber_wrapper.dart';
import '../../../models/child_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../models/story_models.dart';
import '../story_adventure_plugin.dart';
import '../widgets/image_first_story_viewer.dart';
import '../widgets/story_interaction_settings.dart';

/// Story reader screen - displays story content with interactive features
class StoryReaderScreen extends ConsumerStatefulWidget {
  final ChildProfile childProfile;
  final StoryTemplate storyTemplate;
  final StorySession storySession;

  const StoryReaderScreen({
    super.key,
    required this.childProfile,
    required this.storyTemplate,
    required this.storySession,
  });

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> 
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  List<StoryPage> _pages = [];
  bool _isLoading = true;
  bool _useImageFirstMode = true; // Toggle for image-first vs traditional mode
  late AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.storySession.currentPage - 1; // Convert to 0-based index
    _pageController = PageController(initialPage: _currentPage);
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadStoryPages();
    _checkUserPreference();
  }
  
  void _checkUserPreference() {
    // Check if child's age suggests image-first mode
    final ageInYears = widget.childProfile.age;
    _useImageFirstMode = ageInYears <= 8; // Use image-first for younger children
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _loadStoryPages() {
    try {
      // Parse story content from template
      final contentData = widget.storyTemplate.content;
      if (contentData.containsKey('pages')) {
        final pagesData = contentData['pages'] as List;
        _pages = pagesData.map((pageData) {
          final pageMap = pageData as Map<String, dynamic>;
          return StoryPage(
            pageNumber: pageMap['pageNumber'] ?? 1,
            text: pageMap['text'] ?? '',
            image: pageMap['image'],
            audioUrl: pageMap['audioUrl'],
            vocabularyWords: [], // TODO: Parse vocabulary words
          );
        }).toList();
      }

      if (_pages.isEmpty) {
        // Create a sample page if no content
        _pages = [
          StoryPage(
            pageNumber: 1,
            text: 'Welcome to ${widget.storyTemplate.title}! This is a wonderful story waiting to be told.',
            vocabularyWords: [],
          ),
        ];
      }

      setState(() {
        _isLoading = false;
      });
      
      Timber.d('Loaded ${_pages.length} story pages');
    } catch (e) {
      Timber.e('Error loading story pages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading) 
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _buildStoryContent(),
              ),
            _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _onBackPressed,
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.storyTemplate.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_pages.isNotEmpty)
                  Text(
                    'Page ${_currentPage + 1} of ${_pages.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Progress indicator
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _pages.isNotEmpty ? (_currentPage + 1) / _pages.length : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    // Use image-first mode for younger children
    if (_useImageFirstMode) {
      return PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          final page = _pages[index];
          return ImageFirstStoryViewer(
            imageUrl: page.image,
            narratorText: page.text,
            dialogues: _extractDialogues(page),
            currentPage: index,
            totalPages: _pages.length,
            onNextPage: () {
              if (index < _pages.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            onPreviousPage: () {
              if (index > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            enableSound: true,
          );
        },
      );
    }
    
    // Traditional mode for older children
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _buildStoryPage(_pages[index]);
      },
    );
  }
  
  List<CharacterDialogue>? _extractDialogues(StoryPage page) {
    // Extract character dialogues from page if available
    // This would parse the page content for dialogue markers
    // For now, return sample dialogues for demo
    if (page.text.contains('"')) {
      return [
        CharacterDialogue(
          text: "Let's explore!",
          characterName: 'Character',
          position: BubblePosition.left,
          color: Colors.blue[100],
        ),
      ];
    }
    return null;
  }

  Widget _buildStoryPage(StoryPage page) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image placeholder
          if (page.image != null)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Story Illustration',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    if (page.image != null)
                      Text(
                        page.image!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.1),
                      AppColors.primaryBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_stories,
                    size: 80,
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 20),

          // Story text
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    page.text,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Audio controls placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Implement text-to-speech
                  _recordVocabularyEncounter();
                },
                icon: Icon(
                  Icons.volume_up,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
                tooltip: 'Read aloud',
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () {
                  // TODO: Show vocabulary definitions
                  _showVocabularyHelp();
                },
                icon: Icon(
                  Icons.help_outline,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
                tooltip: 'Vocabulary help',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentPage > 0 ? _previousPage : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey[100],
                disabledForegroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),

          // Next/Finish button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentPage < _pages.length - 1 ? _nextPage : _finishStory,
              icon: Icon(_currentPage < _pages.length - 1 ? Icons.arrow_forward : Icons.check),
              label: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Finish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Update progress on backend
    _updateProgress();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishStory() async {
    try {
      final service = ref.read(storyAdventureServiceProvider);
      
      // Calculate reading time
      final readingTime = DateTime.now().difference(widget.storySession.startTime);
      
      // Complete the story
      await service.completeStory(
        sessionId: widget.storySession.sessionId,
        finalPage: _pages.length,
        readingTime: readingTime,
        completionData: {
          'pagesRead': _pages.length,
          'storyId': widget.storyTemplate.id,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      Timber.d('Story completed: ${widget.storyTemplate.title}');

      if (mounted) {
        // Show completion dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildCompletionDialog(readingTime),
        );
      }
    } catch (e) {
      Timber.e('Error finishing story: $e');
    }
  }

  Widget _buildCompletionDialog(Duration readingTime) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.celebration,
            size: 64,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Story Complete!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great job reading "${widget.storyTemplate.title}"!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 8),
                    Text('Reading time: ${readingTime.inMinutes} minutes'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.book, size: 16),
                    const SizedBox(width: 8),
                    Text('Pages read: ${_pages.length}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Return to story selection
          },
          child: const Text('Choose Another Story'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Return to story selection
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Future<void> _updateProgress() async {
    try {
      final service = ref.read(storyAdventureServiceProvider);
      await service.updateProgress(
        childId: widget.childProfile.id,
        sessionId: widget.storySession.sessionId,
        currentPage: _currentPage + 1, // Convert back to 1-based
      );
    } catch (e) {
      Timber.e('Error updating progress: $e');
    }
  }

  Future<void> _recordVocabularyEncounter() async {
    try {
      final service = ref.read(storyAdventureServiceProvider);
      final currentPageText = _pages[_currentPage].text;
      
      // Find vocabulary words in current page
      for (final word in widget.storyTemplate.vocabularyWords) {
        if (currentPageText.toLowerCase().contains(word.toLowerCase())) {
          await service.recordVocabularyEncounter(
            childId: widget.childProfile.id,
            word: word,
            templateId: widget.storyTemplate.id,
            interactionType: 'encountered',
          );
        }
      }

      Timber.d('Recorded vocabulary encounters for page ${_currentPage + 1}');
    } catch (e) {
      Timber.e('Error recording vocabulary encounter: $e');
    }
  }

  void _showVocabularyHelp() {
    // Show vocabulary definitions for words on current page
    final vocabularyWords = widget.storyTemplate.vocabularyWords
        .where((word) => _pages[_currentPage].text.toLowerCase().contains(word.toLowerCase()))
        .toList();

    if (vocabularyWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vocabulary words on this page'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vocabulary Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: vocabularyWords.map((word) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    word,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Text('- definition here'), // TODO: Add real definitions
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _onBackPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Story?'),
        content: const Text('Your progress will be saved, but you\'ll need to start from where you left off.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Reading'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit to story selection
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}