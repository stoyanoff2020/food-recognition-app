import 'package:flutter/material.dart';
import '../../services/ai_recipe_service.dart';
import '../../models/app_state.dart';
import '../../config/app_theme.dart';

class NutritionSummaryWidget extends StatelessWidget {
  final NutritionInfo nutrition;
  final bool isCompact;
  final bool showDetails;

  const NutritionSummaryWidget({
    super.key,
    required this.nutrition,
    this.isCompact = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView(context);
    } else {
      return _buildDetailedView(context);
    }
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            '${nutrition.calories} cal',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationS,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: Theme.of(context).nutritionColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Nutrition Facts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Per ${nutrition.servingSize}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildNutritionGrid(context),
            if (showDetails) ...[
              const SizedBox(height: AppTheme.spacingM),
              _buildDetailedNutrients(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: AppTheme.spacingS,
      mainAxisSpacing: AppTheme.spacingS,
      children: [
        _buildNutrientCard(
          context,
          'Calories',
          '${nutrition.calories}',
          'kcal',
          Icons.local_fire_department,
          AppTheme.errorColor,
        ),
        _buildNutrientCard(
          context,
          'Protein',
          nutrition.protein.toStringAsFixed(1),
          'g',
          Icons.fitness_center,
          AppTheme.successColor,
        ),
        _buildNutrientCard(
          context,
          'Carbs',
          nutrition.carbohydrates.toStringAsFixed(1),
          'g',
          Icons.grain,
          AppTheme.warningColor,
        ),
        _buildNutrientCard(
          context,
          'Fat',
          nutrition.fat.toStringAsFixed(1),
          'g',
          Icons.opacity,
          AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildNutrientCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$value$unit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedNutrients(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Nutrients',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        _buildNutrientRow(context, 'Fiber', nutrition.fiber, 'g'),
        _buildNutrientRow(context, 'Sugar', nutrition.sugar, 'g'),
        _buildNutrientRow(context, 'Sodium', nutrition.sodium, 'mg'),
      ],
    );
  }

  Widget _buildNutrientRow(BuildContext context, String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class NutritionVisualizationWidget extends StatelessWidget {
  final NutritionInfo nutrition;
  final NutritionGoals? goals;

  const NutritionVisualizationWidget({
    super.key,
    required this.nutrition,
    this.goals,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationS,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildMacronutrientChart(context),
            if (goals != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              _buildGoalProgress(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacronutrientChart(BuildContext context) {
    final totalMacros = nutrition.protein + nutrition.carbohydrates + nutrition.fat;
    
    if (totalMacros == 0) {
      return const Text('No macronutrient data available');
    }

    final proteinPercentage = (nutrition.protein / totalMacros) * 100;
    final carbPercentage = (nutrition.carbohydrates / totalMacros) * 100;
    final fatPercentage = (nutrition.fat / totalMacros) * 100;

    return Column(
      children: [
        // Visual bar chart
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              if (proteinPercentage > 0)
                Expanded(
                  flex: proteinPercentage.round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(AppTheme.radiusM),
                        right: carbPercentage == 0 && fatPercentage == 0
                            ? const Radius.circular(AppTheme.radiusM)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              if (carbPercentage > 0)
                Expanded(
                  flex: carbPercentage.round(),
                  child: Container(
                    color: AppTheme.warningColor,
                  ),
                ),
              if (fatPercentage > 0)
                Expanded(
                  flex: fatPercentage.round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor,
                      borderRadius: BorderRadius.horizontal(
                        right: const Radius.circular(AppTheme.radiusM),
                        left: proteinPercentage == 0 && carbPercentage == 0
                            ? const Radius.circular(AppTheme.radiusM)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              context,
              'Protein',
              '${proteinPercentage.toInt()}%',
              AppTheme.successColor,
            ),
            _buildLegendItem(
              context,
              'Carbs',
              '${carbPercentage.toInt()}%',
              AppTheme.warningColor,
            ),
            _buildLegendItem(
              context,
              'Fat',
              '${fatPercentage.toInt()}%',
              AppTheme.infoColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, String percentage, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          percentage,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(BuildContext context) {
    if (goals == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Goal Progress',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        _buildProgressBar(
          context,
          'Calories',
          nutrition.calories.toDouble(),
          goals!.dailyCalories.toDouble(),
          AppTheme.errorColor,
        ),
        _buildProgressBar(
          context,
          'Protein',
          nutrition.protein,
          goals!.dailyProtein,
          AppTheme.successColor,
        ),
        _buildProgressBar(
          context,
          'Carbs',
          nutrition.carbohydrates,
          goals!.dailyCarbohydrates,
          AppTheme.warningColor,
        ),
        _buildProgressBar(
          context,
          'Fat',
          nutrition.fat,
          goals!.dailyFat,
          AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double current,
    double goal,
    Color color,
  ) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXS),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}