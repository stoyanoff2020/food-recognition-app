import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:food_recognition_app/services/ai_recipe_service.dart';

import 'ai_recipe_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('AIRecipeService', () {
    late MockDio mockDio;
    late AIRecipeService aiRecipeService;
    const String testApiKey = 'test-api-key';

    setUp(() {
      mockDio = MockDio();
      aiRecipeService = AIRecipeService(apiKey: testApiKey, dio: mockDio);
    });

    tearDown(() {
      aiRecipeService.dispose();
    });

    group('Data Models', () {
      group('NutritionInfo', () {
        test('should create NutritionInfo from JSON', () {
          final json = {
            'calories': 350,
            'protein': 25.5,
            'carbohydrates': 45.2,
            'fat': 12.8,
            'fiber': 8.3,
            'sugar': 6.1,
            'sodium': 580.2,
            'serving_size': '1 cup',
          };

          final nutrition = NutritionInfo.fromJson(json);

          expect(nutrition.calories, equals(350));
          expect(nutrition.protein, equals(25.5));
          expect(nutrition.carbohydrates, equals(45.2));
          expect(nutrition.fat, equals(12.8));
          expect(nutrition.fiber, equals(8.3));
          expect(nutrition.sugar, equals(6.1));
          expect(nutrition.sodium, equals(580.2));
          expect(nutrition.servingSize, equals('1 cup'));
        });

        test('should convert NutritionInfo to JSON', () {
          const nutrition = NutritionInfo(
            calories: 350,
            protein: 25.5,
            carbohydrates: 45.2,
            fat: 12.8,
            fiber: 8.3,
            sugar: 6.1,
            sodium: 580.2,
            servingSize: '1 cup',
          );

          final json = nutrition.toJson();

          expect(json['calories'], equals(350));
          expect(json['protein'], equals(25.5));
          expect(json['carbohydrates'], equals(45.2));
          expect(json['fat'], equals(12.8));
          expect(json['fiber'], equals(8.3));
          expect(json['sugar'], equals(6.1));
          expect(json['sodium'], equals(580.2));
          expect(json['serving_size'], equals('1 cup'));
        });

        test('should implement equality correctly', () {
          const nutrition1 = NutritionInfo(
            calories: 350,
            protein: 25.5,
            carbohydrates: 45.2,
            fat: 12.8,
            fiber: 8.3,
            sugar: 6.1,
            sodium: 580.2,
            servingSize: '1 cup',
          );

          const nutrition2 = NutritionInfo(
            calories: 350,
            protein: 25.5,
            carbohydrates: 45.2,
            fat: 12.8,
            fiber: 8.3,
            sugar: 6.1,
            sodium: 580.2,
            servingSize: '1 cup',
          );

          const nutrition3 = NutritionInfo(
            calories: 400,
            protein: 25.5,
            carbohydrates: 45.2,
            fat: 12.8,
            fiber: 8.3,
            sugar: 6.1,
            sodium: 580.2,
            servingSize: '1 cup',
          );

          expect(nutrition1, equals(nutrition2));
          expect(nutrition1, isNot(equals(nutrition3)));
          expect(nutrition1.hashCode, equals(nutrition2.hashCode));
        });
      });

      group('Allergen', () {
        test('should create Allergen from JSON', () {
          final json = {
            'name': 'Dairy',
            'severity': 'medium',
            'description': 'Contains milk products',
          };

          final allergen = Allergen.fromJson(json);

          expect(allergen.name, equals('Dairy'));
          expect(allergen.severity, equals('medium'));
          expect(allergen.description, equals('Contains milk products'));
        });

        test('should convert Allergen to JSON', () {
          const allergen = Allergen(
            name: 'Dairy',
            severity: 'medium',
            description: 'Contains milk products',
          );

          final json = allergen.toJson();

          expect(json['name'], equals('Dairy'));
          expect(json['severity'], equals('medium'));
          expect(json['description'], equals('Contains milk products'));
        });
      });

      group('Intolerance', () {
        test('should create Intolerance from JSON', () {
          final json = {
            'name': 'Lactose',
            'type': 'lactose',
            'description': 'Contains lactose from dairy products',
          };

          final intolerance = Intolerance.fromJson(json);

          expect(intolerance.name, equals('Lactose'));
          expect(intolerance.type, equals('lactose'));
          expect(intolerance.description, equals('Contains lactose from dairy products'));
        });

        test('should convert Intolerance to JSON', () {
          const intolerance = Intolerance(
            name: 'Lactose',
            type: 'lactose',
            description: 'Contains lactose from dairy products',
          );

          final json = intolerance.toJson();

          expect(json['name'], equals('Lactose'));
          expect(json['type'], equals('lactose'));
          expect(json['description'], equals('Contains lactose from dairy products'));
        });
      });

      group('Recipe', () {
        test('should create Recipe from JSON', () {
          final json = {
            'id': 'recipe-1',
            'title': 'Test Recipe',
            'ingredients': ['ingredient1', 'ingredient2'],
            'instructions': ['step1', 'step2'],
            'cooking_time': 30,
            'servings': 4,
            'match_percentage': 85.5,
            'image_url': 'https://example.com/image.jpg',
            'nutrition': {
              'calories': 350,
              'protein': 25.5,
              'carbohydrates': 45.2,
              'fat': 12.8,
              'fiber': 8.3,
              'sugar': 6.1,
              'sodium': 580.2,
              'serving_size': '1 cup',
            },
            'allergens': [
              {
                'name': 'Dairy',
                'severity': 'medium',
                'description': 'Contains milk products',
              }
            ],
            'intolerances': [
              {
                'name': 'Lactose',
                'type': 'lactose',
                'description': 'Contains lactose from dairy products',
              }
            ],
            'used_ingredients': ['ingredient1'],
            'missing_ingredients': ['ingredient2'],
            'difficulty': 'easy',
          };

          final recipe = Recipe.fromJson(json);

          expect(recipe.id, equals('recipe-1'));
          expect(recipe.title, equals('Test Recipe'));
          expect(recipe.ingredients, equals(['ingredient1', 'ingredient2']));
          expect(recipe.instructions, equals(['step1', 'step2']));
          expect(recipe.cookingTime, equals(30));
          expect(recipe.servings, equals(4));
          expect(recipe.matchPercentage, equals(85.5));
          expect(recipe.imageUrl, equals('https://example.com/image.jpg'));
          expect(recipe.nutrition.calories, equals(350));
          expect(recipe.allergens.length, equals(1));
          expect(recipe.allergens.first.name, equals('Dairy'));
          expect(recipe.intolerances.length, equals(1));
          expect(recipe.intolerances.first.name, equals('Lactose'));
          expect(recipe.usedIngredients, equals(['ingredient1']));
          expect(recipe.missingIngredients, equals(['ingredient2']));
          expect(recipe.difficulty, equals('easy'));
        });

        test('should implement equality based on id', () {
          const nutrition = NutritionInfo(
            calories: 350,
            protein: 25.5,
            carbohydrates: 45.2,
            fat: 12.8,
            fiber: 8.3,
            sugar: 6.1,
            sodium: 580.2,
            servingSize: '1 cup',
          );

          const recipe1 = Recipe(
            id: 'recipe-1',
            title: 'Test Recipe',
            ingredients: ['ingredient1'],
            instructions: ['step1'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 85.5,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          );

          const recipe2 = Recipe(
            id: 'recipe-1',
            title: 'Different Title',
            ingredients: ['different ingredient'],
            instructions: ['different step'],
            cookingTime: 60,
            servings: 2,
            matchPercentage: 50.0,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'hard',
          );

          const recipe3 = Recipe(
            id: 'recipe-2',
            title: 'Test Recipe',
            ingredients: ['ingredient1'],
            instructions: ['step1'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 85.5,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          );

          expect(recipe1, equals(recipe2)); // Same ID
          expect(recipe1, isNot(equals(recipe3))); // Different ID
          expect(recipe1.hashCode, equals(recipe2.hashCode));
        });
      });

      group('RecipeGenerationResult', () {
        test('should create success result', () {
          const nutrition = NutritionInfo(
            calories: 350,
            protein: 25.5,
            carbohydrates: 45.2,
            fat: 12.8,
            fiber: 8.3,
            sugar: 6.1,
            sodium: 580.2,
            servingSize: '1 cup',
          );

          const recipe = Recipe(
            id: 'recipe-1',
            title: 'Test Recipe',
            ingredients: ['ingredient1'],
            instructions: ['step1'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 85.5,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          );

          final result = RecipeGenerationResult.success(
            recipes: [recipe],
            totalFound: 1,
            generationTime: 1000,
          );

          expect(result.isSuccess, isTrue);
          expect(result.recipes.length, equals(1));
          expect(result.totalFound, equals(1));
          expect(result.generationTime, equals(1000));
          expect(result.errorMessage, isNull);
        });

        test('should create failure result', () {
          final result = RecipeGenerationResult.failure(
            errorMessage: 'Test error',
            generationTime: 500,
          );

          expect(result.isSuccess, isFalse);
          expect(result.recipes.isEmpty, isTrue);
          expect(result.totalFound, equals(0));
          expect(result.generationTime, equals(500));
          expect(result.errorMessage, equals('Test error'));
        });
      });
    });

    group('generateRecipesByIngredients', () {
      test('should return failure when no ingredients provided', () async {
        final result = await aiRecipeService.generateRecipesByIngredients([]);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('No ingredients provided'));
        expect(result.recipes.isEmpty, isTrue);
      });

      test('should successfully generate recipes', () async {
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'recipes': [
                    {
                      'id': 'recipe-1',
                      'title': 'Tomato Pasta',
                      'ingredients': ['tomatoes', 'pasta', 'garlic'],
                      'instructions': ['Cook pasta', 'Add tomatoes', 'Season with garlic'],
                      'cooking_time': 20,
                      'servings': 2,
                      'match_percentage': 90.0,
                      'nutrition': {
                        'calories': 400,
                        'protein': 12.0,
                        'carbohydrates': 75.0,
                        'fat': 8.0,
                        'fiber': 5.0,
                        'sugar': 8.0,
                        'sodium': 300.0,
                        'serving_size': '1 plate',
                      },
                      'allergens': [],
                      'intolerances': [],
                      'used_ingredients': ['tomatoes'],
                      'missing_ingredients': ['pasta', 'garlic'],
                      'difficulty': 'easy',
                    }
                  ],
                  'total_found': 1,
                  'alternative_suggestions': [],
                })
              }
            }
          ]
        };

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response<Map<String, dynamic>>(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isTrue);
        expect(result.recipes.length, equals(1));
        expect(result.recipes.first.title, equals('Tomato Pasta'));
        expect(result.recipes.first.matchPercentage, closeTo(33.33, 0.1)); // 1/3 ingredients match
        expect(result.totalFound, equals(1));
        verify(mockDio.post(any, data: anyNamed('data'))).called(1);
      });

      test('should handle API errors with retry logic', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Request timed out'));
        verify(mockDio.post(any, data: anyNamed('data'))).called(3); // Max retries
      });

      test('should handle authentication errors without retry', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.badResponse,
              response: Response<Map<String, dynamic>>(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Authentication failed'));
        verify(mockDio.post(any, data: anyNamed('data'))).called(1); // No retry for auth errors
      });

      test('should handle rate limiting with exponential backoff', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.badResponse,
              response: Response<Map<String, dynamic>>(
                statusCode: 429,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Too many requests'));
        verify(mockDio.post(any, data: anyNamed('data'))).called(3); // Max retries
      });

      test('should handle invalid JSON response', () async {
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': 'Invalid JSON content'
              }
            }
          ]
        };

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response<Map<String, dynamic>>(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Failed to parse recipe response'));
      });
    });

    group('getTopRecipes', () {
      test('should return limited number of recipes', () async {
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'recipes': List.generate(10, (index) => {
                    'id': 'recipe-$index',
                    'title': 'Recipe $index',
                    'ingredients': ['ingredient$index'],
                    'instructions': ['step$index'],
                    'cooking_time': 20,
                    'servings': 2,
                    'match_percentage': 90.0 - index,
                    'nutrition': {
                      'calories': 400,
                      'protein': 12.0,
                      'carbohydrates': 75.0,
                      'fat': 8.0,
                      'fiber': 5.0,
                      'sugar': 8.0,
                      'sodium': 300.0,
                      'serving_size': '1 plate',
                    },
                    'allergens': [],
                    'intolerances': [],
                    'used_ingredients': ['ingredient$index'],
                    'missing_ingredients': [],
                    'difficulty': 'easy',
                  }),
                  'total_found': 10,
                  'alternative_suggestions': [],
                })
              }
            }
          ]
        };

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response<Map<String, dynamic>>(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        final recipes = await aiRecipeService.getTopRecipes(['tomatoes'], 3);

        expect(recipes.length, equals(3));
        expect(recipes.first.title, equals('Recipe 0'));
        expect(recipes.last.title, equals('Recipe 2'));
      });

      test('should throw exception when generation fails', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        expect(
          () => aiRecipeService.getTopRecipes(['tomatoes'], 3),
          throwsA(isA<AIRecipeServiceException>()),
        );
      });
    });

    group('rankRecipesByMatch', () {
      test('should sort recipes by match percentage', () {
        const nutrition = NutritionInfo(
          calories: 350,
          protein: 25.5,
          carbohydrates: 45.2,
          fat: 12.8,
          fiber: 8.3,
          sugar: 6.1,
          sodium: 580.2,
          servingSize: '1 cup',
        );

        final recipes = [
          const Recipe(
            id: 'recipe-1',
            title: 'Low Match Recipe',
            ingredients: ['ingredient1'],
            instructions: ['step1'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 30.0,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          ),
          const Recipe(
            id: 'recipe-2',
            title: 'High Match Recipe',
            ingredients: ['ingredient2'],
            instructions: ['step2'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 90.0,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          ),
          const Recipe(
            id: 'recipe-3',
            title: 'Medium Match Recipe',
            ingredients: ['ingredient3'],
            instructions: ['step3'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 60.0,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          ),
        ];

        final rankedRecipes = aiRecipeService.rankRecipesByMatch(recipes, ['tomatoes']);

        expect(rankedRecipes.length, equals(3));
        expect(rankedRecipes[0].matchPercentage, equals(90.0));
        expect(rankedRecipes[1].matchPercentage, equals(60.0));
        expect(rankedRecipes[2].matchPercentage, equals(30.0));
      });

      test('should return original list when no user ingredients', () {
        const nutrition = NutritionInfo(
          calories: 350,
          protein: 25.5,
          carbohydrates: 45.2,
          fat: 12.8,
          fiber: 8.3,
          sugar: 6.1,
          sodium: 580.2,
          servingSize: '1 cup',
        );

        final recipes = [
          const Recipe(
            id: 'recipe-1',
            title: 'Recipe 1',
            ingredients: ['ingredient1'],
            instructions: ['step1'],
            cookingTime: 30,
            servings: 4,
            matchPercentage: 30.0,
            nutrition: nutrition,
            allergens: [],
            intolerances: [],
            usedIngredients: [],
            missingIngredients: [],
            difficulty: 'easy',
          ),
        ];

        final rankedRecipes = aiRecipeService.rankRecipesByMatch(recipes, []);

        expect(rankedRecipes, equals(recipes));
      });
    });

    group('highlightUsedIngredients', () {
      test('should correctly identify used and missing ingredients', () {
        const nutrition = NutritionInfo(
          calories: 350,
          protein: 25.5,
          carbohydrates: 45.2,
          fat: 12.8,
          fiber: 8.3,
          sugar: 6.1,
          sodium: 580.2,
          servingSize: '1 cup',
        );

        const recipe = Recipe(
          id: 'recipe-1',
          title: 'Tomato Pasta',
          ingredients: ['tomatoes', 'pasta', 'garlic', 'olive oil'],
          instructions: ['step1'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 50.0,
          nutrition: nutrition,
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
        );

        final detectedIngredients = ['tomatoes', 'garlic'];
        final highlightedRecipe = aiRecipeService.highlightUsedIngredients(recipe, detectedIngredients);

        expect(highlightedRecipe.usedIngredients.length, equals(2));
        expect(highlightedRecipe.usedIngredients, contains('tomatoes'));
        expect(highlightedRecipe.usedIngredients, contains('garlic'));
        expect(highlightedRecipe.missingIngredients.length, equals(2));
        expect(highlightedRecipe.missingIngredients, contains('pasta'));
        expect(highlightedRecipe.missingIngredients, contains('olive oil'));
        expect(highlightedRecipe.matchPercentage, equals(50.0)); // 2/4 * 100
      });

      test('should handle partial ingredient name matches', () {
        const nutrition = NutritionInfo(
          calories: 350,
          protein: 25.5,
          carbohydrates: 45.2,
          fat: 12.8,
          fiber: 8.3,
          sugar: 6.1,
          sodium: 580.2,
          servingSize: '1 cup',
        );

        const recipe = Recipe(
          id: 'recipe-1',
          title: 'Bell Pepper Stir Fry',
          ingredients: ['red bell pepper', 'green bell pepper', 'onion'],
          instructions: ['step1'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 50.0,
          nutrition: nutrition,
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
        );

        final detectedIngredients = ['bell pepper', 'onion'];
        final highlightedRecipe = aiRecipeService.highlightUsedIngredients(recipe, detectedIngredients);

        expect(highlightedRecipe.usedIngredients.length, equals(3));
        expect(highlightedRecipe.usedIngredients, contains('red bell pepper'));
        expect(highlightedRecipe.usedIngredients, contains('green bell pepper'));
        expect(highlightedRecipe.usedIngredients, contains('onion'));
        expect(highlightedRecipe.missingIngredients.isEmpty, isTrue);
        expect(highlightedRecipe.matchPercentage, equals(100.0)); // 3/3 * 100
      });

      test('should calculate match percentage correctly for empty ingredients', () {
        const nutrition = NutritionInfo(
          calories: 350,
          protein: 25.5,
          carbohydrates: 45.2,
          fat: 12.8,
          fiber: 8.3,
          sugar: 6.1,
          sodium: 580.2,
          servingSize: '1 cup',
        );

        const recipe = Recipe(
          id: 'recipe-1',
          title: 'Empty Recipe',
          ingredients: [],
          instructions: ['step1'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 50.0,
          nutrition: nutrition,
          allergens: [],
          intolerances: [],
          usedIngredients: [],
          missingIngredients: [],
          difficulty: 'easy',
        );

        final detectedIngredients = ['tomatoes'];
        final highlightedRecipe = aiRecipeService.highlightUsedIngredients(recipe, detectedIngredients);

        expect(highlightedRecipe.matchPercentage, equals(0.0));
        expect(highlightedRecipe.usedIngredients.isEmpty, isTrue);
        expect(highlightedRecipe.missingIngredients.isEmpty, isTrue);
      });
    });

    group('findAlternativeRecipes', () {
      test('should generate alternative recipes', () async {
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'recipes': [
                    {
                      'id': 'alt-recipe-1',
                      'title': 'Alternative Recipe',
                      'ingredients': ['common ingredient'],
                      'instructions': ['alternative step'],
                      'cooking_time': 25,
                      'servings': 3,
                      'match_percentage': 70.0,
                      'nutrition': {
                        'calories': 300,
                        'protein': 15.0,
                        'carbohydrates': 50.0,
                        'fat': 10.0,
                        'fiber': 6.0,
                        'sugar': 5.0,
                        'sodium': 250.0,
                        'serving_size': '1 portion',
                      },
                      'allergens': [],
                      'intolerances': [],
                      'used_ingredients': [],
                      'missing_ingredients': [],
                      'difficulty': 'medium',
                    }
                  ],
                  'total_found': 1,
                  'alternative_suggestions': [],
                })
              }
            }
          ]
        };

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response<Map<String, dynamic>>(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        final alternatives = await aiRecipeService.findAlternativeRecipes(['rare ingredient']);

        expect(alternatives.length, equals(1));
        expect(alternatives.first.title, equals('Alternative Recipe'));
        expect(alternatives.first.difficulty, equals('medium'));
      });

      test('should return empty list on error', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        final alternatives = await aiRecipeService.findAlternativeRecipes(['rare ingredient']);

        expect(alternatives.isEmpty, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle connection timeout errors', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Request timed out'));
      });

      test('should handle authentication errors', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.badResponse,
              response: Response<Map<String, dynamic>>(statusCode: 401, requestOptions: RequestOptions(path: '')),
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Authentication failed'));
      });

      test('should handle server errors', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.badResponse,
              response: Response<Map<String, dynamic>>(statusCode: 500, requestOptions: RequestOptions(path: '')),
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Server error'));
      });

      test('should handle connection errors', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionError,
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Connection error'));
      });

      test('should handle request cancellation', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.cancel,
            ));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Request was cancelled'));
      });

      test('should handle generic exceptions', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(Exception('Generic error'));

        final result = await aiRecipeService.generateRecipesByIngredients(['tomatoes']);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('An unexpected error occurred'));
      });
    });

    group('AIRecipeServiceFactory', () {
      test('should create AIRecipeService instance', () {
        final service = AIRecipeServiceFactory.create(apiKey: testApiKey);
        
        expect(service, isA<AIRecipeService>());
        
        service.dispose();
      });
    });

    group('AIRecipeServiceException', () {
      test('should create exception with message only', () {
        const exception = AIRecipeServiceException('Test message');
        
        expect(exception.message, equals('Test message'));
        expect(exception.code, isNull);
        expect(exception.toString(), equals('AIRecipeServiceException: Test message'));
      });

      test('should create exception with message and code', () {
        const exception = AIRecipeServiceException('Test message', code: 'TEST_CODE');
        
        expect(exception.message, equals('Test message'));
        expect(exception.code, equals('TEST_CODE'));
        expect(exception.toString(), equals('AIRecipeServiceException: Test message (Code: TEST_CODE)'));
      });
    });
  });
}