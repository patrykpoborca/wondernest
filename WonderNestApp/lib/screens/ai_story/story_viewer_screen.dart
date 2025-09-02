import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ai_story.dart';
import '../../providers/ai_story_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final AIStory story;
  
  const StoryViewerScreen({
    super.key,
    required this.story,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _saveToLibrary() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      await ref.read(aiStoryProvider.notifier).saveStoryToLibrary(widget.story);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story saved to library!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  Widget _buildStoryContent() {
    if (widget.story.chapters.isEmpty) {
      // Single page story
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story Title
            Text(
              widget.story.title,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn().slideX(),
            
            const SizedBox(height: 16),
            
            // Story Image if available
            if (widget.story.imageUrls.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.story.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.auto_stories,
                          size: 64,
                          color: AppColors.primaryBlue.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
            
            // Story Content
            Text(
              widget.story.content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.8,
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 32),
            
            // Story Metadata
            _buildMetadata(),
          ],
        ),
      );
    } else {
      // Multi-chapter story with pages
      return PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.story.chapters.length + 1, // +1 for title page
        itemBuilder: (context, index) {
          if (index == 0) {
            // Title page
            return _buildTitlePage();
          } else {
            // Chapter pages
            final chapter = widget.story.chapters[index - 1];
            return _buildChapterPage(chapter);
          }
        },
      );
    }
  }
  
  Widget _buildTitlePage() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.1),
            AppColors.backgroundLight,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 80,
            color: AppColors.primaryBlue,
          ).animate().fadeIn().scale(),
          
          const SizedBox(height: 24),
          
          Text(
            widget.story.title,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 16),
          
          if (widget.story.metadata.themes.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: widget.story.metadata.themes.map((theme) {
                return Chip(
                  label: Text(
                    theme,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.accentGreen.withValues(alpha: 0.2),
                );
              }).toList(),
            ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 32),
          
          Text(
            'Age ${widget.story.metadata.ageRange}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 500.ms),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.story.estimatedReadingMinutes} min read',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 48),
          
          Text(
            'Swipe to begin →',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).fadeIn(delay: 800.ms).slideX(begin: -0.1, end: 0.1),
        ],
      ),
    );
  }
  
  Widget _buildChapterPage(StoryChapter chapter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter Title
          Text(
            chapter.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn().slideX(),
          
          const SizedBox(height: 16),
          
          // Chapter Image if available
          if (chapter.imageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  chapter.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: AppColors.primaryBlue.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
          
          // Chapter Content
          Text(
            chapter.content,
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
  
  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Story Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildMetadataRow(
            Icons.child_care,
            'Age Range',
            widget.story.metadata.ageRange,
          ),
          
          if (widget.story.metadata.educationalGoals.isNotEmpty)
            _buildMetadataRow(
              Icons.school,
              'Educational Goals',
              widget.story.metadata.educationalGoals.join(', '),
            ),
          
          if (widget.story.metadata.themes.isNotEmpty)
            _buildMetadataRow(
              Icons.category,
              'Themes',
              widget.story.metadata.themes.join(', '),
            ),
          
          _buildMetadataRow(
            Icons.access_time,
            'Reading Time',
            '${widget.story.estimatedReadingMinutes} minutes',
          ),
          
          if (widget.story.metadata.safetyScore != null)
            _buildMetadataRow(
              Icons.security,
              'Safety Score',
              '${(widget.story.metadata.safetyScore! * 100).toStringAsFixed(0)}%',
            ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
  
  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final hasChapters = widget.story.chapters.isNotEmpty;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Story Viewer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.bookmark_border),
            onPressed: _isSaving ? null : _saveToLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildStoryContent(),
          
          // Page indicator for multi-chapter stories
          if (hasChapters)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.story.chapters.length + 1,
                  (index) => Container(
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)),
                ),
              ),
            ),
          
          // Navigation buttons for chapters
          if (hasChapters && _currentPage > 0)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          
          if (hasChapters && _currentPage < widget.story.chapters.length)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
        ],
      ),
      
      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/ai-story-creator');
                  },
                  icon: const Icon(Icons.create),
                  label: const Text('Create Another'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primaryBlue),
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to child's library
                    context.go('/child-home');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Library'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}