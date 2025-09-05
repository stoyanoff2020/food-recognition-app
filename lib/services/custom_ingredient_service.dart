import 'dart:convert';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Service for managing custom ingredients with validation, storage, and retrieval
class CustomIngredientService {
  final StorageServiceInterface _storageService;
  
  static const String _customIngredientsKey = 'custom_ingredients';
  static const String _ingredientHistoryKey = 'ingredient_history';
  static const String _frequentIngredientsKey = 'frequent_ingredients';
  
  // Common ingredient categories for validation and suggestions
  static const Map<String, List<String>> _commonIngredients = {
    'proteins': [
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'shrimp', 'eggs',
      'tofu', 'beans', 'lentils', 'chickpeas', 'turkey', 'lamb', 'duck'
    ],
    'vegetables': [
      'onion', 'garlic', 'tomato', 'carrot', 'potato', 'bell pepper', 'broccoli',
      'spinach', 'lettuce', 'cucumber', 'celery', 'mushroom', 'zucchini', 'corn'
    ],
    'fruits': [
      'apple', 'banana', 'orange', 'lemon', 'lime', 'strawberry', 'blueberry',
      'avocado', 'mango', 'pineapple', 'grape', 'cherry', 'peach', 'pear'
    ],
    'grains': [
      'rice', 'pasta', 'bread', 'flour', 'oats', 'quinoa', 'barley', 'wheat',
      'noodles', 'couscous', 'bulgur', 'cornmeal', 'cereal'
    ],
    'dairy': [
      'milk', 'cheese', 'butter', 'yogurt', 'cream', 'sour cream', 'cottage cheese',
      'mozzarella', 'cheddar', 'parmesan', 'feta', 'ricotta'
    ],
    'spices': [
      'salt', 'pepper', 'paprika', 'cumin', 'oregano', 'basil', 'thyme', 'rosemary',
      'cinnamon', 'ginger', 'turmeric', 'chili powder', 'garlic powder', 'onion powder'
    ],
    'oils': [
      'olive oil', 'vegetable oil', 'coconut oil', 'canola oil', 'sesame oil',
      'sunflower oil', 'avocado oil', 'peanut oil'
    ]
  };

  CustomIngredientService(this._storageService);

  /// Validates an ingredient name
  IngredientValidationResult validateIngredient(String ingredient) {
    final trimmed = ingredient.trim();
    
    if (trimmed.isEmpty) {
      return IngredientValidationResult(
        isValid: false,
        error: 'Ingredient name cannot be empty',
      );
    }
    
    if (trimmed.length < 2) {
      return IngredientValidationResult(
        isValid: false,
        error: 'Ingredient name must be at least 2 characters long',
      );
    }
    
    if (trimmed.length > 50) {
      return IngredientValidationResult(
        isValid: false,
        error: 'Ingredient name cannot exceed 50 characters',
      );
    }
    
    // Check for invalid characters (allow letters, numbers, spaces, hyphens, apostrophes)
    final validPattern = RegExp(r"^[a-zA-Z0-9\s\-']+$");
    if (!validPattern.hasMatch(trimmed)) {
      return IngredientValidationResult(
        isValid: false,
        error: 'Ingredient name contains invalid characters',
      );
    }
    
    // Check if it's a reasonable ingredient name (not just numbers or special chars)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(trimmed);
    if (!hasLetter) {
      return IngredientValidationResult(
        isValid: false,
        error: 'Ingredient name must contain at least one letter',
      );
    }
    
    return IngredientValidationResult(
      isValid: true,
      normalizedName: _normalizeIngredientName(trimmed),
      category: _categorizeIngredient(trimmed),
      suggestions: _getSimilarIngredients(trimmed),
    );
  }

  /// Normalizes ingredient name for consistent storage
  String _normalizeIngredientName(String ingredient) {
    return ingredient.trim()
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  /// Categorizes an ingredient based on common ingredient lists
  String _categorizeIngredient(String ingredient) {
    final normalized = ingredient.toLowerCase().trim();
    
    for (final entry in _commonIngredients.entries) {
      if (entry.value.any((item) => 
          normalized.contains(item) || item.contains(normalized))) {
        return entry.key;
      }
    }
    
    return 'other';
  }

  /// Gets similar ingredients for suggestions
  List<String> _getSimilarIngredients(String ingredient) {
    final normalized = ingredient.toLowerCase().trim();
    final suggestions = <String>[];
    
    // Find exact matches first
    for (final category in _commonIngredients.values) {
      for (final item in category) {
        if (item.toLowerCase() == normalized) {
          continue; // Skip exact match
        }
        if (item.toLowerCase().contains(normalized) || 
            normalized.contains(item.toLowerCase())) {
          suggestions.add(_normalizeIngredientName(item));
        }
      }
    }
    
    // Limit suggestions to 5
    return suggestions.take(5).toList();
  }

  /// Adds a custom ingredient to the user's list
  Future<CustomIngredientResult> addCustomIngredient(String ingredient) async {
    try {
      final validation = validateIngredient(ingredient);
      if (!validation.isValid) {
        return CustomIngredientResult(
          success: false,
          error: validation.error,
        );
      }

      final normalizedName = validation.normalizedName!;
      final customIngredients = await getCustomIngredients();
      
      // Check for duplicates
      if (customIngredients.any((item) => 
          item.name.toLowerCase() == normalizedName.toLowerCase())) {
        return CustomIngredientResult(
          success: false,
          error: 'Ingredient "$normalizedName" is already in your list',
        );
      }

      // Create new custom ingredient
      final newIngredient = CustomIngredient(
        name: normalizedName,
        category: validation.category!,
        addedDate: DateTime.now(),
        usageCount: 1,
      );

      customIngredients.add(newIngredient);
      await _saveCustomIngredients(customIngredients);
      
      // Update ingredient history
      await _updateIngredientHistory(normalizedName);
      
      debugPrint('Custom ingredient added: $normalizedName');
      
      return CustomIngredientResult(
        success: true,
        ingredient: newIngredient,
      );
    } catch (e) {
      debugPrint('Error adding custom ingredient: $e');
      return CustomIngredientResult(
        success: false,
        error: 'Failed to add ingredient: $e',
      );
    }
  }

  /// Removes a custom ingredient from the user's list
  Future<bool> removeCustomIngredient(String ingredientName) async {
    try {
      final customIngredients = await getCustomIngredients();
      final initialLength = customIngredients.length;
      
      customIngredients.removeWhere((item) => 
          item.name.toLowerCase() == ingredientName.toLowerCase());
      
      if (customIngredients.length < initialLength) {
        await _saveCustomIngredients(customIngredients);
        debugPrint('Custom ingredient removed: $ingredientName');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error removing custom ingredient: $e');
      return false;
    }
  }

  /// Gets all custom ingredients
  Future<List<CustomIngredient>> getCustomIngredients() async {
    try {
      final preferences = await _storageService.getUserPreferencesMap();
      final ingredientsJson = preferences[_customIngredientsKey] as String?;
      
      if (ingredientsJson == null) return [];
      
      final ingredientsList = jsonDecode(ingredientsJson) as List<dynamic>;
      return ingredientsList
          .map((item) => CustomIngredient.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading custom ingredients: $e');
      return [];
    }
  }

  /// Gets custom ingredients by category
  Future<List<CustomIngredient>> getCustomIngredientsByCategory(String category) async {
    final ingredients = await getCustomIngredients();
    return ingredients.where((item) => item.category == category).toList();
  }

  /// Searches custom ingredients
  Future<List<CustomIngredient>> searchCustomIngredients(String query) async {
    if (query.trim().isEmpty) return [];
    
    final ingredients = await getCustomIngredients();
    final normalizedQuery = query.toLowerCase().trim();
    
    return ingredients.where((item) => 
        item.name.toLowerCase().contains(normalizedQuery)).toList();
  }

  /// Gets frequently used ingredients
  Future<List<CustomIngredient>> getFrequentIngredients({int limit = 10}) async {
    final ingredients = await getCustomIngredients();
    ingredients.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return ingredients.take(limit).toList();
  }

  /// Gets recently added ingredients
  Future<List<CustomIngredient>> getRecentIngredients({int limit = 10}) async {
    final ingredients = await getCustomIngredients();
    ingredients.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return ingredients.take(limit).toList();
  }

  /// Updates usage count for an ingredient
  Future<void> incrementIngredientUsage(String ingredientName) async {
    try {
      final ingredients = await getCustomIngredients();
      final index = ingredients.indexWhere((item) => 
          item.name.toLowerCase() == ingredientName.toLowerCase());
      
      if (index != -1) {
        ingredients[index] = ingredients[index].copyWith(
          usageCount: ingredients[index].usageCount + 1,
          lastUsedDate: DateTime.now(),
        );
        await _saveCustomIngredients(ingredients);
      }
    } catch (e) {
      debugPrint('Error incrementing ingredient usage: $e');
    }
  }

  /// Gets ingredient suggestions based on user history and common ingredients
  Future<List<String>> getIngredientSuggestions({
    String? query,
    int limit = 10,
  }) async {
    final suggestions = <String>[];
    
    // Add frequent ingredients first
    final frequentIngredients = await getFrequentIngredients(limit: 5);
    suggestions.addAll(frequentIngredients.map((item) => item.name));
    
    // Add common ingredients based on query
    if (query != null && query.trim().isNotEmpty) {
      final normalizedQuery = query.toLowerCase().trim();
      
      for (final category in _commonIngredients.values) {
        for (final ingredient in category) {
          if (ingredient.toLowerCase().contains(normalizedQuery) &&
              !suggestions.contains(_normalizeIngredientName(ingredient))) {
            suggestions.add(_normalizeIngredientName(ingredient));
          }
        }
      }
    } else {
      // Add some common ingredients if no query
      final commonSuggestions = [
        'Onion', 'Garlic', 'Tomato', 'Chicken', 'Rice', 'Olive Oil',
        'Salt', 'Pepper', 'Cheese', 'Eggs'
      ];
      
      for (final suggestion in commonSuggestions) {
        if (!suggestions.contains(suggestion)) {
          suggestions.add(suggestion);
        }
      }
    }
    
    return suggestions.take(limit).toList();
  }

  /// Gets ingredient categories with counts
  Future<Map<String, int>> getIngredientCategoryCounts() async {
    final ingredients = await getCustomIngredients();
    final categoryCounts = <String, int>{};
    
    for (final ingredient in ingredients) {
      categoryCounts[ingredient.category] = 
          (categoryCounts[ingredient.category] ?? 0) + 1;
    }
    
    return categoryCounts;
  }

  /// Clears all custom ingredients
  Future<void> clearAllCustomIngredients() async {
    try {
      await _saveCustomIngredients([]);
      await _storageService.saveUserPreference(_ingredientHistoryKey, []);
      debugPrint('All custom ingredients cleared');
    } catch (e) {
      debugPrint('Error clearing custom ingredients: $e');
    }
  }

  /// Exports custom ingredients as JSON
  Future<String> exportCustomIngredients() async {
    final ingredients = await getCustomIngredients();
    return jsonEncode(ingredients.map((item) => item.toJson()).toList());
  }

  /// Imports custom ingredients from JSON
  Future<bool> importCustomIngredients(String jsonData) async {
    try {
      final ingredientsList = jsonDecode(jsonData) as List<dynamic>;
      final ingredients = ingredientsList
          .map((item) => CustomIngredient.fromJson(item as Map<String, dynamic>))
          .toList();
      
      await _saveCustomIngredients(ingredients);
      debugPrint('Custom ingredients imported: ${ingredients.length} items');
      return true;
    } catch (e) {
      debugPrint('Error importing custom ingredients: $e');
      return false;
    }
  }

  /// Private method to save custom ingredients
  Future<void> _saveCustomIngredients(List<CustomIngredient> ingredients) async {
    final json = jsonEncode(ingredients.map((item) => item.toJson()).toList());
    await _storageService.saveUserPreference(_customIngredientsKey, json);
  }

  /// Private method to update ingredient history
  Future<void> _updateIngredientHistory(String ingredientName) async {
    try {
      final preferences = await _storageService.getUserPreferencesMap();
      final historyJson = preferences[_ingredientHistoryKey] as String?;
      
      List<String> history = [];
      if (historyJson != null) {
        history = List<String>.from(jsonDecode(historyJson));
      }
      
      // Remove if exists to avoid duplicates
      history.remove(ingredientName);
      // Add to beginning
      history.insert(0, ingredientName);
      
      // Keep only last 50 items
      if (history.length > 50) {
        history = history.take(50).toList();
      }
      
      await _storageService.saveUserPreference(
        _ingredientHistoryKey, 
        jsonEncode(history)
      );
    } catch (e) {
      debugPrint('Error updating ingredient history: $e');
    }
  }
}

/// Custom ingredient model
class CustomIngredient {
  final String name;
  final String category;
  final DateTime addedDate;
  final int usageCount;
  final DateTime? lastUsedDate;

  const CustomIngredient({
    required this.name,
    required this.category,
    required this.addedDate,
    this.usageCount = 1,
    this.lastUsedDate,
  });

  CustomIngredient copyWith({
    String? name,
    String? category,
    DateTime? addedDate,
    int? usageCount,
    DateTime? lastUsedDate,
  }) {
    return CustomIngredient(
      name: name ?? this.name,
      category: category ?? this.category,
      addedDate: addedDate ?? this.addedDate,
      usageCount: usageCount ?? this.usageCount,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'addedDate': addedDate.toIso8601String(),
      'usageCount': usageCount,
      'lastUsedDate': lastUsedDate?.toIso8601String(),
    };
  }

  factory CustomIngredient.fromJson(Map<String, dynamic> json) {
    return CustomIngredient(
      name: json['name'] as String,
      category: json['category'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
      usageCount: json['usageCount'] as int? ?? 1,
      lastUsedDate: json['lastUsedDate'] != null 
          ? DateTime.parse(json['lastUsedDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomIngredient &&
        other.name == name &&
        other.category == category &&
        other.addedDate == addedDate &&
        other.usageCount == usageCount &&
        other.lastUsedDate == lastUsedDate;
  }

  @override
  int get hashCode {
    return Object.hash(name, category, addedDate, usageCount, lastUsedDate);
  }

  @override
  String toString() {
    return 'CustomIngredient(name: $name, category: $category, usageCount: $usageCount)';
  }
}

/// Result of ingredient validation
class IngredientValidationResult {
  final bool isValid;
  final String? error;
  final String? normalizedName;
  final String? category;
  final List<String> suggestions;

  const IngredientValidationResult({
    required this.isValid,
    this.error,
    this.normalizedName,
    this.category,
    this.suggestions = const [],
  });
}

/// Result of adding a custom ingredient
class CustomIngredientResult {
  final bool success;
  final String? error;
  final CustomIngredient? ingredient;

  const CustomIngredientResult({
    required this.success,
    this.error,
    this.ingredient,
  });
}