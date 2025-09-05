import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/app_state.dart';
import '../services/ai_recipe_service.dart';
import '../utils/error_handler.dart';

// Storage service interface
abstract class StorageServiceInterface {
  Future<bool> initialize();
  Future<void> dispose();
  
  // User preferences
  Future<void> saveUserPreferences(UserPreferences preferences);
  Future<UserPreferences?> getUserPreferences();
  
  // Onboarding data
  Future<void> saveOnboardingData(OnboardingData data);
  Future<OnboardingData?> getOnboardingData();
  
  // Subscription data
  Future<void> saveSubscriptionData(SubscriptionData data);
  Future<SubscriptionData?> getSubscriptionData();
  
  // Recipe book (saved recipes)
  Future<void> saveRecipe(SavedRecipe recipe);
  Future<void> deleteRecipe(String recipeId);
  Future<List<SavedRecipe>> getSavedRecipes();
  Future<SavedRecipe?> getRecipeById(String recipeId);
  Future<List<SavedRecipe>> searchRecipes(String query);
  Future<List<SavedRecipe>> getRecipesByCategory(String category);
  
  // Meal plans
  Future<void> saveMealPlan(MealPlan mealPlan);
  Future<void> deleteMealPlan(String mealPlanId);
  Future<List<MealPlan>> getMealPlans();
  Future<MealPlan?> getMealPlanById(String mealPlanId);
  
  // Recent searches and favorites
  Future<void> addRecentSearch(String search);
  Future<List<String>> getRecentSearches();
  Future<void> clearRecentSearches();
  
  // App settings
  Future<void> saveAppSettings(Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getAppSettings();
  
  // Individual user preferences
  Future<void> saveUserPreference(String key, dynamic value);
  Future<Map<String, dynamic>> getUserPreferencesMap();
  
  // Clear all data
  Future<void> clearAllData();
  
  // Generic data storage methods
  Future<void> saveData(String key, dynamic data);
  Future<dynamic> getData(String key);
}

// Storage service implementation
class StorageService implements StorageServiceInterface {
  Database? _database;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  static const String _dbName = 'food_recognition.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _recipesTable = 'saved_recipes';
  static const String _mealPlansTable = 'meal_plans';
  static const String _plannedMealsTable = 'planned_meals';
  static const String _dailyNutrientsTable = 'daily_nutrients';

  // SharedPreferences keys
  static const String _userPreferencesKey = 'user_preferences';
  static const String _onboardingDataKey = 'onboarding_data';
  static const String _subscriptionDataKey = 'subscription_data';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _appSettingsKey = 'app_settings';

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize SQLite database
      final dbPath = await getDatabasesPath();
      final fullPath = path.join(dbPath, _dbName);

      _database = await openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      _isInitialized = true;
      debugPrint('Storage service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing storage service: $e');
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _database?.close();
      _database = null;
      _prefs = null;
      _isInitialized = false;
      debugPrint('Storage service disposed');
    } catch (e) {
      debugPrint('Error disposing storage service: $e');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create saved recipes table
    await db.execute('''
      CREATE TABLE $_recipesTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        cooking_time INTEGER NOT NULL,
        servings INTEGER NOT NULL,
        match_percentage REAL NOT NULL,
        image_url TEXT,
        nutrition TEXT NOT NULL,
        allergens TEXT NOT NULL,
        intolerances TEXT NOT NULL,
        used_ingredients TEXT NOT NULL,
        missing_ingredients TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        saved_date TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT NOT NULL,
        personal_notes TEXT
      )
    ''');

    // Create meal plans table
    await db.execute('''
      CREATE TABLE $_mealPlansTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Create planned meals table
    await db.execute('''
      CREATE TABLE $_plannedMealsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_plan_id TEXT NOT NULL,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        servings INTEGER NOT NULL,
        FOREIGN KEY (meal_plan_id) REFERENCES $_mealPlansTable (id) ON DELETE CASCADE
      )
    ''');

    // Create daily nutrients table
    await db.execute('''
      CREATE TABLE $_dailyNutrientsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_plan_id TEXT NOT NULL,
        date TEXT NOT NULL,
        total_calories INTEGER NOT NULL,
        total_protein REAL NOT NULL,
        total_carbohydrates REAL NOT NULL,
        total_fat REAL NOT NULL,
        total_fiber REAL NOT NULL,
        total_sugar REAL NOT NULL,
        total_sodium REAL NOT NULL,
        nutrition_goals TEXT,
        goal_progress TEXT,
        FOREIGN KEY (meal_plan_id) REFERENCES $_mealPlansTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_recipes_category ON $_recipesTable (category)');
    await db.execute('CREATE INDEX idx_recipes_saved_date ON $_recipesTable (saved_date)');
    await db.execute('CREATE INDEX idx_planned_meals_plan_id ON $_plannedMealsTable (meal_plan_id)');
    await db.execute('CREATE INDEX idx_planned_meals_date ON $_plannedMealsTable (date)');
    await db.execute('CREATE INDEX idx_daily_nutrients_plan_id ON $_dailyNutrientsTable (meal_plan_id)');
    await db.execute('CREATE INDEX idx_daily_nutrients_date ON $_dailyNutrientsTable (date)');

    debugPrint('Database tables created successfully');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    debugPrint('Database upgraded from version $oldVersion to $newVersion');
  }

  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = jsonEncode({
        'dietaryRestrictions': preferences.dietaryRestrictions,
        'preferredCuisines': preferences.preferredCuisines,
        'skillLevel': preferences.skillLevel,
      });
      
      await _prefs!.setString(_userPreferencesKey, json);
      debugPrint('User preferences saved');
    } catch (e) {
      throw StorageException('Failed to save user preferences: $e');
    }
  }

  @override
  Future<UserPreferences?> getUserPreferences() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = _prefs!.getString(_userPreferencesKey);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserPreferences(
        dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
        preferredCuisines: List<String>.from(data['preferredCuisines'] ?? []),
        skillLevel: data['skillLevel'] ?? 'beginner',
      );
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      return null;
    }
  }

  @override
  Future<void> saveOnboardingData(OnboardingData data) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = jsonEncode({
        'isComplete': data.isComplete,
        'completedSteps': data.completedSteps,
        'lastShownStep': data.lastShownStep,
        'hasSeenPermissionExplanation': data.hasSeenPermissionExplanation,
        'completionDate': data.completionDate,
      });
      
      await _prefs!.setString(_onboardingDataKey, json);
      debugPrint('Onboarding data saved');
    } catch (e) {
      throw StorageException('Failed to save onboarding data: $e');
    }
  }

  @override
  Future<OnboardingData?> getOnboardingData() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = _prefs!.getString(_onboardingDataKey);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return OnboardingData(
        isComplete: data['isComplete'] ?? false,
        completedSteps: List<int>.from(data['completedSteps'] ?? []),
        lastShownStep: data['lastShownStep'] ?? 0,
        hasSeenPermissionExplanation: data['hasSeenPermissionExplanation'] ?? false,
        completionDate: data['completionDate'],
      );
    } catch (e) {
      debugPrint('Error loading onboarding data: $e');
      return null;
    }
  }

  @override
  Future<void> saveSubscriptionData(SubscriptionData data) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = jsonEncode({
        'currentTier': data.currentTier,
        'subscriptionId': data.subscriptionId,
        'purchaseDate': data.purchaseDate,
        'expiryDate': data.expiryDate,
        'usageHistory': data.usageHistory.map((record) => {
          'date': record.date,
          'scansUsed': record.scansUsed,
          'adsWatched': record.adsWatched,
          'actionType': record.actionType,
        }).toList(),
        'lastQuotaReset': data.lastQuotaReset,
      });
      
      await _prefs!.setString(_subscriptionDataKey, json);
      debugPrint('Subscription data saved');
    } catch (e) {
      throw StorageException('Failed to save subscription data: $e');
    }
  }

  @override
  Future<SubscriptionData?> getSubscriptionData() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = _prefs!.getString(_subscriptionDataKey);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return SubscriptionData(
        currentTier: data['currentTier'] ?? 'free',
        subscriptionId: data['subscriptionId'],
        purchaseDate: data['purchaseDate'],
        expiryDate: data['expiryDate'],
        usageHistory: (data['usageHistory'] as List<dynamic>?)?.map((record) => 
          UsageRecord(
            date: record['date'],
            scansUsed: record['scansUsed'],
            adsWatched: record['adsWatched'],
            actionType: record['actionType'],
          )
        ).toList() ?? [],
        lastQuotaReset: data['lastQuotaReset'] ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
      return null;
    }
  }

  @override
  Future<void> saveRecipe(SavedRecipe recipe) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      await _database!.insert(
        _recipesTable,
        {
          'id': recipe.id,
          'title': recipe.title,
          'ingredients': jsonEncode(recipe.ingredients),
          'instructions': jsonEncode(recipe.instructions),
          'cooking_time': recipe.cookingTime,
          'servings': recipe.servings,
          'match_percentage': recipe.matchPercentage,
          'image_url': recipe.imageUrl,
          'nutrition': jsonEncode(_nutritionToMap(recipe.nutrition)),
          'allergens': jsonEncode(recipe.allergens.map(_allergenToMap).toList()),
          'intolerances': jsonEncode(recipe.intolerances.map(_intoleranceToMap).toList()),
          'used_ingredients': jsonEncode(recipe.usedIngredients),
          'missing_ingredients': jsonEncode(recipe.missingIngredients),
          'difficulty': recipe.difficulty,
          'saved_date': recipe.savedDate,
          'category': recipe.category,
          'tags': jsonEncode(recipe.tags),
          'personal_notes': recipe.personalNotes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Recipe saved: ${recipe.title}');
    } catch (e) {
      throw StorageException('Failed to save recipe: $e');
    }
  }

  @override
  Future<void> deleteRecipe(String recipeId) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      await _database!.delete(
        _recipesTable,
        where: 'id = ?',
        whereArgs: [recipeId],
      );
      debugPrint('Recipe deleted: $recipeId');
    } catch (e) {
      throw StorageException('Failed to delete recipe: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> getSavedRecipes() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _recipesTable,
        orderBy: 'saved_date DESC',
      );

      return maps.map(_mapToSavedRecipe).toList();
    } catch (e) {
      throw StorageException('Failed to get saved recipes: $e');
    }
  }

  @override
  Future<SavedRecipe?> getRecipeById(String recipeId) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _recipesTable,
        where: 'id = ?',
        whereArgs: [recipeId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToSavedRecipe(maps.first);
    } catch (e) {
      throw StorageException('Failed to get recipe by ID: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> searchRecipes(String query) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _recipesTable,
        where: 'title LIKE ? OR ingredients LIKE ? OR tags LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'saved_date DESC',
      );

      return maps.map(_mapToSavedRecipe).toList();
    } catch (e) {
      throw StorageException('Failed to search recipes: $e');
    }
  }

  @override
  Future<List<SavedRecipe>> getRecipesByCategory(String category) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _recipesTable,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'saved_date DESC',
      );

      return maps.map(_mapToSavedRecipe).toList();
    } catch (e) {
      throw StorageException('Failed to get recipes by category: $e');
    }
  }

  @override
  Future<void> saveMealPlan(MealPlan mealPlan) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      await _database!.transaction((txn) async {
        // Save meal plan
        await txn.insert(
          _mealPlansTable,
          {
            'id': mealPlan.id,
            'name': mealPlan.name,
            'start_date': mealPlan.startDate,
            'end_date': mealPlan.endDate,
            'type': mealPlan.type.toString().split('.').last,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Delete existing planned meals and daily nutrients
        await txn.delete(_plannedMealsTable, where: 'meal_plan_id = ?', whereArgs: [mealPlan.id]);
        await txn.delete(_dailyNutrientsTable, where: 'meal_plan_id = ?', whereArgs: [mealPlan.id]);

        // Save planned meals
        for (final meal in mealPlan.meals) {
          await txn.insert(_plannedMealsTable, {
            'meal_plan_id': mealPlan.id,
            'date': meal.date,
            'meal_type': meal.mealType.toString().split('.').last,
            'recipe_id': meal.recipeId,
            'servings': meal.servings,
          });
        }

        // Save daily nutrients
        for (final nutrients in mealPlan.dailyNutrients) {
          await txn.insert(_dailyNutrientsTable, {
            'meal_plan_id': mealPlan.id,
            'date': nutrients.date,
            'total_calories': nutrients.totalCalories.round(),
            'total_protein': nutrients.totalProtein,
            'total_carbohydrates': nutrients.totalCarbohydrates,
            'total_fat': nutrients.totalFat,
            'total_fiber': nutrients.totalFiber,
            'total_sugar': nutrients.totalSugar,
            'total_sodium': nutrients.totalSodium,
            'nutrition_goals': nutrients.nutritionGoals != null 
                ? jsonEncode(_nutritionGoalsToMap(nutrients.nutritionGoals!)) 
                : null,
            'goal_progress': nutrients.goalProgress != null 
                ? jsonEncode(_nutritionProgressToMap(nutrients.goalProgress!)) 
                : null,
          });
        }
      });
      debugPrint('Meal plan saved: ${mealPlan.name}');
    } catch (e) {
      throw StorageException('Failed to save meal plan: $e');
    }
  }

  @override
  Future<void> deleteMealPlan(String mealPlanId) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      await _database!.delete(
        _mealPlansTable,
        where: 'id = ?',
        whereArgs: [mealPlanId],
      );
      debugPrint('Meal plan deleted: $mealPlanId');
    } catch (e) {
      throw StorageException('Failed to delete meal plan: $e');
    }
  }

  @override
  Future<List<MealPlan>> getMealPlans() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final List<Map<String, dynamic>> mealPlanMaps = await _database!.query(
        _mealPlansTable,
        orderBy: 'start_date DESC',
      );

      final List<MealPlan> mealPlans = [];
      
      for (final mealPlanMap in mealPlanMaps) {
        final mealPlanId = mealPlanMap['id'] as String;
        
        // Get planned meals
        final plannedMealMaps = await _database!.query(
          _plannedMealsTable,
          where: 'meal_plan_id = ?',
          whereArgs: [mealPlanId],
          orderBy: 'date ASC',
        );
        
        // Get daily nutrients
        final dailyNutrientMaps = await _database!.query(
          _dailyNutrientsTable,
          where: 'meal_plan_id = ?',
          whereArgs: [mealPlanId],
          orderBy: 'date ASC',
        );
        
        mealPlans.add(_mapToMealPlan(mealPlanMap, plannedMealMaps, dailyNutrientMaps));
      }

      return mealPlans;
    } catch (e) {
      throw StorageException('Failed to get meal plans: $e');
    }
  }

  @override
  Future<MealPlan?> getMealPlanById(String mealPlanId) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final List<Map<String, dynamic>> mealPlanMaps = await _database!.query(
        _mealPlansTable,
        where: 'id = ?',
        whereArgs: [mealPlanId],
        limit: 1,
      );

      if (mealPlanMaps.isEmpty) return null;

      // Get planned meals
      final plannedMealMaps = await _database!.query(
        _plannedMealsTable,
        where: 'meal_plan_id = ?',
        whereArgs: [mealPlanId],
        orderBy: 'date ASC',
      );
      
      // Get daily nutrients
      final dailyNutrientMaps = await _database!.query(
        _dailyNutrientsTable,
        where: 'meal_plan_id = ?',
        whereArgs: [mealPlanId],
        orderBy: 'date ASC',
      );

      return _mapToMealPlan(mealPlanMaps.first, plannedMealMaps, dailyNutrientMaps);
    } catch (e) {
      throw StorageException('Failed to get meal plan by ID: $e');
    }
  }

  @override
  Future<void> addRecentSearch(String search) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final searches = await getRecentSearches();
      searches.remove(search); // Remove if exists to avoid duplicates
      searches.insert(0, search); // Add to beginning
      
      // Keep only last 10 searches
      if (searches.length > 10) {
        searches.removeRange(10, searches.length);
      }
      
      await _prefs!.setStringList(_recentSearchesKey, searches);
      debugPrint('Recent search added: $search');
    } catch (e) {
      throw StorageException('Failed to add recent search: $e');
    }
  }

  @override
  Future<List<String>> getRecentSearches() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      return _prefs!.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
      return [];
    }
  }

  @override
  Future<void> clearRecentSearches() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      await _prefs!.remove(_recentSearchesKey);
      debugPrint('Recent searches cleared');
    } catch (e) {
      throw StorageException('Failed to clear recent searches: $e');
    }
  }

  @override
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = jsonEncode(settings);
      await _prefs!.setString(_appSettingsKey, json);
      debugPrint('App settings saved');
    } catch (e) {
      throw StorageException('Failed to save app settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAppSettings() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = _prefs!.getString(_appSettingsKey);
      if (json == null) return {};

      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      debugPrint('Error loading app settings: $e');
      return {};
    }
  }

  @override
  Future<void> saveUserPreference(String key, dynamic value) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final preferences = await getUserPreferencesMap();
      preferences[key] = value;
      
      final json = jsonEncode(preferences);
      await _prefs!.setString('user_preferences_individual', json);
      debugPrint('User preference saved: $key');
    } catch (e) {
      throw StorageException('Failed to save user preference: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserPreferencesMap() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = _prefs!.getString('user_preferences_individual');
      if (json == null) return {};

      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      return {};
    }
  }

  @override
  Future<void> clearAllData() async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      // Clear SharedPreferences
      await _prefs!.clear();
      
      // Clear database
      await _database!.delete(_recipesTable);
      await _database!.delete(_mealPlansTable);
      await _database!.delete(_plannedMealsTable);
      await _database!.delete(_dailyNutrientsTable);
      
      debugPrint('All data cleared');
    } catch (e) {
      throw StorageException('Failed to clear all data: $e');
    }
  }

  @override
  Future<void> saveData(String key, dynamic data) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = jsonEncode(data);
      await _prefs!.setString(key, json);
      debugPrint('Data saved for key: $key');
    } catch (e) {
      throw StorageException('Failed to save data for key $key: $e');
    }
  }

  @override
  Future<dynamic> getData(String key) async {
    if (!_isInitialized) throw StorageException('Storage not initialized');

    try {
      final json = _prefs!.getString(key);
      if (json == null) return null;

      return jsonDecode(json);
    } catch (e) {
      debugPrint('Error loading data for key $key: $e');
      return null;
    }
  }

  // Helper methods for data conversion
  SavedRecipe _mapToSavedRecipe(Map<String, dynamic> map) {
    return SavedRecipe(
      id: map['id'],
      title: map['title'],
      ingredients: List<String>.from(jsonDecode(map['ingredients'])),
      instructions: List<String>.from(jsonDecode(map['instructions'])),
      cookingTime: map['cooking_time'],
      servings: map['servings'],
      matchPercentage: map['match_percentage'],
      imageUrl: map['image_url'],
      nutrition: _mapToNutrition(jsonDecode(map['nutrition'])),
      allergens: (jsonDecode(map['allergens']) as List)
          .map((a) => _mapToAllergen(a))
          .toList(),
      intolerances: (jsonDecode(map['intolerances']) as List)
          .map((i) => _mapToIntolerance(i))
          .toList(),
      usedIngredients: List<String>.from(jsonDecode(map['used_ingredients'])),
      missingIngredients: List<String>.from(jsonDecode(map['missing_ingredients'])),
      difficulty: map['difficulty'],
      savedDate: map['saved_date'],
      category: map['category'],
      tags: List<String>.from(jsonDecode(map['tags'])),
      personalNotes: map['personal_notes'],
    );
  }

  MealPlan _mapToMealPlan(
    Map<String, dynamic> mealPlanMap,
    List<Map<String, dynamic>> plannedMealMaps,
    List<Map<String, dynamic>> dailyNutrientMaps,
  ) {
    return MealPlan(
      id: mealPlanMap['id'],
      name: mealPlanMap['name'],
      startDate: mealPlanMap['start_date'],
      endDate: mealPlanMap['end_date'],
      type: MealPlanType.values.firstWhere(
        (e) => e.toString().split('.').last == mealPlanMap['type'],
      ),
      meals: plannedMealMaps.map((map) => PlannedMeal(
        id: map['id'].toString(),
        date: map['date'],
        mealType: MealType.values.firstWhere(
          (e) => e.toString().split('.').last == map['meal_type'],
        ),
        recipeId: map['recipe_id'],
        recipeTitle: '', // Will be populated from recipe data
        servings: map['servings'],
        createdDate: DateTime.now(), // Default value
      )).toList(),
      dailyNutrients: dailyNutrientMaps.map((map) => DailyNutrients(
        date: map['date'],
        totalCalories: (map['total_calories'] as num).toDouble(),
        totalProtein: (map['total_protein'] as num).toDouble(),
        totalCarbohydrates: (map['total_carbohydrates'] as num).toDouble(),
        totalFat: (map['total_fat'] as num).toDouble(),
        totalFiber: (map['total_fiber'] as num).toDouble(),
        totalSugar: (map['total_sugar'] as num).toDouble(),
        totalSodium: (map['total_sodium'] as num).toDouble(),
        nutritionGoals: map['nutrition_goals'] != null 
            ? _mapToNutritionGoals(jsonDecode(map['nutrition_goals'])) 
            : null,
        goalProgress: map['goal_progress'] != null 
            ? _mapToNutritionProgress(jsonDecode(map['goal_progress'])) 
            : null,
      )).toList(),
      createdDate: DateTime.now(), // Default value
    );
  }

  Map<String, dynamic> _nutritionToMap(NutritionInfo nutrition) {
    return {
      'calories': nutrition.calories,
      'protein': nutrition.protein,
      'carbohydrates': nutrition.carbohydrates,
      'fat': nutrition.fat,
      'fiber': nutrition.fiber,
      'sugar': nutrition.sugar,
      'sodium': nutrition.sodium,
      'servingSize': nutrition.servingSize,
    };
  }

  NutritionInfo _mapToNutrition(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: map['calories'],
      protein: map['protein'],
      carbohydrates: map['carbohydrates'],
      fat: map['fat'],
      fiber: map['fiber'],
      sugar: map['sugar'],
      sodium: map['sodium'],
      servingSize: map['servingSize'],
    );
  }

  Map<String, dynamic> _allergenToMap(Allergen allergen) {
    return {
      'name': allergen.name,
      'severity': allergen.severity,
      'description': allergen.description,
    };
  }

  Allergen _mapToAllergen(Map<String, dynamic> map) {
    return Allergen(
      name: map['name'],
      severity: map['severity'],
      description: map['description'],
    );
  }

  Map<String, dynamic> _intoleranceToMap(Intolerance intolerance) {
    return {
      'name': intolerance.name,
      'type': intolerance.type,
      'description': intolerance.description,
    };
  }

  Intolerance _mapToIntolerance(Map<String, dynamic> map) {
    return Intolerance(
      name: map['name'],
      type: map['type'],
      description: map['description'],
    );
  }

  Map<String, dynamic> _nutritionGoalsToMap(NutritionGoals goals) {
    return {
      'dailyCalories': goals.dailyCalories,
      'dailyProtein': goals.dailyProtein,
      'dailyCarbohydrates': goals.dailyCarbohydrates,
      'dailyFat': goals.dailyFat,
      'dailyFiber': goals.dailyFiber,
      'dailySodium': goals.dailySodium,
    };
  }

  NutritionGoals _mapToNutritionGoals(Map<String, dynamic> map) {
    return NutritionGoals(
      dailyCalories: map['dailyCalories'],
      dailyProtein: map['dailyProtein'],
      dailyCarbohydrates: map['dailyCarbohydrates'],
      dailyFat: map['dailyFat'],
      dailyFiber: map['dailyFiber'],
      dailySodium: map['dailySodium'],
    );
  }

  Map<String, dynamic> _nutritionProgressToMap(NutritionProgress progress) {
    return {
      'caloriesProgress': progress.caloriesProgress,
      'proteinProgress': progress.proteinProgress,
      'carbsProgress': progress.carbsProgress,
      'fatProgress': progress.fatProgress,
      'fiberProgress': progress.fiberProgress,
      'sodiumProgress': progress.sodiumProgress,
    };
  }

  NutritionProgress _mapToNutritionProgress(Map<String, dynamic> map) {
    return NutritionProgress(
      caloriesProgress: map['caloriesProgress'],
      proteinProgress: map['proteinProgress'],
      carbsProgress: map['carbsProgress'],
      fatProgress: map['fatProgress'],
      fiberProgress: map['fiberProgress'],
      sodiumProgress: map['sodiumProgress'],
    );
  }
}

// Storage service exception
class StorageException implements Exception {
  final String message;
  final String? code;
  
  const StorageException(this.message, {this.code});
  
  @override
  String toString() => 'StorageException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Storage service factory
class StorageServiceFactory {
  static StorageServiceInterface create() {
    return StorageService();
  }
}

// Additional data models for storage
class OnboardingData {
  final bool isComplete;
  final List<int> completedSteps;
  final int lastShownStep;
  final bool hasSeenPermissionExplanation;
  final String? completionDate;

  const OnboardingData({
    required this.isComplete,
    required this.completedSteps,
    required this.lastShownStep,
    required this.hasSeenPermissionExplanation,
    this.completionDate,
  });
}

class SubscriptionData {
  final String currentTier;
  final String? subscriptionId;
  final String? purchaseDate;
  final String? expiryDate;
  final List<UsageRecord> usageHistory;
  final String lastQuotaReset;

  const SubscriptionData({
    required this.currentTier,
    this.subscriptionId,
    this.purchaseDate,
    this.expiryDate,
    required this.usageHistory,
    required this.lastQuotaReset,
  });
}

class UsageRecord {
  final String date;
  final int scansUsed;
  final int adsWatched;
  final String actionType;

  const UsageRecord({
    required this.date,
    required this.scansUsed,
    required this.adsWatched,
    required this.actionType,
  });
}