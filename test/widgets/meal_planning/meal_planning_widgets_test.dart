import 'package:flutter_test/flutter_test.dart';
import '../../../lib/models/app_state.dart';

void main() {
  group('Meal Planning Models', () {
    test('MealPlanType enum should have correct values', () {
      expect(MealPlanType.values, hasLength(3));
      expect(MealPlanType.values, contains(MealPlanType.weekly));
      expect(MealPlanType.values, contains(MealPlanType.monthly));
      expect(MealPlanType.values, contains(MealPlanType.custom));
    });

    test('MealType enum should have correct values', () {
      expect(MealType.values, hasLength(4));
      expect(MealType.values, contains(MealType.breakfast));
      expect(MealType.values, contains(MealType.lunch));
      expect(MealType.values, contains(MealType.dinner));
      expect(MealType.values, contains(MealType.snack));
    });

    test('ShoppingListItem should calculate completion correctly', () {
      final shoppingList = ShoppingList(
        id: 'list1',
        mealPlanId: 'plan1',
        mealPlanName: 'Test Plan',
        items: [
          const ShoppingListItem(
            ingredient: 'Flour',
            quantity: '2',
            unit: 'cups',
            usedInRecipes: ['Bread'],
            isChecked: true,
          ),
          const ShoppingListItem(
            ingredient: 'Sugar',
            quantity: '1',
            unit: 'cup',
            usedInRecipes: ['Cake'],
            isChecked: false,
          ),
        ],
        generatedDate: DateTime.now(),
        startDate: '2024-01-01',
        endDate: '2024-01-07',
      );

      expect(shoppingList.completionPercentage, 50.0);
      expect(shoppingList.isComplete, false);
      expect(shoppingList.checkedItems, hasLength(1));
      expect(shoppingList.uncheckedItems, hasLength(1));
    });

    test('MealPlan should calculate dates correctly', () {
      final mealPlan = MealPlan(
        id: 'plan1',
        name: 'Test Plan',
        startDate: '2024-01-01',
        endDate: '2024-01-03',
        type: MealPlanType.custom,
        meals: [],
        dailyNutrients: [],
        createdDate: DateTime.now(),
      );

      final dates = mealPlan.getAllDates();
      expect(dates, hasLength(3));
      expect(dates, contains('2024-01-01'));
      expect(dates, contains('2024-01-02'));
      expect(dates, contains('2024-01-03'));
    });

    test('MealPlan should identify active plans correctly', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final activePlan = MealPlan(
        id: 'active',
        name: 'Active Plan',
        startDate: yesterday.toIso8601String().split('T')[0],
        endDate: tomorrow.toIso8601String().split('T')[0],
        type: MealPlanType.custom,
        meals: [],
        dailyNutrients: [],
        createdDate: DateTime.now(),
      );

      final inactivePlan = MealPlan(
        id: 'inactive',
        name: 'Inactive Plan',
        startDate: '2023-01-01',
        endDate: '2023-01-03',
        type: MealPlanType.custom,
        meals: [],
        dailyNutrients: [],
        createdDate: DateTime.now(),
      );

      expect(activePlan.isActive, true);
      expect(inactivePlan.isActive, false);
    });

    test('DailyNutrients should calculate progress correctly', () {
      const goals = NutritionGoals(
        dailyCalories: 2000,
        dailyProtein: 50,
        dailyCarbohydrates: 300,
        dailyFat: 65,
        dailyFiber: 25,
        dailySodium: 2300,
      );

      const dailyNutrients = DailyNutrients(
        date: '2024-01-01',
        totalCalories: 1800,
        totalProtein: 45,
        totalCarbohydrates: 270,
        totalFat: 58,
        totalFiber: 22,
        totalSugar: 50,
        totalSodium: 2000,
      );

      final progress = dailyNutrients.calculateProgress(goals);

      expect(progress.caloriesProgress, 90);
      expect(progress.proteinProgress, 90);
      expect(progress.carbsProgress, 90);
      expect(progress.fatProgress, closeTo(89.23, 0.01));
      expect(progress.fiberProgress, 88);
      expect(progress.sodiumProgress, closeTo(86.96, 0.01));
    });

    test('NutritionProgress should calculate overall score correctly', () {
      const progress = NutritionProgress(
        caloriesProgress: 100,
        proteinProgress: 95,
        carbsProgress: 105,
        fatProgress: 90,
        fiberProgress: 110,
        sodiumProgress: 80,
      );

      expect(progress.allGoalsMet, true);
      expect(progress.overallScore, greaterThan(90));
    });
  });
}