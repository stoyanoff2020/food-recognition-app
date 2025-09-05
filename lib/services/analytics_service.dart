import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for handling analytics and crash reporting
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  /// Initialize analytics and crash reporting
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable crash reporting in release mode
      if (!kDebugMode) {
        await _crashlytics?.setCrashlyticsCollectionEnabled(true);
      }

      // Set user properties
      await _analytics?.setAnalyticsCollectionEnabled(true);
      
      debugPrint('Analytics and Crashlytics initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
    }
  }

  /// Log custom events
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  /// Log screen views
  Future<void> logScreenView(String screenName, String screenClass) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Failed to log screen view $screenName: $e');
    }
  }

  /// Log user properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Failed to set user property $name: $e');
    }
  }

  /// Log app-specific events
  
  /// Log when user takes a photo
  Future<void> logPhotoCapture() async {
    await logEvent('photo_capture', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log successful food recognition
  Future<void> logFoodRecognition({
    required int ingredientCount,
    required double processingTime,
    required double averageConfidence,
  }) async {
    await logEvent('food_recognition_success', {
      'ingredient_count': ingredientCount,
      'processing_time_ms': processingTime,
      'average_confidence': averageConfidence,
    });
  }

  /// Log recipe generation
  Future<void> logRecipeGeneration({
    required int recipeCount,
    required double processingTime,
    required List<String> ingredients,
  }) async {
    await logEvent('recipe_generation', {
      'recipe_count': recipeCount,
      'processing_time_ms': processingTime,
      'ingredient_count': ingredients.length,
    });
  }

  /// Log recipe view
  Future<void> logRecipeView({
    required String recipeId,
    required String recipeTitle,
    required double matchPercentage,
  }) async {
    await logEvent('recipe_view', {
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
      'match_percentage': matchPercentage,
    });
  }

  /// Log recipe save (Premium feature)
  Future<void> logRecipeSave({
    required String recipeId,
    required String category,
  }) async {
    await logEvent('recipe_save', {
      'recipe_id': recipeId,
      'category': category,
    });
  }

  /// Log meal plan creation (Professional feature)
  Future<void> logMealPlanCreation({
    required String planType,
    required int mealCount,
  }) async {
    await logEvent('meal_plan_creation', {
      'plan_type': planType,
      'meal_count': mealCount,
    });
  }

  /// Log subscription events
  Future<void> logSubscriptionEvent({
    required String eventType, // 'upgrade', 'cancel', 'renew'
    required String tier, // 'free', 'premium', 'professional'
  }) async {
    await logEvent('subscription_event', {
      'event_type': eventType,
      'tier': tier,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log onboarding completion
  Future<void> logOnboardingComplete({
    required int stepsCompleted,
    required bool skipped,
  }) async {
    await logEvent('onboarding_complete', {
      'steps_completed': stepsCompleted,
      'skipped': skipped,
    });
  }

  /// Log errors and exceptions
  Future<void> logError({
    required String error,
    required String context,
    Map<String, Object>? additionalData,
  }) async {
    try {
      // Log to analytics
      final Map<String, Object> eventData = {
        'error_type': error,
        'context': context,
      };
      if (additionalData != null) {
        eventData.addAll(additionalData);
      }
      
      await logEvent('app_error', eventData);

      // Log to crashlytics
      await _crashlytics?.log('Error in $context: $error');
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Record non-fatal exceptions
  Future<void> recordError({
    required dynamic exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Failed to record error: $e');
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      await _crashlytics?.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Failed to set custom key $key: $e');
    }
  }

  /// Performance monitoring events
  
  /// Log app startup time
  Future<void> logAppStartup(Duration startupTime) async {
    await logEvent('app_startup', {
      'startup_time_ms': startupTime.inMilliseconds,
    });
  }

  /// Log API response times
  Future<void> logApiPerformance({
    required String endpoint,
    required Duration responseTime,
    required bool success,
  }) async {
    await logEvent('api_performance', {
      'endpoint': endpoint,
      'response_time_ms': responseTime.inMilliseconds,
      'success': success,
    });
  }

  /// Log image processing performance
  Future<void> logImageProcessingPerformance({
    required Duration processingTime,
    required int imageSize,
    required bool success,
  }) async {
    await logEvent('image_processing_performance', {
      'processing_time_ms': processingTime.inMilliseconds,
      'image_size_bytes': imageSize,
      'success': success,
    });
  }
}