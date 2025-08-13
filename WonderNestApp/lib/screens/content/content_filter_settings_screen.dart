import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../models/content_model.dart';
import '../../providers/content_provider.dart';
import '../../providers/family_provider.dart';

class ContentFilterSettingsScreen extends ConsumerStatefulWidget {
  const ContentFilterSettingsScreen({super.key});

  @override
  ConsumerState<ContentFilterSettingsScreen> createState() =>
      _ContentFilterSettingsScreenState();
}

class _ContentFilterSettingsScreenState
    extends ConsumerState<ContentFilterSettingsScreen> {
  bool _requireEducational = false;
  RangeValues _ageRange = const RangeValues(3, 13);
  ContentRating _maxRating = ContentRating.all;
  int? _maxDuration;
  final Set<ContentType> _allowedTypes = {...ContentType.values};
  final Set<ContentCategory> _blockedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final filter = ref.read(contentFilterProvider);
    setState(() {
      _requireEducational = filter.requireEducational;
      // Clamp values to slider bounds (2-18)
      final minAgeValue = filter.minAge.toDouble().clamp(2.0, 18.0);
      final maxAgeValue = filter.maxAge.toDouble().clamp(2.0, 18.0);
      _ageRange = RangeValues(minAgeValue, maxAgeValue);
      _maxRating = filter.maxRating;
      _maxDuration = filter.maxDurationMinutes;
      _allowedTypes.clear();
      _allowedTypes.addAll(filter.allowedTypes);
      _blockedCategories.clear();
      _blockedCategories.addAll(filter.blockedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedChild = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Content Filters'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Selection Card
            if (selectedChild != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        selectedChild.initials,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filters for ${selectedChild.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedChild.age != null)
                            Text(
                              '${selectedChild.age} years old',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/family');
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),

            // Settings Sections
            _buildSection(
              title: 'Age Range',
              subtitle: 'Content appropriate for ages ${_ageRange.start.round()} to ${_ageRange.end.round()}',
              icon: PhosphorIcons.baby(),
              child: _buildAgeRangeSlider(theme),
            ),

            _buildSection(
              title: 'Content Rating',
              subtitle: 'Maximum allowed content rating',
              icon: PhosphorIcons.shield(),
              child: _buildRatingSelector(theme),
            ),

            _buildSection(
              title: 'Content Types',
              subtitle: 'Allow or block specific content types',
              icon: PhosphorIcons.videoCamera(),
              child: _buildContentTypeSelector(theme),
            ),

            _buildSection(
              title: 'Categories',
              subtitle: 'Block specific content categories',
              icon: PhosphorIcons.tag(),
              child: _buildCategorySelector(theme),
            ),

            _buildSection(
              title: 'Time Limits',
              subtitle: 'Maximum content duration',
              icon: PhosphorIcons.clock(),
              child: _buildDurationSelector(theme),
            ),

            _buildSection(
              title: 'Educational Content',
              subtitle: 'Require all content to be educational',
              icon: PhosphorIcons.graduationCap(),
              child: SwitchListTile(
                value: _requireEducational,
                onChanged: (value) {
                  setState(() {
                    _requireEducational = value;
                  });
                },
                title: Text(
                  _requireEducational ? 'Required' : 'Not Required',
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: Text(
                  _requireEducational
                      ? 'Only educational content will be shown'
                      : 'All appropriate content will be shown',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _saveFilters,
                  icon: Icon(PhosphorIcons.check()),
                  label: const Text('Save Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeSlider(ThemeData theme) {
    return Column(
      children: [
        RangeSlider(
          values: _ageRange,
          min: 2,
          max: 18,
          divisions: 16,
          labels: RangeLabels(
            '${_ageRange.start.round()} years',
            '${_ageRange.end.round()} years',
          ),
          onChanged: (values) {
            setState(() {
              _ageRange = values;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2 years',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${_ageRange.start.round()}-${_ageRange.end.round()} years',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '18 years',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ContentRating.values.map((rating) {
        final isSelected = rating == _maxRating;
        return ChoiceChip(
          label: Text(_getRatingLabel(rating)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _maxRating = rating;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildContentTypeSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ContentType.values.map((type) {
        final isAllowed = _allowedTypes.contains(type);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getContentTypeIcon(type),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(_getContentTypeLabel(type)),
            ],
          ),
          selected: isAllowed,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _allowedTypes.add(type);
              } else {
                _allowedTypes.remove(type);
              }
            });
          },
          backgroundColor: isAllowed ? null : theme.colorScheme.errorContainer,
          selectedColor: theme.colorScheme.primaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ContentCategory.values.map((category) {
        final isBlocked = _blockedCategories.contains(category);
        return FilterChip(
          label: Text(_getCategoryLabel(category)),
          selected: isBlocked,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _blockedCategories.add(category);
              } else {
                _blockedCategories.remove(category);
              }
            });
          },
          backgroundColor: isBlocked ? theme.colorScheme.errorContainer : null,
          selectedColor: theme.colorScheme.errorContainer,
          checkmarkColor: theme.colorScheme.onErrorContainer,
        );
      }).toList(),
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    final durations = [
      null,
      15,
      30,
      45,
      60,
      90,
      120,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((duration) {
        final isSelected = _maxDuration == duration;
        final label = duration == null
            ? 'No Limit'
            : duration < 60
                ? '$duration min'
                : '${duration ~/ 60} hr';
                
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _maxDuration = duration;
              });
            }
          },
        );
      }).toList(),
    );
  }

  String _getRatingLabel(ContentRating rating) {
    switch (rating) {
      case ContentRating.all:
        return 'All Ages';
      case ContentRating.preschool:
        return 'Preschool';
      case ContentRating.elementary:
        return 'Elementary';
      case ContentRating.preteen:
        return 'Preteen';
    }
  }

  String _getContentTypeLabel(ContentType type) {
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

  IconData _getContentTypeIcon(ContentType type) {
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
        return PhosphorIcons.puzzlePiece();
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

  void _resetFilters() {
    setState(() {
      _requireEducational = false;
      _ageRange = const RangeValues(3, 13);
      _maxRating = ContentRating.all;
      _maxDuration = null;
      _allowedTypes.clear();
      _allowedTypes.addAll(ContentType.values);
      _blockedCategories.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters reset to defaults'),
      ),
    );
  }

  void _saveFilters() {
    final filterNotifier = ref.read(contentFilterProvider.notifier);
    
    filterNotifier.updateAllowedTypes(_allowedTypes.toList());
    filterNotifier.updateAgeRange(
      _ageRange.start.round(),
      _ageRange.end.round(),
    );
    filterNotifier.updateMaxRating(_maxRating);
    filterNotifier.setRequireEducational(_requireEducational);
    filterNotifier.setMaxDuration(_maxDuration);
    
    // Update blocked categories
    for (final category in ContentCategory.values) {
      filterNotifier.toggleCategory(
        category,
        _blockedCategories.contains(category),
      );
    }
    
    // Refresh content library with new filters
    ref.read(contentLibraryProvider.notifier).refresh();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content filters saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
    
    context.pop();
  }
}