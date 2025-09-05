import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/app_state.dart';
import '../../lib/services/meal_planning_service.dart';

void main() {
  group('MealPlanningService Simple Tests', () {
    test('MealPlanningException should have correct message', () {
      const exception = MealPlanningException('Test error', code: 'TEST_CODE');
      
      expect(exception.message, 'Test error');
      expect(exception.code, 'TEST_CODE');
      expect(exception.toString(), 'MealPlanningException: Test error (Code: TEST_CODE)');
    });

    test('MealPlanningException without code should format correctly', () {
      const exception = MealPlanningException('Test error');
      
      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.toString(), 'MealPlanningException: Test error');
    });

    test('MealPlanningStats should be created correctly', () {
      const stats = MealPlanningStats(
        totalMealPlans: 5,
        totalMeals: 20,
        uniqueRecipes: 15,
        totalShoppingLists: 3,
        mealTypeDistribution: {
          MealType.breakfast: 5,
          MealType.lunch: 5,
          MealType.dinner: 5,
          MealType.snack: 5,
        },
        averageMealsPerPlan: 4.0,
      );

      expect(stats.totalMealPlans, 5);
      expect(stats.totalMeals, 20);
      expect(stats.uniqueRecipes, 15);
      expect(stats.totalShoppingLists, 3);
      expect(stats.averageMealsPerPlan, 4.0);
      expect(stats.mealTypeDistribution[MealType.breakfast], 5);
    });

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

    test('ShoppingListItem should be created and copied correctly', () {
      const item = ShoppingListItem(
        ingredient: 'Flour',
        quantity: '2',
        unit: 'cups',
        usedInRecipes: ['Bread', 'Cake'],
        isChecked: false,
      );

      expect(item.ingredient, 'Flour');
      expect(item.quantity, '2');
      expect(item.unit, 'cups');
      expect(item.usedInRecipes, ['Bread', 'Cake']);
      expect(item.isChecked, false);

      final checkedItem = item.copyWith(isChecked: true);
      expect(checkedItem.isChecked, true);
      expect(checkedItem.ingredient, 'Flour'); // Other properties unchanged
    });

    test('ShoppingListItem should serialize to/from JSON correctly', () {
      const item = ShoppingListItem(
        ingredient: 'Flour',
        quantity: '2',
        unit: 'cups',
        usedInRecipes: ['Bread', 'Cake'],
        isChecked: true,
      );

      final json = item.toJson();
      final fromJson = ShoppingListItem.fromJson(json);

      expect(fromJson.ingredient, item.ingredient);
      expect(fromJson.quantity, item.quantity);
      expect(fromJson.unit, item.unit);
      expect(fromJson.usedInRecipes, item.usedInRecipes);
      expect(fromJson.isChecked, item.isChecked);
    });

    test('ShoppingList should calculate completion percentage correctly', () {
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
          const ShoppingListItem(
            ingredient: 'Eggs',
            quantity: '3',
            unit: 'pieces',
            usedInRecipes: ['Cake'],
            isChecked: true,
          ),
        ],
        generatedDate: DateTime.now(),
        startDate: '2024-01-01',
        endDate: '2024-01-07',
      );

      expect(shoppingList.completionPercentage, closeTo(66.67, 0.01));
      expect(shoppingList.isComplete, false);
      expect(shoppingList.checkedItems, hasLength(2));
      expect(shoppingList.uncheckedItems, hasLength(1));
    });

    test('NutritionGoals should have correct default values', () {
      const goals = NutritionGoals.defaultGoals;
      
      expect(goals.dailyCalories, 2000);
      expect(goals.dailyProtein, 50);
      expect(goals.dailyCarbohydrates, 300);
      expect(goals.dailyFat, 65);
      expect(goals.dailyFiber, 25);
      expect(goals.dailySodium, 2300);
    });

    test('NutritionGoals should serialize to/from JSON correctly', () {
      const goals = NutritionGoals(
        dailyCalories: 1800,
        dailyProtein: 60,
        dailyCarbohydrates: 250,
        dailyFat: 70,
        dailyFiber: 30,
        dailySodium: 2000,
      );

      final json = goals.toJson();
      final fromJson = NutritionGoals.fromJson(json);

      expect(fromJson.dailyCalories, goals.dailyCalories);
      expect(fromJson.dailyProtein, goals.dailyProtein);
      expect(fromJson.dailyCarbohydrates, goals.dailyCarbohydrates);
      expect(fromJson.dailyFat, goals.dailyFat);
      expect(fromJson.dailyFiber, goals.dailyFiber);
      expect(fromJson.dailySodium, goals.dailySodium);
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

    test('DailyNutrients.empty should create empty nutrients', () {
      final empty = DailyNutrients.empty('2024-01-01');

      expect(empty.date, '2024-01-01');
      expect(empty.totalCalories, 0);
      expect(empty.totalProtein, 0);
      expect(empty.totalCarbohydrates, 0);
      expect(empty.totalFat, 0);
      expect(empty.totalFiber, 0);
      expect(empty.totalSugar, 0);
      expect(empty.totalSodium, 0);
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
  });
}