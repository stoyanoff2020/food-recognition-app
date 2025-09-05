import 'package:flutter/material.dart';
import '../../models/app_state.dart';

class MealPlanList extends StatelessWidget {
  final List<MealPlan> mealPlans;
  final MealPlan? selectedMealPlan;
  final Function(MealPlan) onMealPlanSelected;
  final Function(MealPlan) onMealPlanDeleted;

  const MealPlanList({
    super.key,
    required this.mealPlans,
    required this.selectedMealPlan,
    required this.onMealPlanSelected,
    required this.onMealPlanDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (mealPlans.isEmpty) {
      return const Center(
        child: Text('No meal plans available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mealPlans.length,
      itemBuilder: (context, index) {
        final mealPlan = mealPlans[index];
        final isSelected = selectedMealPlan?.id == mealPlan.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          child: InkWell(
            onTap: () => onMealPlanSelected(mealPlan),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealPlan.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected 
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(mealPlan.startDate)} - ${_formatDate(mealPlan.endDate)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildMealPlanTypeChip(mealPlan.type),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: ListTile(
                              leading: Icon(Icons.copy),
                              title: Text('Duplicate'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'shopping_list',
                            child: ListTile(
                              leading: Icon(Icons.shopping_cart),
                              title: Text('Generate Shopping List'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editMealPlan(context, mealPlan);
                              break;
                            case 'duplicate':
                              _duplicateMealPlan(context, mealPlan);
                              break;
                            case 'shopping_list':
                              _generateShoppingList(context, mealPlan);
                              break;
                            case 'delete':
                              onMealPlanDeleted(mealPlan);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        Icons.restaurant,
                        '${mealPlan.totalMeals} meals',
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        context,
                        Icons.menu_book,
                        '${mealPlan.uniqueRecipes} recipes',
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        context,
                        Icons.calendar_today,
                        '${_calculateDuration(mealPlan)} days',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(context, mealPlan),
                  if (mealPlan.isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealPlanTypeChip(MealPlanType type) {
    Color color;
    String label;

    switch (type) {
      case MealPlanType.weekly:
        color = Colors.blue;
        label = 'Weekly';
        break;
      case MealPlanType.monthly:
        color = Colors.purple;
        label = 'Monthly';
        break;
      case MealPlanType.custom:
        color = Colors.orange;
        label = 'Custom';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, MealPlan mealPlan) {
    final totalDays = _calculateDuration(mealPlan);
    final plannedDays = mealPlan.meals
        .map((meal) => meal.date)
        .toSet()
        .length;
    final progress = totalDays > 0 ? plannedDays / totalDays : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Planning Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$plannedDays of $totalDays days planned',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  int _calculateDuration(MealPlan mealPlan) {
    final start = DateTime.parse(mealPlan.startDate);
    final end = DateTime.parse(mealPlan.endDate);
    return end.difference(start).inDays + 1;
  }

  void _editMealPlan(BuildContext context, MealPlan mealPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit meal plan functionality coming soon!'),
      ),
    );
  }

  void _duplicateMealPlan(BuildContext context, MealPlan mealPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate meal plan functionality coming soon!'),
      ),
    );
  }

  void _generateShoppingList(BuildContext context, MealPlan mealPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generate shopping list functionality coming soon!'),
      ),
    );
  }
}