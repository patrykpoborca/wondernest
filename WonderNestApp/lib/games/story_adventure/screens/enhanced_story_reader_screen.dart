import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wonder_nest/models/story/enhanced_story_models.dart' as story_models;
import 'package:wonder_nest/widgets/story/styled_text_block.dart';
import 'package:wonder_nest/core/services/timber_wrapper.dart';

/// Enhanced story reader that supports the new story builder format
class EnhancedStoryReaderScreen extends ConsumerStatefulWidget {
  final story_models.EnhancedStory story;
  final String childId;
  final int childAge;

  const EnhancedStoryReaderScreen({
    Key? key,
    required this.story,
    required this.childId,
    required this.childAge,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedStoryReaderScreen> createState() =>
      _EnhancedStoryReaderScreenState();
}

class _EnhancedStoryReaderScreenState
    extends ConsumerState<EnhancedStoryReaderScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showVocabularyHints = true;
  final Set<String> _encounteredVocabulary = {};
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTime = DateTime.now();
    Timber.i('Starting story: ${widget.story.title}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _trackReadingSession();
    super.dispose();
  }

  void _trackReadingSession() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      Timber.i('Story reading session ended. Duration: ${duration.inSeconds}s');
      // TODO: Send reading session data to backend
    }
  }

  void _handlePageChange(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Track vocabulary from the current page
    final currentPageData = widget.story.content.pages[page];
    for (final textBlock in currentPageData.textBlocks) {
      _encounteredVocabulary.addAll(textBlock.vocabularyWords);
    }
    
    Timber.d('Page changed to ${page + 1}/${widget.story.pageCount}');
  }

  void _handleVocabularyTap(String word) {
    Timber.d('Vocabulary word tapped: $word');
    // Show vocabulary definition dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(word),
        content: Text('Definition for "$word" would appear here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goToNextPage() {
    if (_currentPage < widget.story.pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeStory();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeStory() {
    Timber.i('Story completed: ${widget.story.title}');
    
    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Great Job!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You finished the story!'),
            const SizedBox(height: 16),
            Text('Vocabulary words learned: ${_encounteredVocabulary.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Stories'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentPage = 0;
                _pageController.jumpToPage(0);
              });
            },
            child: const Text('Read Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Story pages
            PageView.builder(
              controller: _pageController,
              onPageChanged: _handlePageChange,
              itemCount: widget.story.pageCount,
              itemBuilder: (context, index) {
                final page = widget.story.content.pages[index];
                return Container(
                  color: Colors.white,
                  child: StoryPageWidget(
                    page: page,
                    childAge: widget.childAge,
                    onVocabularyTap: _handleVocabularyTap,
                    showVocabularyHints: _showVocabularyHints,
                  ),
                );
              },
            ),

            // Top navigation bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // Page indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${widget.story.pageCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // Settings button
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: _showSettings,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom navigation controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    ),

                    // Progress indicator
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (_currentPage + 1) / widget.story.pageCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Next button
                    IconButton(
                      icon: Icon(
                        _currentPage < widget.story.pageCount - 1
                            ? Icons.arrow_forward_ios
                            : Icons.check,
                        color: Colors.white,
                      ),
                      onPressed: _goToNextPage,
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reading Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Vocabulary Hints'),
              subtitle: const Text('Highlight vocabulary words'),
              value: _showVocabularyHints,
              onChanged: (value) {
                setState(() {
                  _showVocabularyHints = value;
                });
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Story Info'),
              subtitle: Text(
                'Target Age: ${widget.story.metadata.targetAge[0]}-${widget.story.metadata.targetAge[1]}\n'
                'Reading Time: ${widget.story.metadata.estimatedReadTime ~/ 60} minutes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}