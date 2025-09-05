import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_recognition_app/services/storage_service.dart';
import 'package:food_recognition_app/models/app_state.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    tearDown(() async {
      await storageService.dispose();
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        final result = await storageService.initialize();
        expect(result, true);
      });

      test('should return true if already initialized', () async {
        await storageService.initialize();
        final result = await storageService.initialize();
        expect(result, true);
      });
    });

    group('user preferences', () {
      test('should save and retrieve user preferences', () async {
        await storageService.initialize();
        
        const preferences = UserPreferences(
          dietaryRestrictions: ['vegetarian', 'gluten-free'],
          preferredCuisines: ['italian', 'mexican'],
          skillLevel: 'intermediate',
        );

        await storageService.saveUserPreferences(preferences);
        final retrieved = await storageService.getUserPreferences();

        expect(retrieved, isNotNull);
        expect(retrieved!.dietaryRestrictions, preferences.dietaryRestrictions);
        expect(retrieved.preferredCuisines, preferences.preferredCuisines);
        expect(retrieved.skillLevel, preferences.skillLevel);
      });

      test('should return null when no preferences saved', () async {
        await storageService.initialize();
        
        final retrieved = await storageService.getUserPreferences();
        expect(retrieved, isNull);
      });
    });

    group('onboarding data', () {
      test('should save and retrieve onboarding data', () async {
        await storageService.initialize();
        
        const data = OnboardingData(
          isComplete: true,
          completedSteps: [1, 2, 3],
          lastShownStep: 3,
          hasSeenPermissionExplanation: true,
          completionDate: '2024-01-01',
        );

        await storageService.saveOnboardingData(data);
        final retrieved = await storageService.getOnboardingData();

        expect(retrieved, isNotNull);
        expect(retrieved!.isComplete, data.isComplete);
        expect(retrieved.completedSteps, data.completedSteps);
        expect(retrieved.lastShownStep, data.lastShownStep);
        expect(retrieved.hasSeenPermissionExplanation, data.hasSeenPermissionExplanation);
        expect(retrieved.completionDate, data.completionDate);
      });
    });

    group('subscription data', () {
      test('should save and retrieve subscription data', () async {
        await storageService.initialize();
        
        final data = SubscriptionData(
          currentTier: 'premium',
          subscriptionId: 'sub_123',
          purchaseDate: '2024-01-01',
          expiryDate: '2024-12-31',
          usageHistory: [
            const UsageRecord(
              date: '2024-01-01',
              scansUsed: 5,
              adsWatched: 2,
              actionType: 'scan',
            ),
          ],
          lastQuotaReset: '2024-01-01',
        );

        await storageService.saveSubscriptionData(data);
        final retrieved = await storageService.getSubscriptionData();

        expect(retrieved, isNotNull);
        expect(retrieved!.currentTier, data.currentTier);
        expect(retrieved.subscriptionId, data.subscriptionId);
        expect(retrieved.usageHistory.length, 1);
        expect(retrieved.usageHistory.first.scansUsed, 5);
      });
    });

    group('recipes', () {
      test('should save and retrieve recipes', () async {
        await storageService.initialize();
        
        const recipe = SavedRecipe(
          id: 'recipe_1',
          title: 'Test Recipe',
          ingredients: ['ingredient1', 'ingredient2'],
          instructions: ['step1', 'step2'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 85.5,
          nutrition: NutritionInfo(
            calories: 250,
            protein: 15.0,
            carbohydrates: 30.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 500.0,
            servingSize: '1 cup',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: ['ingredient1'],
          missingIngredients: ['ingredient3'],
          difficulty: 'easy',
          savedDate: '2024-01-01',
          category: 'main',
          tags: ['quick', 'healthy'],
        );

        await storageService.saveRecipe(recipe);
        final recipes = await storageService.getSavedRecipes();

        expect(recipes.length, 1);
        expect(recipes.first.id, recipe.id);
        expect(recipes.first.title, recipe.title);
        expect(recipes.first.ingredients, recipe.ingredients);
      });

      test('should delete recipes', () async {
        await storageService.initialize();
        
        const recipe = SavedRecipe(
          id: 'recipe_1',
          title: 'Test Recipe',
          ingredients: ['ingredient1'],
          instructions: ['step1'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 85.5,
          nutrition: NutritionInfo(
            calories: 250,
            protein: 15.0,
            carbohydrates: 30.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 500.0,
            servingSize: '1 cup',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
          savedDate: '2024-01-01',
          category: 'main',
          tags: [],
        );

        await storageService.saveRecipe(recipe);
        await storageService.deleteRecipe('recipe_1');
        final recipes = await storageService.getSavedRecipes();

        expect(recipes.length, 0);
      });

      test('should search recipes', () async {
        await storageService.initialize();
        
        const recipe1 = SavedRecipe(
          id: 'recipe_1',
          title: 'Pasta Recipe',
          ingredients: ['pasta', 'tomato'],
          instructions: ['step1'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 85.5,
          nutrition: NutritionInfo(
            calories: 250,
            protein: 15.0,
            carbohydrates: 30.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 500.0,
            servingSize: '1 cup',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
          savedDate: '2024-01-01',
          category: 'main',
          tags: ['italian'],
        );

        const recipe2 = SavedRecipe(
          id: 'recipe_2',
          title: 'Salad Recipe',
          ingredients: ['lettuce', 'tomato'],
          instructions: ['step1'],
          cookingTime: 10,
          servings: 2,
          matchPercentage: 90.0,
          nutrition: NutritionInfo(
            calories: 100,
            protein: 5.0,
            carbohydrates: 15.0,
            fat: 3.0,
            fiber: 8.0,
            sugar: 5.0,
            sodium: 200.0,
            servingSize: '1 bowl',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
          savedDate: '2024-01-02',
          category: 'salad',
          tags: ['healthy'],
        );

        await storageService.saveRecipe(recipe1);
        await storageService.saveRecipe(recipe2);

        final pastaResults = await storageService.searchRecipes('pasta');
        expect(pastaResults.length, 1);
        expect(pastaResults.first.title, 'Pasta Recipe');

        final tomatoResults = await storageService.searchRecipes('tomato');
        expect(tomatoResults.length, 2);
      });

      test('should get recipes by category', () async {
        await storageService.initialize();
        
        const recipe1 = SavedRecipe(
          id: 'recipe_1',
          title: 'Main Dish',
          ingredients: ['ingredient1'],
          instructions: ['step1'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 85.5,
          nutrition: NutritionInfo(
            calories: 250,
            protein: 15.0,
            carbohydrates: 30.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 500.0,
            servingSize: '1 cup',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
          savedDate: '2024-01-01',
          category: 'main',
          tags: [],
        );

        const recipe2 = SavedRecipe(
          id: 'recipe_2',
          title: 'Dessert',
          ingredients: ['sugar'],
          instructions: ['step1'],
          cookingTime: 20,
          servings: 6,
          matchPercentage: 90.0,
          nutrition: NutritionInfo(
            calories: 300,
            protein: 3.0,
            carbohydrates: 50.0,
            fat: 12.0,
            fiber: 1.0,
            sugar: 40.0,
            sodium: 100.0,
            servingSize: '1 slice',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'medium',
          savedDate: '2024-01-02',
          category: 'dessert',
          tags: [],
        );

        await storageService.saveRecipe(recipe1);
        await storageService.saveRecipe(recipe2);

        final mainRecipes = await storageService.getRecipesByCategory('main');
        expect(mainRecipes.length, 1);
        expect(mainRecipes.first.title, 'Main Dish');

        final dessertRecipes = await storageService.getRecipesByCategory('dessert');
        expect(dessertRecipes.length, 1);
        expect(dessertRecipes.first.title, 'Dessert');
      });
    });

    group('recent searches', () {
      test('should add and retrieve recent searches', () async {
        await storageService.initialize();
        
        await storageService.addRecentSearch('pasta');
        await storageService.addRecentSearch('pizza');
        
        final searches = await storageService.getRecentSearches();
        expect(searches.length, 2);
        expect(searches.first, 'pizza'); // Most recent first
        expect(searches.last, 'pasta');
      });

      test('should limit recent searches to 10', () async {
        await storageService.initialize();
        
        // Add 12 searches
        for (int i = 1; i <= 12; i++) {
          await storageService.addRecentSearch('search$i');
        }
        
        final searches = await storageService.getRecentSearches();
        expect(searches.length, 10);
        expect(searches.first, 'search12'); // Most recent
        expect(searches.last, 'search3'); // Oldest kept
      });

      test('should clear recent searches', () async {
        await storageService.initialize();
        
        await storageService.addRecentSearch('pasta');
        await storageService.clearRecentSearches();
        
        final searches = await storageService.getRecentSearches();
        expect(searches.length, 0);
      });
    });

    group('app settings', () {
      test('should save and retrieve app settings', () async {
        await storageService.initialize();
        
        final settings = {
          'theme': 'dark',
          'notifications': true,
          'language': 'en',
        };

        await storageService.saveAppSettings(settings);
        final retrieved = await storageService.getAppSettings();

        expect(retrieved['theme'], 'dark');
        expect(retrieved['notifications'], true);
        expect(retrieved['language'], 'en');
      });
    });

    group('error handling', () {
      test('should throw StorageException when not initialized', () async {
        expect(
          () => storageService.saveUserPreferences(const UserPreferences()),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('clear all data', () {
      test('should clear all data', () async {
        await storageService.initialize();
        
        // Add some data
        await storageService.saveUserPreferences(const UserPreferences(skillLevel: 'advanced'));
        await storageService.addRecentSearch('test');
        
        // Clear all data
        await storageService.clearAllData();
        
        // Verify data is cleared
        final preferences = await storageService.getUserPreferences();
        final searches = await storageService.getRecentSearches();
        final recipes = await storageService.getSavedRecipes();
        
        expect(preferences, isNull);
        expect(searches.length, 0);
        expect(recipes.length, 0);
      });
    });
  });

  group('StorageServiceFactory', () {
    test('should create StorageService instance', () {
      final service = StorageServiceFactory.create();
      expect(service, isA<StorageServiceInterface>());
      expect(service, isA<StorageService>());
    });

    test('should create new instances each time', () {
      final service1 = StorageServiceFactory.create();
      final service2 = StorageServiceFactory.create();
      expect(service1, isNot(same(service2)));
    });
  });

  group('StorageException', () {
    test('should create exception with message', () {
      const exception = StorageException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.code, null);
    });

    test('should create exception with message and code', () {
      const exception = StorageException('Test error', code: 'STORAGE_001');
      expect(exception.message, 'Test error');
      expect(exception.code, 'STORAGE_001');
    });

    test('should format toString correctly', () {
      const exception1 = StorageException('Test error');
      expect(exception1.toString(), 'StorageException: Test error');

      const exception2 = StorageException('Test error', code: 'STORAGE_001');
      expect(exception2.toString(), 'StorageException: Test error (Code: STORAGE_001)');
    });
  });
}