import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/recipe_cache_service.dart';
import '../../lib/services/ai_recipe_service.dart';

void main() {
  group('RecipeCacheService', () {
    group('PaginatedRecipeResult', () {
      test('toString returns correct format', () {
        const result = PaginatedRecipeResult(
          recipes: [],
          currentPage: 2,
          totalPages: 5,
          totalRecipes: 50,
          hasNextPage: true,
          hasPreviousPage: true,
        );
        
        final string = result.toString();
        expect(string, contains('page: 2/5'));
        expect(string, contains('recipes: 0/50'));
      });
    });

    group('CachedRecipeResult', () {
      test('correctly identifies expired results', () {
        final expiredResult = CachedRecipeResult(
          result: RecipeGenerationResult(
            recipes: [],
            totalFound: 0,
            generationTime: 1000,
            alternativeSuggestions: [],
            isSuccess: true,
          ),
          cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
          cacheKey: 'test_key',
          fromCache: true,
        );
        
        expect(expiredResult.isExpired, isTrue);
      });

      test('correctly identifies non-expired results', () {
        final freshResult = CachedRecipeResult(
          result: RecipeGenerationResult(
            recipes: [],
            totalFound: 0,
            generationTime: 1000,
            alternativeSuggestions: [],
            isSuccess: true,
          ),
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
          cacheKey: 'test_key',
          fromCache: true,
        );
        
        expect(freshResult.isExpired, isFalse);
      });

      test('serializes and deserializes correctly', () {
        final originalResult = CachedRecipeResult(
          result: RecipeGenerationResult(
            recipes: [_createTestRecipe()],
            totalFound: 1,
            generationTime: 1000,
            alternativeSuggestions: [],
            isSuccess: true,
          ),
          cachedAt: DateTime.now(),
          cacheKey: 'test_key',
          fromCache: true,
        );
        
        final json = originalResult.toJson();
        final deserializedResult = CachedRecipeResult.fromJson(json);
        
        expect(deserializedResult.result.recipes.length, equals(1));
        expect(deserializedResult.result.totalFound, equals(1));
        expect(deserializedResult.result.isSuccess, isTrue);
        expect(deserializedResult.cacheKey, equals('test_key'));
        expect(deserializedResult.fromCache, isTrue);
      });
    });

    group('RecipeCacheConfig', () {
      test('has correct default values', () {
        expect(RecipeCacheConfig.cacheMaxAge, equals(const Duration(hours: 24)));
        expect(RecipeCacheConfig.maxCacheObjects, equals(200));
        expect(RecipeCacheConfig.maxMemoryCacheSize, equals(50));
        expect(RecipeCacheConfig.cacheKeyPrefix, equals('recipe_cache_'));
        expect(RecipeCacheConfig.metadataCacheKey, equals('recipe_metadata_cache'));
      });
    });
  });
}

Recipe _createTestRecipe() {
  return Recipe(
    id: 'test_recipe_${DateTime.now().millisecondsSinceEpoch}',
    title: 'Test Recipe',
    ingredients: ['apple', 'banana'],
    instructions: ['Step 1', 'Step 2'],
    cookingTime: 30,
    servings: 4,
    matchPercentage: 85,
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
    usedIngredients: ['apple', 'banana'],
    missingIngredients: [],
    difficulty: 'easy',
  );
}