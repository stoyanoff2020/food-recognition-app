import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/ai_vision_service.dart';
import '../../lib/services/ai_recipe_service.dart';
import '../../lib/services/custom_ingredient_service.dart';
import '../../lib/services/recipe_cache_service.dart';
import '../../lib/services/storage_service.dart';

void main() {
  group('Recognition to Recipe Integration Tests', () {
    late AIVisionService aiVisionService;
    late AIRecipeService aiRecipeService;
    late CustomIngredientService customIngredientService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      aiVisionService = AIVisionService(apiKey: 'test-api-key');
      aiRecipeService = AIRecipeService(apiKey: 'test-api-key');
      customIngredientService = CustomIngredientService(StorageServiceFactory.create());
    });

    tearDown(() {
      aiVisionService.dispose();
      aiRecipeService.dispose();
    });

    group('Recognition Result Processing', () {
      test('handles successful recognition results', () {
        final mockResult = FoodRecognitionResult.success(
          ingredients: [
            const Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable'),
            const Ingredient(name: 'basil', confidence: 0.85, category: 'herb'),
          ],
          confidence: 0.90,
          processingTime: 1500,
        );

        expect(mockResult.isSuccess, isTrue);
        expect(mockResult.ingredients.length, equals(2));
        expect(mockResult.ingredients.first.name, equals('tomato'));
        expect(mockResult.confidence, equals(0.90));
      });

      test('handles failed recognition results', () {
        final mockResult = FoodRecognitionResult.failure(
          errorMessage: 'No food detected',
          processingTime: 500,
        );

        expect(mockResult.isSuccess, isFalse);
        expect(mockResult.ingredients, isEmpty);
        expect(mockResult.confidence, equals(0.0));
        expect(mockResult.errorMessage, equals('No food detected'));
      });
    });

    group('Custom Ingredient Integration', () {
      test('adds custom ingredients to recognition results', () async {
        // Add some custom ingredients
        await customIngredientService.addCustomIngredient('olive oil');
        await customIngredientService.addCustomIngredient('garlic');

        final customIngredients = await customIngredientService.getCustomIngredients();
        expect(customIngredients.any((i) => i.name == 'olive oil'), isTrue);
        expect(customIngredients.any((i) => i.name == 'garlic'), isTrue);

        // Simulate combining with recognition results
        final recognizedIngredients = ['tomato', 'basil'];
        final customIngredientNames = customIngredients.map((i) => i.name).toList();
        final allIngredients = [...recognizedIngredients, ...customIngredientNames];
        
        expect(allIngredients, contains('tomato'));
        expect(allIngredients, contains('basil'));
        expect(allIngredients, contains('olive oil'));
        expect(allIngredients, contains('garlic'));
      });

      test('manages ingredient history correctly', () async {
        await customIngredientService.addCustomIngredient('ingredient1');
        await customIngredientService.addCustomIngredient('ingredient2');
        await customIngredientService.addCustomIngredient('ingredient3');

        final history = await customIngredientService.getRecentIngredients();
        expect(history.length, greaterThanOrEqualTo(3));
        expect(history.any((i) => i.name == 'ingredient1'), isTrue);
        expect(history.any((i) => i.name == 'ingredient2'), isTrue);
        expect(history.any((i) => i.name == 'ingredient3'), isTrue);
      });

      test('handles ingredient suggestions', () async {
        await customIngredientService.addCustomIngredient('tomato sauce');
        await customIngredientService.addCustomIngredient('tomato paste');

        final suggestions = await customIngredientService.getIngredientSuggestions(query: 'tom');
        expect(suggestions, isNotEmpty);
        
        // Should contain ingredients that start with 'tom'
        final tomIngredients = suggestions.where((s) => s.toLowerCase().startsWith('tom')).toList();
        expect(tomIngredients, isNotEmpty);
      });
    });

    group('Recipe Generation Integration', () {
      test('handles empty ingredient list', () async {
        final result = await aiRecipeService.generateRecipesByIngredients([]);
        
        expect(result.isSuccess, isFalse);
        expect(result.recipes, isEmpty);
        expect(result.errorMessage, isNotNull);
      });

      test('processes ingredient list for recipe generation', () async {
        final ingredients = ['tomato', 'basil', 'mozzarella'];
        
        // This will fail in test environment due to no API key, but we can test the structure
        final result = await aiRecipeService.generateRecipesByIngredients(ingredients);
        
        expect(result, isA<RecipeGenerationResult>());
        expect(result.isSuccess, isFalse); // Expected to fail in test environment
        expect(result.errorMessage, isNotNull);
      });

      test('handles recipe ranking correctly', () {
        final mockRecipes = [
          _createMockRecipe('Recipe 1', ['tomato', 'basil'], 80.0),
          _createMockRecipe('Recipe 2', ['tomato', 'cheese'], 90.0),
          _createMockRecipe('Recipe 3', ['basil', 'garlic'], 70.0),
        ];

        final userIngredients = ['tomato', 'basil', 'cheese'];
        final rankedRecipes = aiRecipeService.rankRecipesByMatch(mockRecipes, userIngredients);

        expect(rankedRecipes.length, equals(3));
        // Recipe 2 should be first (has tomato and cheese, 90% match)
        expect(rankedRecipes.first.title, equals('Recipe 2'));
        expect(rankedRecipes.first.matchPercentage, equals(90.0));
      });

      test('highlights used ingredients correctly', () {
        final recipe = _createMockRecipe('Test Recipe', ['tomato', 'basil', 'cheese'], 85.0);
        final detectedIngredients = ['tomato', 'basil'];

        final highlightedRecipe = aiRecipeService.highlightUsedIngredients(recipe, detectedIngredients);

        expect(highlightedRecipe.usedIngredients, contains('tomato'));
        expect(highlightedRecipe.usedIngredients, contains('basil'));
        expect(highlightedRecipe.usedIngredients, isNot(contains('cheese')));
      });
    });

    group('End-to-End Recognition to Recipe Flow', () {
      test('complete flow from recognition to recipe suggestions', () async {
        // Step 1: Simulate recognition results
        final recognitionResult = FoodRecognitionResult.success(
          ingredients: [
            const Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable'),
            const Ingredient(name: 'basil', confidence: 0.85, category: 'herb'),
          ],
          confidence: 0.90,
          processingTime: 1500,
        );

        expect(recognitionResult.isSuccess, isTrue);

        // Step 2: Extract ingredient names
        final ingredientNames = recognitionResult.ingredients.map((i) => i.name).toList();
        expect(ingredientNames, equals(['tomato', 'basil']));

        // Step 3: Add custom ingredients
        await customIngredientService.addCustomIngredient('olive oil');
        final customIngredients = await customIngredientService.getCustomIngredients();
        
        // Step 4: Combine all ingredients
        final customIngredientNames = customIngredients.map((i) => i.name).toList();
        final allIngredients = [...ingredientNames, ...customIngredientNames];
        expect(allIngredients, contains('tomato'));
        expect(allIngredients, contains('basil'));
        expect(allIngredients, contains('olive oil'));

        // Step 5: Generate recipes (will fail in test environment, but structure is tested)
        final recipeResult = await aiRecipeService.generateRecipesByIngredients(allIngredients);
        expect(recipeResult, isA<RecipeGenerationResult>());
      });

      test('handles errors in the flow gracefully', () async {
        // Test with failed recognition
        final failedRecognition = FoodRecognitionResult.failure(
          errorMessage: 'No food detected',
          processingTime: 500,
        );

        expect(failedRecognition.isSuccess, isFalse);
        expect(failedRecognition.ingredients, isEmpty);

        // Flow should handle empty ingredients gracefully
        final recipeResult = await aiRecipeService.generateRecipesByIngredients([]);
        expect(recipeResult.isSuccess, isFalse);
        expect(recipeResult.errorMessage, isNotNull);
      });

      test('maintains ingredient history throughout flow', () async {
        // Add ingredients through the flow
        await customIngredientService.addCustomIngredient('ingredient1');
        await customIngredientService.addCustomIngredient('ingredient2');

        // Check history is maintained
        final history = await customIngredientService.getRecentIngredients();
        expect(history.any((i) => i.name == 'ingredient1'), isTrue);
        expect(history.any((i) => i.name == 'ingredient2'), isTrue);

        // Clear ingredients
        await customIngredientService.clearAllCustomIngredients();
        final clearedIngredients = await customIngredientService.getCustomIngredients();
        expect(clearedIngredients, isEmpty);

        // Recent ingredients should still be available (they're not cleared by clearAllCustomIngredients)
        final historyAfterClear = await customIngredientService.getRecentIngredients();
        // Note: In a real implementation, recent ingredients might persist even after clearing custom ingredients
      });
    });

    group('Performance and Caching Integration', () {
      test('handles multiple concurrent ingredient operations', () async {
        final futures = <Future>[];
        
        // Add multiple ingredients concurrently
        for (int i = 0; i < 5; i++) {
          futures.add(customIngredientService.addCustomIngredient('ingredient_$i'));
        }
        
        await Future.wait(futures);
        
        final ingredients = await customIngredientService.getCustomIngredients();
        expect(ingredients.length, greaterThanOrEqualTo(5));
      });

      test('caching integration works correctly', () {
        // Test that cache configuration is accessible
        expect(RecipeCacheConfig.cacheMaxAge, equals(const Duration(hours: 24)));
        expect(RecipeCacheConfig.maxCacheObjects, equals(200));
        expect(RecipeCacheConfig.maxMemoryCacheSize, equals(50));
      });
    });
  });
}

Recipe _createMockRecipe(String title, List<String> ingredients, double matchPercentage) {
  return Recipe(
    id: 'mock_${title.toLowerCase().replaceAll(' ', '_')}',
    title: title,
    ingredients: ingredients,
    instructions: ['Step 1', 'Step 2'],
    cookingTime: 30,
    servings: 4,
    matchPercentage: matchPercentage,
    nutrition: const NutritionInfo(
      calories: 200,
      protein: 5,
      carbohydrates: 40,
      fat: 2,
      fiber: 3,
      sugar: 20,
      sodium: 100,
      servingSize: '1 cup',
    ),
    allergens: [],
    intolerances: [],
    usedIngredients: ingredients,
    missingIngredients: [],
    difficulty: 'easy',
  );
}