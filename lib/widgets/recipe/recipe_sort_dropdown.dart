import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class RecipeSortDropdown extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const RecipeSortDropdown({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSort,
          icon: const Icon(Icons.sort),
          items: _buildSortOptions(context),
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
            }
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildSortOptions(BuildContext context) {
    return [
      DropdownMenuItem(
        value: 'match',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.percent,
              size: 16,
              color: AppTheme.successColor,
            ),
            const SizedBox(width: AppTheme.spacingS),
            const Text('Best Match'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'time',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: AppTheme.infoColor,
            ),
            const SizedBox(width: AppTheme.spacingS),
            const Text('Cooking Time'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'difficulty',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart,
              size: 16,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: AppTheme.spacingS),
            const Text('Difficulty'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'calories',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: AppTheme.spacingS),
            const Text('Calories'),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'protein',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 16,
              color: AppTheme.successColor,
            ),
            const SizedBox(width: AppTheme.spacingS),
            const Text('Protein'),
          ],
        ),
      ),
    ];
  }
}

class RecipeSortBottomSheet extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const RecipeSortBottomSheet({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

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
            'Sort Recipes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Sort options
          ..._buildSortOptions(context),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildSortOptions(BuildContext context) {
    final sortOptions = [
      _SortOption(
        value: 'match',
        title: 'Best Match',
        subtitle: 'Recipes with most matching ingredients',
        icon: Icons.percent,
        color: AppTheme.successColor,
      ),
      _SortOption(
        value: 'time',
        title: 'Cooking Time',
        subtitle: 'Fastest recipes first',
        icon: Icons.access_time,
        color: AppTheme.infoColor,
      ),
      _SortOption(
        value: 'difficulty',
        title: 'Difficulty',
        subtitle: 'Easiest recipes first',
        icon: Icons.bar_chart,
        color: AppTheme.warningColor,
      ),
      _SortOption(
        value: 'calories',
        title: 'Calories',
        subtitle: 'Lowest calories first',
        icon: Icons.local_fire_department,
        color: AppTheme.errorColor,
      ),
      _SortOption(
        value: 'protein',
        title: 'Protein',
        subtitle: 'Highest protein first',
        icon: Icons.fitness_center,
        color: AppTheme.successColor,
      ),
    ];

    return sortOptions.map((option) => _buildSortTile(context, option)).toList();
  }

  Widget _buildSortTile(BuildContext context, _SortOption option) {
    final isSelected = selectedSort == option.value;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: option.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Icon(
          option.icon,
          color: option.color,
          size: 20,
        ),
      ),
      title: Text(
        option.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? option.color : null,
        ),
      ),
      subtitle: Text(
        option.subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: option.color,
            )
          : null,
      onTap: () {
        onSortChanged(option.value);
        Navigator.of(context).pop();
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      tileColor: isSelected ? option.color.withValues(alpha: 0.05) : null,
    );
  }
}

class _SortOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SortOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}