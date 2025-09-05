import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/ai_vision_service.dart';
import '../services/ai_recipe_service.dart';

class AppStateProvider extends ChangeNotifier {
  static SubscriptionState _createInitialSubscriptionState() {
    final now = DateTime.now();
    final resetTime = now.add(const Duration(days: 1));
    
    return SubscriptionState(
      currentTier: SubscriptionTier(
        type: 'free',
        features: const ['basic_recognition'],
        quotas: UsageQuota(
          dailyScans: 1,
          usedScans: 0,
          resetTime: resetTime,
          adWatchesAvailable: 3,
          historyDays: 7,
        ),
        price: 0.0,
        billingPeriod: 'monthly',
      ),
      usageQuota: UsageQuota(
        dailyScans: 1,
        usedScans: 0,
        resetTime: resetTime,
        adWatchesAvailable: 3,
        historyDays: 7,
      ),
      lastUpdated: now,
    );
  }

  AppState _state = AppState(
    camera: const CameraState(),
    recognition: const RecognitionState(),
    recipes: const RecipeState(),
    user: UserState(
      preferences: const UserPreferences(),
    ),
    onboarding: const OnboardingState(),
    subscription: _createInitialSubscriptionState(),
  );

  AppState get state => _state;

  // Camera state updates
  void updateCameraState(CameraState newCameraState) {
    _state = _state.copyWith(camera: newCameraState);
    notifyListeners();
  }

  void setCameraActive(bool isActive) {
    final newCameraState = _state.camera.copyWith(isActive: isActive);
    updateCameraState(newCameraState);
  }

  void setCameraPermission(bool hasPermission) {
    final newCameraState = _state.camera.copyWith(hasPermission: hasPermission);
    updateCameraState(newCameraState);
  }

  void setLastCapturedImage(String? imagePath) {
    final newCameraState = _state.camera.copyWith(lastCapturedImage: imagePath);
    updateCameraState(newCameraState);
  }

  // Recognition state updates
  void updateRecognitionState(RecognitionState newRecognitionState) {
    _state = _state.copyWith(recognition: newRecognitionState);
    notifyListeners();
  }

  void setRecognitionProcessing(bool isProcessing) {
    final newRecognitionState = _state.recognition.copyWith(isProcessing: isProcessing);
    updateRecognitionState(newRecognitionState);
  }

  void setRecognitionResults(FoodRecognitionResult? results) {
    final newRecognitionState = _state.recognition.copyWith(results: results, error: null);
    updateRecognitionState(newRecognitionState);
  }

  void setRecognitionError(String? error) {
    final newRecognitionState = _state.recognition.copyWith(error: error, results: null);
    updateRecognitionState(newRecognitionState);
  }

  // Recipe state updates
  void updateRecipeState(RecipeState newRecipeState) {
    _state = _state.copyWith(recipes: newRecipeState);
    notifyListeners();
  }

  void setRecipeSuggestions(List<Recipe> suggestions) {
    final newRecipeState = _state.recipes.copyWith(suggestions: suggestions);
    updateRecipeState(newRecipeState);
  }

  void setSelectedRecipe(Recipe? recipe) {
    final newRecipeState = _state.recipes.copyWith(selectedRecipe: recipe);
    updateRecipeState(newRecipeState);
  }

  void setRecipeLoading(bool isLoading) {
    final newRecipeState = _state.recipes.copyWith(isLoading: isLoading);
    updateRecipeState(newRecipeState);
  }

  void addCustomIngredient(String ingredient) {
    final currentIngredients = List<String>.from(_state.recipes.customIngredients);
    if (!currentIngredients.contains(ingredient)) {
      currentIngredients.add(ingredient);
      final newRecipeState = _state.recipes.copyWith(customIngredients: currentIngredients);
      updateRecipeState(newRecipeState);
    }
  }

  void removeCustomIngredient(String ingredient) {
    final currentIngredients = List<String>.from(_state.recipes.customIngredients);
    currentIngredients.remove(ingredient);
    final newRecipeState = _state.recipes.copyWith(customIngredients: currentIngredients);
    updateRecipeState(newRecipeState);
  }

  void clearCustomIngredients() {
    final newRecipeState = _state.recipes.copyWith(customIngredients: []);
    updateRecipeState(newRecipeState);
  }

  void setRecipeGenerating(bool isGenerating) {
    final newRecipeState = _state.recipes.copyWith(isGeneratingRecipes: isGenerating);
    updateRecipeState(newRecipeState);
  }

  void setRecipeGenerationResult(RecipeGenerationResult? result) {
    final newRecipeState = _state.recipes.copyWith(
      generationResult: result,
      lastGenerationTime: DateTime.now().millisecondsSinceEpoch,
    );
    updateRecipeState(newRecipeState);
  }

  void setAlternativeSuggestions(List<Recipe> alternatives) {
    final newRecipeState = _state.recipes.copyWith(alternativeSuggestions: alternatives);
    updateRecipeState(newRecipeState);
  }

  // User state updates
  void updateUserState(UserState newUserState) {
    _state = _state.copyWith(user: newUserState);
    notifyListeners();
  }

  void updateUserPreferences(UserPreferences preferences) {
    final newUserState = _state.user.copyWith(preferences: preferences);
    updateUserState(newUserState);
  }

  void addFavoriteRecipe(String recipeId) {
    final currentFavorites = List<String>.from(_state.user.favoriteRecipes);
    if (!currentFavorites.contains(recipeId)) {
      currentFavorites.add(recipeId);
      final newUserState = _state.user.copyWith(favoriteRecipes: currentFavorites);
      updateUserState(newUserState);
    }
  }

  void removeFavoriteRecipe(String recipeId) {
    final currentFavorites = List<String>.from(_state.user.favoriteRecipes);
    currentFavorites.remove(recipeId);
    final newUserState = _state.user.copyWith(favoriteRecipes: currentFavorites);
    updateUserState(newUserState);
  }

  void addRecentSearch(String search) {
    final currentSearches = List<String>.from(_state.user.recentSearches);
    currentSearches.remove(search); // Remove if exists to avoid duplicates
    currentSearches.insert(0, search); // Add to beginning
    if (currentSearches.length > 10) {
      currentSearches.removeLast(); // Keep only last 10 searches
    }
    final newUserState = _state.user.copyWith(recentSearches: currentSearches);
    updateUserState(newUserState);
  }

  void addSavedRecipe(SavedRecipe recipe) {
    final currentRecipeBook = List<SavedRecipe>.from(_state.user.recipeBook);
    // Remove existing recipe with same ID if exists
    currentRecipeBook.removeWhere((r) => r.id == recipe.id);
    currentRecipeBook.add(recipe);
    final newUserState = _state.user.copyWith(recipeBook: currentRecipeBook);
    updateUserState(newUserState);
  }

  void removeSavedRecipe(String recipeId) {
    final currentRecipeBook = List<SavedRecipe>.from(_state.user.recipeBook);
    currentRecipeBook.removeWhere((r) => r.id == recipeId);
    final newUserState = _state.user.copyWith(recipeBook: currentRecipeBook);
    updateUserState(newUserState);
  }

  void addMealPlan(MealPlan mealPlan) {
    final currentMealPlans = List<MealPlan>.from(_state.user.mealPlans);
    // Remove existing meal plan with same ID if exists
    currentMealPlans.removeWhere((mp) => mp.id == mealPlan.id);
    currentMealPlans.add(mealPlan);
    final newUserState = _state.user.copyWith(mealPlans: currentMealPlans);
    updateUserState(newUserState);
  }

  void removeMealPlan(String mealPlanId) {
    final currentMealPlans = List<MealPlan>.from(_state.user.mealPlans);
    currentMealPlans.removeWhere((mp) => mp.id == mealPlanId);
    final newUserState = _state.user.copyWith(mealPlans: currentMealPlans);
    updateUserState(newUserState);
  }

  // Onboarding state updates
  void updateOnboardingState(OnboardingState newOnboardingState) {
    _state = _state.copyWith(onboarding: newOnboardingState);
    notifyListeners();
  }

  void setOnboardingComplete(bool isComplete) {
    final newOnboardingState = _state.onboarding.copyWith(isComplete: isComplete);
    updateOnboardingState(newOnboardingState);
  }

  void setOnboardingStep(int step) {
    final newOnboardingState = _state.onboarding.copyWith(currentStep: step);
    updateOnboardingState(newOnboardingState);
  }

  void setFirstLaunch(bool isFirstLaunch) {
    final newOnboardingState = _state.onboarding.copyWith(isFirstLaunch: isFirstLaunch);
    updateOnboardingState(newOnboardingState);
  }

  void setPermissionExplanationSeen(bool hasSeen) {
    final newOnboardingState = _state.onboarding.copyWith(hasSeenPermissionExplanation: hasSeen);
    updateOnboardingState(newOnboardingState);
  }

  void resetOnboarding() {
    final newOnboardingState = const OnboardingState(
      isFirstLaunch: true,
      currentStep: 0,
      isComplete: false,
      hasSeenPermissionExplanation: false,
    );
    updateOnboardingState(newOnboardingState);
  }

  // Subscription state updates
  void updateSubscriptionState(SubscriptionState newSubscriptionState) {
    _state = _state.copyWith(subscription: newSubscriptionState);
    notifyListeners();
  }

  void setSubscriptionTier(SubscriptionTier tier) {
    final newSubscriptionState = _state.subscription.copyWith(
      currentTier: tier,
      lastUpdated: DateTime.now(),
    );
    updateSubscriptionState(newSubscriptionState);
  }

  void updateUsageQuota(UsageQuota quota) {
    final newSubscriptionState = _state.subscription.copyWith(
      usageQuota: quota,
      lastUpdated: DateTime.now(),
    );
    updateSubscriptionState(newSubscriptionState);
  }

  void incrementScanUsage() {
    final currentQuota = _state.subscription.usageQuota;
    final newQuota = currentQuota.copyWith(
      usedScans: currentQuota.usedScans + 1,
    );
    updateUsageQuota(newQuota);
  }

  void decrementAdWatches() {
    final currentQuota = _state.subscription.usageQuota;
    if (currentQuota.adWatchesAvailable > 0) {
      final newQuota = currentQuota.copyWith(
        adWatchesAvailable: currentQuota.adWatchesAvailable - 1,
      );
      updateUsageQuota(newQuota);
    }
  }

  void setSubscriptionLoading(bool isLoading) {
    final newSubscriptionState = _state.subscription.copyWith(isLoading: isLoading);
    updateSubscriptionState(newSubscriptionState);
  }

  // Utility methods
  bool canPerformScan() {
    final quota = _state.subscription.usageQuota;
    final tier = _state.subscription.currentTier;
    
    if (tier.type == 'professional') {
      return true; // Unlimited scans
    }
    
    return quota.usedScans < quota.dailyScans || quota.adWatchesAvailable > 0;
  }

  bool hasFeatureAccess(String feature) {
    return _state.subscription.currentTier.features.contains(feature);
  }

  void resetDailyQuota() {
    final currentQuota = _state.subscription.usageQuota;
    final tier = _state.subscription.currentTier;
    
    int adWatches;
    
    switch (tier.type) {
      case 'free':
        adWatches = 3;
        break;
      case 'premium':
        adWatches = 10;
        break;
      case 'professional':
        adWatches = 0; // No ads
        break;
      default:
        adWatches = 3;
    }
    
    final newQuota = currentQuota.copyWith(
      usedScans: 0,
      adWatchesAvailable: adWatches,
      resetTime: DateTime.now().add(const Duration(days: 1)),
    );
    updateUsageQuota(newQuota);
  }
}

// Extension to make it easier to access the provider
extension AppStateContext on BuildContext {
  AppStateProvider get appState => Provider.of<AppStateProvider>(this, listen: false);
  AppStateProvider watchAppState() => Provider.of<AppStateProvider>(this);
}