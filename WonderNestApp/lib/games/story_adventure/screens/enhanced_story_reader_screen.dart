import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TransformationController _transformationController;
  int _currentPage = 0;
  bool _showVocabularyHints = true;
  bool _isFullscreen = false;
  // bool _isLandscape = false; // Currently not used but kept for potential future features
  final Set<String> _encounteredVocabulary = {};
  DateTime? _startTime;
  
  // Default story dimensions (assumed from web builder)
  static const double _defaultStoryWidth = 1200.0;
  static const double _defaultStoryHeight = 800.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _transformationController = TransformationController();
    _startTime = DateTime.now();
    Timber.i('Starting story: ${widget.story.title}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    
    // Restore system UI if it was hidden
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
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

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      // Hide system UI for fullscreen experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      // Restore system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
    Timber.d('Fullscreen toggled: $_isFullscreen');
  }
  
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    Timber.d('Zoom reset to identity matrix (letterboxed view)');
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
    return OrientationBuilder(
      builder: (context, orientation) {
        // Track orientation for potential future features
        final isLandscape = orientation == Orientation.landscape;
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: _isFullscreen ? _buildFullscreenView() : _buildNormalView(),
        );
      },
    );
  }
  
  Widget _buildFullscreenView() {
    return Stack(
      children: [
        // Fullscreen story content
        _buildStoryContent(isFullscreen: true),
        
        // Minimal controls overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.refresh,
                onPressed: _resetZoom,
                tooltip: 'Reset zoom',
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                icon: Icons.fullscreen_exit,
                onPressed: _toggleFullscreen,
                tooltip: 'Exit fullscreen',
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        
        // Page navigation in fullscreen
        _buildFullscreenNavigation(),
      ],
    );
  }
  
  Widget _buildNormalView() {
    return SafeArea(
      child: Stack(
        children: [
          // Story content with controls
          _buildStoryContent(isFullscreen: false),
          
          // Top navigation bar
          _buildTopNavigationBar(),
          
          // Bottom navigation controls
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }
  
  Widget _buildStoryContent({required bool isFullscreen}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PageView.builder(
          controller: _pageController,
          onPageChanged: _handlePageChange,
          itemCount: widget.story.pageCount,
          itemBuilder: (context, index) {
            final page = widget.story.content.pages[index];
            
            // Calculate scaling options
            final scaleX = constraints.maxWidth / _defaultStoryWidth;
            final scaleY = constraints.maxHeight / _defaultStoryHeight;
            final containScale = scaleX < scaleY ? scaleX : scaleY; // Fit entire image (may letterbox)
            final coverScale = scaleX > scaleY ? scaleX : scaleY;   // Fill entire screen edge-to-edge
            
            // Start with contain scale to show full image initially
            final initialScale = containScale;
            
            // Calculate dimensions at various scales
            final initialWidth = _defaultStoryWidth * initialScale;
            final initialHeight = _defaultStoryHeight * initialScale;
            final coverWidth = _defaultStoryWidth * coverScale;
            final coverHeight = _defaultStoryHeight * coverScale;
            
            // Max scale should allow zooming well beyond cover scale for detailed viewing
            final maxScale = (coverScale / initialScale) * 2.0; // 2x beyond cover scale
            final minScale = 0.8; // Allow slight zoom out from initial view
            
            // Calculate boundary margins that allow full panning of the zoomed content
            // We need to ensure the user can pan to see all edges of the 1200x800 canvas
            final maxContentWidth = _defaultStoryWidth * initialScale * maxScale;
            final maxContentHeight = _defaultStoryHeight * initialScale * maxScale;
            
            // Margins should allow the content to be positioned so that any edge can be at the screen edge
            final horizontalMargin = (maxContentWidth - constraints.maxWidth) / 2 + constraints.maxWidth * 0.1;
            final verticalMargin = (maxContentHeight - constraints.maxHeight) / 2 + constraints.maxHeight * 0.1;
            
            Timber.d('Story viewer enhanced - Screen: ${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}, '
                    'Content: ${_defaultStoryWidth.toInt()}x${_defaultStoryHeight.toInt()}, '
                    'Contain scale: ${containScale.toStringAsFixed(2)}, Cover scale: ${coverScale.toStringAsFixed(2)}, '
                    'Initial size: ${initialWidth.toInt()}x${initialHeight.toInt()}, '
                    'Cover size: ${coverWidth.toInt()}x${coverHeight.toInt()}, '
                    'Max scale: ${maxScale.toStringAsFixed(2)}');
            
            return Container(
              color: Colors.black, // Black background
              child: InteractiveViewer(
                transformationController: _transformationController,
                // Set boundary margins to allow full panning of zoomed content
                boundaryMargin: EdgeInsets.symmetric(
                  horizontal: horizontalMargin,
                  vertical: verticalMargin,
                ),
                minScale: minScale,
                maxScale: maxScale,
                constrained: false, // Allow content to extend beyond screen bounds
                panEnabled: true,
                scaleEnabled: true,
                clipBehavior: Clip.hardEdge,
                onInteractionStart: (details) {
                  HapticFeedback.lightImpact();
                },
                onInteractionEnd: (details) {
                  // Log final transformation for debugging
                  final transform = _transformationController.value;
                  final scale = transform.getMaxScaleOnAxis();
                  Timber.d('Interaction ended - Scale: ${scale.toStringAsFixed(2)}');
                },
                child: GestureDetector(
                  onDoubleTap: () {
                    // Double tap cycles through: contain -> cover -> contain
                    final currentScale = _transformationController.value.getMaxScaleOnAxis();
                    
                    if (currentScale <= minScale * 1.1) {
                      // Currently at minimum, zoom to cover (edge-to-edge)
                      final targetScale = coverScale / initialScale;
                      
                      // Calculate centering offset
                      final offsetX = (constraints.maxWidth - coverWidth) / 2;
                      final offsetY = (constraints.maxHeight - coverHeight) / 2;
                      
                      _transformationController.value = Matrix4.identity()
                        ..translate(offsetX, offsetY)
                        ..scale(targetScale);
                      
                      Timber.d('Double tap: zoomed to cover scale (${targetScale.toStringAsFixed(2)})');
                    } else {
                      // Reset to initial contain view
                      _resetZoom();
                      Timber.d('Double tap: reset to contain scale');
                    }
                    
                    HapticFeedback.mediumImpact();
                  },
                  child: SizedBox(
                    // Use exact story dimensions scaled to initial size
                    width: initialWidth,
                    height: initialHeight,
                    child: ScaledStoryPageWidget(
                      page: page,
                      childAge: widget.childAge,
                      onVocabularyTap: _handleVocabularyTap,
                      showVocabularyHints: _showVocabularyHints,
                      scaleFactor: initialScale,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(isLarge ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isLarge ? 28 : 20),
          onTap: () {
            HapticFeedback.lightImpact(); // Haptic feedback for children
            onPressed();
          },
          child: Padding(
            padding: EdgeInsets.all(isLarge ? 16 : 12),
            child: Icon(
              icon, 
              color: Colors.white, 
              size: isLarge ? 28 : 20,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFullscreenNavigation() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button - larger for fullscreen
          _buildControlButton(
            icon: Icons.arrow_back_ios,
            onPressed: _currentPage > 0 ? _goToPreviousPage : () {},
            tooltip: 'Previous page',
            isLarge: true,
          ),
          
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_currentPage + 1} / ${widget.story.pageCount}',
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 18, 
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Next button - larger for fullscreen
          _buildControlButton(
            icon: _currentPage < widget.story.pageCount - 1
                ? Icons.arrow_forward_ios
                : Icons.check_circle,
            onPressed: _goToNextPage,
            tooltip: _currentPage < widget.story.pageCount - 1 
                ? 'Next page' 
                : 'Complete story',
            isLarge: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopNavigationBar() {
    if (_isFullscreen) return const SizedBox.shrink();
    
    return Positioned(
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

            // Page indicator and controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reset zoom button
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _resetZoom,
                  tooltip: 'Reset zoom',
                ),
                
                // Fullscreen toggle
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                  tooltip: _isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
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
              ],
            ),

            // Settings button
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showSettings,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    if (_isFullscreen) return const SizedBox.shrink();
    
    return Positioned(
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
            SwitchListTile(
              title: const Text('Fullscreen Mode'),
              subtitle: const Text('Immersive reading experience'),
              value: _isFullscreen,
              onChanged: (value) {
                _toggleFullscreen();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Zoom'),
              subtitle: const Text('Return to original size or double-tap the story'),
              onTap: () {
                _resetZoom();
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.touch_app, color: Colors.blue),
              title: Text('How to Read'),
              subtitle: Text('• Pinch to zoom in/out\\n• Drag to move around\\n• Double-tap to reset zoom\\n• Swipe or use arrows to change pages'),
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