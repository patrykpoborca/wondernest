import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ai_story_provider.dart';
import '../../providers/content_pack_provider.dart';

class AIStoryCreatorScreen extends ConsumerStatefulWidget {
  const AIStoryCreatorScreen({super.key});

  @override
  ConsumerState<AIStoryCreatorScreen> createState() => _AIStoryCreatorScreenState();
}

class _AIStoryCreatorScreenState extends ConsumerState<AIStoryCreatorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final List<String> _selectedImageIds = [];
  String _selectedAgeRange = '3-5';
  final List<String> _selectedEducationalGoals = [];
  final List<String> _selectedCharacterPacks = [];
  bool _isGenerating = false;

  final List<String> _ageRanges = ['3-5', '6-8', '9-12'];
  final List<String> _educationalGoals = [
    'Problem Solving',
    'Friendship',
    'Creativity',
    'Science',
    'Math',
    'Reading',
    'Social Skills',
    'Emotional Intelligence',
    'Environmental Awareness',
    'Cultural Diversity',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentPackProvider.notifier).loadOwnedPacks();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateStory() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a story prompt')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final story = await ref.read(aiStoryProvider.notifier).generateStory(
        prompt: _promptController.text,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        imageIds: _selectedImageIds,
        ageRange: _selectedAgeRange,
        educationalGoals: _selectedEducationalGoals,
        characterPackIds: _selectedCharacterPacks,
      );

      if (mounted && story != null) {
        // Navigate to story viewer with the generated story
        context.push('/story-viewer', extra: story);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Add file upload provider when implemented
    final uploadedFiles = []; // Temporarily empty

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'AI Story Creator',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section
                Text(
                  'Create a Magical Story',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn().slideX(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Use AI to generate personalized stories for your children',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                
                const SizedBox(height: 24),
                
                // Story Title (Optional)
                _buildSectionTitle('Story Title (Optional)'),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Give your story a title...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.title, color: AppColors.primaryBlue),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 24),
                
                // Story Prompt
                _buildSectionTitle('Story Prompt *'),
                TextField(
                  controller: _promptController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe your story idea...\nExample: "A brave little fox who learns to fly with the help of magical butterflies"',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.auto_stories, color: AppColors.primaryBlue),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 24),
                
                // Age Range Selection
                _buildSectionTitle('Age Range'),
                Wrap(
                  spacing: 8,
                  children: _ageRanges.map((range) {
                    final isSelected = _selectedAgeRange == range;
                    return ChoiceChip(
                      label: Text(
                        '$range years',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          _selectedAgeRange = range;
                        });
                      },
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 24),
                
                // Educational Goals
                _buildSectionTitle('Educational Goals (Optional)'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _educationalGoals.map((goal) {
                    final isSelected = _selectedEducationalGoals.contains(goal);
                    return FilterChip(
                      label: Text(
                        goal,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.accentGreen,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedEducationalGoals.add(goal);
                          } else {
                            _selectedEducationalGoals.remove(goal);
                          }
                        });
                      },
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 500.ms),
                
                const SizedBox(height: 24),
                
                // Character Pack Selection
                _buildCharacterPackSection(),
                
                const SizedBox(height: 24),
                
                // Image Selection
                _buildSectionTitle('Add Images (Optional)'),
                Text(
                  'Select uploaded images to include in your story',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (uploadedFiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No images uploaded yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              context.push('/parent-dashboard');
                            },
                            child: const Text('Upload Images'),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms)
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: uploadedFiles.length,
                      itemBuilder: (context, index) {
                        final file = uploadedFiles[index];
                        final isSelected = _selectedImageIds.contains(file.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedImageIds.remove(file.id);
                                } else {
                                  _selectedImageIds.add(file.id);
                                }
                              });
                            },
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                    ? AppColors.primaryBlue 
                                    : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.network(
                                      file.url,
                                      width: 100,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.backgroundLight,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: AppColors.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 700 + (index * 50))),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isGenerating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Creating Your Story...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Generate Story',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isGenerating)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Creating Magic...',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Create AI Stories',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                '1. Story Prompt',
                'Describe your story idea. Be creative! The AI will expand on your ideas.',
              ),
              _buildHelpItem(
                '2. Age Range',
                'Select the appropriate age group to ensure the story language and themes are suitable.',
              ),
              _buildHelpItem(
                '3. Educational Goals',
                'Choose learning objectives to incorporate educational content naturally into the story.',
              ),
              _buildHelpItem(
                '4. Images',
                'Add your uploaded images to have them included as characters or settings in the story.',
              ),
              _buildHelpItem(
                '5. Generate',
                'Click generate and wait for your personalized story to be created!',
              ),
            ],
          ),
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

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterPackSection() {
    final contentPackState = ref.watch(contentPackProvider);
    final characterPacks = contentPackState.ownedPacks
        .where((pack) => pack.packType == 'characterBundle')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Character Packs (Optional)'),
        Text(
          'Select character packs to include characters in your story',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (contentPackState.isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
            ),
          )
        else if (characterPacks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No character packs owned yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.push('/content-packs');
                    },
                    child: const Text('Browse Character Packs'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: characterPacks.length,
              itemBuilder: (context, index) {
                final pack = characterPacks[index];
                final isSelected = _selectedCharacterPacks.contains(pack.id);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCharacterPacks.remove(pack.id);
                        } else {
                          _selectedCharacterPacks.add(pack.id);
                        }
                      });
                    },
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? AppColors.accentGreen
                            : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              width: 100,
                              height: 120,
                              color: AppColors.backgroundLight,
                              child: pack.thumbnailUrl != null
                                ? Image.network(
                                    pack.thumbnailUrl!,
                                    width: 100,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.backgroundLight,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.people,
                                              color: AppColors.textSecondary,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              pack.name,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        color: AppColors.textSecondary,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          pack.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pack.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 600 + (index * 50))),
                );
              },
            ),
          ),
      ],
    );
  }
}