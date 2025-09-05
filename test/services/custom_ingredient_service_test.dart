import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/custom_ingredient_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/models/app_state.dart';

// Test implementation of StorageServiceInterface
class TestStorageService implements StorageServiceInterface {
  Map<String, dynamic> _preferences = {};
  
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
    _preferences[key] = value;
  }
  
  @override
  Future<Map<String, dynamic>> getUserPreferencesMap() async => _preferences;
  
  @override
  Future<void> clearAllData() async {
    _preferences.clear();
  }
  
  // Helper methods for testing
  void setPreference(String key, dynamic value) {
    _preferences[key] = value;
  }
  
  void throwOnNextCall() {
    // For testing error scenarios
  }
}

void main() {
  group('CustomIngredientService', () {
    late CustomIngredientService service;
    late TestStorageService mockStorage;

    setUp(() {
      mockStorage = TestStorageService();
      service = CustomIngredientService(mockStorage);
    });

    group('validateIngredient', () {
      test('should return invalid for empty ingredient', () {
        final result = service.validateIngredient('');
        
        expect(result.isValid, false);
        expect(result.error, 'Ingredient name cannot be empty');
      });

      test('should return invalid for ingredient with only spaces', () {
        final result = service.validateIngredient('   ');
        
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

      test('should allow valid special characters', () {
        final validNames = [
          "bell pepper",
          "mother's milk",
          "whole-wheat bread",
          "chicken123",
        ];

        for (final name in validNames) {
          final result = service.validateIngredient(name);
          expect(result.isValid, true, reason: '$name should be valid');
        }
      });
    });

    group('addCustomIngredient', () {
      setUp(() {
        mockStorage._preferences.clear();
      });

      test('should add valid ingredient successfully', () async {
        final result = await service.addCustomIngredient('tomato');
        
        expect(result.success, true);
        expect(result.ingredient, isNotNull);
        expect(result.ingredient!.name, 'Tomato');
        expect(result.ingredient!.category, 'vegetables');
        expect(result.ingredient!.usageCount, 1);
        expect(result.error, null);
        
        // Verify data was saved
        expect(mockStorage._preferences.containsKey('custom_ingredients'), true);
        expect(mockStorage._preferences.containsKey('ingredient_history'), true);
      });

      test('should reject invalid ingredient', () async {
        final result = await service.addCustomIngredient('');
        
        expect(result.success, false);
        expect(result.error, 'Ingredient name cannot be empty');
        expect(result.ingredient, null);
        
        // Verify no data was saved
        expect(mockStorage._preferences.isEmpty, true);
      });

      test('should reject duplicate ingredient', () async {
        // Setup existing ingredients
        final existingIngredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(existingIngredients.map((i) => i.toJson()).toList()),
        });

        final result = await service.addCustomIngredient('tomato');
        
        expect(result.success, false);
        expect(result.error, 'Ingredient "Tomato" is already in your list');
        expect(result.ingredient, null);
      });

      test('should handle storage errors gracefully', () async {
        when(mockStorage.getUserPreferencesMap())
            .thenThrow(Exception('Storage error'));

        final result = await service.addCustomIngredient('tomato');
        
        expect(result.success, false);
        expect(result.error, contains('Failed to add ingredient'));
      });
    });

    group('removeCustomIngredient', () {
      setUp(() {
        final existingIngredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Chicken',
            category: 'proteins',
            addedDate: DateTime.now(),
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(existingIngredients.map((i) => i.toJson()).toList()),
        });
        when(mockStorage.saveUserPreference(any, any))
            .thenAnswer((_) async {});
      });

      test('should remove existing ingredient successfully', () async {
        final result = await service.removeCustomIngredient('Tomato');
        
        expect(result, true);
        verify(mockStorage.saveUserPreference(any, any)).called(1);
      });

      test('should handle case-insensitive removal', () async {
        final result = await service.removeCustomIngredient('tomato');
        
        expect(result, true);
      });

      test('should return false for non-existent ingredient', () async {
        final result = await service.removeCustomIngredient('NonExistent');
        
        expect(result, false);
        verifyNever(mockStorage.saveUserPreference(any, any));
      });

      test('should handle storage errors gracefully', () async {
        when(mockStorage.getUserPreferencesMap())
            .thenThrow(Exception('Storage error'));

        final result = await service.removeCustomIngredient('Tomato');
        
        expect(result, false);
      });
    });

    group('getCustomIngredients', () {
      test('should return empty list when no ingredients stored', () async {
        when(mockStorage.getUserPreferencesMap())
            .thenAnswer((_) async => <String, dynamic>{});

        final result = await service.getCustomIngredients();
        
        expect(result, isEmpty);
      });

      test('should return stored ingredients', () async {
        final storedIngredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
            usageCount: 2,
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(storedIngredients.map((i) => i.toJson()).toList()),
        });

        final result = await service.getCustomIngredients();
        
        expect(result, hasLength(1));
        expect(result.first.name, 'Tomato');
        expect(result.first.category, 'vegetables');
        expect(result.first.usageCount, 2);
      });

      test('should handle malformed data gracefully', () async {
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': 'invalid json',
        });

        final result = await service.getCustomIngredients();
        
        expect(result, isEmpty);
      });

      test('should handle storage errors gracefully', () async {
        when(mockStorage.getUserPreferencesMap())
            .thenThrow(Exception('Storage error'));

        final result = await service.getCustomIngredients();
        
        expect(result, isEmpty);
      });
    });

    group('getCustomIngredientsByCategory', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Chicken',
            category: 'proteins',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Carrot',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
      });

      test('should return ingredients for specific category', () async {
        final result = await service.getCustomIngredientsByCategory('vegetables');
        
        expect(result, hasLength(2));
        expect(result.every((i) => i.category == 'vegetables'), true);
        expect(result.map((i) => i.name), containsAll(['Tomato', 'Carrot']));
      });

      test('should return empty list for non-existent category', () async {
        final result = await service.getCustomIngredientsByCategory('nonexistent');
        
        expect(result, isEmpty);
      });
    });

    group('searchCustomIngredients', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Chicken Breast',
            category: 'proteins',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Cherry Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
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

    group('getFrequentIngredients', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
            usageCount: 5,
          ),
          CustomIngredient(
            name: 'Chicken',
            category: 'proteins',
            addedDate: DateTime.now(),
            usageCount: 3,
          ),
          CustomIngredient(
            name: 'Rice',
            category: 'grains',
            addedDate: DateTime.now(),
            usageCount: 8,
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
      });

      test('should return ingredients sorted by usage count', () async {
        final result = await service.getFrequentIngredients();
        
        expect(result, hasLength(3));
        expect(result[0].name, 'Rice'); // highest usage count (8)
        expect(result[1].name, 'Tomato'); // second highest (5)
        expect(result[2].name, 'Chicken'); // lowest (3)
      });

      test('should respect limit parameter', () async {
        final result = await service.getFrequentIngredients(limit: 2);
        
        expect(result, hasLength(2));
        expect(result[0].name, 'Rice');
        expect(result[1].name, 'Tomato');
      });
    });

    group('getRecentIngredients', () {
      setUp(() {
        final now = DateTime.now();
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: now.subtract(const Duration(days: 2)),
          ),
          CustomIngredient(
            name: 'Chicken',
            category: 'proteins',
            addedDate: now.subtract(const Duration(days: 1)),
          ),
          CustomIngredient(
            name: 'Rice',
            category: 'grains',
            addedDate: now,
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
      });

      test('should return ingredients sorted by added date', () async {
        final result = await service.getRecentIngredients();
        
        expect(result, hasLength(3));
        expect(result[0].name, 'Rice'); // most recent
        expect(result[1].name, 'Chicken'); // second most recent
        expect(result[2].name, 'Tomato'); // oldest
      });

      test('should respect limit parameter', () async {
        final result = await service.getRecentIngredients(limit: 2);
        
        expect(result, hasLength(2));
        expect(result[0].name, 'Rice');
        expect(result[1].name, 'Chicken');
      });
    });

    group('incrementIngredientUsage', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
            usageCount: 2,
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
        when(mockStorage.saveUserPreference(any, any))
            .thenAnswer((_) async {});
      });

      test('should increment usage count for existing ingredient', () async {
        await service.incrementIngredientUsage('Tomato');
        
        verify(mockStorage.saveUserPreference(any, any)).called(1);
      });

      test('should handle case-insensitive ingredient names', () async {
        await service.incrementIngredientUsage('tomato');
        
        verify(mockStorage.saveUserPreference(any, any)).called(1);
      });

      test('should handle non-existent ingredient gracefully', () async {
        await service.incrementIngredientUsage('NonExistent');
        
        verifyNever(mockStorage.saveUserPreference(any, any));
      });
    });

    group('getIngredientSuggestions', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
            usageCount: 5,
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
      });

      test('should return suggestions without query', () async {
        final result = await service.getIngredientSuggestions();
        
        expect(result, isNotEmpty);
        expect(result, contains('Tomato')); // frequent ingredient
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

    group('getIngredientCategoryCounts', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Carrot',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
          CustomIngredient(
            name: 'Chicken',
            category: 'proteins',
            addedDate: DateTime.now(),
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
      });

      test('should return category counts', () async {
        final result = await service.getIngredientCategoryCounts();
        
        expect(result, hasLength(2));
        expect(result['vegetables'], 2);
        expect(result['proteins'], 1);
      });
    });

    group('clearAllCustomIngredients', () {
      setUp(() {
        when(mockStorage.saveUserPreference(any, any))
            .thenAnswer((_) async {});
      });

      test('should clear all ingredients and history', () async {
        await service.clearAllCustomIngredients();
        
        verify(mockStorage.saveUserPreference('custom_ingredients', '[]')).called(1);
        verify(mockStorage.saveUserPreference('ingredient_history', [])).called(1);
      });
    });

    group('exportCustomIngredients', () {
      setUp(() {
        final ingredients = [
          CustomIngredient(
            name: 'Tomato',
            category: 'vegetables',
            addedDate: DateTime.now(),
          ),
        ];
        
        when(mockStorage.getUserPreferencesMap()).thenAnswer((_) async => {
          'custom_ingredients': jsonEncode(ingredients.map((i) => i.toJson()).toList()),
        });
      });

      test('should export ingredients as JSON', () async {
        final result = await service.exportCustomIngredients();
        
        expect(result, isA<String>());
        expect(result, contains('Tomato'));
        expect(result, contains('vegetables'));
      });
    });

    group('importCustomIngredients', () {
      setUp(() {
        when(mockStorage.saveUserPreference(any, any))
            .thenAnswer((_) async {});
      });

      test('should import valid JSON data', () async {
        final jsonData = '[{"name":"Tomato","category":"vegetables","addedDate":"2023-01-01T00:00:00.000Z","usageCount":1}]';
        
        final result = await service.importCustomIngredients(jsonData);
        
        expect(result, true);
        verify(mockStorage.saveUserPreference(any, any)).called(1);
      });

      test('should handle invalid JSON gracefully', () async {
        final result = await service.importCustomIngredients('invalid json');
        
        expect(result, false);
        verifyNever(mockStorage.saveUserPreference(any, any));
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

    test('should create ingredient with all fields', () {
      final now = DateTime.now();
      final lastUsed = now.subtract(const Duration(hours: 1));
      
      final ingredient = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
        usageCount: 5,
        lastUsedDate: lastUsed,
      );

      expect(ingredient.name, 'Tomato');
      expect(ingredient.category, 'vegetables');
      expect(ingredient.addedDate, now);
      expect(ingredient.usageCount, 5);
      expect(ingredient.lastUsedDate, lastUsed);
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

    test('should serialize to JSON', () {
      final now = DateTime.now();
      final ingredient = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: now,
        usageCount: 2,
      );

      final json = ingredient.toJson();

      expect(json['name'], 'Tomato');
      expect(json['category'], 'vegetables');
      expect(json['addedDate'], now.toIso8601String());
      expect(json['usageCount'], 2);
    });

    test('should deserialize from JSON', () {
      final now = DateTime.now();
      final json = {
        'name': 'Tomato',
        'category': 'vegetables',
        'addedDate': now.toIso8601String(),
        'usageCount': 2,
        'lastUsedDate': now.toIso8601String(),
      };

      final ingredient = CustomIngredient.fromJson(json);

      expect(ingredient.name, 'Tomato');
      expect(ingredient.category, 'vegetables');
      expect(ingredient.addedDate, now);
      expect(ingredient.usageCount, 2);
      expect(ingredient.lastUsedDate, now);
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

    test('should have consistent hashCode', () {
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

      expect(ingredient1.hashCode, equals(ingredient2.hashCode));
    });

    test('should have meaningful toString', () {
      final ingredient = CustomIngredient(
        name: 'Tomato',
        category: 'vegetables',
        addedDate: DateTime.now(),
        usageCount: 3,
      );

      final string = ingredient.toString();

      expect(string, contains('Tomato'));
      expect(string, contains('vegetables'));
      expect(string, contains('3'));
    });
  });
}