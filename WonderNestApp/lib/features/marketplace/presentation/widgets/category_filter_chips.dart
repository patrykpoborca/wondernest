// WonderNest Category Filter Chips Widget
// Provides category filtering functionality for marketplace browsing

import 'package:flutter/material.dart';

class CategoryFilterChips extends StatelessWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onSelectionChanged;
  
  static const List<CategoryItem> _categories = [
    CategoryItem('Math', Icons.calculate, Colors.blue),
    CategoryItem('Reading', Icons.menu_book, Colors.green),
    CategoryItem('Science', Icons.science, Colors.purple),
    CategoryItem('Arts', Icons.palette, Colors.orange),
    CategoryItem('Music', Icons.music_note, Colors.pink),
    CategoryItem('Language', Icons.translate, Colors.cyan),
    CategoryItem('Social Studies', Icons.public, Colors.brown),
    CategoryItem('Health', Icons.favorite, Colors.red),
    CategoryItem('Technology', Icons.computer, Colors.indigo),
    CategoryItem('Games', Icons.games, Colors.amber),
  ];

  const CategoryFilterChips({
    Key? key,
    required this.selectedCategories,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = selectedCategories.contains(category.name);
        
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 16,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : category.color,
              ),
              const SizedBox(width: 6),
              Text(category.name),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            final updatedCategories = [...selectedCategories];
            if (selected) {
              updatedCategories.add(category.name);
            } else {
              updatedCategories.remove(category.name);
            }
            onSelectionChanged(updatedCategories);
          },
          backgroundColor: category.color.withOpacity(0.1),
          selectedColor: Theme.of(context).colorScheme.secondaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
        );
      }).toList(),
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  
  const CategoryItem(this.name, this.icon, this.color);
}