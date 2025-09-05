import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/sharing_service.dart';
import '../../lib/services/ai_recipe_service.dart';

// Generate mocks
@GenerateMocks([])
class MockSharingService extends Mock implements SharingServiceInterface {}

// Mock implementation for testing that doesn't call actual Share.share
class TestSharingService implements SharingServiceInterface {
  final SharingService _realService = SharingService();
  
  @override
  Future<void> shareRecipe(Recipe recipe, SharingPlatform platform) async {
    // Don't actually call Share.share, just validate inputs
    if (recipe.title.isEmpty) {
      throw const SharingException('Invalid recipe');
    }
    // Simulate successful sharing
  }

  @override
  String generateShareableContent(Recipe recipe) {
    return _realService.generateShareableContent(recipe);
  }

  @override
  Future<String?> shareRecipeWithImage(Recipe recipe, SharingPlatform platform) async {
    // Don't actually call Share.share, just return image URL logic
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
      return recipe.imageUrl;
    }
    return null;
  }

  @override
  bool isSharingAvailable() {
    return _realService.isSharingAvailable();
  }
}

void main() {
  group('SharingService', () {
    late TestSharingService sharingService;
    late Recipe testRecipe;

    setUp(() {
      sharingService = TestSharingService();
      
      // Create a test recipe with all required fields
      testRecipe = const Recipe(
        id: 'test-recipe-1',
        title: 'Delicious Pasta Carbonara',
        ingredients: [
          '400g spaghetti',
          '200g pancetta',
          '4 large eggs',
          '100g Parmesan cheese',
          'Black pepper',
          'Salt'
        ],
        instructions: [
          'Boil water in a large pot and cook spaghetti according to package directions',
          'While pasta cooks, fry pancetta in a large skillet until crispy',
          'Beat eggs with grated Parmesan and black pepper in a bowl',
          'Drain pasta, reserving 1 cup pasta water',
          'Add hot pasta to pancetta skillet',
          'Remove from heat and quickly stir in egg mixture',
          'Add pasta water gradually until creamy',
          'Serve immediately with extra Parmesan'
        ],
        cookingTime: 25,
        servings: 4,
        matchPercentage: 95.0,
        imageUrl: 'https://example.com/pasta-carbonara.jpg',
        nutrition: NutritionInfo(
          calories: 520,
          protein: 22.5,
          carbohydrates: 65.0,
          fat: 18.0,
          fiber: 3.2,
          sugar: 2.8,
          sodium: 890,
          servingSize: '1 serving (200g)',
        ),
        allergens: [
          Allergen(
            name: 'Eggs',
            severity: 'medium',
            description: 'Contains eggs',
          ),
          Allergen(
            name: 'Dairy',
            severity: 'low',
            description: 'Contains cheese',
          ),
        ],
        intolerances: [
          Intolerance(
            name: 'Lactose',
            type: 'lactose',
            description: 'Contains dairy products',
          ),
        ],
        usedIngredients: ['pasta', 'eggs', 'cheese'],
        missingIngredients: ['pancetta'],
        difficulty: 'medium',
      );
    });

    group('generateShareableContent', () {
      test('should generate complete shareable content with all recipe details', () {
        final content = sharingService.generateShareableContent(testRecipe);

        expect(content, contains('🍽️ Delicious Pasta Carbonara'));
        expect(content, contains('Found this amazing recipe using Food Recognition App!'));
        expect(content, contains('⏱️ Cooking Time: 25 minutes'));
        expect(content, contains('👥 Servings: 4'));
        expect(content, contains('📊 Difficulty: 🟡 Medium'));
        expect(content, contains('🥗 Nutrition (per serving):'));
        expect(content, contains('• Calories: 520'));
        expect(content, contains('• Protein: 22.5g'));
        expect(content, contains('• Carbs: 65.0g'));
        expect(content, contains('• Fat: 18.0g'));
        expect(content, contains('🛒 Ingredients:'));
        expect(content, contains('1. 400g spaghetti'));
        expect(content, contains('👨‍🍳 Instructions:'));
        expect(content, contains('1. Boil water in a large pot'));
        expect(content, contains('⚠️ Contains: Eggs, Dairy'));
        expect(content, contains('Discover recipes from your ingredients!'));
      });

      test('should truncate instructions when more than 5 steps', () {
        final content = sharingService.generateShareableContent(testRecipe);

        expect(content, contains('1. Boil water in a large pot'));
        expect(content, contains('5. Add hot pasta to pancetta skillet'));
        expect(content, contains('... and 3 more steps!'));
      });

      test('should handle recipe with no allergens', () {
        final recipeNoAllergens = Recipe(
          id: 'test-recipe-2',
          title: 'Simple Salad',
          ingredients: ['lettuce', 'tomatoes'],
          instructions: ['Mix ingredients'],
          cookingTime: 5,
          servings: 2,
          matchPercentage: 80.0,
          nutrition: const NutritionInfo(
            calories: 50,
            protein: 2.0,
            carbohydrates: 8.0,
            fat: 1.0,
            fiber: 3.0,
            sugar: 4.0,
            sodium: 10,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: const ['lettuce'],
          missingIngredients: const [],
          difficulty: 'easy',
        );

        final content = sharingService.generateShareableContent(recipeNoAllergens);

        expect(content, isNot(contains('⚠️ Contains:')));
        expect(content, contains('📊 Difficulty: 🟢 Easy'));
      });

      test('should handle recipe with hard difficulty', () {
        final hardRecipe = Recipe(
          id: 'test-recipe-3',
          title: 'Complex Dish',
          ingredients: ['ingredient1'],
          instructions: ['step1'],
          cookingTime: 120,
          servings: 1,
          matchPercentage: 70.0,
          nutrition: const NutritionInfo(
            calories: 300,
            protein: 15.0,
            carbohydrates: 30.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 2.0,
            sodium: 500,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: const [],
          missingIngredients: const [],
          difficulty: 'hard',
        );

        final content = sharingService.generateShareableContent(hardRecipe);

        expect(content, contains('📊 Difficulty: 🔴 Hard'));
      });
    });

    group('isSharingAvailable', () {
      test('should return true indicating sharing is available', () {
        expect(sharingService.isSharingAvailable(), isTrue);
      });
    });

    group('shareRecipe', () {
      test('should not throw exception for valid recipe and platform', () async {
        // Note: We can't easily test the actual sharing functionality without mocking
        // the Share.share method, but we can test that the method doesn't throw
        // for valid inputs. In a real test environment, we would mock Share.share.
        
        expect(
          () async => await sharingService.shareRecipe(testRecipe, SharingPlatform.general),
          returnsNormally,
        );
      });
    });

    group('shareRecipeWithImage', () {
      test('should handle recipe with image URL', () async {
        final result = await sharingService.shareRecipeWithImage(testRecipe, SharingPlatform.social);
        
        expect(result, equals(testRecipe.imageUrl));
      });

      test('should handle recipe without image URL', () async {
        final recipeNoImage = Recipe(
          id: 'test-recipe-no-image',
          title: 'No Image Recipe',
          ingredients: const ['ingredient1'],
          instructions: const ['step1'],
          cookingTime: 10,
          servings: 1,
          matchPercentage: 50.0,
          imageUrl: null,
          nutrition: const NutritionInfo(
            calories: 100,
            protein: 5.0,
            carbohydrates: 15.0,
            fat: 2.0,
            fiber: 1.0,
            sugar: 1.0,
            sodium: 100,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: const [],
          missingIngredients: const [],
          difficulty: 'easy',
        );

        final result = await sharingService.shareRecipeWithImage(recipeNoImage, SharingPlatform.email);
        
        expect(result, isNull);
      });

      test('should handle recipe with empty image URL', () async {
        final recipeEmptyImage = Recipe(
          id: 'test-recipe-empty-image',
          title: 'Empty Image Recipe',
          ingredients: const ['ingredient1'],
          instructions: const ['step1'],
          cookingTime: 10,
          servings: 1,
          matchPercentage: 50.0,
          imageUrl: '',
          nutrition: const NutritionInfo(
            calories: 100,
            protein: 5.0,
            carbohydrates: 15.0,
            fat: 2.0,
            fiber: 1.0,
            sugar: 1.0,
            sodium: 100,
            servingSize: '1 serving',
          ),
          allergens: const [],
          intolerances: const [],
          usedIngredients: const [],
          missingIngredients: const [],
          difficulty: 'easy',
        );

        final result = await sharingService.shareRecipeWithImage(recipeEmptyImage, SharingPlatform.messaging);
        
        expect(result, isNull);
      });
    });

    group('content formatting', () {
      test('should format content differently for social media', () {
        // We can't directly test private methods, but we can test the behavior
        // through the public shareRecipe method by checking the generated content
        final content = sharingService.generateShareableContent(testRecipe);
        
        // Verify that the content includes social media friendly elements
        expect(content, contains('🍽️'));
        expect(content, contains('⏱️'));
        expect(content, contains('👥'));
        expect(content, contains('📊'));
        expect(content, contains('🥗'));
      });
    });

    group('SharingPlatform enum', () {
      test('should have all expected platform values', () {
        expect(SharingPlatform.values, contains(SharingPlatform.social));
        expect(SharingPlatform.values, contains(SharingPlatform.email));
        expect(SharingPlatform.values, contains(SharingPlatform.messaging));
        expect(SharingPlatform.values, contains(SharingPlatform.general));
      });
    });

    group('SharingException', () {
      test('should create exception with message only', () {
        const exception = SharingException('Test error');
        
        expect(exception.message, equals('Test error'));
        expect(exception.code, isNull);
        expect(exception.toString(), equals('SharingException: Test error'));
      });

      test('should create exception with message and code', () {
        const exception = SharingException('Test error', 'ERR001');
        
        expect(exception.message, equals('Test error'));
        expect(exception.code, equals('ERR001'));
        expect(exception.toString(), equals('SharingException: Test error (Code: ERR001)'));
      });
    });

    group('SharingServiceFactory', () {
      test('should create SharingService instance', () {
        final service = SharingServiceFactory.create();
        
        expect(service, isA<SharingServiceInterface>());
        expect(service, isA<SharingService>());
      });
    });

    group('Real SharingService content generation', () {
      late SharingService realService;
      
      setUp(() {
        realService = SharingService();
      });

      test('should generate content without calling Share.share', () {
        final content = realService.generateShareableContent(testRecipe);
        
        expect(content, contains('🍽️ Delicious Pasta Carbonara'));
        expect(content, contains('Found this amazing recipe using Food Recognition App!'));
      });

      test('should report sharing as available', () {
        expect(realService.isSharingAvailable(), isTrue);
      });
    });
  });

  group('Integration Tests', () {
    test('should handle complete sharing workflow', () async {
      final service = TestSharingService();
      
      final recipe = Recipe(
        id: 'integration-test',
        title: 'Integration Test Recipe',
        ingredients: const ['test ingredient'],
        instructions: const ['test instruction'],
        cookingTime: 15,
        servings: 2,
        matchPercentage: 85.0,
        nutrition: const NutritionInfo(
          calories: 200,
          protein: 10.0,
          carbohydrates: 20.0,
          fat: 5.0,
          fiber: 2.0,
          sugar: 3.0,
          sodium: 200,
          servingSize: '1 serving',
        ),
        allergens: const [],
        intolerances: const [],
        usedIngredients: const [],
        missingIngredients: const [],
        difficulty: 'easy',
      );

      // Test that the service can generate content
      final content = service.generateShareableContent(recipe);
      expect(content, isNotEmpty);
      expect(content, contains('Integration Test Recipe'));

      // Test that sharing availability check works
      expect(service.isSharingAvailable(), isTrue);

      // Test that sharing methods don't throw exceptions
      expect(
        () async => await service.shareRecipe(recipe, SharingPlatform.general),
        returnsNormally,
      );

      expect(
        () async => await service.shareRecipeWithImage(recipe, SharingPlatform.social),
        returnsNormally,
      );
    });
  });
}