import 'package:flutter/material.dart';
import '../../services/ai_recipe_service.dart';
import '../../config/app_theme.dart';
import 'allergen_warning_chip.dart';
import 'nutrition_summary_widget.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndMatch(context),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildTimeAndDifficulty(context),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildAllergenWarnings(context),
                    const Spacer(),
                    _buildNutritionSummary(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (recipe.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusL),
              ),
              child: Image.network(
                recipe.imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
              ),
            )
          else
            _buildPlaceholderImage(context),
          
          // Match percentage badge
          Positioned(
            top: AppTheme.spacingS,
            right: AppTheme.spacingS,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: _getMatchColor(recipe.matchPercentage),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Text(
                '${recipe.matchPercentage.toInt()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Action buttons for recipe book
          if (showActions)
            Positioned(
              top: AppTheme.spacingS,
              left: AppTheme.spacingS,
              child: Row(
                children: [
                  if (onShare != null) ...[
                    _buildActionButton(
                      context,
                      Icons.share,
                      onShare!,
                      'Share recipe',
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                  ],
                  if (onEdit != null) ...[
                    _buildActionButton(
                      context,
                      Icons.edit,
                      onEdit!,
                      'Edit recipe',
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                  ],
                  if (onDelete != null)
                    _buildActionButton(
                      context,
                      Icons.delete,
                      onDelete!,
                      'Delete recipe',
                      color: AppTheme.errorColor,
                    ),
                ],
              ),
            ),
          
          // Action buttons for regular recipes
          if (!showActions && (onSave != null || onShare != null))
            Positioned(
              top: AppTheme.spacingS,
              left: AppTheme.spacingS,
              child: Row(
                children: [
                  if (onShare != null) ...[
                    _buildActionButton(
                      context,
                      Icons.share,
                      onShare!,
                      'Share recipe',
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                  ],
                  if (onSave != null)
                    _buildActionButton(
                      context,
                      Icons.bookmark_add,
                      onSave!,
                      'Save recipe',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.restaurant_menu,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitleAndMatch(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          '${recipe.usedIngredients.length}/${recipe.ingredients.length} ingredients match',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndDifficulty(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          '${recipe.cookingTime} min',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: AppTheme.spacingM),
        Icon(
          _getDifficultyIcon(recipe.difficulty),
          size: 16,
          color: _getDifficultyColor(recipe.difficulty),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          recipe.difficulty.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getDifficultyColor(recipe.difficulty),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAllergenWarnings(BuildContext context) {
    if (recipe.allergens.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only high severity allergens in card
    final highSeverityAllergens = recipe.allergens
        .where((allergen) => allergen.severity == 'high')
        .take(2)
        .toList();

    if (highSeverityAllergens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppTheme.spacingXS,
      children: highSeverityAllergens
          .map((allergen) => AllergenWarningChip(
                allergen: allergen,
                size: AllergenChipSize.small,
              ))
          .toList(),
    );
  }

  Widget _buildNutritionSummary(BuildContext context) {
    return NutritionSummaryWidget(
      nutrition: recipe.nutrition,
      isCompact: true,
    );
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 80) {
      return AppTheme.successColor;
    } else if (percentage >= 60) {
      return AppTheme.warningColor;
    } else {
      return Colors.grey[600]!;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'hard':
        return AppTheme.errorColor;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    String tooltip, {
    Color? color,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 16,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }
}