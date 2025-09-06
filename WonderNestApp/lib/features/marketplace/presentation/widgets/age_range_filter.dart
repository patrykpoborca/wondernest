// WonderNest Age Range Filter Widget
// Provides age-appropriate filtering for educational content

import 'package:flutter/material.dart';

class AgeRangeFilter extends StatelessWidget {
  final RangeValues ageRange;
  final Function(RangeValues) onChanged;
  
  const AgeRangeFilter({
    Key? key,
    required this.ageRange,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Range: ${ageRange.start.round()} - ${ageRange.end.round()} years',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: ageRange,
          min: 2,
          max: 18,
          divisions: 16,
          labels: RangeLabels(
            '${ageRange.start.round()} years',
            '${ageRange.end.round()} years',
          ),
          onChanged: onChanged,
        ),
        
        // Age Group Quick Selectors
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildAgeGroupChip(
              context,
              'Toddler (2-4)',
              const RangeValues(2, 4),
            ),
            _buildAgeGroupChip(
              context,
              'Preschool (3-5)',
              const RangeValues(3, 5),
            ),
            _buildAgeGroupChip(
              context,
              'Elementary (6-10)',
              const RangeValues(6, 10),
            ),
            _buildAgeGroupChip(
              context,
              'Middle School (11-13)',
              const RangeValues(11, 13),
            ),
            _buildAgeGroupChip(
              context,
              'High School (14-18)',
              const RangeValues(14, 18),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAgeGroupChip(BuildContext context, String label, RangeValues range) {
    final isSelected = ageRange.start == range.start && ageRange.end == range.end;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onChanged(range);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}