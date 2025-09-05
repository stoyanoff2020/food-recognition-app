import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class RecipeFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const RecipeFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(context, 'all', 'All Recipes'),
          const SizedBox(width: AppTheme.spacingS),
          _buildFilterChip(context, 'easy', 'Easy'),
          const SizedBox(width: AppTheme.spacingS),
          _buildFilterChip(context, 'medium', 'Medium'),
          const SizedBox(width: AppTheme.spacingS),
          _buildFilterChip(context, 'hard', 'Hard'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String value, String label) {
    final isSelected = selectedFilter == value;
    final color = _getFilterColor(value);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onFilterChanged(value),
      backgroundColor: Colors.grey[100],
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'easy':
        return AppTheme.successColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'hard':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}

class AdvancedRecipeFilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final ValueChanged<Map<String, dynamic>> onFiltersChanged;

  const AdvancedRecipeFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedRecipeFilterSheet> createState() => _AdvancedRecipeFilterSheetState();
}

class _AdvancedRecipeFilterSheetState extends State<AdvancedRecipeFilterSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Title
          Text(
            'Filter Recipes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Cooking Time Filter
          _buildCookingTimeFilter(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Dietary Restrictions
          _buildDietaryRestrictionsFilter(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Allergen Filter
          _buildAllergenFilter(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Nutrition Filter
          _buildNutritionFilter(),
          const SizedBox(height: AppTheme.spacingXL),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildCookingTimeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cooking Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        RangeSlider(
          values: RangeValues(
            (_filters['minTime'] as double?) ?? 0,
            (_filters['maxTime'] as double?) ?? 120,
          ),
          min: 0,
          max: 120,
          divisions: 24,
          labels: RangeLabels(
            '${(_filters['minTime'] as double?) ?? 0} min',
            '${(_filters['maxTime'] as double?) ?? 120} min',
          ),
          onChanged: (values) {
            setState(() {
              _filters['minTime'] = values.start;
              _filters['maxTime'] = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDietaryRestrictionsFilter() {
    final restrictions = ['vegetarian', 'vegan', 'gluten-free', 'dairy-free', 'keto', 'paleo'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Restrictions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: restrictions.map((restriction) {
            final isSelected = (_filters['dietaryRestrictions'] as List<String>?)
                ?.contains(restriction) ?? false;
            
            return FilterChip(
              label: Text(restriction.replaceAll('-', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final restrictions = (_filters['dietaryRestrictions'] as List<String>?) ?? <String>[];
                  if (selected) {
                    restrictions.add(restriction);
                  } else {
                    restrictions.remove(restriction);
                  }
                  _filters['dietaryRestrictions'] = restrictions;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllergenFilter() {
    final allergens = ['nuts', 'dairy', 'gluten', 'shellfish', 'eggs', 'soy'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exclude Allergens',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: allergens.map((allergen) {
            final isSelected = (_filters['excludeAllergens'] as List<String>?)
                ?.contains(allergen) ?? false;
            
            return FilterChip(
              label: Text(allergen.toUpperCase()),
              selected: isSelected,
              selectedColor: AppTheme.errorColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.errorColor,
              onSelected: (selected) {
                setState(() {
                  final allergens = (_filters['excludeAllergens'] as List<String>?) ?? <String>[];
                  if (selected) {
                    allergens.add(allergen);
                  } else {
                    allergens.remove(allergen);
                  }
                  _filters['excludeAllergens'] = allergens;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNutritionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Goals',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        
        // Max Calories
        Text(
          'Max Calories: ${(_filters['maxCalories'] as double?)?.toInt() ?? 1000}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: (_filters['maxCalories'] as double?) ?? 1000,
          min: 100,
          max: 1000,
          divisions: 18,
          onChanged: (value) {
            setState(() {
              _filters['maxCalories'] = value;
            });
          },
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // High Protein Toggle
        SwitchListTile(
          title: const Text('High Protein (>20g)'),
          value: (_filters['highProtein'] as bool?) ?? false,
          onChanged: (value) {
            setState(() {
              _filters['highProtein'] = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        
        // Low Carb Toggle
        SwitchListTile(
          title: const Text('Low Carb (<30g)'),
          value: (_filters['lowCarb'] as bool?) ?? false,
          onChanged: (value) {
            setState(() {
              _filters['lowCarb'] = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'minTime': 0.0,
        'maxTime': 120.0,
        'dietaryRestrictions': <String>[],
        'excludeAllergens': <String>[],
        'maxCalories': 1000.0,
        'highProtein': false,
        'lowCarb': false,
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }
}