import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/app_state.dart';
import '../../services/meal_planning_service.dart';

class NutritionDashboard extends StatefulWidget {
  final MealPlan? mealPlan;

  const NutritionDashboard({
    super.key,
    required this.mealPlan,
  });

  @override
  State<NutritionDashboard> createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends State<NutritionDashboard> {
  DateTime _selectedDate = DateTime.now();
  NutritionGoals? _nutritionGoals;
  DailyNutrients? _dailyNutrients;
  NutritionProgress? _progress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  @override
  void didUpdateWidget(NutritionDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mealPlan?.id != widget.mealPlan?.id) {
      _loadNutritionData();
    }
  }

  Future<void> _loadNutritionData() async {
    if (widget.mealPlan == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Get meal planning service from context
      // For now, we'll use mock data
      _nutritionGoals = NutritionGoals.defaultGoals;
      
      final selectedDateString = _selectedDate.toIso8601String().split('T')[0];
      _dailyNutrients = widget.mealPlan!.getDailyNutrientsForDate(selectedDateString) ??
          DailyNutrients.empty(selectedDateString);
      
      _progress = _dailyNutrients!.calculateProgress(_nutritionGoals!);
    } catch (e) {
      debugPrint('Error loading nutrition data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mealPlan == null) {
      return const Center(
        child: Text('No meal plan selected'),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildNutritionOverview(),
          const SizedBox(height: 24),
          _buildProgressCharts(),
          const SizedBox(height: 24),
          _buildNutritionGoalsCard(),
          const SizedBox(height: 24),
          _buildWeeklyTrends(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nutrition for ${_formatDate(_selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              onPressed: () => _selectDate(),
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Select Date',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionOverview() {
    if (_dailyNutrients == null || _nutritionGoals == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientCard(
                    'Calories',
                    '${_dailyNutrients!.totalCalories.round()}',
                    '${_nutritionGoals!.dailyCalories.round()}',
                    'kcal',
                    Colors.red,
                    _progress!.caloriesProgress,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientCard(
                    'Protein',
                    '${_dailyNutrients!.totalProtein.round()}',
                    '${_nutritionGoals!.dailyProtein.round()}',
                    'g',
                    Colors.blue,
                    _progress!.proteinProgress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientCard(
                    'Carbs',
                    '${_dailyNutrients!.totalCarbohydrates.round()}',
                    '${_nutritionGoals!.dailyCarbohydrates.round()}',
                    'g',
                    Colors.orange,
                    _progress!.carbsProgress,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientCard(
                    'Fat',
                    '${_dailyNutrients!.totalFat.round()}',
                    '${_nutritionGoals!.dailyFat.round()}',
                    'g',
                    Colors.green,
                    _progress!.fatProgress,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(
    String label,
    String current,
    String goal,
    String unit,
    Color color,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current$unit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'of $goal$unit',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (progress / 100).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCharts() {
    if (_progress == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final data = [
      ('Calories', _progress!.caloriesProgress, Colors.red),
      ('Protein', _progress!.proteinProgress, Colors.blue),
      ('Carbs', _progress!.carbsProgress, Colors.orange),
      ('Fat', _progress!.fatProgress, Colors.green),
    ];

    return data.map((item) {
      final progress = (item.$2 / 100).clamp(0.0, 1.0);
      return PieChartSectionData(
        color: item.$3,
        value: progress * 100,
        title: '${(progress * 100).round()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildProgressLegend() {
    final data = [
      ('Calories', Colors.red),
      ('Protein', Colors.blue),
      ('Carbs', Colors.orange),
      ('Fat', Colors.green),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.$1,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNutritionGoalsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nutrition Goals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _editNutritionGoals,
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_nutritionGoals != null) ...[
              _buildGoalItem('Daily Calories', '${_nutritionGoals!.dailyCalories.round()} kcal'),
              _buildGoalItem('Protein', '${_nutritionGoals!.dailyProtein.round()} g'),
              _buildGoalItem('Carbohydrates', '${_nutritionGoals!.dailyCarbohydrates.round()} g'),
              _buildGoalItem('Fat', '${_nutritionGoals!.dailyFat.round()} g'),
              _buildGoalItem('Fiber', '${_nutritionGoals!.dailyFiber.round()} g'),
              _buildGoalItem('Sodium', '${_nutritionGoals!.dailySodium.round()} mg'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: const Center(
                child: Text(
                  'Weekly trends chart coming soon!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectDate() async {
    if (widget.mealPlan == null) return;

    final startDate = DateTime.parse(widget.mealPlan!.startDate);
    final endDate = DateTime.parse(widget.mealPlan!.endDate);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: startDate,
      lastDate: endDate,
    );

    if (date != null && date != _selectedDate) {
      setState(() {
        _selectedDate = date;
      });
      _loadNutritionData();
    }
  }

  void _editNutritionGoals() {
    // TODO: Implement edit nutrition goals dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit nutrition goals functionality coming soon!'),
      ),
    );
  }
}