import 'package:flutter/material.dart';
import '../../services/ai_recipe_service.dart';
import '../../config/app_theme.dart';

enum AllergenChipSize { small, medium, large }

class AllergenWarningChip extends StatelessWidget {
  final Allergen allergen;
  final AllergenChipSize size;
  final VoidCallback? onTap;

  const AllergenWarningChip({
    super.key,
    required this.allergen,
    this.size = AllergenChipSize.medium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = _getSeverityColor(allergen.severity);
    final chipSize = _getChipSize();
    
    return GestureDetector(
      onTap: onTap ?? () => _showAllergenDetails(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: chipSize.horizontal,
          vertical: chipSize.vertical,
        ),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.1),
          border: Border.all(color: chipColor, width: 1),
          borderRadius: BorderRadius.circular(chipSize.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getAllergenIcon(allergen.name),
              size: chipSize.iconSize,
              color: chipColor,
            ),
            SizedBox(width: chipSize.spacing),
            Text(
              allergen.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
                fontSize: chipSize.fontSize,
              ),
            ),
            if (size != AllergenChipSize.small) ...[
              SizedBox(width: chipSize.spacing),
              Icon(
                _getSeverityIcon(allergen.severity),
                size: chipSize.iconSize * 0.8,
                color: chipColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ChipSize _getChipSize() {
    switch (size) {
      case AllergenChipSize.small:
        return const _ChipSize(
          horizontal: 6,
          vertical: 2,
          borderRadius: 8,
          iconSize: 12,
          fontSize: 10,
          spacing: 2,
        );
      case AllergenChipSize.medium:
        return const _ChipSize(
          horizontal: 8,
          vertical: 4,
          borderRadius: 10,
          iconSize: 14,
          fontSize: 11,
          spacing: 4,
        );
      case AllergenChipSize.large:
        return const _ChipSize(
          horizontal: 12,
          vertical: 6,
          borderRadius: 12,
          iconSize: 16,
          fontSize: 12,
          spacing: 6,
        );
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.infoColor;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getAllergenIcon(String allergenName) {
    switch (allergenName.toLowerCase()) {
      case 'dairy':
      case 'milk':
        return Icons.local_drink;
      case 'nuts':
      case 'tree nuts':
      case 'peanuts':
        return Icons.eco;
      case 'gluten':
      case 'wheat':
        return Icons.grain;
      case 'shellfish':
      case 'seafood':
        return Icons.set_meal;
      case 'eggs':
        return Icons.egg;
      case 'soy':
      case 'soybeans':
        return Icons.grass;
      case 'fish':
        return Icons.phishing;
      case 'sesame':
        return Icons.circle;
      default:
        return Icons.warning;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.info;
      default:
        return Icons.help_outline;
    }
  }

  void _showAllergenDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAllergenIcon(allergen.name),
              color: _getSeverityColor(allergen.severity),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(allergen.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Severity: ',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(allergen.severity).withValues(alpha: 0.1),
                    border: Border.all(color: _getSeverityColor(allergen.severity)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    allergen.severity.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getSeverityColor(allergen.severity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              allergen.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Please consult with a healthcare professional if you have severe allergies.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ChipSize {
  final double horizontal;
  final double vertical;
  final double borderRadius;
  final double iconSize;
  final double fontSize;
  final double spacing;

  const _ChipSize({
    required this.horizontal,
    required this.vertical,
    required this.borderRadius,
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
  });
}

class AllergenWarningList extends StatelessWidget {
  final List<Allergen> allergens;
  final AllergenChipSize chipSize;
  final int? maxItems;
  final VoidCallback? onShowAll;

  const AllergenWarningList({
    super.key,
    required this.allergens,
    this.chipSize = AllergenChipSize.medium,
    this.maxItems,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    if (allergens.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayAllergens = maxItems != null && allergens.length > maxItems!
        ? allergens.take(maxItems!).toList()
        : allergens;

    final hasMore = maxItems != null && allergens.length > maxItems!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allergen Warnings',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: [
            ...displayAllergens.map((allergen) => AllergenWarningChip(
                  allergen: allergen,
                  size: chipSize,
                )),
            if (hasMore)
              GestureDetector(
                onTap: onShowAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Text(
                    '+${allergens.length - maxItems!} more',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}