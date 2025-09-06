// WonderNest Search Bar Widget
// Provides search functionality for marketplace content

import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final String hintText;
  final bool showVoiceSearch;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.hintText = 'Search educational content...',
    this.showVoiceSearch = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clear button
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
              
              // Voice search button (placeholder for future implementation)
              if (showVoiceSearch)
                IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    // TODO: Implement voice search
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice search coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}