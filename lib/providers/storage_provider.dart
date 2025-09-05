import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/app_state_provider.dart';
import '../models/app_state.dart';

class StorageProvider extends ChangeNotifier {
  final StorageServiceInterface _storageService;
  final AppStateProvider _appStateProvider;
  
  bool _isInitializing = false;
  String? _lastError;

  StorageProvider(this._storageService, this._appStateProvider);

  // Getters
  StorageServiceInterface get storageService => _storageService;
  bool get isInitializing => _isInitializing;
  String? get lastError => _lastError;

  // Initialize storage
  Future<bool> initialize() async {
    if (_isInitializing) return false;

    _isInitializing = true;
    _lastError = null;
    notifyListeners();

    try {
      final bool success = await _storageService.initialize();
      
      if (success) {
        // Load initial data
        await _loadInitialData();
        debugPrint('Storage provider: initialization successful');
      } else {
        _lastError = 'Failed to initialize storage';
        debugPrint('Storage provider: initialization failed');
      }

      return success;
    } catch (e) {
      _lastError = 'Storage initialization error: $e';
      debugPrint('Storage provider: initialization error: $e');
      return false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Load initial data from storage
  Future<void> _loadInitialData() async {
    try {
      // Load user preferences
      final userPreferences = await _storageService.getUserPreferences();
      if (userPreferences != null) {
        _appStateProvider.updateUserPreferences(userPreferences);
      }

      // Load onboarding data
      final onboardingData = await _storageService.getOnboardingData();
      if (onboardingData != null) {
        _appStateProvider.setOnboardingComplete(onboardingData.isComplete);
        _appStateProvider.setOnboardingStep(onboardingData.lastShownStep);
        _appStateProvider.setPermissionExplanationSeen(onboardingData.hasSeenPermissionExplanation);
        _appStateProvider.setFirstLaunch(!onboardingData.isComplete);
      }

      // Load subscription data
      final subscriptionData = await _storageService.getSubscriptionData();
      if (subscriptionData != null) {
        // Update subscription state based on stored data
        final tier = SubscriptionTier(
          type: subscriptionData.currentTier,
          features: _getFeaturesForTier(subscriptionData.currentTier),
          quotas: _getQuotasForTier(subscriptionData.currentTier),
          price: _getPriceForTier(subscriptionData.currentTier),
          billingPeriod: 'monthly',
        );
        _appStateProvider.setSubscriptionTier(tier);
      }

      // Load saved recipes
      final savedRecipes = await _storageService.getSavedRecipes();
      final currentUserState = _appStateProvider.state.user;
      final updatedUserState = currentUserState.copyWith(recipeBook: savedRecipes);
      _appStateProvider.updateUserState(updatedUserState);

      // Load meal plans
      final mealPlans = await _storageService.getMealPlans();
      final finalUserState = _appStateProvider.state.user.copyWith(mealPlans: mealPlans);
      _appStateProvider.updateUserState(finalUserState);

      // Load recent searches
      final recentSearches = await _storageService.getRecentSearches();
      final searchUserState = _appStateProvider.state.user.copyWith(recentSearches: recentSearches);
      _appStateProvider.updateUserState(searchUserState);

      debugPrint('Storage provider: initial data loaded');
    } catch (e) {
      debugPrint('Storage provider: error loading initial data: $e');
    }
  }

  // User preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      await _storageService.saveUserPreferences(preferences);
      _appStateProvider.updateUserPreferences(preferences);
      debugPrint('Storage provider: user preferences saved');
    } catch (e) {
      _lastError = 'Failed to save user preferences: $e';
      debugPrint('Storage provider: error saving user preferences: $e');
      notifyListeners();
    }
  }

  // Onboarding data
  Future<void> saveOnboardingData({
    required bool isComplete,
    required List<int> completedSteps,
    required int lastShownStep,
    required bool hasSeenPermissionExplanation,
    String? completionDate,
  }) async {
    try {
      final data = OnboardingData(
        isComplete: isComplete,
        completedSteps: completedSteps,
        lastShownStep: lastShownStep,
        hasSeenPermissionExplanation: hasSeenPermissionExplanation,
        completionDate: completionDate,
      );
      
      await _storageService.saveOnboardingData(data);
      
      // Update app state
      _appStateProvider.setOnboardingComplete(isComplete);
      _appStateProvider.setOnboardingStep(lastShownStep);
      _appStateProvider.setPermissionExplanationSeen(hasSeenPermissionExplanation);
      _appStateProvider.setFirstLaunch(!isComplete);
      
      debugPrint('Storage provider: onboarding data saved');
    } catch (e) {
      _lastError = 'Failed to save onboarding data: $e';
      debugPrint('Storage provider: error saving onboarding data: $e');
      notifyListeners();
    }
  }

  // Subscription data
  Future<void> saveSubscriptionData(SubscriptionData data) async {
    try {
      await _storageService.saveSubscriptionData(data);
      debugPrint('Storage provider: subscription data saved');
    } catch (e) {
      _lastError = 'Failed to save subscription data: $e';
      debugPrint('Storage provider: error saving subscription data: $e');
      notifyListeners();
    }
  }

  // Recipe management
  Future<void> saveRecipe(SavedRecipe recipe) async {
    try {
      await _storageService.saveRecipe(recipe);
      _appStateProvider.addSavedRecipe(recipe);
      debugPrint('Storage provider: recipe saved');
    } catch (e) {
      _lastError = 'Failed to save recipe: $e';
      debugPrint('Storage provider: error saving recipe: $e');
      notifyListeners();
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _storageService.deleteRecipe(recipeId);
      _appStateProvider.removeSavedRecipe(recipeId);
      debugPrint('Storage provider: recipe deleted');
    } catch (e) {
      _lastError = 'Failed to delete recipe: $e';
      debugPrint('Storage provider: error deleting recipe: $e');
      notifyListeners();
    }
  }

  Future<List<SavedRecipe>> searchRecipes(String query) async {
    try {
      return await _storageService.searchRecipes(query);
    } catch (e) {
      _lastError = 'Failed to search recipes: $e';
      debugPrint('Storage provider: error searching recipes: $e');
      notifyListeners();
      return [];
    }
  }

  Future<List<SavedRecipe>> getRecipesByCategory(String category) async {
    try {
      return await _storageService.getRecipesByCategory(category);
    } catch (e) {
      _lastError = 'Failed to get recipes by category: $e';
      debugPrint('Storage provider: error getting recipes by category: $e');
      notifyListeners();
      return [];
    }
  }

  // Meal plan management
  Future<void> saveMealPlan(MealPlan mealPlan) async {
    try {
      await _storageService.saveMealPlan(mealPlan);
      _appStateProvider.addMealPlan(mealPlan);
      debugPrint('Storage provider: meal plan saved');
    } catch (e) {
      _lastError = 'Failed to save meal plan: $e';
      debugPrint('Storage provider: error saving meal plan: $e');
      notifyListeners();
    }
  }

  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _storageService.deleteMealPlan(mealPlanId);
      _appStateProvider.removeMealPlan(mealPlanId);
      debugPrint('Storage provider: meal plan deleted');
    } catch (e) {
      _lastError = 'Failed to delete meal plan: $e';
      debugPrint('Storage provider: error deleting meal plan: $e');
      notifyListeners();
    }
  }

  Future<MealPlan?> getMealPlanById(String mealPlanId) async {
    try {
      return await _storageService.getMealPlanById(mealPlanId);
    } catch (e) {
      _lastError = 'Failed to get meal plan: $e';
      debugPrint('Storage provider: error getting meal plan: $e');
      notifyListeners();
      return null;
    }
  }

  // Recent searches
  Future<void> addRecentSearch(String search) async {
    try {
      await _storageService.addRecentSearch(search);
      _appStateProvider.addRecentSearch(search);
      debugPrint('Storage provider: recent search added');
    } catch (e) {
      _lastError = 'Failed to add recent search: $e';
      debugPrint('Storage provider: error adding recent search: $e');
      notifyListeners();
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      await _storageService.clearRecentSearches();
      final currentUserState = _appStateProvider.state.user;
      final updatedUserState = currentUserState.copyWith(recentSearches: []);
      _appStateProvider.updateUserState(updatedUserState);
      debugPrint('Storage provider: recent searches cleared');
    } catch (e) {
      _lastError = 'Failed to clear recent searches: $e';
      debugPrint('Storage provider: error clearing recent searches: $e');
      notifyListeners();
    }
  }

  // App settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      await _storageService.saveAppSettings(settings);
      debugPrint('Storage provider: app settings saved');
    } catch (e) {
      _lastError = 'Failed to save app settings: $e';
      debugPrint('Storage provider: error saving app settings: $e');
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      return await _storageService.getAppSettings();
    } catch (e) {
      _lastError = 'Failed to get app settings: $e';
      debugPrint('Storage provider: error getting app settings: $e');
      notifyListeners();
      return {};
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await _storageService.clearAllData();
      
      // Reset app state to initial values
      _appStateProvider.updateUserPreferences(const UserPreferences());
      _appStateProvider.setOnboardingComplete(false);
      _appStateProvider.setFirstLaunch(true);
      
      debugPrint('Storage provider: all data cleared');
    } catch (e) {
      _lastError = 'Failed to clear all data: $e';
      debugPrint('Storage provider: error clearing all data: $e');
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Dispose
  @override
  Future<void> dispose() async {
    try {
      await _storageService.dispose();
      debugPrint('Storage provider: disposed');
    } catch (e) {
      debugPrint('Storage provider: dispose error: $e');
    }
    super.dispose();
  }

  // Helper methods for subscription tiers
  List<String> _getFeaturesForTier(String tier) {
    switch (tier) {
      case 'free':
        return ['basic_recognition'];
      case 'premium':
        return ['basic_recognition', 'recipe_book', 'ad_free'];
      case 'professional':
        return ['basic_recognition', 'recipe_book', 'meal_planning', 'unlimited_scans', 'priority_processing'];
      default:
        return ['basic_recognition'];
    }
  }

  UsageQuota _getQuotasForTier(String tier) {
    final now = DateTime.now();
    final resetTime = now.add(const Duration(days: 1));
    
    switch (tier) {
      case 'free':
        return UsageQuota(
          dailyScans: 1,
          usedScans: 0,
          resetTime: resetTime,
          adWatchesAvailable: 3,
          historyDays: 7,
        );
      case 'premium':
        return UsageQuota(
          dailyScans: 5,
          usedScans: 0,
          resetTime: resetTime,
          adWatchesAvailable: 10,
          historyDays: 30,
        );
      case 'professional':
        return UsageQuota(
          dailyScans: 999999,
          usedScans: 0,
          resetTime: resetTime,
          adWatchesAvailable: 0,
          historyDays: 365,
        );
      default:
        return UsageQuota(
          dailyScans: 1,
          usedScans: 0,
          resetTime: resetTime,
          adWatchesAvailable: 3,
          historyDays: 7,
        );
    }
  }

  double _getPriceForTier(String tier) {
    switch (tier) {
      case 'free':
        return 0.0;
      case 'premium':
        return 4.99;
      case 'professional':
        return 9.99;
      default:
        return 0.0;
    }
  }
}

// Extension to make it easier to access the storage provider
extension StorageProviderContext on BuildContext {
  StorageProvider get storageProvider => Provider.of<StorageProvider>(this, listen: false);
  StorageProvider watchStorageProvider() => Provider.of<StorageProvider>(this);
}