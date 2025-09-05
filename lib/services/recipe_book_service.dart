import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../models/subscription.dart';
import '../services/ai_recipe_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

/// Exception thrown when recipe book operations fail
class RecipeBookException implements Exception {
  final String message;
  final String? code;
  
  const RecipeBookException(this.message, {this.code});
  
  @override
  String toString() => 'RecipeBookException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Service interface for recipe book functionality
abstract class RecipeBookServiceInterface {
  /// Save a recipe to the user's recipe book
  /// Requires Premium+ subscription
  Future<void> saveRecipe(Recipe recipe, {String? category, List<String>? tags});
  
  /// Get all saved recipes
  Future<List<SavedRecipe>> getSavedRecipes();
  
  /// Delete a recipe from the recipe book
  Future<void> deleteRecipe(String recipeId);
  
  /// Search saved recipes by query
  Future<List<SavedRecipe>> searchSavedRecipes(String query);
  
  /// Get recipes by category
  Future<List<SavedRecipe>> getRecipesByCategory(String category);
  
  /// Get all available categories
  Future<List<String>> getCategories();
  
  /// Get all available tags
  Future<List<String>> getTags();
  
  /// Update recipe category and tags
  Future<void> updateRecipeMetadata(String recipeId, {String? category, List<String>? tags, String? personalNotes});
  
  /// Check if user has access to recipe book features
  Future<bool> hasRecipeBookAccess();
  
  /// Get recipe by ID
  Future<SavedRecipe?> getRecipeById(String recipeId);
  
  /// Check if a recipe is already saved
  Future<bool> isRecipeSaved(String recipeId);
  
  /// Get recipe book statistics
  Future<RecipeBookStats> getStats();
}

/// Implementation of recipe book service
class RecipeBookService implements RecipeBookServiceInterface {
  final StorageServiceInterface _storageService;
  final SubscriptionService _subscriptionService;
  
  RecipeBookService({
    required StorageServiceInterface storageService,
    required SubscriptionService subscriptionService,
  }) : _storageService = storageService,
       _subscriptionService = subscriptionService;

  @override
  Future<void> saveRecipe(Recipe recipe, {String? category, List<String>? tags}) async {
    // Check subscription access
    if (!await hasRecipeBookAccess()) {
      throw const RecipeBookException(
        'Recipe book access requires Premium or Professional subscription',
        code: 'SUBSCRIPTION_REQUIRED',
      );
    }

    try {
      // Check if recipe is already saved
      if (await isRecipeSaved(recipe.id)) {
        throw RecipeBookException(
          'Recipe "${recipe.title}" is already saved',
          code: 'RECIPE_ALREADY_SAVED',
        );
      }

      // Create saved recipe with metadata
      final savedRecipe = SavedRecipe(
        id: recipe.id,
        title: recipe.title,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        cookingTime: recipe.cookingTime,
        servings: recipe.servings,
        matchPercentage: recipe.matchPercentage,
        imageUrl: recipe.imageUrl,
        nutrition: recipe.nutrition,
        allergens: recipe.allergens,
        intolerances: recipe.intolerances,
        usedIngredients: recipe.usedIngredients,
        missingIngredients: recipe.missingIngredients,
        difficulty: recipe.difficulty,
        savedDate: DateTime.now().toIso8601String(),
        category: category ?? 'Uncategorized',
        tags: tags ?? [],
        personalNotes: null,
      );

      // Save to storage
      await _storageService.saveRecipe(savedRecipe);
      
      // Track usage
      await _subscriptionService.incrementUsage(UsageType.recipeSave);
      
      debugPrint('Recipe saved successfully: ${recipe.title}');
    } catch (e) {
      if (e is RecipeBookException) rethrow;
      throw RecipeBookException('Failed to save recipe: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> getSavedRecipes() async {
    try {
      return await _storageService.getSavedRecipes();
    } catch (e) {
      throw RecipeBookException('Failed to get saved recipes: $e');
    }
  }

  @override
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _storageService.deleteRecipe(recipeId);
      debugPrint('Recipe deleted successfully: $recipeId');
    } catch (e) {
      throw RecipeBookException('Failed to delete recipe: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> searchSavedRecipes(String query) async {
    if (query.trim().isEmpty) {
      return await getSavedRecipes();
    }

    try {
      return await _storageService.searchRecipes(query.trim());
    } catch (e) {
      throw RecipeBookException('Failed to search recipes: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> getRecipesByCategory(String category) async {
    try {
      return await _storageService.getRecipesByCategory(category);
    } catch (e) {
      throw RecipeBookException('Failed to get recipes by category: $e');
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final recipes = await getSavedRecipes();
      final categories = recipes.map((recipe) => recipe.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      throw RecipeBookException('Failed to get categories: $e');
    }
  }

  @override
  Future<List<String>> getTags() async {
    try {
      final recipes = await getSavedRecipes();
      final allTags = <String>{};
      
      for (final recipe in recipes) {
        allTags.addAll(recipe.tags);
      }
      
      final tags = allTags.toList();
      tags.sort();
      return tags;
    } catch (e) {
      throw RecipeBookException('Failed to get tags: $e');
    }
  }

  @override
  Future<void> updateRecipeMetadata(
    String recipeId, {
    String? category,
    List<String>? tags,
    String? personalNotes,
  }) async {
    try {
      // Get existing recipe
      final existingRecipe = await _storageService.getRecipeById(recipeId);
      if (existingRecipe == null) {
        throw RecipeBookException(
          'Recipe not found: $recipeId',
          code: 'RECIPE_NOT_FOUND',
        );
      }

      // Create updated recipe
      final updatedRecipe = SavedRecipe(
        id: existingRecipe.id,
        title: existingRecipe.title,
        ingredients: existingRecipe.ingredients,
        instructions: existingRecipe.instructions,
        cookingTime: existingRecipe.cookingTime,
        servings: existingRecipe.servings,
        matchPercentage: existingRecipe.matchPercentage,
        imageUrl: existingRecipe.imageUrl,
        nutrition: existingRecipe.nutrition,
        allergens: existingRecipe.allergens,
        intolerances: existingRecipe.intolerances,
        usedIngredients: existingRecipe.usedIngredients,
        missingIngredients: existingRecipe.missingIngredients,
        difficulty: existingRecipe.difficulty,
        savedDate: existingRecipe.savedDate,
        category: category ?? existingRecipe.category,
        tags: tags ?? existingRecipe.tags,
        personalNotes: personalNotes ?? existingRecipe.personalNotes,
      );

      // Save updated recipe
      await _storageService.saveRecipe(updatedRecipe);
      debugPrint('Recipe metadata updated: $recipeId');
    } catch (e) {
      if (e is RecipeBookException) rethrow;
      throw RecipeBookException('Failed to update recipe metadata: $e');
    }
  }

  @override
  Future<bool> hasRecipeBookAccess() async {
    try {
      return await _subscriptionService.hasFeatureAccess(FeatureType.recipeBook);
    } catch (e) {
      debugPrint('Error checking recipe book access: $e');
      return false;
    }
  }

  @override
  Future<SavedRecipe?> getRecipeById(String recipeId) async {
    try {
      return await _storageService.getRecipeById(recipeId);
    } catch (e) {
      throw RecipeBookException('Failed to get recipe by ID: $e');
    }
  }

  @override
  Future<bool> isRecipeSaved(String recipeId) async {
    try {
      final recipe = await _storageService.getRecipeById(recipeId);
      return recipe != null;
    } catch (e) {
      debugPrint('Error checking if recipe is saved: $e');
      return false;
    }
  }

  @override
  Future<RecipeBookStats> getStats() async {
    try {
      final recipes = await getSavedRecipes();
      final categories = await getCategories();
      final tags = await getTags();
      
      // Calculate difficulty distribution
      final difficultyCount = <String, int>{};
      for (final recipe in recipes) {
        difficultyCount[recipe.difficulty] = (difficultyCount[recipe.difficulty] ?? 0) + 1;
      }
      
      // Calculate average cooking time
      final totalCookingTime = recipes.fold<int>(0, (sum, recipe) => sum + recipe.cookingTime);
      final averageCookingTime = recipes.isNotEmpty ? totalCookingTime / recipes.length : 0.0;
      
      // Find most used category
      final categoryCount = <String, int>{};
      for (final recipe in recipes) {
        categoryCount[recipe.category] = (categoryCount[recipe.category] ?? 0) + 1;
      }
      
      String? mostUsedCategory;
      int maxCategoryCount = 0;
      for (final entry in categoryCount.entries) {
        if (entry.value > maxCategoryCount) {
          maxCategoryCount = entry.value;
          mostUsedCategory = entry.key;
        }
      }
      
      return RecipeBookStats(
        totalRecipes: recipes.length,
        totalCategories: categories.length,
        totalTags: tags.length,
        difficultyDistribution: difficultyCount,
        averageCookingTime: averageCookingTime,
        mostUsedCategory: mostUsedCategory,
        recentlySaved: recipes.take(5).toList(),
      );
    } catch (e) {
      throw RecipeBookException('Failed to get recipe book stats: $e');
    }
  }
}

/// Recipe book statistics
class RecipeBookStats {
  final int totalRecipes;
  final int totalCategories;
  final int totalTags;
  final Map<String, int> difficultyDistribution;
  final double averageCookingTime;
  final String? mostUsedCategory;
  final List<SavedRecipe> recentlySaved;

  const RecipeBookStats({
    required this.totalRecipes,
    required this.totalCategories,
    required this.totalTags,
    required this.difficultyDistribution,
    required this.averageCookingTime,
    this.mostUsedCategory,
    required this.recentlySaved,
  });
}

/// Factory for creating recipe book service instances
class RecipeBookServiceFactory {
  static RecipeBookServiceInterface create({
    required StorageServiceInterface storageService,
    required SubscriptionService subscriptionService,
  }) {
    return RecipeBookService(
      storageService: storageService,
      subscriptionService: subscriptionService,
    );
  }
}