import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/recipe_book_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/services/subscription_service.dart';
import '../../lib/services/ai_recipe_service.dart';
import '../../lib/models/app_state.dart';
import '../../lib/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RecipeBookService', () {
    late RecipeBookService recipeBookService;
    late StorageService storageService;
    late SubscriptionServiceImpl subscriptionService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // Create real services for integration testing
      storageService = StorageService();
      await storageService.initialize();
      
      subscriptionService = SubscriptionServiceImpl(prefs);
      await subscriptionService.initialize();
      
      recipeBookService = RecipeBookService(
        storageService: storageService,
        subscriptionService: subscriptionService,
      );
    });

    tearDown(() async {
      await storageService.dispose();
      subscriptionService.dispose();
    });

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

    group('hasRecipeBookAccess', () {
      test('should return false for free tier', () async {
        // Free tier by default
        final result = await recipeBookService.hasRecipeBookAccess();
        expect(result, isFalse);
      });

      test('should return true after upgrading to premium', () async {
        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        final result = await recipeBookService.hasRecipeBookAccess();
        expect(result, isTrue);
      });

      test('should return true after upgrading to professional', () async {
        // Upgrade to professional
        await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        
        final result = await recipeBookService.hasRecipeBookAccess();
        expect(result, isTrue);
      });
    });

    group('saveRecipe', () {
      test('should throw exception when user does not have access', () async {
        // Free tier by default - no recipe book access
        expect(
          () => recipeBookService.saveRecipe(testRecipe),
          throwsA(isA<RecipeBookException>()
              .having((e) => e.code, 'code', 'SUBSCRIPTION_REQUIRED')),
        );
      });

      test('should save recipe successfully when user has premium access', () async {
        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Should not throw
        await recipeBookService.saveRecipe(
          testRecipe,
          category: 'Main Course',
          tags: ['healthy', 'quick'],
        );

        // Verify recipe was saved
        final savedRecipes = await recipeBookService.getSavedRecipes();
        expect(savedRecipes.length, 1);
        expect(savedRecipes.first.title, 'Test Recipe');
        expect(savedRecipes.first.category, 'Main Course');
        expect(savedRecipes.first.tags, ['healthy', 'quick']);
      });

      test('should throw exception when recipe is already saved', () async {
        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Save recipe first time
        await recipeBookService.saveRecipe(testRecipe);

        // Try to save again - should throw
        expect(
          () => recipeBookService.saveRecipe(testRecipe),
          throwsA(isA<RecipeBookException>()
              .having((e) => e.code, 'code', 'RECIPE_ALREADY_SAVED')),
        );
      });
    });

    group('getSavedRecipes', () {
      test('should return empty list when no recipes saved', () async {
        final result = await recipeBookService.getSavedRecipes();
        expect(result, isEmpty);
      });

      test('should return saved recipes', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe);

        final result = await recipeBookService.getSavedRecipes();
        expect(result.length, 1);
        expect(result.first.title, 'Test Recipe');
      });
    });

    group('deleteRecipe', () {
      test('should delete recipe successfully', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe);

        // Verify recipe exists
        var recipes = await recipeBookService.getSavedRecipes();
        expect(recipes.length, 1);

        // Delete recipe
        await recipeBookService.deleteRecipe('recipe_1');

        // Verify recipe is deleted
        recipes = await recipeBookService.getSavedRecipes();
        expect(recipes, isEmpty);
      });
    });

    group('searchSavedRecipes', () {
      test('should return all recipes when query is empty', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe);

        final result = await recipeBookService.searchSavedRecipes('  ');
        expect(result.length, 1);
      });

      test('should return matching recipes', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe);

        final result = await recipeBookService.searchSavedRecipes('Test');
        expect(result.length, 1);
        expect(result.first.title, 'Test Recipe');
      });

      test('should return empty list when no matches', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe);

        final result = await recipeBookService.searchSavedRecipes('NonExistent');
        expect(result, isEmpty);
      });
    });

    group('getRecipesByCategory', () {
      test('should return recipes by category', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe, category: 'Main Course');

        final result = await recipeBookService.getRecipesByCategory('Main Course');
        expect(result.length, 1);
        expect(result.first.category, 'Main Course');
      });

      test('should return empty list for non-existent category', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe, category: 'Main Course');

        final result = await recipeBookService.getRecipesByCategory('Dessert');
        expect(result, isEmpty);
      });
    });

    group('getCategories', () {
      test('should return empty list when no recipes', () async {
        final result = await recipeBookService.getCategories();
        expect(result, isEmpty);
      });

      test('should return sorted unique categories', () async {
        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Save recipes with different categories
        await recipeBookService.saveRecipe(testRecipe, category: 'Main Course');
        
        final recipe2 = Recipe(
          id: 'recipe_2',
          title: 'Test Recipe 2',
          ingredients: ['ingredient1'],
          instructions: ['step1'],
          cookingTime: 20,
          servings: 2,
          matchPercentage: 90.0,
          nutrition: const NutritionInfo(
            calories: 200,
            protein: 10.0,
            carbohydrates: 25.0,
            fat: 5.0,
            fiber: 3.0,
            sugar: 8.0,
            sodium: 300.0,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: ['ingredient1'],
          missingIngredients: [],
          difficulty: 'easy',
        );
        
        await recipeBookService.saveRecipe(recipe2, category: 'Appetizer');

        final result = await recipeBookService.getCategories();
        expect(result, ['Appetizer', 'Main Course']);
      });
    });

    group('getTags', () {
      test('should return empty list when no recipes', () async {
        final result = await recipeBookService.getTags();
        expect(result, isEmpty);
      });

      test('should return sorted unique tags', () async {
        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Save recipes with different tags
        await recipeBookService.saveRecipe(testRecipe, tags: ['healthy', 'quick']);
        
        final recipe2 = Recipe(
          id: 'recipe_2',
          title: 'Test Recipe 2',
          ingredients: ['ingredient1'],
          instructions: ['step1'],
          cookingTime: 20,
          servings: 2,
          matchPercentage: 90.0,
          nutrition: const NutritionInfo(
            calories: 200,
            protein: 10.0,
            carbohydrates: 25.0,
            fat: 5.0,
            fiber: 3.0,
            sugar: 8.0,
            sodium: 300.0,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: ['ingredient1'],
          missingIngredients: [],
          difficulty: 'easy',
        );
        
        await recipeBookService.saveRecipe(recipe2, tags: ['quick', 'vegetarian']);

        final result = await recipeBookService.getTags();
        expect(result, ['healthy', 'quick', 'vegetarian']);
      });
    });

    group('isRecipeSaved', () {
      test('should return false when recipe is not saved', () async {
        final result = await recipeBookService.isRecipeSaved('recipe_1');
        expect(result, isFalse);
      });

      test('should return true when recipe is saved', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe);

        final result = await recipeBookService.isRecipeSaved('recipe_1');
        expect(result, isTrue);
      });
    });

    group('updateRecipeMetadata', () {
      test('should update recipe metadata successfully', () async {
        // Upgrade to premium and save a recipe
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        await recipeBookService.saveRecipe(testRecipe, category: 'Main Course');

        // Update metadata
        await recipeBookService.updateRecipeMetadata(
          'recipe_1',
          category: 'Dessert',
          tags: ['sweet'],
          personalNotes: 'Great recipe!',
        );

        // Verify update
        final recipe = await recipeBookService.getRecipeById('recipe_1');
        expect(recipe?.category, 'Dessert');
        expect(recipe?.tags, ['sweet']);
        expect(recipe?.personalNotes, 'Great recipe!');
      });

      test('should throw exception when recipe not found', () async {
        expect(
          () => recipeBookService.updateRecipeMetadata('non_existent', category: 'Dessert'),
          throwsA(isA<RecipeBookException>()
              .having((e) => e.code, 'code', 'RECIPE_NOT_FOUND')),
        );
      });
    });

    group('getStats', () {
      test('should return correct statistics', () async {
        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Save multiple recipes
        await recipeBookService.saveRecipe(testRecipe, category: 'Main Course', tags: ['healthy', 'quick']);
        
        final recipe2 = Recipe(
          id: 'recipe_2',
          title: 'Test Recipe 2',
          ingredients: ['ingredient1'],
          instructions: ['step1'],
          cookingTime: 20,
          servings: 2,
          matchPercentage: 90.0,
          nutrition: const NutritionInfo(
            calories: 200,
            protein: 10.0,
            carbohydrates: 25.0,
            fat: 5.0,
            fiber: 3.0,
            sugar: 8.0,
            sodium: 300.0,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: ['ingredient1'],
          missingIngredients: [],
          difficulty: 'easy',
        );
        
        await recipeBookService.saveRecipe(recipe2, category: 'Main Course', tags: ['quick']);

        final stats = await recipeBookService.getStats();
        expect(stats.totalRecipes, 2);
        expect(stats.totalCategories, 1);
        expect(stats.totalTags, 2);
        expect(stats.difficultyDistribution, {'medium': 1, 'easy': 1});
        expect(stats.averageCookingTime, 25.0);
        expect(stats.mostUsedCategory, 'Main Course');
        expect(stats.recentlySaved.length, 2);
      });
    });
  });
}