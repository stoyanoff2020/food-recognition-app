import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/services/ai_recipe_service.dart';
import '../../lib/services/recipe_cache_service.dart';
import '../../lib/services/optimized_recipe_service.dart';

void main() {
  group('Recipe Display Performance Tests', () {
    late OptimizedRecipeService service;
    late MockAIRecipeService mockAIService;
    late MockRecipeCacheService mockCacheService;

    setUp(() {
      mockAIService = MockAIRecipeService();
      mockCacheService = MockRecipeCacheService();
      service = OptimizedRecipeService(
        aiRecipeService: mockAIService,
        cacheService: mockCacheService,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('Large Dataset Performance', () {
      test('should handle 1000 recipes efficiently', () async {
        // Arrange
        final List<String> ingredients = ['test'];
        final List<Recipe> largeRecipeList = _generateLargeRecipeList(1000);
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: largeRecipeList,
          totalFound: 1000,
          generationTime: 5000,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'large_dataset_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async => _mockPagination(invocation));
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act & Assert - Test multiple pages
        final List<int> pagesToTest = [1, 5, 10, 25, 50, 100];
        
        for (final int page in pagesToTest) {
          final Stopwatch stopwatch = Stopwatch()..start();
          
          final OptimizedRecipeResult result = await service.getRecipes(
            RecipeRequestParams(
              ingredients: ingredients,
              page: page,
              pageSize: 10,
            ),
          );
          
          stopwatch.stop();
          
          expect(result.isSuccess, isTrue, reason: 'Page $page should succeed');
          expect(result.paginatedResult.recipes.length, equals(10), reason: 'Page $page should have 10 recipes');
          expect(stopwatch.elapsedMilliseconds, lessThan(50), reason: 'Page $page should load in under 50ms');
          
          print('Page $page loaded in ${stopwatch.elapsedMilliseconds}ms');
        }
      });

      test('should maintain performance with complex filtering', () async {
        // Arrange
        final List<String> ingredients = ['complex_test'];
        final List<Recipe> complexRecipeList = _generateComplexRecipeList(500);
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: complexRecipeList,
          totalFound: 500,
          generationTime: 3000,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'complex_filter_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async => _mockPagination(invocation));
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act & Assert - Test different filter combinations
        final List<List<String>> filterCombinations = [
          ['vegetarian'],
          ['vegan'],
          ['gluten-free'],
          ['dairy-free'],
          ['vegetarian', 'gluten-free'],
          ['vegan', 'nut-free'],
          ['vegetarian', 'dairy-free', 'gluten-free'],
        ];
        
        for (final List<String> filters in filterCombinations) {
          final Stopwatch stopwatch = Stopwatch()..start();
          
          final OptimizedRecipeResult result = await service.getRecipes(
            RecipeRequestParams(
              ingredients: ingredients,
              page: 1,
              pageSize: 20,
              filters: filters,
            ),
          );
          
          stopwatch.stop();
          
          expect(result.isSuccess, isTrue, reason: 'Filters $filters should succeed');
          expect(stopwatch.elapsedMilliseconds, lessThan(100), reason: 'Filters $filters should apply in under 100ms');
          
          print('Filters $filters applied in ${stopwatch.elapsedMilliseconds}ms, ${result.paginatedResult.recipes.length} results');
        }
      });

      test('should handle rapid pagination requests', () async {
        // Arrange
        final List<String> ingredients = ['pagination_test'];
        final List<Recipe> recipeList = _generateLargeRecipeList(200);
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: recipeList,
          totalFound: 200,
          generationTime: 2000,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'pagination_test_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async => _mockPagination(invocation));
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Simulate rapid pagination (user scrolling quickly)
        final Stopwatch totalStopwatch = Stopwatch()..start();
        
        final List<Future<OptimizedRecipeResult>> rapidRequests = [];
        for (int page = 1; page <= 20; page++) {
          rapidRequests.add(service.getRecipes(
            RecipeRequestParams(
              ingredients: ingredients,
              page: page,
              pageSize: 10,
            ),
          ));
        }
        
        final List<OptimizedRecipeResult> results = await Future.wait(rapidRequests);
        totalStopwatch.stop();

        // Assert
        expect(results.length, equals(20));
        for (int i = 0; i < results.length; i++) {
          expect(results[i].isSuccess, isTrue, reason: 'Page ${i + 1} should succeed');
          expect(results[i].paginatedResult.currentPage, equals(i + 1));
        }
        
        expect(totalStopwatch.elapsedMilliseconds, lessThan(1000), reason: '20 pages should load in under 1 second');
        print('20 rapid pagination requests completed in ${totalStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Performance', () {
      test('should not leak memory with repeated requests', () async {
        // Arrange
        final List<String> ingredients = ['memory_test'];
        final List<Recipe> recipeList = _generateLargeRecipeList(100);
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: recipeList,
          totalFound: 100,
          generationTime: 1500,
        );
        
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'memory_test_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async => _mockPagination(invocation));
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Make many repeated requests
        for (int i = 0; i < 100; i++) {
          final OptimizedRecipeResult result = await service.getRecipes(
            RecipeRequestParams(
              ingredients: ingredients,
              page: (i % 10) + 1, // Cycle through pages 1-10
              pageSize: 10,
            ),
          );
          
          expect(result.isSuccess, isTrue);
          
          // Simulate some processing time
          await Future.delayed(const Duration(milliseconds: 1));
        }

        // Assert - Service should still be responsive
        final Stopwatch finalStopwatch = Stopwatch()..start();
        final OptimizedRecipeResult finalResult = await service.getRecipes(
          RecipeRequestParams(ingredients: ingredients, page: 1, pageSize: 10),
        );
        finalStopwatch.stop();

        expect(finalResult.isSuccess, isTrue);
        expect(finalStopwatch.elapsedMilliseconds, lessThan(50), reason: 'Service should remain responsive after many requests');
        
        print('Service remained responsive after 100 requests: ${finalStopwatch.elapsedMilliseconds}ms');
      });

      test('should handle concurrent requests without memory issues', () async {
        // Arrange
        final List<Recipe> recipeList = _generateLargeRecipeList(50);
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: recipeList,
          totalFound: 50,
          generationTime: 1000,
        );

        when(mockCacheService.getCachedRecipes(any))
            .thenAnswer((_) async => CachedRecipeResult(
              result: generationResult,
              cachedAt: DateTime.now(),
              cacheKey: 'concurrent_test_key',
              fromCache: true,
            ));
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async => _mockPagination(invocation));
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - Create many concurrent requests with different parameters
        final List<Future<OptimizedRecipeResult>> concurrentRequests = [];
        
        for (int i = 0; i < 50; i++) {
          concurrentRequests.add(service.getRecipes(
            RecipeRequestParams(
              ingredients: ['ingredient_$i'],
              page: (i % 5) + 1,
              pageSize: 10,
              sortBy: i % 2 == 0 ? 'match' : 'time',
              filters: i % 3 == 0 ? ['vegetarian'] : [],
            ),
          ));
        }
        
        final Stopwatch concurrentStopwatch = Stopwatch()..start();
        final List<OptimizedRecipeResult> results = await Future.wait(concurrentRequests);
        concurrentStopwatch.stop();

        // Assert
        expect(results.length, equals(50));
        for (int i = 0; i < results.length; i++) {
          expect(results[i].isSuccess, isTrue, reason: 'Concurrent request $i should succeed');
        }
        
        expect(concurrentStopwatch.elapsedMilliseconds, lessThan(2000), reason: '50 concurrent requests should complete in under 2 seconds');
        print('50 concurrent requests completed in ${concurrentStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Cache Performance', () {
      test('should demonstrate significant cache performance improvement', () async {
        // Arrange
        final List<String> ingredients = ['cache_performance_test'];
        final List<Recipe> recipeList = _generateLargeRecipeList(100);
        
        final RecipeGenerationResult generationResult = RecipeGenerationResult.success(
          recipes: recipeList,
          totalFound: 100,
          generationTime: 3000, // Simulate slow generation
        );

        // First request - cache miss
        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => null);
        when(mockAIService.generateRecipesByIngredients(ingredients))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
              return generationResult;
            });
        when(mockCacheService.cacheRecipes(ingredients, generationResult))
            .thenAnswer((_) async {});
        when(mockCacheService.getPaginatedRecipes(any, any, any))
            .thenAnswer((invocation) async => _mockPagination(invocation));
        when(mockCacheService.preloadRecipeImages(any))
            .thenAnswer((_) async {});

        // Act - First request (cache miss)
        final Stopwatch cacheMissStopwatch = Stopwatch()..start();
        final OptimizedRecipeResult cacheMissResult = await service.getRecipes(
          RecipeRequestParams(ingredients: ingredients, page: 1, pageSize: 10),
        );
        cacheMissStopwatch.stop();

        // Arrange - Second request - cache hit
        final CachedRecipeResult cachedResult = CachedRecipeResult(
          result: generationResult,
          cachedAt: DateTime.now(),
          cacheKey: 'cache_hit_key',
          fromCache: true,
        );

        when(mockCacheService.getCachedRecipes(ingredients))
            .thenAnswer((_) async => cachedResult);

        // Act - Second request (cache hit)
        final Stopwatch cacheHitStopwatch = Stopwatch()..start();
        final OptimizedRecipeResult cacheHitResult = await service.getRecipes(
          RecipeRequestParams(ingredients: ingredients, page: 1, pageSize: 10),
        );
        cacheHitStopwatch.stop();

        // Assert
        expect(cacheMissResult.isSuccess, isTrue);
        expect(cacheHitResult.isSuccess, isTrue);
        expect(cacheMissResult.fromCache, isFalse);
        expect(cacheHitResult.fromCache, isTrue);
        
        // Cache hit should be significantly faster
        final double speedImprovement = cacheMissStopwatch.elapsedMilliseconds / cacheHitStopwatch.elapsedMilliseconds;
        expect(speedImprovement, greaterThan(5.0), reason: 'Cache should provide at least 5x speed improvement');
        
        print('Cache miss: ${cacheMissStopwatch.elapsedMilliseconds}ms');
        print('Cache hit: ${cacheHitStopwatch.elapsedMilliseconds}ms');
        print('Speed improvement: ${speedImprovement.toStringAsFixed(1)}x');
      });
    });
  });
}

// Helper functions
List<Recipe> _generateLargeRecipeList(int count) {
  final Random random = Random(42); // Fixed seed for consistent tests
  final List<String> cuisines = ['Italian', 'Mexican', 'Asian', 'American', 'Mediterranean'];
  final List<String> difficulties = ['easy', 'medium', 'hard'];
  final List<String> commonIngredients = ['chicken', 'beef', 'vegetables', 'rice', 'pasta', 'cheese', 'tomatoes'];
  
  return List.generate(count, (index) {
    final String cuisine = cuisines[index % cuisines.length];
    final String difficulty = difficulties[index % difficulties.length];
    final List<String> ingredients = [
      commonIngredients[index % commonIngredients.length],
      commonIngredients[(index + 1) % commonIngredients.length],
    ];
    
    return Recipe(
      id: 'recipe_$index',
      title: '$cuisine Recipe $index',
      ingredients: ingredients,
      instructions: ['Step 1', 'Step 2', 'Step 3'],
      cookingTime: 20 + (index % 60), // 20-80 minutes
      servings: 2 + (index % 6), // 2-8 servings
      matchPercentage: 50.0 + (index % 50), // 50-100% match
      nutrition: NutritionInfo(
        calories: 200 + (index % 400), // 200-600 calories
        protein: 10.0 + (index % 30), // 10-40g protein
        carbohydrates: 20.0 + (index % 50), // 20-70g carbs
        fat: 5.0 + (index % 25), // 5-30g fat
        fiber: 2.0 + (index % 10), // 2-12g fiber
        sugar: 1.0 + (index % 15), // 1-16g sugar
        sodium: 300.0 + (index % 700), // 300-1000mg sodium
        servingSize: '1 serving',
      ),
      allergens: index % 3 == 0 ? [
        const Allergen(name: 'Dairy', severity: 'medium', description: 'Contains milk'),
      ] : [],
      intolerances: index % 4 == 0 ? [
        const Intolerance(name: 'Lactose', type: 'lactose', description: 'Contains lactose'),
      ] : [],
      usedIngredients: ingredients,
      missingIngredients: index % 5 == 0 ? ['salt', 'pepper'] : [],
      difficulty: difficulty,
    );
  });
}

List<Recipe> _generateComplexRecipeList(int count) {
  final Random random = Random(123); // Fixed seed for consistent tests
  final List<String> allergenTypes = ['Dairy', 'Nuts', 'Gluten', 'Shellfish', 'Eggs'];
  final List<String> intoleranceTypes = ['lactose', 'gluten', 'nuts'];
  final List<String> meatIngredients = ['chicken', 'beef', 'pork', 'fish'];
  final List<String> dairyIngredients = ['milk', 'cheese', 'butter', 'yogurt'];
  final List<String> glutenIngredients = ['wheat flour', 'bread', 'pasta'];
  
  return List.generate(count, (index) {
    final bool hasMeat = index % 3 == 0;
    final bool hasDairy = index % 4 == 0;
    final bool hasGluten = index % 5 == 0;
    
    final List<String> ingredients = ['vegetables'];
    final List<Allergen> allergens = [];
    final List<Intolerance> intolerances = [];
    
    if (hasMeat) {
      ingredients.add(meatIngredients[index % meatIngredients.length]);
    }
    
    if (hasDairy) {
      ingredients.add(dairyIngredients[index % dairyIngredients.length]);
      allergens.add(const Allergen(name: 'Dairy', severity: 'medium', description: 'Contains dairy'));
      intolerances.add(const Intolerance(name: 'Lactose', type: 'lactose', description: 'Contains lactose'));
    }
    
    if (hasGluten) {
      ingredients.add(glutenIngredients[index % glutenIngredients.length]);
      allergens.add(const Allergen(name: 'Gluten', severity: 'high', description: 'Contains gluten'));
      intolerances.add(const Intolerance(name: 'Gluten', type: 'gluten', description: 'Contains gluten'));
    }
    
    return Recipe(
      id: 'complex_recipe_$index',
      title: 'Complex Recipe $index',
      ingredients: ingredients,
      instructions: ['Complex step 1', 'Complex step 2'],
      cookingTime: 30 + (index % 90),
      servings: 4,
      matchPercentage: 60.0 + (index % 40),
      nutrition: NutritionInfo(
        calories: 250 + (index % 350),
        protein: 15.0 + (index % 25),
        carbohydrates: 25.0 + (index % 45),
        fat: 8.0 + (index % 20),
        fiber: 3.0 + (index % 8),
        sugar: 2.0 + (index % 12),
        sodium: 400.0 + (index % 600),
        servingSize: '1 serving',
      ),
      allergens: allergens,
      intolerances: intolerances,
      usedIngredients: ingredients,
      missingIngredients: [],
      difficulty: ['easy', 'medium', 'hard'][index % 3],
    );
  });
}

PaginatedRecipeResult _mockPagination(Invocation invocation) {
  final List<Recipe> recipes = invocation.positionalArguments[0] as List<Recipe>;
  final int page = invocation.positionalArguments[1] as int;
  final int pageSize = invocation.positionalArguments[2] as int;
  
  final int startIndex = (page - 1) * pageSize;
  final int endIndex = (startIndex + pageSize).clamp(0, recipes.length);
  final List<Recipe> pageRecipes = startIndex < recipes.length 
      ? recipes.sublist(startIndex, endIndex)
      : <Recipe>[];
  
  return PaginatedRecipeResult(
    recipes: pageRecipes,
    currentPage: page,
    totalPages: (recipes.length / pageSize).ceil(),
    totalRecipes: recipes.length,
    hasNextPage: page < (recipes.length / pageSize).ceil(),
    hasPreviousPage: page > 1,
  );
}

// Mock classes
class MockAIRecipeService extends Mock implements AIRecipeServiceInterface {}
class MockRecipeCacheService extends Mock implements RecipeCacheServiceInterface {}