import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/models/app_state.dart';
import '../../lib/models/subscription.dart';
import '../../lib/services/ai_recipe_service.dart';
import '../../lib/services/meal_planning_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/services/subscription_service.dart';

import 'meal_planning_service_test.mocks.dart';

@GenerateMocks([StorageServiceInterface, SubscriptionService])
void main() {
  group('MealPlanningService', () {
    late MealPlanningService mealPlanningService;
    late MockStorageServiceInterface mockStorageService;
    late MockSubscriptionService mockSubscriptionService;

    setUp(() {
      mockStorageService = MockStorageServiceInterface();
      mockSubscriptionService = MockSubscriptionService();
      mealPlanningService = MealPlanningService(
        storageService: mockStorageService,
        subscriptionService: mockSubscriptionService,
      );
    });

    group('createMealPlan', () {
      test('should create weekly meal plan successfully', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.mealPlanning))
            .thenAnswer((_) async => true);
        when(mockSubscriptionService.incrementUsage(UsageType.mealPlanCreate))
            .thenAnswer((_) async {});
        when(mockStorageService.saveData(any, any))
            .thenAnswer((_) async {});
        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => []);

        // Act
        final mealPlan = await mealPlanningService.createMealPlan(
          'Weekly Plan',
          '2024-01-01',
          MealPlanType.weekly,
        );

        // Assert
        expect(mealPlan.name, 'Weekly Plan');
        expect(mealPlan.startDate, '2024-01-01');
        expect(mealPlan.endDate, '2024-01-07');
        expect(mealPlan.type, MealPlanType.weekly);
        expect(mealPlan.meals, isEmpty);
        expect(mealPlan.dailyNutrients, hasLength(7));
        
        verify(mockSubscriptionService.hasFeatureAccess(FeatureType.mealPlanning));
        verify(mockSubscriptionService.incrementUsage(UsageType.mealPlanCreate));
      });

      test('should create monthly meal plan successfully', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.mealPlanning))
            .thenAnswer((_) async => true);
        when(mockSubscriptionService.incrementUsage(UsageType.mealPlanCreate))
            .thenAnswer((_) async {});
        when(mockStorageService.saveData(any, any))
            .thenAnswer((_) async {});
        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => []);

        // Act
        final mealPlan = await mealPlanningService.createMealPlan(
          'Monthly Plan',
          '2024-01-01',
          MealPlanType.monthly,
        );

        // Assert
        expect(mealPlan.name, 'Monthly Plan');
        expect(mealPlan.startDate, '2024-01-01');
        expect(mealPlan.endDate, '2024-01-31');
        expect(mealPlan.type, MealPlanType.monthly);
      });

      test('should throw exception when subscription access is denied', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.mealPlanning))
            .thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => mealPlanningService.createMealPlan(
            'Test Plan',
            '2024-01-01',
            MealPlanType.weekly,
          ),
          throwsA(isA<MealPlanningException>()),
        );
      });
    });

    group('getMealPlans', () {
      test('should return empty list when no meal plans exist', () async {
        // Arrange
        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => null);

        // Act
        final mealPlans = await mealPlanningService.getMealPlans();

        // Assert
        expect(mealPlans, isEmpty);
      });

      test('should return list of meal plans', () async {
        // Arrange
        final mealPlanData = [
          {
            'id': 'plan1',
            'name': 'Test Plan',
            'startDate': '2024-01-01',
            'endDate': '2024-01-07',
            'type': 'weekly',
            'meals': [],
            'dailyNutrients': [],
            'createdDate': DateTime.now().toIso8601String(),
          }
        ];
        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => mealPlanData);

        // Act
        final mealPlans = await mealPlanningService.getMealPlans();

        // Assert
        expect(mealPlans, hasLength(1));
        expect(mealPlans.first.name, 'Test Plan');
      });
    });

    group('addMealToPlan', () {
      test('should add meal to existing plan successfully', () async {
        // Arrange
        final existingPlan = MealPlan(
          id: 'plan1',
          name: 'Test Plan',
          startDate: '2024-01-01',
          endDate: '2024-01-07',
          type: MealPlanType.weekly,
          meals: [],
          dailyNutrients: [DailyNutrients.empty('2024-01-01')],
          createdDate: DateTime.now(),
        );

        final meal = PlannedMeal(
          id: 'meal1',
          date: '2024-01-01',
          mealType: MealType.breakfast,
          recipeId: 'recipe1',
          recipeTitle: 'Test Recipe',
          servings: 2,
          createdDate: DateTime.now(),
        );

        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => [existingPlan.toJson()]);
        when(mockStorageService.getData('nutrition_goals'))
            .thenAnswer((_) async => null);
        when(mockStorageService.saveData(any, any))
            .thenAnswer((_) async {});

        // Act
        await mealPlanningService.addMealToPlan('plan1', meal);

        // Assert
        verify(mockStorageService.saveData('meal_plans', any));
      });

      test('should throw exception when meal plan not found', () async {
        // Arrange
        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => []);

        final meal = PlannedMeal(
          id: 'meal1',
          date: '2024-01-01',
          mealType: MealType.breakfast,
          recipeId: 'recipe1',
          recipeTitle: 'Test Recipe',
          servings: 2,
          createdDate: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => mealPlanningService.addMealToPlan('nonexistent', meal),
          throwsA(isA<MealPlanningException>()),
        );
      });
    });

    group('calculateDailyNutrients', () {
      test('should calculate daily nutrients correctly', () async {
        // Arrange
        const nutrition = NutritionInfo(
          calories: 300,
          protein: 20.0,
          carbohydrates: 30.0,
          fat: 10.0,
          fiber: 5.0,
          sugar: 8.0,
          sodium: 400.0,
          servingSize: '1 serving',
        );

        final meal = PlannedMeal(
          id: 'meal1',
          date: '2024-01-01',
          mealType: MealType.breakfast,
          recipeId: 'recipe1',
          recipeTitle: 'Test Recipe',
          servings: 2,
          nutrition: nutrition,
          createdDate: DateTime.now(),
        );

        final mealPlan = MealPlan(
          id: 'plan1',
          name: 'Test Plan',
          startDate: '2024-01-01',
          endDate: '2024-01-07',
          type: MealPlanType.weekly,
          meals: [meal],
          dailyNutrients: [],
          createdDate: DateTime.now(),
        );

        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => [mealPlan.toJson()]);
        when(mockStorageService.getData('nutrition_goals'))
            .thenAnswer((_) async => null);

        // Act
        final dailyNutrients = await mealPlanningService.calculateDailyNutrients(
          'plan1',
          '2024-01-01',
        );

        // Assert
        expect(dailyNutrients.totalCalories, 600); // 300 * 2 servings
        expect(dailyNutrients.totalProtein, 40.0); // 20 * 2 servings
        expect(dailyNutrients.date, '2024-01-01');
      });
    });

    group('setNutritionGoals', () {
      test('should save nutrition goals successfully', () async {
        // Arrange
        const goals = NutritionGoals(
          dailyCalories: 2000,
          dailyProtein: 150,
          dailyCarbohydrates: 250,
          dailyFat: 65,
          dailyFiber: 25,
          dailySodium: 2300,
        );

        when(mockStorageService.saveData('nutrition_goals', any))
            .thenAnswer((_) async {});

        // Act
        await mealPlanningService.setNutritionGoals(goals);

        // Assert
        verify(mockStorageService.saveData('nutrition_goals', goals.toJson()));
      });
    });

    group('generateShoppingList', () {
      test('should generate shopping list from meal plan', () async {
        // Arrange
        final savedRecipe = SavedRecipe(
          id: 'recipe1',
          title: 'Test Recipe',
          ingredients: ['2 cups flour', '1 cup milk', '3 eggs'],
          instructions: ['Mix ingredients'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 95.0,
          nutrition: const NutritionInfo(
            calories: 300,
            protein: 20.0,
            carbohydrates: 30.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 400.0,
            servingSize: '1 serving',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
          savedDate: DateTime.now().toIso8601String(),
          category: 'Breakfast',
          tags: [],
        );

        final meal = PlannedMeal(
          id: 'meal1',
          date: '2024-01-01',
          mealType: MealType.breakfast,
          recipeId: 'recipe1',
          recipeTitle: 'Test Recipe',
          servings: 2,
          createdDate: DateTime.now(),
        );

        final mealPlan = MealPlan(
          id: 'plan1',
          name: 'Test Plan',
          startDate: '2024-01-01',
          endDate: '2024-01-07',
          type: MealPlanType.weekly,
          meals: [meal],
          dailyNutrients: [],
          createdDate: DateTime.now(),
        );

        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => [mealPlan.toJson()]);
        when(mockStorageService.getSavedRecipes())
            .thenAnswer((_) async => [savedRecipe]);
        when(mockStorageService.getData('shopping_lists'))
            .thenAnswer((_) async => []);
        when(mockStorageService.saveData('shopping_lists', any))
            .thenAnswer((_) async {});

        // Act
        final shoppingList = await mealPlanningService.generateShoppingList('plan1');

        // Assert
        expect(shoppingList.items, hasLength(3)); // flour, milk, eggs
        expect(shoppingList.mealPlanId, 'plan1');
        expect(shoppingList.mealPlanName, 'Test Plan');
        verify(mockStorageService.saveData('shopping_lists', any));
      });
    });

    group('hasMealPlanningAccess', () {
      test('should return true when user has Professional subscription', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.mealPlanning))
            .thenAnswer((_) async => true);

        // Act
        final hasAccess = await mealPlanningService.hasMealPlanningAccess();

        // Assert
        expect(hasAccess, isTrue);
      });

      test('should return false when user does not have Professional subscription', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.mealPlanning))
            .thenAnswer((_) async => false);

        // Act
        final hasAccess = await mealPlanningService.hasMealPlanningAccess();

        // Assert
        expect(hasAccess, isFalse);
      });
    });

    group('getStats', () {
      test('should return meal planning statistics', () async {
        // Arrange
        final mealPlan = MealPlan(
          id: 'plan1',
          name: 'Test Plan',
          startDate: '2024-01-01',
          endDate: '2024-01-07',
          type: MealPlanType.weekly,
          meals: [
            PlannedMeal(
              id: 'meal1',
              date: '2024-01-01',
              mealType: MealType.breakfast,
              recipeId: 'recipe1',
              recipeTitle: 'Recipe 1',
              servings: 2,
              createdDate: DateTime.now(),
            ),
            PlannedMeal(
              id: 'meal2',
              date: '2024-01-01',
              mealType: MealType.lunch,
              recipeId: 'recipe2',
              recipeTitle: 'Recipe 2',
              servings: 1,
              createdDate: DateTime.now(),
            ),
          ],
          dailyNutrients: [],
          createdDate: DateTime.now(),
        );

        when(mockStorageService.getData('meal_plans'))
            .thenAnswer((_) async => [mealPlan.toJson()]);
        when(mockStorageService.getData('shopping_lists'))
            .thenAnswer((_) async => []);

        // Act
        final stats = await mealPlanningService.getStats();

        // Assert
        expect(stats.totalMealPlans, 1);
        expect(stats.totalMeals, 2);
        expect(stats.uniqueRecipes, 2);
        expect(stats.mealTypeDistribution[MealType.breakfast], 1);
        expect(stats.mealTypeDistribution[MealType.lunch], 1);
        expect(stats.averageMealsPerPlan, 2.0);
      });
    });
  });
}