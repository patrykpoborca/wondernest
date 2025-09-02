import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/services/timber_wrapper.dart';

/// Widget for inputting and managing tags
class TagInputWidget extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final List<String> suggestions;
  final bool isRequired;
  final int minimumTags;
  final String? helperText;
  final bool enabled;

  const TagInputWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.suggestions = const [],
    this.isRequired = true,
    this.minimumTags = 2,
    this.helperText,
    this.enabled = true,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _currentTags = [];
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  // Common tag suggestions
  static const List<String> _defaultSuggestions = [
    // Animals
    'animal', 'bird', 'dog', 'cat', 'fish', 'butterfly', 'dinosaur',
    // Colors
    'red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'black', 'white', 'brown',
    // Sizes
    'big', 'small', 'tiny', 'large', 'medium',
    // Nature
    'tree', 'flower', 'sun', 'moon', 'star', 'cloud', 'mountain', 'ocean', 'river', 'forest',
    // Objects
    'car', 'truck', 'airplane', 'train', 'boat', 'house', 'building', 'toy', 'ball', 'book',
    // People
    'person', 'child', 'family', 'friend', 'baby',
    // Actions
    'running', 'jumping', 'playing', 'sleeping', 'eating', 'flying', 'swimming',
    // Emotions
    'happy', 'sad', 'excited', 'calm', 'funny',
    // Descriptive
    'colorful', 'bright', 'dark', 'shiny', 'soft', 'rough', 'smooth',
  ];

  @override
  void initState() {
    super.initState();
    _currentTags = List.from(widget.tags);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.toLowerCase().trim();
    if (text.isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Filter suggestions based on input
    final allSuggestions = [
      ...widget.suggestions,
      ..._defaultSuggestions,
    ].where((tag) => !_currentTags.contains(tag)).toList();

    setState(() {
      _filteredSuggestions = allSuggestions
          .where((tag) => tag.toLowerCase().startsWith(text))
          .take(8)
          .toList();
      _showSuggestions = _filteredSuggestions.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _addTag(String tag) {
    final normalizedTag = tag.toLowerCase().trim();
    
    // Validate tag
    if (normalizedTag.isEmpty) return;
    if (_currentTags.contains(normalizedTag)) {
      _showSnackBar('Tag already added');
      return;
    }
    if (normalizedTag.length > 50) {
      _showSnackBar('Tag too long (max 50 characters)');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9-_]+$').hasMatch(normalizedTag)) {
      _showSnackBar('Tags can only contain letters, numbers, hyphens and underscores');
      return;
    }

    setState(() {
      _currentTags.add(normalizedTag);
      _controller.clear();
      _showSuggestions = false;
    });
    
    widget.onTagsChanged(_currentTags);
    Timber.d('Added tag: $normalizedTag');
  }

  void _removeTag(String tag) {
    setState(() {
      _currentTags.remove(tag);
    });
    widget.onTagsChanged(_currentTags);
    Timber.d('Removed tag: $tag');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _hasMinimumTags => !widget.isRequired || _currentTags.length >= widget.minimumTags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: 'Add tags',
            hintText: 'Type a tag and press enter',
            helperText: widget.helperText ?? 
              'Add at least ${widget.minimumTags} tags to describe this image',
            helperStyle: TextStyle(
              color: _hasMinimumTags ? Colors.grey : Colors.orange,
            ),
            prefixIcon: const Icon(Icons.label_outline),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => _addTag(_controller.text),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: !_hasMinimumTags && _currentTags.isNotEmpty
                ? 'Add at least ${widget.minimumTags} tags'
                : null,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-_\s]')),
            LengthLimitingTextInputFormatter(50),
          ],
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _addTag(value);
            }
          },
        ),
        
        // Suggestions dropdown
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.label, size: 16),
                  title: Text(suggestion),
                  onTap: () {
                    _addTag(suggestion);
                    _focusNode.requestFocus();
                  },
                );
              },
            ),
          ),
        ],
        
        // Current tags
        if (_currentTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: widget.enabled ? () => _removeTag(tag) : null,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
        
        // Tag count indicator
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _hasMinimumTags ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: _hasMinimumTags ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              '${_currentTags.length} tag${_currentTags.length != 1 ? 's' : ''} added',
              style: TextStyle(
                fontSize: 12,
                color: _hasMinimumTags ? Colors.green : Colors.orange,
              ),
            ),
            if (!_hasMinimumTags) ...[
              Text(
                ' (${widget.minimumTags - _currentTags.length} more needed)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        
        // Popular tags section
        const SizedBox(height: 16),
        Text(
          'Popular tags:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _defaultSuggestions
              .where((tag) => !_currentTags.contains(tag))
              .take(12)
              .map((tag) {
            return ActionChip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              onPressed: widget.enabled ? () => _addTag(tag) : null,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            );
          }).toList(),
        ),
      ],
    );
  }
}