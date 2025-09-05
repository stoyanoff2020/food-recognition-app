import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/ai_recipe_service.dart';
import '../../lib/services/recipe_cache_service.dart';
import '../../lib/services/optimized_recipe_service.dart';

// Generate mocks
@GenerateMocks([AIRecipeServiceInterface, RecipeCacheServiceInterface])
import 'optimized_recipe_service_test.mocks.dart';

void main() {
  group('OptimizedRecipeService', () {
    late OptimizedRecipeService service;
    late MockAIRecipeServiceInterface mockAIService;
    late MockRecipeCacheServiceInterface mockCacheService;

    setUp(() {
      mockAIService = MockAIRecipeServiceInterface();
      mockCacheService = MockRecipeCacheServiceInterface();
      service = OptimizedRecipeService(
        aiRecipeService: mockAIService,
        cacheService: mockCacheService,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('Recipe Generation Performance', () {
      test('should return cached results quickly', () async {
        // Arrange
        final List<String> ingredients = ['tomato', 'cheese', 'bread'];
        final RecipeRequestParams params = RecipeRequestParams(ingredients: ingredients);
        
        final Recipe testRecipe = _createTestRecipe('1', 'Test Recipe', 85.0);
        final RecipeGenerationResult cachedGenerationResult = RecipeGenerationResult.success(
          recipes: [testRecipe],
          totalFound: 1,
          generationTime: 100,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: cachedGenerationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'test_key',
          fromCache: true,
        );
        
        final PaginatedRecipeResult paginatedResult = PaginatedRecipeResult(
          recipes: [testRecipe],
          currentPage: 1,
          totalPages: 1,
          totalRecipes: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((_) async => paginatedResult);
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act
        final Stopwatch stopwatch = Stopwatch()..start();
        final OptimizedRecipeResult result = await service.getRecipes(params);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.fromCache, isTrue);
        expect(result.paginatedResult.recipes.length, equals(1));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast from cache
        
        verify(mockCacheService.getCachedRecipes(ingredients)).called(1);
        verify(mockCacheService.getPaginatedRecipes(any, 1, 10)).called(1);
        verify(mockCacheService.preloadRecipeImages(any)).called(1);
        verifyNever(mockAIService.generateRecipesByIngredients(any));
      });

      test('should handle cache miss and generate new recipes', () async {
        // Arrange
        final List<String> ingredients = ['chicken', 'rice', 'vegetables'];
        final RecipeRequestParams params = RecipeRequestParams(ingredients: ingredients);
        
        final Recipe testRecipe = _createTestRecipe('2', 'Chicken Rice', 90.0);
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: [testRecipe],
          totalFound: 1,
          generationTime: 2000,
        );
        
        final PaginatedRecipeResult paginatedResult = PaginatedRecipeResult(
          recipes: [testRecipe],
          currentPage: 1,
          totalPages: 1,
          totalRecipes: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => null); // Cache miss
        when(mockAIService.generateRecipesByIngredients(ingredients))
            .thenAnswer((_) async => generationResult);
        when(mockCacheService.cacheRecipes(ingredients, generationResult))
            .thenAnswer((_) async {});
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((_) async => paginatedResult);
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act
        final OptimizedRecipeResult result = await service.getRecipes(params);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.fromCache, isFalse);
        expect(result.paginatedResult.recipes.length, equals(1));
        
        verify(mockCacheService.getCachedRecipes(ingredients)).called(1);
        verify(mockAIService.generateRecipesByIngredients(ingredients)).called(1);
        verify(mockCacheService.cacheRecipes(ingredients, generationResult)).called(1);
        verify(mockCacheService.getPaginatedRecipes(any, 1, 10)).called(1);
        verify(mockCacheService.preloadRecipeImages(any)).called(1);
      });

      test('should handle concurrent requests efficiently', () async {
        // Arrange
        final List<String> ingredients = ['pasta', 'sauce', 'cheese'];
        final RecipeRequestParams params = RecipeRequestParams(ingredients: ingredients);
        
        final Recipe testRecipe = _createTestRecipe('3', 'Pasta Recipe', 75.0);
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: [testRecipe],
          totalFound: 1,
          generationTime: 1500,
        );
        
        final PaginatedRecipeResult paginatedResult = PaginatedRecipeResult(
          recipes: [testRecipe],
          currentPage: 1,
          totalPages: 1,
          totalRecipes: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => null);
        when(mockAIService.generateRecipesByIngredients(ingredients))
            .thenAnswer((_) async {
              // Simulate network delay
              await Future.delayed(const Duration(milliseconds: 100));
              return generationResult;
            });
        when(mockCacheService.cacheRecipes(ingredients, generationResult))
            .thenAnswer((_) async {});
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((_) async => paginatedResult);
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Make multiple concurrent requests
        final List<Future<OptimizedRecipeResult>> futures = List.generate(
          5,
          (_) => service.getRecipes(params),
        );
        
        final List<OptimizedRecipeResult> results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final OptimizedRecipeResult result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.paginatedResult.recipes.length, equals(1));
        }
        
        // Should only call AI service once due to request deduplication
        verify(mockAIService.generateRecipesByIngredients(ingredients)).called(1);
      });
    });

    group('Pagination Performance', () {
      test('should paginate large recipe lists efficiently', () async {
        // Arrange
        final List<String> ingredients = ['flour', 'sugar', 'eggs'];
        final List<Recipe> allRecipes = List.generate(
          50,
          (index) => _createTestRecipe('recipe_$index', 'Recipe $index', 80.0 - index),
        );
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: allRecipes,
          totalFound: 50,
          generationTime: 3000,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'large_test_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async {
              final List<Recipe> recipes = invocation.positionalArguments[0] as List<Recipe>;
              final int page = invocation.positionalArguments[1] as int;
              final int pageSize = invocation.positionalArguments[2] as int;
              
              final int startIndex = (page - 1) * pageSize;
              final int endIndex = (startIndex + pageSize).clamp(0, recipes.length);
              final List<Recipe> pageRecipes = recipes.sublist(startIndex, endIndex);
              
              return PaginatedRecipeResult(
                recipes: pageRecipes,
                currentPage: page,
                totalPages: (recipes.length / pageSize).ceil(),
                totalRecipes: recipes.length,
                hasNextPage: page < (recipes.length / pageSize).ceil(),
                hasPreviousPage: page > 1,
              );
            });
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Test different pages
        final List<Future<OptimizedRecipeResult>> pageFutures = [
          service.getRecipes(RecipeRequestParams(ingredients: ingredients, page: 1, pageSize: 10)),
          service.getRecipes(RecipeRequestParams(ingredients: ingredients, page: 2, pageSize: 10)),
          service.getRecipes(RecipeRequestParams(ingredients: ingredients, page: 3, pageSize: 10)),
        ];
        
        final Stopwatch stopwatch = Stopwatch()..start();
        final List<OptimizedRecipeResult> results = await Future.wait(pageFutures);
        stopwatch.stop();

        // Assert
        expect(results.length, equals(3));
        expect(results[0].paginatedResult.recipes.length, equals(10)); // Page 1
        expect(results[1].paginatedResult.recipes.length, equals(10)); // Page 2
        expect(results[2].paginatedResult.recipes.length, equals(10)); // Page 3
        
        expect(results[0].paginatedResult.currentPage, equals(1));
        expect(results[1].paginatedResult.currentPage, equals(2));
        expect(results[2].paginatedResult.currentPage, equals(3));
        
        expect(results[0].paginatedResult.hasNextPage, isTrue);
        expect(results[1].paginatedResult.hasNextPage, isTrue);
        expect(results[2].paginatedResult.hasNextPage, isTrue);
        
        // Should be fast since all from cache
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle empty results gracefully', () async {
        // Arrange
        final List<String> ingredients = ['nonexistent'];
        final RecipeRequestParams params = RecipeRequestParams(ingredients: ingredients);

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => null);
        when(mockAIService.generateRecipesByIngredients(ingredients))
            .thenAnswer((_) async => RecipeGenerationResult.failure(
              errorMessage: 'No recipes found',
              generationTime: 1000,
            ));

        // Act
        final OptimizedRecipeResult result = await service.getRecipes(params);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.paginatedResult.recipes.isEmpty, isTrue);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('Filtering and Sorting Performance', () {
      test('should apply filters efficiently', () async {
        // Arrange
        final List<String> ingredients = ['vegetables', 'tofu'];
        final List<Recipe> allRecipes = [
          _createTestRecipe('1', 'Meat Recipe', 80.0, ingredients: ['beef', 'vegetables']),
          _createTestRecipe('2', 'Vegan Recipe', 85.0, ingredients: ['tofu', 'vegetables']),
          _createTestRecipe('3', 'Dairy Recipe', 75.0, ingredients: ['milk', 'vegetables']),
        ];
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: allRecipes,
          totalFound: 3,
          generationTime: 2000,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'filter_test_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async {
              final List<Recipe> recipes = invocation.positionalArguments[0] as List<Recipe>;
              return PaginatedRecipeResult(
                recipes: recipes,
                currentPage: 1,
                totalPages: 1,
                totalRecipes: recipes.length,
                hasNextPage: false,
                hasPreviousPage: false,
              );
            });
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Apply vegetarian filter
        final RecipeRequestParams params = RecipeRequestParams(
          ingredients: ingredients,
          filters: ['vegetarian'],
        );
        
        final Stopwatch stopwatch = Stopwatch()..start();
        final OptimizedRecipeResult result = await service.getRecipes(params);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.fromCache, isTrue);
        // Should filter out meat recipe, keeping vegan and dairy recipes
        expect(result.paginatedResult.recipes.length, lessThanOrEqualTo(2));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });

      test('should sort recipes efficiently', () async {
        // Arrange
        final List<String> ingredients = ['ingredients'];
        final List<Recipe> allRecipes = [
          _createTestRecipe('1', 'Hard Recipe', 90.0, cookingTime: 120, difficulty: 'hard'),
          _createTestRecipe('2', 'Easy Recipe', 85.0, cookingTime: 30, difficulty: 'easy'),
          _createTestRecipe('3', 'Medium Recipe', 95.0, cookingTime: 60, difficulty: 'medium'),
        ];
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: allRecipes,
          totalFound: 3,
          generationTime: 2000,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'sort_test_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async {
              final List<Recipe> recipes = invocation.positionalArguments[0] as List<Recipe>;
              return PaginatedRecipeResult(
                recipes: recipes,
                currentPage: 1,
                totalPages: 1,
                totalRecipes: recipes.length,
                hasNextPage: false,
                hasPreviousPage: false,
              );
            });
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Sort by cooking time
        final RecipeRequestParams params = RecipeRequestParams(
          ingredients: ingredients,
          sortBy: 'time',
        );
        
        final OptimizedRecipeResult result = await service.getRecipes(params);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.paginatedResult.recipes.length, equals(3));
        
        // Should be sorted by cooking time (ascending)
        final List<Recipe> sortedRecipes = result.paginatedResult.recipes;
        expect(sortedRecipes[0].cookingTime, lessThanOrEqualTo(sortedRecipes[1].cookingTime));
        expect(sortedRecipes[1].cookingTime, lessThanOrEqualTo(sortedRecipes[2].cookingTime));
      });
    });

    group('Cache Statistics', () {
      test('should provide accurate cache statistics', () async {
        // Arrange
        when(mockCacheService.getCacheSize())
            .thenAnswer((_) async => 1024 * 1024); // 1MB

        // Act
        final Map<String, dynamic> stats = await service.getCacheStats();

        // Assert
        expect(stats['cacheSize'], equals(1024 * 1024));
        expect(stats['cacheSizeFormatted'], equals('1.0 MB'));
        expect(stats['activeRequests'], equals(0));
        expect(stats['scheduledPreloads'], equals(0));
        expect(stats['timestamp'], isNotNull);
        
        verify(mockCacheService.getCacheSize()).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        // Arrange
        final List<String> ingredients = ['error_ingredient'];
        final RecipeRequestParams params = RecipeRequestParams(ingredients: ingredients);

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenThrow(Exception('Cache error'));
        when(mockAIService.generateRecipesByIngredients(ingredients))
            .thenThrow(Exception('AI service error'));

        // Act
        final OptimizedRecipeResult result = await service.getRecipes(params);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('error'));
      });

      test('should validate input parameters', () async {
        // Arrange
        final RecipeRequestParams params = RecipeRequestParams(ingredients: []);

        // Act
        final OptimizedRecipeResult result = await service.getRecipes(params);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('No ingredients provided'));
        
        verifyNever(mockCacheService.getCachedRecipes(any));
        verifyNever(mockAIService.generateRecipesByIngredients(any));
      });
    });
  });
}

// Helper function to create test recipes
Recipe _createTestRecipe(
  String id,
  String title,
  double matchPercentage, {
  List<String>? ingredients,
  int cookingTime = 30,
  String difficulty = 'easy',
}) {
  return Recipe(
    id: id,
    title: title,
    ingredients: ingredients ?? ['test ingredient'],
    instructions: ['Test instruction'],
    cookingTime: cookingTime,
    servings: 4,
    matchPercentage: matchPercentage,
    nutrition: const NutritionInfo(
      calories: 300,
      protein: 20.0,
      carbohydrates: 30.0,
      fat: 10.0,
      fiber: 5.0,
      sugar: 5.0,
      sodium: 500.0,
      servingSize: '1 serving',
    ),
    allergens: const [],
    intolerances: const [],
    usedIngredients: ingredients ?? ['test ingredient'],
    missingIngredients: const [],
    difficulty: difficulty,
  );
}