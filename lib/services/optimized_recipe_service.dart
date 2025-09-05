import 'dart:async';
import 'package:flutter/foundation.dart';

import 'ai_recipe_service.dart';
import 'recipe_cache_service.dart';

// Optimized recipe service configuration
class OptimizedRecipeConfig {
  static const int defaultPageSize = 10;
  static const int maxConcurrentRequests = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 2;
}

// Recipe request parameters
class RecipeRequestParams {
  final List<String> ingredients;
  final int page;
  final int pageSize;
  final String? sortBy; // 'match', 'time', 'difficulty'
  final List<String> filters; // dietary restrictions, allergens to avoid

  const RecipeRequestParams({
    required this.ingredients,
    this.page = 1,
    this.pageSize = OptimizedRecipeConfig.defaultPageSize,
    this.sortBy,
    this.filters = const [],
  });

  @override
  String toString() {
    return 'RecipeRequestParams(ingredients: $ingredients, page: $page, pageSize: $pageSize, sortBy: $sortBy, filters: $filters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeRequestParams &&
        listEquals(other.ingredients, ingredients) &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.sortBy == sortBy &&
        listEquals(other.filters, filters);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(ingredients),
    page,
    pageSize,
    sortBy,
    Object.hashAll(filters),
  );
}

// Optimized recipe result
class OptimizedRecipeResult {
  final PaginatedRecipeResult paginatedResult;
  final bool fromCache;
  final int totalGenerationTime;
  final int cacheRetrievalTime;
  final String? errorMessage;
  final bool isSuccess;

  const OptimizedRecipeResult({
    required this.paginatedResult,
    required this.fromCache,
    required this.totalGenerationTime,
    required this.cacheRetrievalTime,
    this.errorMessage,
    this.isSuccess = true,
  });

  factory OptimizedRecipeResult.success({
    required PaginatedRecipeResult paginatedResult,
    required bool fromCache,
    required int totalGenerationTime,
    required int cacheRetrievalTime,
  }) {
    return OptimizedRecipeResult(
      paginatedResult: paginatedResult,
      fromCache: fromCache,
      totalGenerationTime: totalGenerationTime,
      cacheRetrievalTime: cacheRetrievalTime,
      isSuccess: true,
    );
  }

  factory OptimizedRecipeResult.failure({
    required String errorMessage,
    required int totalGenerationTime,
  }) {
    return OptimizedRecipeResult(
      paginatedResult: const PaginatedRecipeResult(
        recipes: [],
        currentPage: 1,
        totalPages: 0,
        totalRecipes: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      ),
      fromCache: false,
      totalGenerationTime: totalGenerationTime,
      cacheRetrievalTime: 0,
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    return 'OptimizedRecipeResult(recipes: ${paginatedResult.recipes.length}, '
           'fromCache: $fromCache, totalTime: ${totalGenerationTime}ms, '
           'cacheTime: ${cacheRetrievalTime}ms, isSuccess: $isSuccess)';
  }
}

// Optimized recipe service interface
abstract class OptimizedRecipeServiceInterface {
  Future<OptimizedRecipeResult> getRecipes(RecipeRequestParams params);
  Future<void> preloadNextPage(RecipeRequestParams params);
  Future<void> clearCache();
  Future<Map<String, dynamic>> getCacheStats();
  void dispose();
}

// Optimized recipe service implementation
class OptimizedRecipeService implements OptimizedRecipeServiceInterface {
  final AIRecipeServiceInterface _aiRecipeService;
  final RecipeCacheServiceInterface _cacheService;
  final Map<String, Completer<OptimizedRecipeResult>> _activeRequests = {};
  final Map<String, Timer> _preloadTimers = {};

  OptimizedRecipeService({
    required AIRecipeServiceInterface aiRecipeService,
    RecipeCacheServiceInterface? cacheService,
  }) : _aiRecipeService = aiRecipeService,
       _cacheService = cacheService ?? RecipeCacheServiceFactory.create();

  @override
  Future<OptimizedRecipeResult> getRecipes(RecipeRequestParams params) async {
    final Stopwatch totalStopwatch = Stopwatch()..start();
    
    try {
      // Validate parameters
      if (params.ingredients.isEmpty) {
        return OptimizedRecipeResult.failure(
          errorMessage: 'No ingredients provided',
          totalGenerationTime: totalStopwatch.elapsedMilliseconds,
        );
      }

      // Generate request key for deduplication
      final String requestKey = _generateRequestKey(params);
      
      // Check if request is already in progress
      if (_activeRequests.containsKey(requestKey)) {
        debugPrint('Recipe request already in progress, waiting for result...');
        return await _activeRequests[requestKey]!.future;
      }

      // Create completer for this request
      final Completer<OptimizedRecipeResult> completer = Completer<OptimizedRecipeResult>();
      _activeRequests[requestKey] = completer;

      try {
        final OptimizedRecipeResult result = await _processRecipeRequest(params, totalStopwatch);
        
        // Schedule preloading of next page if successful
        if (result.isSuccess && result.paginatedResult.hasNextPage) {
          _schedulePreload(params);
        }
        
        completer.complete(result);
        return result;
        
      } catch (e) {
        final OptimizedRecipeResult errorResult = OptimizedRecipeResult.failure(
          errorMessage: e.toString(),
          totalGenerationTime: totalStopwatch.elapsedMilliseconds,
        );
        completer.complete(errorResult);
        return errorResult;
      } finally {
        _activeRequests.remove(requestKey);
      }
      
    } catch (e) {
      debugPrint('Error in getRecipes: $e');
      return OptimizedRecipeResult.failure(
        errorMessage: 'Unexpected error: $e',
        totalGenerationTime: totalStopwatch.elapsedMilliseconds,
      );
    } finally {
      totalStopwatch.stop();
    }
  }

  Future<OptimizedRecipeResult> _processRecipeRequest(
    RecipeRequestParams params,
    Stopwatch totalStopwatch,
  ) async {
    final Stopwatch cacheStopwatch = Stopwatch()..start();
    
    // Try to get from cache first
    final CachedRecipeResult? cachedResult = await _cacheService.getCachedRecipes(params.ingredients);
    cacheStopwatch.stop();
    
    if (cachedResult != null && cachedResult.result.isSuccess) {
      debugPrint('Using cached recipe result');
      
      // Apply filters and sorting to cached results
      List<Recipe> filteredRecipes = _applyFiltersAndSorting(
        cachedResult.result.recipes,
        params.sortBy,
        params.filters,
      );
      
      // Get paginated results
      final PaginatedRecipeResult paginatedResult = await _cacheService.getPaginatedRecipes(
        filteredRecipes,
        params.page,
        params.pageSize,
      );
      
      // Preload images for current page
      unawaited(_cacheService.preloadRecipeImages(paginatedResult.recipes));
      
      return OptimizedRecipeResult.success(
        paginatedResult: paginatedResult,
        fromCache: true,
        totalGenerationTime: totalStopwatch.elapsedMilliseconds,
        cacheRetrievalTime: cacheStopwatch.elapsedMilliseconds,
      );
    }
    
    // Generate new recipes
    debugPrint('Generating new recipes for ingredients: ${params.ingredients}');
    final RecipeGenerationResult generationResult = await _aiRecipeService.generateRecipesByIngredients(params.ingredients);
    
    if (!generationResult.isSuccess) {
      return OptimizedRecipeResult.failure(
        errorMessage: generationResult.errorMessage ?? 'Failed to generate recipes',
        totalGenerationTime: totalStopwatch.elapsedMilliseconds,
      );
    }
    
    // Cache the results
    unawaited(_cacheService.cacheRecipes(params.ingredients, generationResult));
    
    // Apply filters and sorting
    List<Recipe> filteredRecipes = _applyFiltersAndSorting(
      generationResult.recipes,
      params.sortBy,
      params.filters,
    );
    
    // Get paginated results
    final PaginatedRecipeResult paginatedResult = await _cacheService.getPaginatedRecipes(
      filteredRecipes,
      params.page,
      params.pageSize,
    );
    
    // Preload images for current page
    unawaited(_cacheService.preloadRecipeImages(paginatedResult.recipes));
    
    return OptimizedRecipeResult.success(
      paginatedResult: paginatedResult,
      fromCache: false,
      totalGenerationTime: totalStopwatch.elapsedMilliseconds,
      cacheRetrievalTime: cacheStopwatch.elapsedMilliseconds,
    );
  }

  List<Recipe> _applyFiltersAndSorting(
    List<Recipe> recipes,
    String? sortBy,
    List<String> filters,
  ) {
    List<Recipe> filteredRecipes = List.from(recipes);
    
    // Apply dietary filters
    if (filters.isNotEmpty) {
      filteredRecipes = filteredRecipes.where((recipe) {
        return _matchesFilters(recipe, filters);
      }).toList();
    }
    
    // Apply sorting
    switch (sortBy) {
      case 'match':
        filteredRecipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
        break;
      case 'time':
        filteredRecipes.sort((a, b) => a.cookingTime.compareTo(b.cookingTime));
        break;
      case 'difficulty':
        filteredRecipes.sort((a, b) => _compareDifficulty(a.difficulty, b.difficulty));
        break;
      default:
        // Default sort by match percentage
        filteredRecipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    }
    
    return filteredRecipes;
  }

  bool _matchesFilters(Recipe recipe, List<String> filters) {
    for (final String filter in filters) {
      switch (filter.toLowerCase()) {
        case 'vegetarian':
          if (_containsMeat(recipe)) return false;
          break;
        case 'vegan':
          if (_containsAnimalProducts(recipe)) return false;
          break;
        case 'gluten-free':
          if (_containsGluten(recipe)) return false;
          break;
        case 'dairy-free':
          if (_containsDairy(recipe)) return false;
          break;
        case 'nut-free':
          if (_containsNuts(recipe)) return false;
          break;
      }
    }
    return true;
  }

  bool _containsMeat(Recipe recipe) {
    final List<String> meatKeywords = ['chicken', 'beef', 'pork', 'lamb', 'turkey', 'fish', 'salmon', 'tuna'];
    return recipe.ingredients.any((ingredient) =>
        meatKeywords.any((meat) => ingredient.toLowerCase().contains(meat)));
  }

  bool _containsAnimalProducts(Recipe recipe) {
    final List<String> animalKeywords = ['milk', 'cheese', 'butter', 'egg', 'honey', 'yogurt', 'cream'];
    return _containsMeat(recipe) || 
           recipe.ingredients.any((ingredient) =>
               animalKeywords.any((animal) => ingredient.toLowerCase().contains(animal)));
  }

  bool _containsGluten(Recipe recipe) {
    return recipe.intolerances.any((intolerance) => intolerance.type == 'gluten') ||
           recipe.ingredients.any((ingredient) => 
               ingredient.toLowerCase().contains('wheat') ||
               ingredient.toLowerCase().contains('flour') ||
               ingredient.toLowerCase().contains('bread'));
  }

  bool _containsDairy(Recipe recipe) {
    return recipe.allergens.any((allergen) => allergen.name.toLowerCase() == 'dairy') ||
           recipe.intolerances.any((intolerance) => intolerance.type == 'lactose');
  }

  bool _containsNuts(Recipe recipe) {
    return recipe.allergens.any((allergen) => allergen.name.toLowerCase().contains('nut'));
  }

  int _compareDifficulty(String a, String b) {
    const Map<String, int> difficultyOrder = {
      'easy': 1,
      'medium': 2,
      'hard': 3,
    };
    
    final int aOrder = difficultyOrder[a.toLowerCase()] ?? 2;
    final int bOrder = difficultyOrder[b.toLowerCase()] ?? 2;
    
    return aOrder.compareTo(bOrder);
  }

  String _generateRequestKey(RecipeRequestParams params) {
    return '${params.ingredients.join(',')}_${params.page}_${params.pageSize}_${params.sortBy}_${params.filters.join(',')}';
  }

  void _schedulePreload(RecipeRequestParams params) {
    final String preloadKey = _generateRequestKey(params);
    
    // Cancel existing preload timer
    _preloadTimers[preloadKey]?.cancel();
    
    // Schedule preload after a short delay
    _preloadTimers[preloadKey] = Timer(const Duration(milliseconds: 500), () {
      final RecipeRequestParams nextPageParams = RecipeRequestParams(
        ingredients: params.ingredients,
        page: params.page + 1,
        pageSize: params.pageSize,
        sortBy: params.sortBy,
        filters: params.filters,
      );
      
      unawaited(preloadNextPage(nextPageParams));
      _preloadTimers.remove(preloadKey);
    });
  }

  @override
  Future<void> preloadNextPage(RecipeRequestParams params) async {
    try {
      debugPrint('Preloading next page: ${params.page}');
      
      // Check if already cached
      final CachedRecipeResult? cachedResult = await _cacheService.getCachedRecipes(params.ingredients);
      if (cachedResult != null) {
        // Apply filters and get paginated results
        final List<Recipe> filteredRecipes = _applyFiltersAndSorting(
          cachedResult.result.recipes,
          params.sortBy,
          params.filters,
        );
        
        final PaginatedRecipeResult paginatedResult = await _cacheService.getPaginatedRecipes(
          filteredRecipes,
          params.page,
          params.pageSize,
        );
        
        // Preload images for next page
        await _cacheService.preloadRecipeImages(paginatedResult.recipes);
        debugPrint('Preloaded ${paginatedResult.recipes.length} recipe images for page ${params.page}');
      }
    } catch (e) {
      debugPrint('Error preloading next page: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _cacheService.clearCache();
      _activeRequests.clear();
      
      // Cancel all preload timers
      for (final Timer timer in _preloadTimers.values) {
        timer.cancel();
      }
      _preloadTimers.clear();
      
      debugPrint('Optimized recipe service cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final int cacheSize = await _cacheService.getCacheSize();
      
      return {
        'cacheSize': cacheSize,
        'cacheSizeFormatted': _formatBytes(cacheSize),
        'activeRequests': _activeRequests.length,
        'scheduledPreloads': _preloadTimers.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void dispose() {
    // Cancel all active requests
    for (final Completer<OptimizedRecipeResult> completer in _activeRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Service disposed'));
      }
    }
    _activeRequests.clear();
    
    // Cancel all preload timers
    for (final Timer timer in _preloadTimers.values) {
      timer.cancel();
    }
    _preloadTimers.clear();
    
    // Dispose services
    _aiRecipeService.dispose();
    _cacheService.dispose();
    
    debugPrint('Optimized recipe service disposed');
  }
}

// Optimized recipe service factory
class OptimizedRecipeServiceFactory {
  static OptimizedRecipeServiceInterface create({
    required String apiKey,
  }) {
    final AIRecipeServiceInterface aiRecipeService = AIRecipeServiceFactory.create(apiKey: apiKey);
    final RecipeCacheServiceInterface cacheService = RecipeCacheServiceFactory.create();
    
    return OptimizedRecipeService(
      aiRecipeService: aiRecipeService,
      cacheService: cacheService,
    );
  }
}