import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/app_state.dart';
import '../../services/meal_planning_service.dart';

class MealPlanCalendar extends StatefulWidget {
  final MealPlan? mealPlan;
  final Function(MealPlan?) onMealPlanChanged;
  final List<MealPlan> mealPlans;

  const MealPlanCalendar({
    super.key,
    required this.mealPlan,
    required this.onMealPlanChanged,
    required this.mealPlans,
  });

  @override
  State<MealPlanCalendar> createState() => _MealPlanCalendarState();
}

class _MealPlanCalendarState extends State<MealPlanCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mealPlan == null) {
      return const Center(
        child: Text('No meal plan selected'),
      );
    }

    return Column(
      children: [
        _buildMealPlanSelector(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCalendar(),
                const SizedBox(height: 16),
                _buildSelectedDayMeals(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MealPlan>(
                value: widget.mealPlan,
                isExpanded: true,
                hint: const Text('Select a meal plan'),
                items: widget.mealPlans.map((plan) {
                  return DropdownMenuItem(
                    value: plan,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${plan.startDate} - ${plan.endDate}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.onMealPlanChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final startDate = DateTime.parse(widget.mealPlan!.startDate);
    final endDate = DateTime.parse(widget.mealPlan!.endDate);

    return TableCalendar<PlannedMeal>(
      firstDay: startDate,
      lastDay: endDate,
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: Colors.red[400]),
        holidayTextStyle: TextStyle(color: Colors.red[400]),
        markerDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        formatButtonTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      onDaySelected: _onDaySelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
    );
  }

  Widget _buildSelectedDayMeals() {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    final selectedDateString = _selectedDay!.toIso8601String().split('T')[0];
    final mealsForDay = widget.mealPlan!.getMealsForDate(selectedDateString);
    final dailyNutrients = widget.mealPlan!.getDailyNutrientsForDate(selectedDateString);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meals for ${_formatDate(_selectedDay!)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => _showAddMealDialog(selectedDateString),
                icon: const Icon(Icons.add),
                tooltip: 'Add Meal',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (mealsForDay.isEmpty)
            _buildEmptyMealsState(selectedDateString)
          else
            _buildMealsList(mealsForDay),
          if (dailyNutrients != null) ...[
            const SizedBox(height: 16),
            _buildNutritionSummary(dailyNutrients),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyMealsState(String date) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No meals planned',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add meals to start planning your day',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddMealDialog(date),
            icon: const Icon(Icons.add),
            label: const Text('Add Meal'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(List<PlannedMeal> meals) {
    return Column(
      children: meals.map((meal) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMealTypeColor(meal.mealType),
              child: Icon(
                _getMealTypeIcon(meal.mealType),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(meal.recipeTitle),
            subtitle: Text(
              '${_getMealTypeLabel(meal.mealType)} • ${meal.servings} serving${meal.servings > 1 ? 's' : ''}',
            ),
            trailing: PopupMenuButton(
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
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editMeal(meal);
                } else if (value == 'delete') {
                  _deleteMeal(meal);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNutritionSummary(DailyNutrients nutrients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Nutrition',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientItem('Calories', '${nutrients.totalCalories.round()}', 'kcal'),
                _buildNutrientItem('Protein', '${nutrients.totalProtein.round()}g', ''),
                _buildNutrientItem('Carbs', '${nutrients.totalCarbohydrates.round()}g', ''),
                _buildNutrientItem('Fat', '${nutrients.totalFat.round()}g', ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  List<PlannedMeal> _getEventsForDay(DateTime day) {
    final dateString = day.toIso8601String().split('T')[0];
    return widget.mealPlan?.getMealsForDate(dateString) ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.dinner:
        return Colors.blue;
      case MealType.snack:
        return Colors.purple;
    }
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  String _getMealTypeLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  void _showAddMealDialog(String date) {
    // TODO: Implement add meal dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add meal functionality coming soon!'),
      ),
    );
  }

  void _editMeal(PlannedMeal meal) {
    // TODO: Implement edit meal functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit meal functionality coming soon!'),
      ),
    );
  }

  void _deleteMeal(PlannedMeal meal) {
    // TODO: Implement delete meal functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete meal functionality coming soon!'),
      ),
    );
  }
}