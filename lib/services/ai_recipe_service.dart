import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../utils/error_handler.dart';
import '../utils/retry_mechanism.dart';
import 'connectivity_service.dart';

// Data models for AI recipe service
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final String servingSize;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.servingSize,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      sugar: (json['sugar'] as num).toDouble(),
      sodium: (json['sodium'] as num).toDouble(),
      servingSize: json['serving_size'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'serving_size': servingSize,
    };
  }

  @override
  String toString() => 'NutritionInfo(calories: $calories, protein: ${protein}g, carbs: ${carbohydrates}g, fat: ${fat}g)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionInfo &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbohydrates == carbohydrates &&
        other.fat == fat &&
        other.fiber == fiber &&
        other.sugar == sugar &&
        other.sodium == sodium &&
        other.servingSize == servingSize;
  }

  @override
  int get hashCode => Object.hash(calories, protein, carbohydrates, fat, fiber, sugar, sodium, servingSize);
}

class Allergen {
  final String name;
  final String severity; // 'low', 'medium', 'high'
  final String description;

  const Allergen({
    required this.name,
    required this.severity,
    required this.description,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      name: json['name'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'description': description,
    };
  }

  @override
  String toString() => 'Allergen(name: $name, severity: $severity)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Allergen &&
        other.name == name &&
        other.severity == severity &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(name, severity, description);
}

class Intolerance {
  final String name;
  final String type; // 'lactose', 'gluten', 'nuts', 'shellfish', 'eggs', 'soy', 'other'
  final String description;

  const Intolerance({
    required this.name,
    required this.type,
    required this.description,
  });

  factory Intolerance.fromJson(Map<String, dynamic> json) {
    return Intolerance(
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
    };
  }

  @override
  String toString() => 'Intolerance(name: $name, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Intolerance &&
        other.name == name &&
        other.type == type &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(name, type, description);
}

class Recipe {
  final String id;
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final int cookingTime;
  final int servings;
  final double matchPercentage;
  final String? imageUrl;
  final NutritionInfo nutrition;
  final List<Allergen> allergens;
  final List<Intolerance> intolerances;
  final List<String> usedIngredients;
  final List<String> missingIngredients;
  final String difficulty; // 'easy', 'medium', 'hard'

  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.servings,
    required this.matchPercentage,
    this.imageUrl,
    required this.nutrition,
    required this.allergens,
    required this.intolerances,
    required this.usedIngredients,
    required this.missingIngredients,
    required this.difficulty,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      ingredients: List<String>.from(json['ingredients'] as List),
      instructions: List<String>.from(json['instructions'] as List),
      cookingTime: json['cooking_time'] as int,
      servings: json['servings'] as int,
      matchPercentage: (json['match_percentage'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      nutrition: NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>),
      allergens: (json['allergens'] as List)
          .map((allergen) => Allergen.fromJson(allergen as Map<String, dynamic>))
          .toList(),
      intolerances: (json['intolerances'] as List)
          .map((intolerance) => Intolerance.fromJson(intolerance as Map<String, dynamic>))
          .toList(),
      usedIngredients: List<String>.from(json['used_ingredients'] as List),
      missingIngredients: List<String>.from(json['missing_ingredients'] as List),
      difficulty: json['difficulty'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'instructions': instructions,
      'cooking_time': cookingTime,
      'servings': servings,
      'match_percentage': matchPercentage,
      'image_url': imageUrl,
      'nutrition': nutrition.toJson(),
      'allergens': allergens.map((allergen) => allergen.toJson()).toList(),
      'intolerances': intolerances.map((intolerance) => intolerance.toJson()).toList(),
      'used_ingredients': usedIngredients,
      'missing_ingredients': missingIngredients,
      'difficulty': difficulty,
    };
  }

  @override
  String toString() => 'Recipe(id: $id, title: $title, match: ${matchPercentage}%)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class RecipeGenerationResult {
  final List<Recipe> recipes;
  final int totalFound;
  final int generationTime;
  final List<Recipe> alternativeSuggestions;
  final String? errorMessage;
  final bool isSuccess;

  const RecipeGenerationResult({
    required this.recipes,
    required this.totalFound,
    required this.generationTime,
    this.alternativeSuggestions = const [],
    this.errorMessage,
    this.isSuccess = true,
  });

  factory RecipeGenerationResult.success({
    required List<Recipe> recipes,
    required int totalFound,
    required int generationTime,
    List<Recipe> alternativeSuggestions = const [],
  }) {
    return RecipeGenerationResult(
      recipes: recipes,
      totalFound: totalFound,
      generationTime: generationTime,
      alternativeSuggestions: alternativeSuggestions,
      isSuccess: true,
    );
  }

  factory RecipeGenerationResult.failure({
    required String errorMessage,
    required int generationTime,
  }) {
    return RecipeGenerationResult(
      recipes: [],
      totalFound: 0,
      generationTime: generationTime,
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    return 'RecipeGenerationResult(recipes: ${recipes.length}, totalFound: $totalFound, '
           'generationTime: ${generationTime}ms, isSuccess: $isSuccess)';
  }
}

// AI recipe service interface
abstract class AIRecipeServiceInterface {
  Future<RecipeGenerationResult> generateRecipesByIngredients(List<String> ingredients);
  Future<List<Recipe>> getTopRecipes(List<String> ingredients, int limit);
  List<Recipe> rankRecipesByMatch(List<Recipe> recipes, List<String> userIngredients);
  Future<List<Recipe>> findAlternativeRecipes(List<String> ingredients);
  Recipe highlightUsedIngredients(Recipe recipe, List<String> detectedIngredients);
  void dispose();
}

// AI recipe service implementation
class AIRecipeService with ConnectivityAware, RetryCapable implements AIRecipeServiceInterface {
  static const String _chatEndpoint = '/chat/completions';
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _defaultRecipeLimit = 5;
  
  late final Dio _dio;
  final String _apiKey;

  AIRecipeService({required String apiKey, Dio? dio}) : _apiKey = apiKey {
    if (dio != null) {
      _dio = dio;
    } else {
      _initializeDio();
    }
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: EnvironmentConfig.apiTimeout,
      receiveTimeout: EnvironmentConfig.apiTimeout,
      sendTimeout: EnvironmentConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    ));

    // Add logging interceptor in debug mode
    if (EnvironmentConfig.isDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  @override
  Future<RecipeGenerationResult> generateRecipesByIngredients(List<String> ingredients) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    
    try {
      if (ingredients.isEmpty) {
        return RecipeGenerationResult.failure(
          errorMessage: 'No ingredients provided',
          generationTime: stopwatch.elapsedMilliseconds,
        );
      }

      // Generate recipes with retry logic
      final Map<String, dynamic> response = await _performRecipeGenerationWithRetry(ingredients);
      
      // Parse the response
      final RecipeGenerationResult result = _parseRecipeResponse(response, ingredients, stopwatch.elapsedMilliseconds);
      
      debugPrint('Recipe generation completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
      
    } catch (e) {
      debugPrint('Error generating recipes: $e');
      return RecipeGenerationResult.failure(
        errorMessage: _getErrorMessage(e),
        generationTime: stopwatch.elapsedMilliseconds,
      );
    } finally {
      stopwatch.stop();
    }
  }

  Future<Map<String, dynamic>> _performRecipeGenerationWithRetry(List<String> ingredients) async {
    return await retryNetworkOperation(() async {
      final Response<Map<String, dynamic>> response = await _dio.post(
        _chatEndpoint,
        data: _buildRecipeGenerationRequest(ingredients),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw AIRecipeServiceException(
          'Invalid response: ${response.statusCode}',
          code: 'INVALID_RESPONSE',
        );
      }
    });
  }

  Map<String, dynamic> _buildRecipeGenerationRequest(List<String> ingredients) {
    return {
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content': _getSystemPrompt(),
        },
        {
          'role': 'user',
          'content': _getUserPrompt(ingredients),
        },
      ],
      'max_tokens': 4000,
      'temperature': 0.3, // Slightly higher for creative recipe generation
    };
  }

  String _getSystemPrompt() {
    return '''
You are a professional chef and nutritionist AI assistant. Your task is to generate detailed recipes based on provided ingredients, including comprehensive nutrition information and allergen detection.

Always respond with valid JSON in this exact structure:
{
  "recipes": [
    {
      "id": "unique_recipe_id",
      "title": "Recipe Name",
      "ingredients": ["ingredient 1", "ingredient 2"],
      "instructions": ["step 1", "step 2"],
      "cooking_time": 30,
      "servings": 4,
      "match_percentage": 85.5,
      "nutrition": {
        "calories": 350,
        "protein": 25.5,
        "carbohydrates": 45.2,
        "fat": 12.8,
        "fiber": 8.3,
        "sugar": 6.1,
        "sodium": 580.2,
        "serving_size": "1 cup"
      },
      "allergens": [
        {
          "name": "Dairy",
          "severity": "medium",
          "description": "Contains milk products"
        }
      ],
      "intolerances": [
        {
          "name": "Lactose",
          "type": "lactose",
          "description": "Contains lactose from dairy products"
        }
      ],
      "used_ingredients": ["ingredient from user list"],
      "missing_ingredients": ["additional ingredients needed"],
      "difficulty": "easy"
    }
  ],
  "total_found": 5,
  "alternative_suggestions": []
}

Guidelines:
- Generate exactly 5 recipes ranked by ingredient match percentage
- Calculate accurate nutrition information per serving
- Identify all potential allergens (nuts, dairy, gluten, shellfish, eggs, soy, etc.)
- Detect intolerances (lactose, gluten, etc.)
- Match percentage should reflect how many user ingredients are used
- Include clear, step-by-step cooking instructions
- Difficulty levels: "easy" (< 30 min, simple techniques), "medium" (30-60 min, moderate skills), "hard" (> 60 min, advanced techniques)
- If no good matches exist, provide alternative suggestions
- All nutrition values should be realistic and accurate
- Allergen severity: "low" (trace amounts), "medium" (moderate amounts), "high" (primary ingredient)
''';
  }

  String _getUserPrompt(List<String> ingredients) {
    final String ingredientList = ingredients.join(', ');
    return '''
Generate 5 recipes using these ingredients: $ingredientList

Requirements:
- Prioritize recipes that use the most provided ingredients
- Include detailed nutrition information for each recipe
- Identify all allergens and intolerances
- Provide clear cooking instructions
- Calculate realistic cooking times
- Rank recipes by ingredient match percentage (highest first)
- If exact matches are limited, include alternative recipe suggestions

Return only the JSON response, no additional text.
''';
  }

  RecipeGenerationResult _parseRecipeResponse(Map<String, dynamic> response, List<String> userIngredients, int processingTime) {
    try {
      final List<dynamic>? choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AIRecipeServiceException('No recipe results in response');
      }

      final Map<String, dynamic>? message = choices[0]['message'] as Map<String, dynamic>?;
      final String? content = message?['content'] as String?;
      
      if (content == null || content.isEmpty) {
        throw AIRecipeServiceException('Empty response content');
      }

      // Parse JSON response
      final Map<String, dynamic> recipeResult = jsonDecode(content);
      
      final List<dynamic>? recipesJson = recipeResult['recipes'] as List<dynamic>?;
      final int totalFound = (recipeResult['total_found'] as int?) ?? 0;
      final List<dynamic>? alternativesJson = recipeResult['alternative_suggestions'] as List<dynamic>?;
      
      if (recipesJson == null) {
        throw AIRecipeServiceException('Invalid response format: missing recipes');
      }

      final List<Recipe> recipes = recipesJson
          .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
          .toList();

      final List<Recipe> alternatives = alternativesJson
          ?.map((json) => Recipe.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      // Rank recipes by match percentage and highlight used ingredients
      final List<Recipe> rankedRecipes = rankRecipesByMatch(recipes, userIngredients);
      final List<Recipe> highlightedRecipes = rankedRecipes
          .map((recipe) => highlightUsedIngredients(recipe, userIngredients))
          .toList();

      return RecipeGenerationResult.success(
        recipes: highlightedRecipes,
        totalFound: totalFound,
        generationTime: processingTime,
        alternativeSuggestions: alternatives,
      );
      
    } catch (e) {
      debugPrint('Error parsing recipe response: $e');
      throw AIRecipeServiceException('Failed to parse recipe response: $e');
    }
  }

  @override
  Future<List<Recipe>> getTopRecipes(List<String> ingredients, int limit) async {
    final RecipeGenerationResult result = await generateRecipesByIngredients(ingredients);
    
    if (!result.isSuccess) {
      throw AIRecipeServiceException(result.errorMessage ?? 'Failed to generate recipes');
    }

    return result.recipes.take(limit).toList();
  }

  @override
  List<Recipe> rankRecipesByMatch(List<Recipe> recipes, List<String> userIngredients) {
    if (userIngredients.isEmpty) return recipes;

    // Create a copy to avoid modifying the original list
    final List<Recipe> rankedRecipes = List.from(recipes);

    // Sort by match percentage (highest first)
    rankedRecipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    return rankedRecipes;
  }

  @override
  Future<List<Recipe>> findAlternativeRecipes(List<String> ingredients) async {
    try {
      // Generate alternative recipes with broader ingredient matching
      final Map<String, dynamic> response = await _performAlternativeRecipeGeneration(ingredients);
      final RecipeGenerationResult result = _parseRecipeResponse(response, ingredients, 0);
      
      return result.isSuccess ? result.recipes : [];
    } catch (e) {
      debugPrint('Error finding alternative recipes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _performAlternativeRecipeGeneration(List<String> ingredients) async {
    final Response<Map<String, dynamic>> response = await _dio.post(
      _chatEndpoint,
      data: _buildAlternativeRecipeRequest(ingredients),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    } else {
      throw AIRecipeServiceException('Failed to generate alternative recipes');
    }
  }

  Map<String, dynamic> _buildAlternativeRecipeRequest(List<String> ingredients) {
    return {
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content': _getSystemPrompt(),
        },
        {
          'role': 'user',
          'content': _getAlternativePrompt(ingredients),
        },
      ],
      'max_tokens': 4000,
      'temperature': 0.5, // Higher temperature for more creative alternatives
    };
  }

  String _getAlternativePrompt(List<String> ingredients) {
    final String ingredientList = ingredients.join(', ');
    return '''
The user has these ingredients: $ingredientList

Since exact matches might be limited, generate 5 alternative recipe suggestions that:
- Use some of the provided ingredients but don't require all of them
- Include common pantry staples that most people have
- Offer different cooking styles and cuisines
- Are accessible for home cooking
- Still provide good nutritional value

Focus on practical, delicious recipes that can work with partial ingredient matches.

Return only the JSON response, no additional text.
''';
  }

  @override
  Recipe highlightUsedIngredients(Recipe recipe, List<String> detectedIngredients) {
    // Normalize ingredient names for better matching
    final List<String> normalizedDetected = detectedIngredients
        .map((ingredient) => ingredient.toLowerCase().trim())
        .toList();

    final List<String> usedIngredients = <String>[];
    final List<String> missingIngredients = <String>[];

    for (final String recipeIngredient in recipe.ingredients) {
      final String normalizedRecipeIngredient = recipeIngredient.toLowerCase().trim();
      
      bool isUsed = false;
      for (final String detectedIngredient in normalizedDetected) {
        if (normalizedRecipeIngredient.contains(detectedIngredient) ||
            detectedIngredient.contains(normalizedRecipeIngredient)) {
          isUsed = true;
          if (!usedIngredients.contains(recipeIngredient)) {
            usedIngredients.add(recipeIngredient);
          }
          break;
        }
      }
      
      if (!isUsed) {
        missingIngredients.add(recipeIngredient);
      }
    }

    // Calculate match percentage based on used ingredients
    final double matchPercentage = recipe.ingredients.isEmpty 
        ? 0.0 
        : (usedIngredients.length / recipe.ingredients.length) * 100;

    return Recipe(
      id: recipe.id,
      title: recipe.title,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      cookingTime: recipe.cookingTime,
      servings: recipe.servings,
      matchPercentage: matchPercentage,
      imageUrl: recipe.imageUrl,
      nutrition: recipe.nutrition,
      allergens: recipe.allergens,
      intolerances: recipe.intolerances,
      usedIngredients: usedIngredients,
      missingIngredients: missingIngredients,
      difficulty: recipe.difficulty,
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is AIRecipeServiceException) {
      return error.message;
    } else if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final int? statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Authentication failed. Please check your API key.';
          } else if (statusCode == 429) {
            return 'Too many requests. Please try again later.';
          } else if (statusCode == 500) {
            return 'Server error. Please try again later.';
          }
          return 'Server returned error: $statusCode';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Connection error. Please check your internet connection.';
        default:
          return 'Network error occurred.';
      }
    }
    return 'An unexpected error occurred: $error';
  }

  @override
  void dispose() {
    _dio.close();
    debugPrint('AI Recipe Service disposed');
  }
}

// AI recipe service exceptions
class AIRecipeServiceException implements Exception {
  final String message;
  final String? code;
  
  const AIRecipeServiceException(this.message, {this.code});
  
  @override
  String toString() => 'AIRecipeServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

// AI recipe service factory
class AIRecipeServiceFactory {
  static AIRecipeServiceInterface create({required String apiKey}) {
    return AIRecipeService(apiKey: apiKey);
  }
}