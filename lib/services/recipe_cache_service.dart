import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_recipe_service.dart';

// Recipe cache configuration
class RecipeCacheConfig {
  static const Duration cacheMaxAge = Duration(hours: 24);
  static const int maxCacheObjects = 200;
  static const int maxMemoryCacheSize = 50;
  static const String cacheKeyPrefix = 'recipe_cache_';
  static const String metadataCacheKey = 'recipe_metadata_cache';
}

// Cached recipe result
class CachedRecipeResult {
  final RecipeGenerationResult result;
  final DateTime cachedAt;
  final String cacheKey;
  final bool fromCache;

  const CachedRecipeResult({
    required this.result,
    required this.cachedAt,
    required this.cacheKey,
    required this.fromCache,
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > RecipeCacheConfig.cacheMaxAge;

  Map<String, dynamic> toJson() {
    return {
      'result': {
        'recipes': result.recipes.map((r) => r.toJson()).toList(),
        'totalFound': result.totalFound,
        'generationTime': result.generationTime,
        'alternativeSuggestions': result.alternativeSuggestions.map((r) => r.toJson()).toList(),
        'errorMessage': result.errorMessage,
        'isSuccess': result.isSuccess,
      },
      'cachedAt': cachedAt.toIso8601String(),
      'cacheKey': cacheKey,
    };
  }

  factory CachedRecipeResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> resultJson = json['result'] as Map<String, dynamic>;
    
    return CachedRecipeResult(
      result: RecipeGenerationResult(
        recipes: (resultJson['recipes'] as List)
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList(),
        totalFound: resultJson['totalFound'] as int,
        generationTime: resultJson['generationTime'] as int,
        alternativeSuggestions: (resultJson['alternativeSuggestions'] as List)
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList(),
        errorMessage: resultJson['errorMessage'] as String?,
        isSuccess: resultJson['isSuccess'] as bool,
      ),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      cacheKey: json['cacheKey'] as String,
      fromCache: true,
    );
  }
}

// Paginated recipe result
class PaginatedRecipeResult {
  final List<Recipe> recipes;
  final int currentPage;
  final int totalPages;
  final int totalRecipes;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedRecipeResult({
    required this.recipes,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecipes,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  @override
  String toString() {
    return 'PaginatedRecipeResult(page: $currentPage/$totalPages, recipes: ${recipes.length}/$totalRecipes)';
  }
}

// Recipe cache service interface
abstract class RecipeCacheServiceInterface {
  Future<CachedRecipeResult?> getCachedRecipes(List<String> ingredients);
  Future<void> cacheRecipes(List<String> ingredients, RecipeGenerationResult result);
  Future<PaginatedRecipeResult> getPaginatedRecipes(List<Recipe> allRecipes, int page, int pageSize);
  Future<void> preloadRecipeImages(List<Recipe> recipes);
  Future<void> clearCache();
  Future<int> getCacheSize();
  void dispose();
}

// Optimized recipe cache service
class RecipeCacheService implements RecipeCacheServiceInterface {
  static const String _cacheManagerKey = 'recipe_cache_manager';
  
  late final DefaultCacheManager _cacheManager;
  late final SharedPreferences _prefs;
  final Map<String, CachedRecipeResult> _memoryCache = {};
  final Map<String, Completer<CachedRecipeResult?>> _loadingCache = {};
  bool _initialized = false;

  RecipeCacheService() {
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    if (_initialized) return;
    
    _cacheManager = DefaultCacheManager();
    _prefs = await SharedPreferences.getInstance();
    
    // Load memory cache from persistent storage
    await _loadMemoryCache();
    
    _initialized = true;
    debugPrint('Recipe cache service initialized');
  }

  Future<void> _loadMemoryCache() async {
    try {
      final String? metadataJson = _prefs.getString(RecipeCacheConfig.metadataCacheKey);
      if (metadataJson != null) {
        final Map<String, dynamic> metadata = jsonDecode(metadataJson);
        final List<String> cacheKeys = List<String>.from(metadata['keys'] ?? []);
        
        // Load recent cache entries into memory
        int loaded = 0;
        for (final String cacheKey in cacheKeys.take(RecipeCacheConfig.maxMemoryCacheSize)) {
          final CachedRecipeResult? cached = await _loadFromDisk(cacheKey);
          if (cached != null && !cached.isExpired) {
            _memoryCache[cacheKey] = cached;
            loaded++;
          }
        }
        
        debugPrint('Loaded $loaded cached recipe results into memory');
      }
    } catch (e) {
      debugPrint('Error loading memory cache: $e');
    }
  }

  String _generateCacheKey(List<String> ingredients) {
    // Sort ingredients for consistent cache keys
    final List<String> sortedIngredients = List.from(ingredients)..sort();
    final String input = sortedIngredients.join(',').toLowerCase();
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return '${RecipeCacheConfig.cacheKeyPrefix}${digest.toString()}';
  }

  @override
  Future<CachedRecipeResult?> getCachedRecipes(List<String> ingredients) async {
    await _initializeCache();
    
    if (ingredients.isEmpty) return null;
    
    final String cacheKey = _generateCacheKey(ingredients);
    
    // Check if already loading
    if (_loadingCache.containsKey(cacheKey)) {
      return await _loadingCache[cacheKey]!.future;
    }
    
    // Check memory cache first
    final CachedRecipeResult? memoryResult = _memoryCache[cacheKey];
    if (memoryResult != null && !memoryResult.isExpired) {
      debugPrint('Recipe cache hit (memory): $cacheKey');
      return memoryResult;
    }
    
    // Create loading completer
    final Completer<CachedRecipeResult?> completer = Completer<CachedRecipeResult?>();
    _loadingCache[cacheKey] = completer;
    
    try {
      // Check disk cache
      final CachedRecipeResult? diskResult = await _loadFromDisk(cacheKey);
      if (diskResult != null && !diskResult.isExpired) {
        debugPrint('Recipe cache hit (disk): $cacheKey');
        
        // Update memory cache
        _updateMemoryCache(cacheKey, diskResult);
        
        completer.complete(diskResult);
        return diskResult;
      }
      
      debugPrint('Recipe cache miss: $cacheKey');
      completer.complete(null);
      return null;
      
    } catch (e) {
      debugPrint('Error loading cached recipes: $e');
      completer.complete(null);
      return null;
    } finally {
      _loadingCache.remove(cacheKey);
    }
  }

  Future<CachedRecipeResult?> _loadFromDisk(String cacheKey) async {
    try {
      final FileInfo? fileInfo = await _cacheManager.getFileFromCache(cacheKey);
      if (fileInfo != null && fileInfo.validTill.isAfter(DateTime.now())) {
        final String cachedData = await fileInfo.file.readAsString();
        final Map<String, dynamic> json = jsonDecode(cachedData);
        return CachedRecipeResult.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading from disk cache: $e');
    }
    return null;
  }

  @override
  Future<void> cacheRecipes(List<String> ingredients, RecipeGenerationResult result) async {
    await _initializeCache();
    
    if (ingredients.isEmpty || !result.isSuccess) return;
    
    final String cacheKey = _generateCacheKey(ingredients);
    final CachedRecipeResult cachedResult = CachedRecipeResult(
      result: result,
      cachedAt: DateTime.now(),
      cacheKey: cacheKey,
      fromCache: false,
    );
    
    try {
      // Save to disk cache
      final String jsonData = jsonEncode(cachedResult.toJson());
      final List<int> bytes = utf8.encode(jsonData);
      
      await _cacheManager.putFile(
        cacheKey,
        Uint8List.fromList(bytes),
        maxAge: RecipeCacheConfig.cacheMaxAge,
      );
      
      // Update memory cache
      _updateMemoryCache(cacheKey, cachedResult);
      
      // Update metadata
      await _updateCacheMetadata(cacheKey);
      
      debugPrint('Cached recipe result: $cacheKey (${bytes.length} bytes)');
      
    } catch (e) {
      debugPrint('Error caching recipes: $e');
    }
  }

  void _updateMemoryCache(String cacheKey, CachedRecipeResult result) {
    _memoryCache[cacheKey] = result;
    
    // Limit memory cache size
    if (_memoryCache.length > RecipeCacheConfig.maxMemoryCacheSize) {
      // Remove oldest entries
      final List<String> keys = _memoryCache.keys.toList();
      final List<MapEntry<String, CachedRecipeResult>> entries = keys
          .map((key) => MapEntry(key, _memoryCache[key]!))
          .toList();
      
      entries.sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      
      final int toRemove = _memoryCache.length - RecipeCacheConfig.maxMemoryCacheSize;
      for (int i = 0; i < toRemove; i++) {
        _memoryCache.remove(entries[i].key);
      }
    }
  }

  Future<void> _updateCacheMetadata(String cacheKey) async {
    try {
      final String? existingMetadata = _prefs.getString(RecipeCacheConfig.metadataCacheKey);
      final Map<String, dynamic> metadata = existingMetadata != null 
          ? jsonDecode(existingMetadata) 
          : <String, dynamic>{};
      
      final List<String> keys = List<String>.from(metadata['keys'] ?? []);
      
      // Add new key if not exists
      if (!keys.contains(cacheKey)) {
        keys.insert(0, cacheKey); // Add to front (most recent)
      } else {
        // Move to front
        keys.remove(cacheKey);
        keys.insert(0, cacheKey);
      }
      
      // Limit metadata size
      if (keys.length > RecipeCacheConfig.maxCacheObjects) {
        keys.removeRange(RecipeCacheConfig.maxCacheObjects, keys.length);
      }
      
      metadata['keys'] = keys;
      metadata['lastUpdated'] = DateTime.now().toIso8601String();
      
      await _prefs.setString(RecipeCacheConfig.metadataCacheKey, jsonEncode(metadata));
      
    } catch (e) {
      debugPrint('Error updating cache metadata: $e');
    }
  }

  @override
  Future<PaginatedRecipeResult> getPaginatedRecipes(List<Recipe> allRecipes, int page, int pageSize) async {
    if (allRecipes.isEmpty || pageSize <= 0 || page < 1) {
      return const PaginatedRecipeResult(
        recipes: [],
        currentPage: 1,
        totalPages: 0,
        totalRecipes: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      );
    }
    
    final int totalRecipes = allRecipes.length;
    final int totalPages = (totalRecipes / pageSize).ceil();
    final int startIndex = (page - 1) * pageSize;
    final int endIndex = (startIndex + pageSize).clamp(0, totalRecipes);
    
    final List<Recipe> pageRecipes = startIndex < totalRecipes 
        ? allRecipes.sublist(startIndex, endIndex)
        : <Recipe>[];
    
    return PaginatedRecipeResult(
      recipes: pageRecipes,
      currentPage: page,
      totalPages: totalPages,
      totalRecipes: totalRecipes,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    );
  }

  @override
  Future<void> preloadRecipeImages(List<Recipe> recipes) async {
    if (recipes.isEmpty) return;
    
    final List<Future<void>> preloadFutures = [];
    
    for (final Recipe recipe in recipes) {
      if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
        preloadFutures.add(_preloadSingleImage(recipe.imageUrl!));
      }
    }
    
    if (preloadFutures.isNotEmpty) {
      try {
        await Future.wait(preloadFutures, eagerError: false);
        debugPrint('Preloaded ${preloadFutures.length} recipe images');
      } catch (e) {
        debugPrint('Error preloading recipe images: $e');
      }
    }
  }

  Future<void> _preloadSingleImage(String imageUrl) async {
    try {
      await _cacheManager.getSingleFile(imageUrl);
    } catch (e) {
      debugPrint('Error preloading image $imageUrl: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    await _initializeCache();
    
    try {
      // Clear disk cache
      await _cacheManager.emptyCache();
      
      // Clear memory cache
      _memoryCache.clear();
      
      // Clear metadata
      await _prefs.remove(RecipeCacheConfig.metadataCacheKey);
      
      debugPrint('Recipe cache cleared');
    } catch (e) {
      debugPrint('Error clearing recipe cache: $e');
    }
  }

  @override
  Future<int> getCacheSize() async {
    await _initializeCache();
    
    try {
      int totalSize = 0;
      
      // Calculate disk cache size
      final String? metadataJson = _prefs.getString(RecipeCacheConfig.metadataCacheKey);
      if (metadataJson != null) {
        final Map<String, dynamic> metadata = jsonDecode(metadataJson);
        final List<String> cacheKeys = List<String>.from(metadata['keys'] ?? []);
        
        for (final String cacheKey in cacheKeys) {
          final FileInfo? fileInfo = await _cacheManager.getFileFromCache(cacheKey);
          if (fileInfo != null) {
            final int fileSize = await fileInfo.file.length();
            totalSize += fileSize;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    _memoryCache.clear();
    _loadingCache.clear();
    debugPrint('Recipe cache service disposed');
  }
}

// Recipe cache service factory
class RecipeCacheServiceFactory {
  static RecipeCacheServiceInterface create() {
    return RecipeCacheService();
  }
}