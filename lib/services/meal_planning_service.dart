import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../models/subscription.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

/// Exception thrown when meal planning operations fail
class MealPlanningException implements Exception {
  final String message;
  final String? code;
  
  const MealPlanningException(this.message, {this.code});
  
  @override
  String toString() => 'MealPlanningException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Service interface for meal planning functionality
abstract class MealPlanningServiceInterface {
  /// Create a new meal plan
  /// Requires Professional subscription
  Future<MealPlan> createMealPlan(String name, String startDate, MealPlanType type);
  
  /// Get all meal plans
  Future<List<MealPlan>> getMealPlans();
  
  /// Get a specific meal plan by ID
  Future<MealPlan?> getMealPlan(String planId);
  
  /// Delete a meal plan
  Future<void> deleteMealPlan(String planId);
  
  /// Add a meal to a meal plan
  Future<void> addMealToPlan(String planId, PlannedMeal meal);
  
  /// Remove a meal from a meal plan
  Future<void> removeMealFromPlan(String planId, String mealId);
  
  /// Update a meal in a meal plan
  Future<void> updateMealInPlan(String planId, PlannedMeal updatedMeal);
  
  /// Calculate daily nutrients for a specific date in a meal plan
  Future<DailyNutrients> calculateDailyNutrients(String planId, String date);
  
  /// Set nutrition goals for a user
  Future<void> setNutritionGoals(NutritionGoals goals);
  
  /// Get current nutrition goals
  Future<NutritionGoals> getNutritionGoals();
  
  /// Get nutrition progress for a specific date
  Future<NutritionProgress> getNutritionProgress(String planId, String date);
  
  /// Generate shopping list from meal plan
  Future<ShoppingList> generateShoppingList(String planId, {String? startDate, String? endDate});
  
  /// Get saved shopping lists
  Future<List<ShoppingList>> getShoppingLists();
  
  /// Update shopping list item
  Future<void> updateShoppingListItem(String shoppingListId, String itemId, bool isChecked);
  
  /// Delete shopping list
  Future<void> deleteShoppingList(String shoppingListId);
  
  /// Check if user has access to meal planning features
  Future<bool> hasMealPlanningAccess();
  
  /// Get meal planning statistics
  Future<MealPlanningStats> getStats();
  
  /// Get suggested recipes for meal planning based on nutrition goals
  Future<List<SavedRecipe>> getSuggestedRecipes(String date, MealType mealType, {NutritionGoals? goals});
}

/// Implementation of meal planning service
class MealPlanningService implements MealPlanningServiceInterface {
  final StorageServiceInterface _storageService;
  final SubscriptionService _subscriptionService;
  
  static const String _mealPlansKey = 'meal_plans';
  static const String _nutritionGoalsKey = 'nutrition_goals';
  static const String _shoppingListsKey = 'shopping_lists';
  
  MealPlanningService({
    required StorageServiceInterface storageService,
    required SubscriptionService subscriptionService,
  }) : _storageService = storageService,
       _subscriptionService = subscriptionService;

  @override
  Future<MealPlan> createMealPlan(String name, String startDate, MealPlanType type) async {
    // Check subscription access
    if (!await hasMealPlanningAccess()) {
      throw const MealPlanningException(
        'Meal planning access requires Professional subscription',
        code: 'SUBSCRIPTION_REQUIRED',
      );
    }

    try {
      // Calculate end date based on type
      final startDateTime = DateTime.parse(startDate);
      String endDate;
      
      switch (type) {
        case MealPlanType.weekly:
          endDate = startDateTime.add(const Duration(days: 6)).toIso8601String().split('T')[0];
          break;
        case MealPlanType.monthly:
          endDate = DateTime(startDateTime.year, startDateTime.month + 1, 0).toIso8601String().split('T')[0];
          break;
        case MealPlanType.custom:
          // For custom, use 7 days as default, can be modified later
          endDate = startDateTime.add(const Duration(days: 6)).toIso8601String().split('T')[0];
          break;
      }

      // Generate unique ID
      final id = 'meal_plan_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create meal plan
      final mealPlan = MealPlan(
        id: id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        type: type,
        meals: [],
        dailyNutrients: _generateEmptyDailyNutrients(startDate, endDate),
        createdDate: DateTime.now(),
      );

      // Save meal plan
      await _saveMealPlan(mealPlan);
      
      // Track usage
      await _subscriptionService.incrementUsage(UsageType.mealPlanCreate);
      
      debugPrint('Meal plan created successfully: $name');
      return mealPlan;
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to create meal plan: $e');
    }
  }

  @override
  Future<List<MealPlan>> getMealPlans() async {
    try {
      final mealPlansData = await _storageService.getData(_mealPlansKey);
      if (mealPlansData == null) return [];
      
      final mealPlansList = mealPlansData as List<dynamic>;
      return mealPlansList
          .map((planData) => MealPlan.fromJson(planData))
          .toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } catch (e) {
      throw MealPlanningException('Failed to get meal plans: $e');
    }
  }

  @override
  Future<MealPlan?> getMealPlan(String planId) async {
    try {
      final mealPlans = await getMealPlans();
      return mealPlans.where((plan) => plan.id == planId).firstOrNull;
    } catch (e) {
      throw MealPlanningException('Failed to get meal plan: $e');
    }
  }

  @override
  Future<void> deleteMealPlan(String planId) async {
    try {
      final mealPlans = await getMealPlans();
      final updatedPlans = mealPlans.where((plan) => plan.id != planId).toList();
      
      await _storageService.saveData(
        _mealPlansKey,
        updatedPlans.map((plan) => plan.toJson()).toList(),
      );
      
      // Also delete associated shopping lists
      final shoppingLists = await getShoppingLists();
      final updatedShoppingLists = shoppingLists
          .where((list) => list.mealPlanId != planId)
          .toList();
      
      await _storageService.saveData(
        _shoppingListsKey,
        updatedShoppingLists.map((list) => list.toJson()).toList(),
      );
      
      debugPrint('Meal plan deleted successfully: $planId');
    } catch (e) {
      throw MealPlanningException('Failed to delete meal plan: $e');
    }
  }

  @override
  Future<void> addMealToPlan(String planId, PlannedMeal meal) async {
    try {
      final mealPlan = await getMealPlan(planId);
      if (mealPlan == null) {
        throw MealPlanningException(
          'Meal plan not found: $planId',
          code: 'MEAL_PLAN_NOT_FOUND',
        );
      }

      // Check if meal already exists for this date and meal type
      final existingMeal = mealPlan.meals.where(
        (m) => m.date == meal.date && m.mealType == meal.mealType,
      ).firstOrNull;

      List<PlannedMeal> updatedMeals;
      if (existingMeal != null) {
        // Replace existing meal
        updatedMeals = mealPlan.meals
            .map((m) => m.id == existingMeal.id ? meal : m)
            .toList();
      } else {
        // Add new meal
        updatedMeals = [...mealPlan.meals, meal];
      }

      // Recalculate daily nutrients
      final updatedDailyNutrients = await _recalculateDailyNutrients(
        mealPlan,
        updatedMeals,
      );

      final updatedMealPlan = mealPlan.copyWith(
        meals: updatedMeals,
        dailyNutrients: updatedDailyNutrients,
        lastModified: DateTime.now(),
      );

      await _saveMealPlan(updatedMealPlan);
      debugPrint('Meal added to plan successfully: ${meal.recipeTitle}');
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to add meal to plan: $e');
    }
  }

  @override
  Future<void> removeMealFromPlan(String planId, String mealId) async {
    try {
      final mealPlan = await getMealPlan(planId);
      if (mealPlan == null) {
        throw MealPlanningException(
          'Meal plan not found: $planId',
          code: 'MEAL_PLAN_NOT_FOUND',
        );
      }

      final updatedMeals = mealPlan.meals.where((meal) => meal.id != mealId).toList();
      
      // Recalculate daily nutrients
      final updatedDailyNutrients = await _recalculateDailyNutrients(
        mealPlan,
        updatedMeals,
      );

      final updatedMealPlan = mealPlan.copyWith(
        meals: updatedMeals,
        dailyNutrients: updatedDailyNutrients,
        lastModified: DateTime.now(),
      );

      await _saveMealPlan(updatedMealPlan);
      debugPrint('Meal removed from plan successfully: $mealId');
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to remove meal from plan: $e');
    }
  }

  @override
  Future<void> updateMealInPlan(String planId, PlannedMeal updatedMeal) async {
    try {
      final mealPlan = await getMealPlan(planId);
      if (mealPlan == null) {
        throw MealPlanningException(
          'Meal plan not found: $planId',
          code: 'MEAL_PLAN_NOT_FOUND',
        );
      }

      final updatedMeals = mealPlan.meals
          .map((meal) => meal.id == updatedMeal.id ? updatedMeal : meal)
          .toList();

      // Recalculate daily nutrients
      final updatedDailyNutrients = await _recalculateDailyNutrients(
        mealPlan,
        updatedMeals,
      );

      final updatedMealPlan = mealPlan.copyWith(
        meals: updatedMeals,
        dailyNutrients: updatedDailyNutrients,
        lastModified: DateTime.now(),
      );

      await _saveMealPlan(updatedMealPlan);
      debugPrint('Meal updated in plan successfully: ${updatedMeal.recipeTitle}');
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to update meal in plan: $e');
    }
  }

  @override
  Future<DailyNutrients> calculateDailyNutrients(String planId, String date) async {
    try {
      final mealPlan = await getMealPlan(planId);
      if (mealPlan == null) {
        throw MealPlanningException(
          'Meal plan not found: $planId',
          code: 'MEAL_PLAN_NOT_FOUND',
        );
      }

      final mealsForDate = mealPlan.getMealsForDate(date);
      final nutritionGoals = await getNutritionGoals();

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbohydrates = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;
      double totalSodium = 0;

      for (final meal in mealsForDate) {
        final scaledNutrition = meal.getScaledNutrition();
        if (scaledNutrition != null) {
          totalCalories += scaledNutrition.calories;
          totalProtein += scaledNutrition.protein;
          totalCarbohydrates += scaledNutrition.carbohydrates;
          totalFat += scaledNutrition.fat;
          totalFiber += scaledNutrition.fiber;
          totalSugar += scaledNutrition.sugar;
          totalSodium += scaledNutrition.sodium;
        }
      }

      final dailyNutrients = DailyNutrients(
        date: date,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbohydrates: totalCarbohydrates,
        totalFat: totalFat,
        totalFiber: totalFiber,
        totalSugar: totalSugar,
        totalSodium: totalSodium,
        nutritionGoals: nutritionGoals,
      );

      final progress = dailyNutrients.calculateProgress(nutritionGoals);
      return dailyNutrients.copyWith(goalProgress: progress);
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to calculate daily nutrients: $e');
    }
  }

  @override
  Future<void> setNutritionGoals(NutritionGoals goals) async {
    try {
      await _storageService.saveData(_nutritionGoalsKey, goals.toJson());
      debugPrint('Nutrition goals updated successfully');
    } catch (e) {
      throw MealPlanningException('Failed to set nutrition goals: $e');
    }
  }

  @override
  Future<NutritionGoals> getNutritionGoals() async {
    try {
      final goalsData = await _storageService.getData(_nutritionGoalsKey);
      if (goalsData == null) {
        return NutritionGoals.defaultGoals;
      }
      return NutritionGoals.fromJson(goalsData);
    } catch (e) {
      debugPrint('Error getting nutrition goals, using defaults: $e');
      return NutritionGoals.defaultGoals;
    }
  }

  @override
  Future<NutritionProgress> getNutritionProgress(String planId, String date) async {
    try {
      final dailyNutrients = await calculateDailyNutrients(planId, date);
      final goals = await getNutritionGoals();
      return dailyNutrients.calculateProgress(goals);
    } catch (e) {
      throw MealPlanningException('Failed to get nutrition progress: $e');
    }
  }

  @override
  Future<ShoppingList> generateShoppingList(String planId, {String? startDate, String? endDate}) async {
    try {
      final mealPlan = await getMealPlan(planId);
      if (mealPlan == null) {
        throw MealPlanningException(
          'Meal plan not found: $planId',
          code: 'MEAL_PLAN_NOT_FOUND',
        );
      }

      final effectiveStartDate = startDate ?? mealPlan.startDate;
      final effectiveEndDate = endDate ?? mealPlan.endDate;

      // Get all meals within the date range
      final mealsInRange = mealPlan.meals.where((meal) {
        final mealDate = DateTime.parse(meal.date);
        final start = DateTime.parse(effectiveStartDate);
        final end = DateTime.parse(effectiveEndDate);
        return mealDate.isAfter(start.subtract(const Duration(days: 1))) &&
               mealDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      // Get saved recipes to extract ingredients
      final savedRecipes = await _storageService.getSavedRecipes();
      final ingredientMap = <String, ShoppingListItem>{};

      for (final meal in mealsInRange) {
        final recipe = savedRecipes.where((r) => r.id == meal.recipeId).firstOrNull;
        if (recipe != null) {
          for (final ingredient in recipe.ingredients) {
            final cleanIngredient = _parseIngredient(ingredient);
            final key = cleanIngredient['name']!.toLowerCase();
            
            if (ingredientMap.containsKey(key)) {
              // Combine quantities (simplified - in real app would need proper unit conversion)
              final existing = ingredientMap[key]!;
              final existingRecipes = [...existing.usedInRecipes];
              if (!existingRecipes.contains(recipe.title)) {
                existingRecipes.add(recipe.title);
              }
              
              ingredientMap[key] = existing.copyWith(
                quantity: '${existing.quantity} + ${cleanIngredient['quantity']}',
                usedInRecipes: existingRecipes,
              );
            } else {
              ingredientMap[key] = ShoppingListItem(
                ingredient: cleanIngredient['name']!,
                quantity: cleanIngredient['quantity']!,
                unit: cleanIngredient['unit']!,
                usedInRecipes: [recipe.title],
              );
            }
          }
        }
      }

      final shoppingList = ShoppingList(
        id: 'shopping_list_${DateTime.now().millisecondsSinceEpoch}',
        mealPlanId: planId,
        mealPlanName: mealPlan.name,
        items: ingredientMap.values.toList()..sort((a, b) => a.ingredient.compareTo(b.ingredient)),
        generatedDate: DateTime.now(),
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      // Save shopping list
      await _saveShoppingList(shoppingList);
      
      debugPrint('Shopping list generated successfully: ${shoppingList.items.length} items');
      return shoppingList;
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to generate shopping list: $e');
    }
  }

  @override
  Future<List<ShoppingList>> getShoppingLists() async {
    try {
      final shoppingListsData = await _storageService.getData(_shoppingListsKey);
      if (shoppingListsData == null) return [];
      
      final shoppingListsList = shoppingListsData as List<dynamic>;
      return shoppingListsList
          .map((listData) => ShoppingList.fromJson(listData))
          .toList()
        ..sort((a, b) => b.generatedDate.compareTo(a.generatedDate));
    } catch (e) {
      throw MealPlanningException('Failed to get shopping lists: $e');
    }
  }

  @override
  Future<void> updateShoppingListItem(String shoppingListId, String itemId, bool isChecked) async {
    try {
      final shoppingLists = await getShoppingLists();
      final shoppingList = shoppingLists.where((list) => list.id == shoppingListId).firstOrNull;
      
      if (shoppingList == null) {
        throw MealPlanningException(
          'Shopping list not found: $shoppingListId',
          code: 'SHOPPING_LIST_NOT_FOUND',
        );
      }

      final updatedItems = shoppingList.items.map((item) {
        if (item.ingredient == itemId) {
          return item.copyWith(isChecked: isChecked);
        }
        return item;
      }).toList();

      final updatedShoppingList = ShoppingList(
        id: shoppingList.id,
        mealPlanId: shoppingList.mealPlanId,
        mealPlanName: shoppingList.mealPlanName,
        items: updatedItems,
        generatedDate: shoppingList.generatedDate,
        startDate: shoppingList.startDate,
        endDate: shoppingList.endDate,
      );

      await _saveShoppingList(updatedShoppingList);
      debugPrint('Shopping list item updated: $itemId');
    } catch (e) {
      if (e is MealPlanningException) rethrow;
      throw MealPlanningException('Failed to update shopping list item: $e');
    }
  }

  @override
  Future<void> deleteShoppingList(String shoppingListId) async {
    try {
      final shoppingLists = await getShoppingLists();
      final updatedLists = shoppingLists.where((list) => list.id != shoppingListId).toList();
      
      await _storageService.saveData(
        _shoppingListsKey,
        updatedLists.map((list) => list.toJson()).toList(),
      );
      
      debugPrint('Shopping list deleted successfully: $shoppingListId');
    } catch (e) {
      throw MealPlanningException('Failed to delete shopping list: $e');
    }
  }

  @override
  Future<bool> hasMealPlanningAccess() async {
    try {
      return await _subscriptionService.hasFeatureAccess(FeatureType.mealPlanning);
    } catch (e) {
      debugPrint('Error checking meal planning access: $e');
      return false;
    }
  }

  @override
  Future<MealPlanningStats> getStats() async {
    try {
      final mealPlans = await getMealPlans();
      final shoppingLists = await getShoppingLists();
      
      int totalMeals = 0;
      int uniqueRecipes = 0;
      final recipeIds = <String>{};
      final mealTypeCount = <MealType, int>{};
      
      for (final plan in mealPlans) {
        totalMeals += plan.totalMeals;
        for (final meal in plan.meals) {
          recipeIds.add(meal.recipeId);
          mealTypeCount[meal.mealType] = (mealTypeCount[meal.mealType] ?? 0) + 1;
        }
      }
      
      uniqueRecipes = recipeIds.length;
      
      // Find most active meal plan
      MealPlan? mostActivePlan;
      int maxMeals = 0;
      for (final plan in mealPlans) {
        if (plan.totalMeals > maxMeals) {
          maxMeals = plan.totalMeals;
          mostActivePlan = plan;
        }
      }
      
      return MealPlanningStats(
        totalMealPlans: mealPlans.length,
        totalMeals: totalMeals,
        uniqueRecipes: uniqueRecipes,
        totalShoppingLists: shoppingLists.length,
        mealTypeDistribution: mealTypeCount,
        mostActivePlan: mostActivePlan,
        averageMealsPerPlan: mealPlans.isNotEmpty ? totalMeals / mealPlans.length : 0.0,
      );
    } catch (e) {
      throw MealPlanningException('Failed to get meal planning stats: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> getSuggestedRecipes(String date, MealType mealType, {NutritionGoals? goals}) async {
    try {
      // Get saved recipes as suggestions
      final savedRecipes = await _storageService.getSavedRecipes();
      
      // Simple filtering based on meal type and nutrition goals
      final filteredRecipes = savedRecipes.where((recipe) {
        // Basic meal type filtering based on cooking time and calories
        switch (mealType) {
          case MealType.breakfast:
            return recipe.cookingTime <= 30 && recipe.nutrition.calories <= 600;
          case MealType.lunch:
            return recipe.cookingTime <= 45 && recipe.nutrition.calories <= 800;
          case MealType.dinner:
            return recipe.cookingTime <= 90 && recipe.nutrition.calories <= 1000;
          case MealType.snack:
            return recipe.cookingTime <= 15 && recipe.nutrition.calories <= 300;
        }
      }).toList();
      
      // Shuffle and return top 10
      filteredRecipes.shuffle(Random());
      return filteredRecipes.take(10).toList();
    } catch (e) {
      debugPrint('Error getting suggested recipes: $e');
      return [];
    }
  }

  // Private helper methods

  Future<void> _saveMealPlan(MealPlan mealPlan) async {
    final mealPlans = await getMealPlans();
    final updatedPlans = mealPlans.where((plan) => plan.id != mealPlan.id).toList();
    updatedPlans.add(mealPlan);
    
    await _storageService.saveData(
      _mealPlansKey,
      updatedPlans.map((plan) => plan.toJson()).toList(),
    );
  }

  Future<void> _saveShoppingList(ShoppingList shoppingList) async {
    final shoppingLists = await getShoppingLists();
    final updatedLists = shoppingLists.where((list) => list.id != shoppingList.id).toList();
    updatedLists.add(shoppingList);
    
    await _storageService.saveData(
      _shoppingListsKey,
      updatedLists.map((list) => list.toJson()).toList(),
    );
  }

  List<DailyNutrients> _generateEmptyDailyNutrients(String startDate, String endDate) {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final dailyNutrients = <DailyNutrients>[];
    
    for (var date = start; 
         date.isBefore(end) || date.isAtSameMomentAs(end); 
         date = date.add(const Duration(days: 1))) {
      dailyNutrients.add(DailyNutrients.empty(date.toIso8601String().split('T')[0]));
    }
    
    return dailyNutrients;
  }

  Future<List<DailyNutrients>> _recalculateDailyNutrients(MealPlan mealPlan, List<PlannedMeal> meals) async {
    final nutritionGoals = await getNutritionGoals();
    final dailyNutrients = <DailyNutrients>[];
    
    for (final date in mealPlan.getAllDates()) {
      final mealsForDate = meals.where((meal) => meal.date == date).toList();
      
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbohydrates = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;
      double totalSodium = 0;

      for (final meal in mealsForDate) {
        final scaledNutrition = meal.getScaledNutrition();
        if (scaledNutrition != null) {
          totalCalories += scaledNutrition.calories;
          totalProtein += scaledNutrition.protein;
          totalCarbohydrates += scaledNutrition.carbohydrates;
          totalFat += scaledNutrition.fat;
          totalFiber += scaledNutrition.fiber;
          totalSugar += scaledNutrition.sugar;
          totalSodium += scaledNutrition.sodium;
        }
      }

      final dayNutrients = DailyNutrients(
        date: date,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbohydrates: totalCarbohydrates,
        totalFat: totalFat,
        totalFiber: totalFiber,
        totalSugar: totalSugar,
        totalSodium: totalSodium,
        nutritionGoals: nutritionGoals,
      );

      final progress = dayNutrients.calculateProgress(nutritionGoals);
      dailyNutrients.add(dayNutrients.copyWith(goalProgress: progress));
    }
    
    return dailyNutrients;
  }

  Map<String, String> _parseIngredient(String ingredient) {
    // Simple ingredient parsing - in a real app this would be more sophisticated
    final parts = ingredient.trim().split(' ');
    
    String quantity = '1';
    String unit = 'item';
    String name = ingredient;
    
    if (parts.isNotEmpty) {
      // Try to extract quantity and unit
      final firstPart = parts[0];
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(firstPart)) {
        quantity = firstPart;
        if (parts.length > 1) {
          unit = parts[1];
          name = parts.skip(2).join(' ');
        }
      } else if (RegExp(r'^\d+/\d+$').hasMatch(firstPart)) {
        quantity = firstPart;
        if (parts.length > 1) {
          unit = parts[1];
          name = parts.skip(2).join(' ');
        }
      }
    }
    
    return {
      'quantity': quantity,
      'unit': unit,
      'name': name.isEmpty ? ingredient : name,
    };
  }
}

/// Meal planning statistics
class MealPlanningStats {
  final int totalMealPlans;
  final int totalMeals;
  final int uniqueRecipes;
  final int totalShoppingLists;
  final Map<MealType, int> mealTypeDistribution;
  final MealPlan? mostActivePlan;
  final double averageMealsPerPlan;

  const MealPlanningStats({
    required this.totalMealPlans,
    required this.totalMeals,
    required this.uniqueRecipes,
    required this.totalShoppingLists,
    required this.mealTypeDistribution,
    this.mostActivePlan,
    required this.averageMealsPerPlan,
  });
}

/// Factory for creating meal planning service instances
class MealPlanningServiceFactory {
  static MealPlanningServiceInterface create({
    required StorageServiceInterface storageService,
    required SubscriptionService subscriptionService,
  }) {
    return MealPlanningService(
      storageService: storageService,
      subscriptionService: subscriptionService,
    );
  }
}