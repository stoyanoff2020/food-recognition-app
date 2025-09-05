
// Import models from services
import '../services/ai_vision_service.dart' show FoodRecognitionResult;
import '../services/ai_recipe_service.dart' show Recipe, RecipeGenerationResult, NutritionInfo, Allergen, Intolerance;

// Core app state models
class AppState {
  final CameraState camera;
  final RecognitionState recognition;
  final RecipeState recipes;
  final UserState user;
  final OnboardingState onboarding;
  final SubscriptionState subscription;

  const AppState({
    required this.camera,
    required this.recognition,
    required this.recipes,
    required this.user,
    required this.onboarding,
    required this.subscription,
  });

  AppState copyWith({
    CameraState? camera,
    RecognitionState? recognition,
    RecipeState? recipes,
    UserState? user,
    OnboardingState? onboarding,
    SubscriptionState? subscription,
  }) {
    return AppState(
      camera: camera ?? this.camera,
      recognition: recognition ?? this.recognition,
      recipes: recipes ?? this.recipes,
      user: user ?? this.user,
      onboarding: onboarding ?? this.onboarding,
      subscription: subscription ?? this.subscription,
    );
  }
}

class CameraState {
  final bool isActive;
  final bool hasPermission;
  final String? lastCapturedImage;

  const CameraState({
    this.isActive = false,
    this.hasPermission = false,
    this.lastCapturedImage,
  });

  CameraState copyWith({
    bool? isActive,
    bool? hasPermission,
    String? lastCapturedImage,
  }) {
    return CameraState(
      isActive: isActive ?? this.isActive,
      hasPermission: hasPermission ?? this.hasPermission,
      lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
    );
  }
}

class RecognitionState {
  final bool isProcessing;
  final FoodRecognitionResult? results;
  final String? error;

  const RecognitionState({
    this.isProcessing = false,
    this.results,
    this.error,
  });

  RecognitionState copyWith({
    bool? isProcessing,
    FoodRecognitionResult? results,
    String? error,
  }) {
    return RecognitionState(
      isProcessing: isProcessing ?? this.isProcessing,
      results: results,
      error: error,
    );
  }
}

class RecipeState {
  final List<Recipe> suggestions;
  final Recipe? selectedRecipe;
  final bool isLoading;
  final List<String> customIngredients;
  final RecipeGenerationResult? generationResult;
  final List<Recipe> alternativeSuggestions;
  final bool isGeneratingRecipes;
  final int? lastGenerationTime;

  const RecipeState({
    this.suggestions = const [],
    this.selectedRecipe,
    this.isLoading = false,
    this.customIngredients = const [],
    this.generationResult,
    this.alternativeSuggestions = const [],
    this.isGeneratingRecipes = false,
    this.lastGenerationTime,
  });

  RecipeState copyWith({
    List<Recipe>? suggestions,
    Recipe? selectedRecipe,
    bool? isLoading,
    List<String>? customIngredients,
    RecipeGenerationResult? generationResult,
    List<Recipe>? alternativeSuggestions,
    bool? isGeneratingRecipes,
    int? lastGenerationTime,
  }) {
    return RecipeState(
      suggestions: suggestions ?? this.suggestions,
      selectedRecipe: selectedRecipe,
      isLoading: isLoading ?? this.isLoading,
      customIngredients: customIngredients ?? this.customIngredients,
      generationResult: generationResult ?? this.generationResult,
      alternativeSuggestions: alternativeSuggestions ?? this.alternativeSuggestions,
      isGeneratingRecipes: isGeneratingRecipes ?? this.isGeneratingRecipes,
      lastGenerationTime: lastGenerationTime ?? this.lastGenerationTime,
    );
  }
}

class UserState {
  final UserPreferences preferences;
  final List<String> favoriteRecipes;
  final List<String> recentSearches;
  final List<SavedRecipe> recipeBook;
  final List<MealPlan> mealPlans;

  const UserState({
    required this.preferences,
    this.favoriteRecipes = const [],
    this.recentSearches = const [],
    this.recipeBook = const [],
    this.mealPlans = const [],
  });

  UserState copyWith({
    UserPreferences? preferences,
    List<String>? favoriteRecipes,
    List<String>? recentSearches,
    List<SavedRecipe>? recipeBook,
    List<MealPlan>? mealPlans,
  }) {
    return UserState(
      preferences: preferences ?? this.preferences,
      favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
      recentSearches: recentSearches ?? this.recentSearches,
      recipeBook: recipeBook ?? this.recipeBook,
      mealPlans: mealPlans ?? this.mealPlans,
    );
  }
}

class OnboardingState {
  final bool isFirstLaunch;
  final int currentStep;
  final bool isComplete;
  final bool hasSeenPermissionExplanation;

  const OnboardingState({
    this.isFirstLaunch = true,
    this.currentStep = 0,
    this.isComplete = false,
    this.hasSeenPermissionExplanation = false,
  });

  OnboardingState copyWith({
    bool? isFirstLaunch,
    int? currentStep,
    bool? isComplete,
    bool? hasSeenPermissionExplanation,
  }) {
    return OnboardingState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      currentStep: currentStep ?? this.currentStep,
      isComplete: isComplete ?? this.isComplete,
      hasSeenPermissionExplanation: hasSeenPermissionExplanation ?? this.hasSeenPermissionExplanation,
    );
  }
}

class SubscriptionState {
  final SubscriptionTier currentTier;
  final UsageQuota usageQuota;
  final bool isLoading;
  final DateTime lastUpdated;

  const SubscriptionState({
    required this.currentTier,
    required this.usageQuota,
    this.isLoading = false,
    required this.lastUpdated,
  });

  SubscriptionState copyWith({
    SubscriptionTier? currentTier,
    UsageQuota? usageQuota,
    bool? isLoading,
    DateTime? lastUpdated,
  }) {
    return SubscriptionState(
      currentTier: currentTier ?? this.currentTier,
      usageQuota: usageQuota ?? this.usageQuota,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}





class UserPreferences {
  final List<String> dietaryRestrictions;
  final List<String> preferredCuisines;
  final String skillLevel;

  const UserPreferences({
    this.dietaryRestrictions = const [],
    this.preferredCuisines = const [],
    this.skillLevel = 'beginner',
  });

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? preferredCuisines,
    String? skillLevel,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }
}

class SavedRecipe extends Recipe {
  final String savedDate;
  final String category;
  final List<String> tags;
  final String? personalNotes;

  const SavedRecipe({
    required super.id,
    required super.title,
    required super.ingredients,
    required super.instructions,
    required super.cookingTime,
    required super.servings,
    required super.matchPercentage,
    super.imageUrl,
    required super.nutrition,
    required super.allergens,
    required super.intolerances,
    required super.usedIngredients,
    required super.missingIngredients,
    required super.difficulty,
    required this.savedDate,
    required this.category,
    required this.tags,
    this.personalNotes,
  });
}

class MealPlan {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final MealPlanType type;
  final List<PlannedMeal> meals;
  final List<DailyNutrients> dailyNutrients;
  final DateTime createdDate;
  final DateTime? lastModified;

  const MealPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.meals,
    required this.dailyNutrients,
    required this.createdDate,
    this.lastModified,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'],
      name: json['name'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      type: MealPlanType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      meals: (json['meals'] as List<dynamic>)
          .map((meal) => PlannedMeal.fromJson(meal))
          .toList(),
      dailyNutrients: (json['dailyNutrients'] as List<dynamic>)
          .map((nutrients) => DailyNutrients.fromJson(nutrients))
          .toList(),
      createdDate: DateTime.parse(json['createdDate']),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'type': type.toString().split('.').last,
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'dailyNutrients': dailyNutrients.map((nutrients) => nutrients.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  MealPlan copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    MealPlanType? type,
    List<PlannedMeal>? meals,
    List<DailyNutrients>? dailyNutrients,
    DateTime? createdDate,
    DateTime? lastModified,
  }) {
    return MealPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      meals: meals ?? this.meals,
      dailyNutrients: dailyNutrients ?? this.dailyNutrients,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Get meals for a specific date
  List<PlannedMeal> getMealsForDate(String date) {
    return meals.where((meal) => meal.date == date).toList();
  }

  /// Get daily nutrients for a specific date
  DailyNutrients? getDailyNutrientsForDate(String date) {
    try {
      return dailyNutrients.firstWhere((nutrients) => nutrients.date == date);
    } catch (e) {
      return null;
    }
  }

  /// Get all dates in the meal plan
  List<String> getAllDates() {
    final startDateTime = DateTime.parse(startDate);
    final endDateTime = DateTime.parse(endDate);
    final dates = <String>[];
    
    for (var date = startDateTime; 
         date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime); 
         date = date.add(const Duration(days: 1))) {
      dates.add(date.toIso8601String().split('T')[0]);
    }
    
    return dates;
  }

  /// Check if the meal plan is active (current date is within range)
  bool get isActive {
    final now = DateTime.now();
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return now.isAfter(start.subtract(const Duration(days: 1))) && 
           now.isBefore(end.add(const Duration(days: 1)));
  }

  /// Get total number of planned meals
  int get totalMeals => meals.length;

  /// Get number of unique recipes used
  int get uniqueRecipes => meals.map((meal) => meal.recipeId).toSet().length;
}

class PlannedMeal {
  final String id;
  final String date;
  final MealType mealType;
  final String recipeId;
  final String recipeTitle;
  final int servings;
  final NutritionInfo? nutrition;
  final DateTime createdDate;

  const PlannedMeal({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
    required this.recipeTitle,
    required this.servings,
    this.nutrition,
    required this.createdDate,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      id: json['id'],
      date: json['date'],
      mealType: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['mealType'],
      ),
      recipeId: json['recipeId'],
      recipeTitle: json['recipeTitle'],
      servings: json['servings'],
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'])
          : null,
      createdDate: DateTime.parse(json['createdDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'mealType': mealType.toString().split('.').last,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'servings': servings,
      'nutrition': nutrition?.toJson(),
      'createdDate': createdDate.toIso8601String(),
    };
  }

  PlannedMeal copyWith({
    String? id,
    String? date,
    MealType? mealType,
    String? recipeId,
    String? recipeTitle,
    int? servings,
    NutritionInfo? nutrition,
    DateTime? createdDate,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      servings: servings ?? this.servings,
      nutrition: nutrition ?? this.nutrition,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  /// Calculate nutrition for the specified servings
  NutritionInfo? getScaledNutrition() {
    if (nutrition == null) return null;
    
    return NutritionInfo(
      calories: (nutrition!.calories * servings).round(),
      protein: nutrition!.protein * servings,
      carbohydrates: nutrition!.carbohydrates * servings,
      fat: nutrition!.fat * servings,
      fiber: nutrition!.fiber * servings,
      sugar: nutrition!.sugar * servings,
      sodium: nutrition!.sodium * servings,
      servingSize: '${servings}x ${nutrition!.servingSize}',
    );
  }
}

class DailyNutrients {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbohydrates;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double totalSodium;
  final NutritionGoals? nutritionGoals;
  final NutritionProgress? goalProgress;

  const DailyNutrients({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbohydrates,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.totalSodium,
    this.nutritionGoals,
    this.goalProgress,
  });

  factory DailyNutrients.fromJson(Map<String, dynamic> json) {
    return DailyNutrients(
      date: json['date'],
      totalCalories: json['totalCalories']?.toDouble() ?? 0.0,
      totalProtein: json['totalProtein']?.toDouble() ?? 0.0,
      totalCarbohydrates: json['totalCarbohydrates']?.toDouble() ?? 0.0,
      totalFat: json['totalFat']?.toDouble() ?? 0.0,
      totalFiber: json['totalFiber']?.toDouble() ?? 0.0,
      totalSugar: json['totalSugar']?.toDouble() ?? 0.0,
      totalSodium: json['totalSodium']?.toDouble() ?? 0.0,
      nutritionGoals: json['nutritionGoals'] != null
          ? NutritionGoals.fromJson(json['nutritionGoals'])
          : null,
      goalProgress: json['goalProgress'] != null
          ? NutritionProgress.fromJson(json['goalProgress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbohydrates': totalCarbohydrates,
      'totalFat': totalFat,
      'totalFiber': totalFiber,
      'totalSugar': totalSugar,
      'totalSodium': totalSodium,
      'nutritionGoals': nutritionGoals?.toJson(),
      'goalProgress': goalProgress?.toJson(),
    };
  }

  DailyNutrients copyWith({
    String? date,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbohydrates,
    double? totalFat,
    double? totalFiber,
    double? totalSugar,
    double? totalSodium,
    NutritionGoals? nutritionGoals,
    NutritionProgress? goalProgress,
  }) {
    return DailyNutrients(
      date: date ?? this.date,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbohydrates: totalCarbohydrates ?? this.totalCarbohydrates,
      totalFat: totalFat ?? this.totalFat,
      totalFiber: totalFiber ?? this.totalFiber,
      totalSugar: totalSugar ?? this.totalSugar,
      totalSodium: totalSodium ?? this.totalSodium,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      goalProgress: goalProgress ?? this.goalProgress,
    );
  }

  /// Create empty daily nutrients for a date
  factory DailyNutrients.empty(String date) {
    return DailyNutrients(
      date: date,
      totalCalories: 0,
      totalProtein: 0,
      totalCarbohydrates: 0,
      totalFat: 0,
      totalFiber: 0,
      totalSugar: 0,
      totalSodium: 0,
    );
  }

  /// Calculate progress against nutrition goals
  NutritionProgress calculateProgress(NutritionGoals goals) {
    return NutritionProgress(
      caloriesProgress: goals.dailyCalories > 0 ? (totalCalories / goals.dailyCalories * 100).clamp(0, 200) : 0,
      proteinProgress: goals.dailyProtein > 0 ? (totalProtein / goals.dailyProtein * 100).clamp(0, 200) : 0,
      carbsProgress: goals.dailyCarbohydrates > 0 ? (totalCarbohydrates / goals.dailyCarbohydrates * 100).clamp(0, 200) : 0,
      fatProgress: goals.dailyFat > 0 ? (totalFat / goals.dailyFat * 100).clamp(0, 200) : 0,
      fiberProgress: goals.dailyFiber > 0 ? (totalFiber / goals.dailyFiber * 100).clamp(0, 200) : 0,
      sodiumProgress: goals.dailySodium > 0 ? (totalSodium / goals.dailySodium * 100).clamp(0, 200) : 0,
    );
  }
}

class NutritionGoals {
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbohydrates;
  final double dailyFat;
  final double dailyFiber;
  final double dailySodium;

  const NutritionGoals({
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbohydrates,
    required this.dailyFat,
    required this.dailyFiber,
    required this.dailySodium,
  });

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      dailyCalories: json['dailyCalories']?.toDouble() ?? 0.0,
      dailyProtein: json['dailyProtein']?.toDouble() ?? 0.0,
      dailyCarbohydrates: json['dailyCarbohydrates']?.toDouble() ?? 0.0,
      dailyFat: json['dailyFat']?.toDouble() ?? 0.0,
      dailyFiber: json['dailyFiber']?.toDouble() ?? 0.0,
      dailySodium: json['dailySodium']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyCalories': dailyCalories,
      'dailyProtein': dailyProtein,
      'dailyCarbohydrates': dailyCarbohydrates,
      'dailyFat': dailyFat,
      'dailyFiber': dailyFiber,
      'dailySodium': dailySodium,
    };
  }

  NutritionGoals copyWith({
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbohydrates,
    double? dailyFat,
    double? dailyFiber,
    double? dailySodium,
  }) {
    return NutritionGoals(
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbohydrates: dailyCarbohydrates ?? this.dailyCarbohydrates,
      dailyFat: dailyFat ?? this.dailyFat,
      dailyFiber: dailyFiber ?? this.dailyFiber,
      dailySodium: dailySodium ?? this.dailySodium,
    );
  }

  /// Default nutrition goals for an average adult
  static const NutritionGoals defaultGoals = NutritionGoals(
    dailyCalories: 2000,
    dailyProtein: 50,
    dailyCarbohydrates: 300,
    dailyFat: 65,
    dailyFiber: 25,
    dailySodium: 2300,
  );
}

class NutritionProgress {
  final double caloriesProgress;
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final double fiberProgress;
  final double sodiumProgress;

  const NutritionProgress({
    required this.caloriesProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.fiberProgress,
    required this.sodiumProgress,
  });

  factory NutritionProgress.fromJson(Map<String, dynamic> json) {
    return NutritionProgress(
      caloriesProgress: json['caloriesProgress']?.toDouble() ?? 0.0,
      proteinProgress: json['proteinProgress']?.toDouble() ?? 0.0,
      carbsProgress: json['carbsProgress']?.toDouble() ?? 0.0,
      fatProgress: json['fatProgress']?.toDouble() ?? 0.0,
      fiberProgress: json['fiberProgress']?.toDouble() ?? 0.0,
      sodiumProgress: json['sodiumProgress']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caloriesProgress': caloriesProgress,
      'proteinProgress': proteinProgress,
      'carbsProgress': carbsProgress,
      'fatProgress': fatProgress,
      'fiberProgress': fiberProgress,
      'sodiumProgress': sodiumProgress,
    };
  }

  /// Check if all goals are met (within 90-110% range)
  bool get allGoalsMet {
    return caloriesProgress >= 90 && caloriesProgress <= 110 &&
           proteinProgress >= 90 && proteinProgress <= 110 &&
           carbsProgress >= 90 && carbsProgress <= 110 &&
           fatProgress >= 90 && fatProgress <= 110 &&
           fiberProgress >= 90 &&
           sodiumProgress <= 110;
  }

  /// Get overall progress score (0-100)
  double get overallScore {
    final scores = [
      _scoreProgress(caloriesProgress),
      _scoreProgress(proteinProgress),
      _scoreProgress(carbsProgress),
      _scoreProgress(fatProgress),
      _scoreProgress(fiberProgress),
      _scoreProgress(sodiumProgress, isLowerBetter: true),
    ];
    
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double _scoreProgress(double progress, {bool isLowerBetter = false}) {
    if (isLowerBetter) {
      // For sodium, lower is better
      if (progress <= 100) return 100;
      if (progress <= 110) return 90;
      if (progress <= 120) return 70;
      return 50;
    } else {
      // For other nutrients, closer to 100% is better
      if (progress >= 90 && progress <= 110) return 100;
      if (progress >= 80 && progress <= 120) return 90;
      if (progress >= 70 && progress <= 130) return 70;
      return 50;
    }
  }
}

class SubscriptionTier {
  final String type;
  final List<String> features;
  final UsageQuota quotas;
  final double price;
  final String billingPeriod;

  const SubscriptionTier({
    required this.type,
    required this.features,
    required this.quotas,
    required this.price,
    required this.billingPeriod,
  });
}

class UsageQuota {
  final int dailyScans;
  final int usedScans;
  final DateTime resetTime;
  final int adWatchesAvailable;
  final int historyDays;

  const UsageQuota({
    required this.dailyScans,
    required this.usedScans,
    required this.resetTime,
    required this.adWatchesAvailable,
    required this.historyDays,
  });

  UsageQuota copyWith({
    int? dailyScans,
    int? usedScans,
    DateTime? resetTime,
    int? adWatchesAvailable,
    int? historyDays,
  }) {
    return UsageQuota(
      dailyScans: dailyScans ?? this.dailyScans,
      usedScans: usedScans ?? this.usedScans,
      resetTime: resetTime ?? this.resetTime,
      adWatchesAvailable: adWatchesAvailable ?? this.adWatchesAvailable,
      historyDays: historyDays ?? this.historyDays,
    );
  }
}

// Meal planning enums
enum MealPlanType {
  weekly,
  monthly,
  custom,
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

// Shopping list models
class ShoppingListItem {
  final String ingredient;
  final String quantity;
  final String unit;
  final List<String> usedInRecipes;
  final bool isChecked;

  const ShoppingListItem({
    required this.ingredient,
    required this.quantity,
    required this.unit,
    required this.usedInRecipes,
    this.isChecked = false,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      ingredient: json['ingredient'],
      quantity: json['quantity'],
      unit: json['unit'],
      usedInRecipes: List<String>.from(json['usedInRecipes']),
      isChecked: json['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient,
      'quantity': quantity,
      'unit': unit,
      'usedInRecipes': usedInRecipes,
      'isChecked': isChecked,
    };
  }

  ShoppingListItem copyWith({
    String? ingredient,
    String? quantity,
    String? unit,
    List<String>? usedInRecipes,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      ingredient: ingredient ?? this.ingredient,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      usedInRecipes: usedInRecipes ?? this.usedInRecipes,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class ShoppingList {
  final String id;
  final String mealPlanId;
  final String mealPlanName;
  final List<ShoppingListItem> items;
  final DateTime generatedDate;
  final String startDate;
  final String endDate;

  const ShoppingList({
    required this.id,
    required this.mealPlanId,
    required this.mealPlanName,
    required this.items,
    required this.generatedDate,
    required this.startDate,
    required this.endDate,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      mealPlanId: json['mealPlanId'],
      mealPlanName: json['mealPlanName'],
      items: (json['items'] as List<dynamic>)
          .map((item) => ShoppingListItem.fromJson(item))
          .toList(),
      generatedDate: DateTime.parse(json['generatedDate']),
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealPlanId': mealPlanId,
      'mealPlanName': mealPlanName,
      'items': items.map((item) => item.toJson()).toList(),
      'generatedDate': generatedDate.toIso8601String(),
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Get unchecked items
  List<ShoppingListItem> get uncheckedItems {
    return items.where((item) => !item.isChecked).toList();
  }

  /// Get checked items
  List<ShoppingListItem> get checkedItems {
    return items.where((item) => item.isChecked).toList();
  }

  /// Get completion percentage
  double get completionPercentage {
    if (items.isEmpty) return 0;
    return (checkedItems.length / items.length) * 100;
  }

  /// Check if shopping list is complete
  bool get isComplete => completionPercentage == 100;
}