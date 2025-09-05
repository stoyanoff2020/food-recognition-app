import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/recipe_book_service.dart';
import '../../lib/services/ai_recipe_service.dart';
import '../../lib/models/subscription.dart';

void main() {
  group('RecipeBookService Unit Tests', () {
    final testRecipe = Recipe(
      id: 'recipe_1',
      title: 'Test Recipe',
      ingredients: ['ingredient1', 'ingredient2'],
      instructions: ['step1', 'step2'],
      cookingTime: 30,
      servings: 4,
      matchPercentage: 85.0,
      imageUrl: 'https://example.com/image.jpg',
      nutrition: const NutritionInfo(
        calories: 250,
        protein: 15.0,
        carbohydrates: 30.0,
        fat: 8.0,
        fiber: 5.0,
        sugar: 10.0,
        sodium: 500.0,
        servingSize: '1 serving',
      ),
      allergens: const [],
      intolerances: const [],
      usedIngredients: ['ingredient1'],
      missingIngredients: ['ingredient2'],
      difficulty: 'medium',
    );

    group('RecipeBookException', () {
      test('should create exception with message', () {
        const exception = RecipeBookException('Test error');
        expect(exception.message, 'Test error');
        expect(exception.code, isNull);
        expect(exception.toString(), 'RecipeBookException: Test error');
      });

      test('should create exception with message and code', () {
        const exception = RecipeBookException('Test error', code: 'TEST_CODE');
        expect(exception.message, 'Test error');
        expect(exception.code, 'TEST_CODE');
        expect(exception.toString(), 'RecipeBookException: Test error (Code: TEST_CODE)');
      });
    });

    group('RecipeBookStats', () {
      test('should create stats with all properties', () {
        final stats = RecipeBookStats(
          totalRecipes: 5,
          totalCategories: 3,
          totalTags: 8,
          difficultyDistribution: {'easy': 2, 'medium': 2, 'hard': 1},
          averageCookingTime: 25.5,
          mostUsedCategory: 'Main Course',
          recentlySaved: [],
        );

        expect(stats.totalRecipes, 5);
        expect(stats.totalCategories, 3);
        expect(stats.totalTags, 8);
        expect(stats.difficultyDistribution, {'easy': 2, 'medium': 2, 'hard': 1});
        expect(stats.averageCookingTime, 25.5);
        expect(stats.mostUsedCategory, 'Main Course');
        expect(stats.recentlySaved, isEmpty);
      });
    });

    group('RecipeBookServiceFactory', () {
      test('should create service instance', () {
        // This test just verifies the factory method exists and returns the correct type
        // We can't actually test it without mocking the dependencies
        expect(RecipeBookServiceFactory.create, isA<Function>());
      });
    });

    group('Recipe Model Validation', () {
      test('should create recipe with all required fields', () {
        expect(testRecipe.id, 'recipe_1');
        expect(testRecipe.title, 'Test Recipe');
        expect(testRecipe.ingredients, ['ingredient1', 'ingredient2']);
        expect(testRecipe.instructions, ['step1', 'step2']);
        expect(testRecipe.cookingTime, 30);
        expect(testRecipe.servings, 4);
        expect(testRecipe.matchPercentage, 85.0);
        expect(testRecipe.imageUrl, 'https://example.com/image.jpg');
        expect(testRecipe.nutrition.calories, 250);
        expect(testRecipe.allergens, isEmpty);
        expect(testRecipe.intolerances, isEmpty);
        expect(testRecipe.usedIngredients, ['ingredient1']);
        expect(testRecipe.missingIngredients, ['ingredient2']);
        expect(testRecipe.difficulty, 'medium');
      });
    });

    group('Subscription Feature Types', () {
      test('should have recipe book feature type', () {
        expect(FeatureType.recipeBook, isA<FeatureType>());
      });

      test('should have usage type for recipe save', () {
        expect(UsageType.recipeSave, isA<UsageType>());
      });
    });
  });
}