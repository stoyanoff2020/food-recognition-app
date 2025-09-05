import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/recipe_book_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/services/subscription_service.dart';
import '../../lib/services/ai_recipe_service.dart';
import '../../lib/models/app_state.dart';
import '../../lib/models/subscription.dart';

import 'recipe_book_service_test.mocks.dart';

@GenerateMocks([StorageServiceInterface, SubscriptionServiceImpl])
void main() {
  late RecipeBookService recipeBookService;
  late MockStorageServiceInterface mockStorageService;
  late MockSubscriptionServiceImpl mockSubscriptionService;

  setUp(() {
    mockStorageService = MockStorageServiceInterface();
    mockSubscriptionService = MockSubscriptionServiceImpl();
    recipeBookService = RecipeBookService(
      storageService: mockStorageService,
      subscriptionService: mockSubscriptionService,
    );
  });

  group('RecipeBookService', () {
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

    final testSavedRecipe = SavedRecipe(
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
      savedDate: '2024-01-01T00:00:00.000Z',
      category: 'Main Course',
      tags: ['healthy', 'quick'],
      personalNotes: null,
    );

    group('saveRecipe', () {
      test('should save recipe successfully when user has access', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenAnswer((_) async => true);
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => null);
        when(mockStorageService.saveRecipe(any))
            .thenAnswer((_) async {});
        when(mockSubscriptionService.incrementUsage(UsageType.recipeSave))
            .thenAnswer((_) async {});

        // Act
        await recipeBookService.saveRecipe(
          testRecipe,
          category: 'Main Course',
          tags: ['healthy', 'quick'],
        );

        // Assert
        verify(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook)).called(1);
        verify(mockStorageService.getRecipeById('recipe_1')).called(1);
        verify(mockStorageService.saveRecipe(any)).called(1);
        verify(mockSubscriptionService.incrementUsage(UsageType.recipeSave)).called(1);
      });

      test('should throw exception when user does not have access', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => recipeBookService.saveRecipe(testRecipe),
          throwsA(isA<RecipeBookException>()
              .having((e) => e.code, 'code', 'SUBSCRIPTION_REQUIRED')),
        );

        verify(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook)).called(1);
        verifyNever(mockStorageService.saveRecipe(any));
      });

      test('should throw exception when recipe is already saved', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenAnswer((_) async => true);
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => testSavedRecipe);

        // Act & Assert
        expect(
          () => recipeBookService.saveRecipe(testRecipe),
          throwsA(isA<RecipeBookException>()
              .having((e) => e.code, 'code', 'RECIPE_ALREADY_SAVED')),
        );

        verify(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook)).called(1);
        verify(mockStorageService.getRecipeById('recipe_1')).called(1);
        verifyNever(mockStorageService.saveRecipe(any));
      });

      test('should use default category when none provided', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenAnswer((_) async => true);
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => null);
        when(mockStorageService.saveRecipe(any))
            .thenAnswer((_) async {});
        when(mockSubscriptionService.incrementUsage(UsageType.recipeSave))
            .thenAnswer((_) async {});

        // Act
        await recipeBookService.saveRecipe(testRecipe);

        // Assert
        final captured = verify(mockStorageService.saveRecipe(captureAny)).captured;
        final savedRecipe = captured.first as SavedRecipe;
        expect(savedRecipe.category, 'Uncategorized');
        expect(savedRecipe.tags, isEmpty);
      });
    });

    group('getSavedRecipes', () {
      test('should return saved recipes from storage', () async {
        // Arrange
        final recipes = [testSavedRecipe];
        when(mockStorageService.getSavedRecipes())
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.getSavedRecipes();

        // Assert
        expect(result, equals(recipes));
        verify(mockStorageService.getSavedRecipes()).called(1);
      });

      test('should throw exception when storage fails', () async {
        // Arrange
        when(mockStorageService.getSavedRecipes())
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => recipeBookService.getSavedRecipes(),
          throwsA(isA<RecipeBookException>()),
        );
      });
    });

    group('deleteRecipe', () {
      test('should delete recipe successfully', () async {
        // Arrange
        when(mockStorageService.deleteRecipe('recipe_1'))
            .thenAnswer((_) async {});

        // Act
        await recipeBookService.deleteRecipe('recipe_1');

        // Assert
        verify(mockStorageService.deleteRecipe('recipe_1')).called(1);
      });

      test('should throw exception when storage fails', () async {
        // Arrange
        when(mockStorageService.deleteRecipe('recipe_1'))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => recipeBookService.deleteRecipe('recipe_1'),
          throwsA(isA<RecipeBookException>()),
        );
      });
    });

    group('searchSavedRecipes', () {
      test('should return search results from storage', () async {
        // Arrange
        final recipes = [testSavedRecipe];
        when(mockStorageService.searchRecipes('test'))
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.searchSavedRecipes('test');

        // Assert
        expect(result, equals(recipes));
        verify(mockStorageService.searchRecipes('test')).called(1);
      });

      test('should return all recipes when query is empty', () async {
        // Arrange
        final recipes = [testSavedRecipe];
        when(mockStorageService.getSavedRecipes())
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.searchSavedRecipes('  ');

        // Assert
        expect(result, equals(recipes));
        verify(mockStorageService.getSavedRecipes()).called(1);
        verifyNever(mockStorageService.searchRecipes(any));
      });
    });

    group('getRecipesByCategory', () {
      test('should return recipes by category from storage', () async {
        // Arrange
        final recipes = [testSavedRecipe];
        when(mockStorageService.getRecipesByCategory('Main Course'))
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.getRecipesByCategory('Main Course');

        // Assert
        expect(result, equals(recipes));
        verify(mockStorageService.getRecipesByCategory('Main Course')).called(1);
      });
    });

    group('getCategories', () {
      test('should return sorted unique categories', () async {
        // Arrange
        final recipes = [
          testSavedRecipe,
          SavedRecipe(
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
            savedDate: '2024-01-02T00:00:00.000Z',
            category: 'Appetizer',
            tags: ['quick'],
          ),
        ];
        when(mockStorageService.getSavedRecipes())
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.getCategories();

        // Assert
        expect(result, equals(['Appetizer', 'Main Course']));
      });
    });

    group('getTags', () {
      test('should return sorted unique tags', () async {
        // Arrange
        final recipes = [
          testSavedRecipe,
          SavedRecipe(
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
            savedDate: '2024-01-02T00:00:00.000Z',
            category: 'Appetizer',
            tags: ['quick', 'vegetarian'],
          ),
        ];
        when(mockStorageService.getSavedRecipes())
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.getTags();

        // Assert
        expect(result, equals(['healthy', 'quick', 'vegetarian']));
      });
    });

    group('updateRecipeMetadata', () {
      test('should update recipe metadata successfully', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => testSavedRecipe);
        when(mockStorageService.saveRecipe(any))
            .thenAnswer((_) async {});

        // Act
        await recipeBookService.updateRecipeMetadata(
          'recipe_1',
          category: 'Dessert',
          tags: ['sweet'],
          personalNotes: 'Great recipe!',
        );

        // Assert
        verify(mockStorageService.getRecipeById('recipe_1')).called(1);
        final captured = verify(mockStorageService.saveRecipe(captureAny)).captured;
        final updatedRecipe = captured.first as SavedRecipe;
        expect(updatedRecipe.category, 'Dessert');
        expect(updatedRecipe.tags, ['sweet']);
        expect(updatedRecipe.personalNotes, 'Great recipe!');
      });

      test('should throw exception when recipe not found', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => recipeBookService.updateRecipeMetadata('recipe_1', category: 'Dessert'),
          throwsA(isA<RecipeBookException>()
              .having((e) => e.code, 'code', 'RECIPE_NOT_FOUND')),
        );

        verifyNever(mockStorageService.saveRecipe(any));
      });
    });

    group('hasRecipeBookAccess', () {
      test('should return true when user has access', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenAnswer((_) async => true);

        // Act
        final result = await recipeBookService.hasRecipeBookAccess();

        // Assert
        expect(result, isTrue);
        verify(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook)).called(1);
      });

      test('should return false when user does not have access', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenAnswer((_) async => false);

        // Act
        final result = await recipeBookService.hasRecipeBookAccess();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when subscription service throws error', () async {
        // Arrange
        when(mockSubscriptionService.hasFeatureAccess(FeatureType.recipeBook))
            .thenThrow(Exception('Subscription error'));

        // Act
        final result = await recipeBookService.hasRecipeBookAccess();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getRecipeById', () {
      test('should return recipe when found', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => testSavedRecipe);

        // Act
        final result = await recipeBookService.getRecipeById('recipe_1');

        // Assert
        expect(result, equals(testSavedRecipe));
        verify(mockStorageService.getRecipeById('recipe_1')).called(1);
      });

      test('should return null when recipe not found', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => null);

        // Act
        final result = await recipeBookService.getRecipeById('recipe_1');

        // Assert
        expect(result, isNull);
      });
    });

    group('isRecipeSaved', () {
      test('should return true when recipe is saved', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => testSavedRecipe);

        // Act
        final result = await recipeBookService.isRecipeSaved('recipe_1');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when recipe is not saved', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenAnswer((_) async => null);

        // Act
        final result = await recipeBookService.isRecipeSaved('recipe_1');

        // Assert
        expect(result, isFalse);
      });

      test('should return false when storage throws error', () async {
        // Arrange
        when(mockStorageService.getRecipeById('recipe_1'))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await recipeBookService.isRecipeSaved('recipe_1');

        // Assert
        expect(result, isFalse);
      });
    });

    group('getStats', () {
      test('should return correct statistics', () async {
        // Arrange
        final recipes = [
          testSavedRecipe,
          SavedRecipe(
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
            savedDate: '2024-01-02T00:00:00.000Z',
            category: 'Main Course',
            tags: ['quick'],
          ),
        ];
        when(mockStorageService.getSavedRecipes())
            .thenAnswer((_) async => recipes);

        // Act
        final result = await recipeBookService.getStats();

        // Assert
        expect(result.totalRecipes, 2);
        expect(result.totalCategories, 1);
        expect(result.totalTags, 2);
        expect(result.difficultyDistribution, {'medium': 1, 'easy': 1});
        expect(result.averageCookingTime, 25.0);
        expect(result.mostUsedCategory, 'Main Course');
        expect(result.recentlySaved.length, 2);
      });
    });
  });
}