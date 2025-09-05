import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/custom_ingredient_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/models/app_state.dart';

// Simple test implementation of StorageServiceInterface
class TestStorageService implements StorageServiceInterface {
  Map<String, dynamic> _preferences = {};
  bool _shouldThrow = false;
  
  void setShouldThrow(bool value) => _shouldThrow = value;
  void setPreference(String key, dynamic value) => _preferences[key] = value;
  void clearPreferences() => _preferences.clear();
  
  @override
  Future<bool> initialize() async => true;
  
  @override
  Future<void> dispose() async {}
  
  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {}
  
  @override
  Future<UserPreferences?> getUserPreferences() async => null;
  
  @override
  Future<void> saveOnboardingData(OnboardingData data) async {}
  
  @override
  Future<OnboardingData?> getOnboardingData() async => null;
  
  @override
  Future<void> saveSubscriptionData(SubscriptionData data) async {}
  
  @override
  Future<SubscriptionData?> getSubscriptionData() async => null;
  
  @override
  Future<void> saveRecipe(SavedRecipe recipe) async {}
  
  @override
  Future<void> deleteRecipe(String recipeId) async {}
  
  @override
  Future<List<SavedRecipe>> getSavedRecipes() async => [];
  
  @override
  Future<SavedRecipe?> getRecipeById(String recipeId) async => null;
  
  @override
  Future<List<SavedRecipe>> searchRecipes(String query) async => [];
  
  @override
  Future<List<SavedRecipe>> getRecipesByCategory(String category) async => [];
  
  @override
  Future<void> saveMealPlan(MealPlan mealPlan) async {}
  
  @override
  Future<void> deleteMealPlan(String mealPlanId) async {}
  
  @override
  Future<List<MealPlan>> getMealPlans() async => [];
  
  @override
  Future<MealPlan?> getMealPlanById(String mealPlanId) async => null;
  
  @override
  Future<void> addRecentSearch(String search) async {}
  
  @override
  Future<List<String>> getRecentSearches() async => [];
  
  @override
  Future<void> clearRecentSearches() async {}
  
  @override
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {}
  
  @override
  Future<Map<String, dynamic>> getAppSettings() async => {};
  
  @override
  Future<void> saveUserPreference(String key, dynamic value) async {
    if (_shouldThrow) throw Exception('Storage error');
    _preferences[key] = value;
  }
  
  @override
  Future<Map<String, dynamic>> getUserPreferencesMap() async {
    if (_shouldThrow) throw Exception('Storage error');
    return _preferences;
  }
  
  @override
  Future<void> clearAllData() async {
    _preferences.clear();
  }
}

void main() {
  group('CustomIngredientService', () {
    late CustomIngredientService service;
    late TestStorageService storage;

    setUp(() {
      storage = TestStorageService();
      service = CustomIngredientService(storage);
    });

    group('validateIngredient', () {
      test('should return invalid for empty ingredient', () {
        final result = service.validateIngredient('');
        
        expect(result.isValid, false);
        expect(result.error, 'Ingredient name cannot be empty');
      });

      test('should return invalid for ingredient too short', () {
        final result = service.validateIngredient('a');
        
        expect(result.isValid, false);
        expect(result.error, 'Ingredient name must be at least 2 characters long');
      });

      test('should return invalid for ingredient too long', () {
        final longName = 'a' * 51;
        final result = service.validateIngredient(longName);
        
        expect(result.isValid, false);
        expect(result.error, 'Ingredient name cannot exceed 50 characters');
      });

      test('should return invalid for ingredient with invalid characters', () {
        final result = service.validateIngredient('tomato@#\$');
        
        expect(result.isValid, false);
        expect(result.error, 'Ingredient name contains invalid characters');
      });

      test('should return invalid for ingredient with only numbers', () {
        final result = service.validateIngredient('123');
        
        expect(result.isValid, false);
        expect(result.error, 'Ingredient name must contain at least one letter');
      });

      test('should return valid for proper ingredient name', () {
        final result = service.validateIngredient('tomato');
        
        expect(result.isValid, true);
        expect(result.normalizedName, 'Tomato');
        expect(result.category, 'vegetables');
        expect(result.error, null);
      });

      test('should normalize ingredient name properly', () {
        final result = service.validateIngredient('  CHICKEN BREAST  ');
        
        expect(result.isValid, true);
        expect(result.normalizedName, 'Chicken Breast');
      });

      test('should categorize ingredients correctly', () {
        final testCases = {
          'chicken': 'proteins',
          'tomato': 'vegetables',
          'apple': 'fruits',
          'rice': 'grains',
          'milk': 'dairy',
          'salt': 'spices',
          'olive oil': 'oils',
          'unknown ingredient': 'other',
        };

        for (final entry in testCases.entries) {
          final result = service.validateIngredient(entry.key);
          expect(result.category, entry.value, 
                 reason: '${entry.key} should be categorized as ${entry.value}');
        }
      });

      test('should provide suggestions for similar ingredients', () {
        final result = service.validateIngredient('tom');
        
        expect(result.isValid, true);
        expect(result.suggestions, isNotEmpty);
        expect(result.suggestions.any((s) => s.toLowerCase().contains('tomato')), true);
      });
    });

    group('addCustomIngredient', () {
      test('should add valid ingredient successfully', () async {
        final result = await service.addCustomIngredient('tomato');
        
        expect(result.success, true);
        expect(result.ingredient, isNotNull);
        expect(result.ingredient!.name, 'Tomato');
        expect(result.ingredient!.category, 'vegetables');
        expect(result.ingredient!.usageCount, 1);
        expect(result.error, null);
        
        // Verify data was saved
        expect(storage._preferences.containsKey('custom_ingredients'), true);
        expect(storage._preferences.containsKey('ingredient_history'), true);
      });

      test('should reject invalid ingredient', () async {
        final result = await service.addCustomIngredient('');
        
        expect(result.success, false);
        expect(result.error, 'Ingredient name cannot be empty');
        expect(result.ingredient, null);
      });

      test('should reject duplicate ingredient', () async {
        // Add first ingredient
        await service.addCustomIngredient('tomato');
        
        // Try to add duplicate
        final result = await service.addCustomIngredient('tomato');
        
        expect(result.success, false);
        expect(result.error, 'Ingredient "Tomato" is already in your list');
        expect(result.ingredient, null);
      });

      test('should handle storage errors gracefully', () async {
        storage.setShouldThrow(true);

        final result = await service.addCustomIngredient('tomato');
        
        expect(result.success, false);
        expect(result.error, contains('Failed to add ingredient'));
      });
    });

    group('removeCustomIngredient', () {
      test('should remove existing ingredient successfully', () async {
        // Add ingredient first
        await service.addCustomIngredient('tomato');
        
        // Remove it
        final result = await service.removeCustomIngredient('Tomato');
        
        expect(result, true);
        
        // Verify it's gone
        final ingredients = await service.getCustomIngredients();
        expect(ingredients.any((i) => i.name == 'Tomato'), false);
      });

      test('should handle case-insensitive removal', () async {
        await service.addCustomIngredient('tomato');
        
        final result = await service.removeCustomIngredient('TOMATO');
        
        expect(result, true);
      });

      test('should return false for non-existent ingredient', () async {
        final result = await service.removeCustomIngredient('NonExistent');
        
        expect(result, false);
      });
    });

    group('getCustomIngredients', () {
      test('should return empty list when no ingredients stored', () async {
        final result = await service.getCustomIngredients();
        
        expect(result, isEmpty);
      });

      test('should return stored ingredients', () async {
        await service.addCustomIngredient('tomato');
        await service.addCustomIngredient('chicken');
        
        final result = await service.getCustomIngredients();
        
        expect(result, hasLength(2));
        expect(result.map((i) => i.name), containsAll(['Tomato', 'Chicken']));
      });

      test('should handle storage errors gracefully', () async {
        storage.setShouldThrow(true);

        final result = await service.getCustomIngredients();
        
        expect(result, isEmpty);
      });
    });

    group('searchCustomIngredients', () {
      setUp(() async {
        await service.addCustomIngredient('tomato');
        await service.addCustomIngredient('chicken breast');
        await service.addCustomIngredient('cherry tomato');
      });

      test('should return matching ingredients', () async {
        final result = await service.searchCustomIngredients('tomato');
        
        expect(result, hasLength(2));
        expect(result.map((i) => i.name), containsAll(['Tomato', 'Cherry Tomato']));
      });

      test('should be case insensitive', () async {
        final result = await service.searchCustomIngredients('CHICKEN');
        
        expect(result, hasLength(1));
        expect(result.first.name, 'Chicken Breast');
      });

      test('should return empty list for empty query', () async {
        final result = await service.searchCustomIngredients('');
        
        expect(result, isEmpty);
      });

      test('should return empty list for no matches', () async {
        final result = await service.searchCustomIngredients('nonexistent');
        
        expect(result, isEmpty);
      });
    });

    group('getIngredientSuggestions', () {
      test('should return suggestions without query', () async {
        final result = await service.getIngredientSuggestions();
        
        expect(result, isNotEmpty);
        expect(result, contains('Onion'));
        expect(result, contains('Garlic'));
      });

      test('should return filtered suggestions with query', () async {
        final result = await service.getIngredientSuggestions(query: 'tom');
        
        expect(result, isNotEmpty);
        expect(result.any((s) => s.toLowerCase().contains('tom')), true);
      });

      test('should respect limit parameter', () async {
        final result = await service.getIngredientSuggestions(limit: 3);
        
        expect(result.length, lessThanOrEqualTo(3));
      });
    });

    group('clearAllCustomIngredients', () {
      test('should clear all ingredients and history', () async {
        await service.addCustomIngredient('tomato');
        await service.addCustomIngredient('chicken');
        
        await service.clearAllCustomIngredients();
        
        final ingredients = await service.getCustomIngredients();
        expect(ingredients, isEmpty);
      });
    });

    group('exportCustomIngredients', () {
      test('should export ingredients as JSON', () async {
        await service.addCustomIngredient('tomato');
        
        final result = await service.exportCustomIngredients();
        
        expect(result, isA<String>());
        expect(result, contains('Tomato'));
        expect(result, contains('vegetables'));
      });
    });

    group('importCustomIngredients', () {
      test('should import valid JSON data', () async {
        final jsonData = '[{"name":"Tomato","category":"vegetables","addedDate":"2023-01-01T00:00:00.000Z","usageCount":1}]';
        
        final result = await service.importCustomIngredients(jsonData);
        
        expect(result, true);
        
        final ingredients = await service.getCustomIngredients();
        expect(ingredients, hasLength(1));
        expect(ingredients.first.name, 'Tomato');
      });

      test('should handle invalid JSON gracefully', () async {
        final result = await service.importCustomIngredients('invalid json');
        
        expect(result, false);
      });
    });
  });

  group('CustomIngredient', () {
    test('should create ingredient with required fields', () {
      final now = DateTime.now();
      final ingredient = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
      );

      expect(ingredient.name, 'Tomato');
      expect(ingredient.category, 'vegetables');
      expect(ingredient.addedDate, now);
      expect(ingredient.usageCount, 1);
      expect(ingredient.lastUsedDate, null);
    });

    test('should copy with changes', () {
      final now = DateTime.now();
      final ingredient = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
        usageCount: 1,
      );

      final updated = ingredient.copyWith(usageCount: 5);

      expect(updated.name, 'Tomato');
      expect(updated.category, 'vegetables');
      expect(updated.addedDate, now);
      expect(updated.usageCount, 5);
    });

    test('should serialize to and from JSON', () {
      final now = DateTime.now();
      final ingredient = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
        usageCount: 2,
      );

      final json = ingredient.toJson();
      final restored = CustomIngredient.fromJson(json);

      expect(restored.name, ingredient.name);
      expect(restored.category, ingredient.category);
      expect(restored.addedDate, ingredient.addedDate);
      expect(restored.usageCount, ingredient.usageCount);
    });

    test('should handle equality correctly', () {
      final now = DateTime.now();
      final ingredient1 = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
      );
      final ingredient2 = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
      );
      final ingredient3 = CustomIngredient(
        name: 'Chicken',
        category: 'proteins',
        addedDate: now,
      );

      expect(ingredient1, equals(ingredient2));
      expect(ingredient1, isNot(equals(ingredient3)));
    });
  });
}