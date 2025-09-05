import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_recognition_app/providers/storage_provider.dart';
import 'package:food_recognition_app/providers/app_state_provider.dart';
import 'package:food_recognition_app/services/storage_service.dart';
import 'package:food_recognition_app/models/app_state.dart';

// Generate mocks
@GenerateMocks([StorageServiceInterface])
import 'storage_provider_test.mocks.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StorageProvider', () {
    late MockStorageServiceInterface mockStorageService;
    late AppStateProvider appStateProvider;
    late StorageProvider storageProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockStorageService = MockStorageServiceInterface();
      appStateProvider = AppStateProvider();
      storageProvider = StorageProvider(mockStorageService, appStateProvider);
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        when(mockStorageService.initialize()).thenAnswer((_) async => true);
        when(mockStorageService.getUserPreferences()).thenAnswer((_) async => null);
        when(mockStorageService.getOnboardingData()).thenAnswer((_) async => null);
        when(mockStorageService.getSubscriptionData()).thenAnswer((_) async => null);
        when(mockStorageService.getSavedRecipes()).thenAnswer((_) async => []);
        when(mockStorageService.getMealPlans()).thenAnswer((_) async => []);
        when(mockStorageService.getRecentSearches()).thenAnswer((_) async => []);

        final result = await storageProvider.initialize();

        expect(result, true);
        expect(storageProvider.isInitializing, false);
        expect(storageProvider.lastError, null);
        verify(mockStorageService.initialize()).called(1);
      });

      test('should handle initialization failure', () async {
        when(mockStorageService.initialize()).thenAnswer((_) async => false);

        final result = await storageProvider.initialize();

        expect(result, false);
        expect(storageProvider.isInitializing, false);
        expect(storageProvider.lastError, 'Failed to initialize storage');
      });

      test('should handle initialization exception', () async {
        when(mockStorageService.initialize()).thenThrow(Exception('Test error'));

        final result = await storageProvider.initialize();

        expect(result, false);
        expect(storageProvider.isInitializing, false);
        expect(storageProvider.lastError, contains('Storage initialization error'));
      });

      test('should not initialize if already initializing', () async {
        when(mockStorageService.initialize()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return true;
        });
        when(mockStorageService.getUserPreferences()).thenAnswer((_) async => null);
        when(mockStorageService.getOnboardingData()).thenAnswer((_) async => null);
        when(mockStorageService.getSubscriptionData()).thenAnswer((_) async => null);
        when(mockStorageService.getSavedRecipes()).thenAnswer((_) async => []);
        when(mockStorageService.getMealPlans()).thenAnswer((_) async => []);
        when(mockStorageService.getRecentSearches()).thenAnswer((_) async => []);

        final future1 = storageProvider.initialize();
        final future2 = storageProvider.initialize();

        final result1 = await future1;
        final result2 = await future2;

        expect(result1, true);
        expect(result2, false);
        verify(mockStorageService.initialize()).called(1);
      });
    });

    group('user preferences', () {
      test('should save user preferences', () async {
        const preferences = UserPreferences(
          dietaryRestrictions: ['vegetarian'],
          preferredCuisines: ['italian'],
          skillLevel: 'intermediate',
        );

        when(mockStorageService.saveUserPreferences(preferences))
            .thenAnswer((_) async => {});

        await storageProvider.saveUserPreferences(preferences);

        expect(storageProvider.lastError, null);
        verify(mockStorageService.saveUserPreferences(preferences)).called(1);
        expect(appStateProvider.state.user.preferences, preferences);
      });

      test('should handle save preferences error', () async {
        const preferences = UserPreferences();
        when(mockStorageService.saveUserPreferences(preferences))
            .thenThrow(StorageException('Save failed'));

        await storageProvider.saveUserPreferences(preferences);

        expect(storageProvider.lastError, contains('Failed to save user preferences'));
      });
    });

    group('onboarding data', () {
      test('should save onboarding data', () async {
        when(mockStorageService.saveOnboardingData(any))
            .thenAnswer((_) async => {});

        await storageProvider.saveOnboardingData(
          isComplete: true,
          completedSteps: [1, 2, 3],
          lastShownStep: 3,
          hasSeenPermissionExplanation: true,
          completionDate: '2024-01-01',
        );

        expect(storageProvider.lastError, null);
        verify(mockStorageService.saveOnboardingData(any)).called(1);
        expect(appStateProvider.state.onboarding.isComplete, true);
        expect(appStateProvider.state.onboarding.currentStep, 3);
      });

      test('should handle save onboarding data error', () async {
        when(mockStorageService.saveOnboardingData(any))
            .thenThrow(StorageException('Save failed'));

        await storageProvider.saveOnboardingData(
          isComplete: true,
          completedSteps: [],
          lastShownStep: 0,
          hasSeenPermissionExplanation: false,
        );

        expect(storageProvider.lastError, contains('Failed to save onboarding data'));
      });
    });

    group('recipe management', () {
      test('should save recipe', () async {
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

        when(mockStorageService.saveRecipe(recipe)).thenAnswer((_) async => {});

        await storageProvider.saveRecipe(recipe);

        expect(storageProvider.lastError, null);
        verify(mockStorageService.saveRecipe(recipe)).called(1);
        expect(appStateProvider.state.user.recipeBook.contains(recipe), true);
      });

      test('should delete recipe', () async {
        const recipeId = 'recipe_1';
        when(mockStorageService.deleteRecipe(recipeId)).thenAnswer((_) async => {});

        await storageProvider.deleteRecipe(recipeId);

        expect(storageProvider.lastError, null);
        verify(mockStorageService.deleteRecipe(recipeId)).called(1);
      });

      test('should search recipes', () async {
        const query = 'pasta';
        const results = <SavedRecipe>[];
        when(mockStorageService.searchRecipes(query)).thenAnswer((_) async => results);

        final searchResults = await storageProvider.searchRecipes(query);

        expect(searchResults, results);
        verify(mockStorageService.searchRecipes(query)).called(1);
      });

      test('should get recipes by category', () async {
        const category = 'main';
        const results = <SavedRecipe>[];
        when(mockStorageService.getRecipesByCategory(category))
            .thenAnswer((_) async => results);

        final categoryResults = await storageProvider.getRecipesByCategory(category);

        expect(categoryResults, results);
        verify(mockStorageService.getRecipesByCategory(category)).called(1);
      });
    });

    group('recent searches', () {
      test('should add recent search', () async {
        const search = 'pasta';
        when(mockStorageService.addRecentSearch(search)).thenAnswer((_) async => {});

        await storageProvider.addRecentSearch(search);

        expect(storageProvider.lastError, null);
        verify(mockStorageService.addRecentSearch(search)).called(1);
      });

      test('should clear recent searches', () async {
        when(mockStorageService.clearRecentSearches()).thenAnswer((_) async => {});

        await storageProvider.clearRecentSearches();

        expect(storageProvider.lastError, null);
        verify(mockStorageService.clearRecentSearches()).called(1);
        expect(appStateProvider.state.user.recentSearches, isEmpty);
      });
    });

    group('app settings', () {
      test('should save app settings', () async {
        final settings = {'theme': 'dark'};
        when(mockStorageService.saveAppSettings(settings)).thenAnswer((_) async => {});

        await storageProvider.saveAppSettings(settings);

        expect(storageProvider.lastError, null);
        verify(mockStorageService.saveAppSettings(settings)).called(1);
      });

      test('should get app settings', () async {
        final settings = {'theme': 'dark'};
        when(mockStorageService.getAppSettings()).thenAnswer((_) async => settings);

        final result = await storageProvider.getAppSettings();

        expect(result, settings);
        verify(mockStorageService.getAppSettings()).called(1);
      });
    });

    group('clear data', () {
      test('should clear all data', () async {
        when(mockStorageService.clearAllData()).thenAnswer((_) async => {});

        await storageProvider.clearAllData();

        expect(storageProvider.lastError, null);
        verify(mockStorageService.clearAllData()).called(1);
        expect(appStateProvider.state.onboarding.isComplete, false);
        expect(appStateProvider.state.onboarding.isFirstLaunch, true);
      });
    });

    group('error handling', () {
      test('should clear error', () {
        // Set an error first
        storageProvider.clearError();
        expect(storageProvider.lastError, null);
      });
    });

    group('disposal', () {
      test('should dispose storage service', () async {
        when(mockStorageService.dispose()).thenAnswer((_) async => {});

        await storageProvider.dispose();

        verify(mockStorageService.dispose()).called(1);
      });

      test('should handle dispose error', () async {
        when(mockStorageService.dispose()).thenThrow(Exception('Dispose error'));

        // Should not throw
        await storageProvider.dispose();

        verify(mockStorageService.dispose()).called(1);
      });
    });
  });
}