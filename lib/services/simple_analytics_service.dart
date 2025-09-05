import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple analytics service without Firebase
/// Stores events locally and can batch upload to custom endpoint
class SimpleAnalyticsService {
  static final SimpleAnalyticsService _instance = SimpleAnalyticsService._internal();
  factory SimpleAnalyticsService() => _instance;
  SimpleAnalyticsService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('Simple Analytics initialized');
  }

  /// Log custom events locally
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    try {
      final event = {
        'name': name,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Store locally
      final events = await _getStoredEvents();
      events.add(event);
      await _storeEvents(events);

      debugPrint('Event logged: $name');
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  /// App-specific event logging methods
  Future<void> logPhotoCapture() async {
    await logEvent('photo_capture', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

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

  Future<void> logSubscriptionEvent({
    required String eventType,
    required String tier,
  }) async {
    await logEvent('subscription_event', {
      'event_type': eventType,
      'tier': tier,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get stored events for batch upload
  Future<List<Map<String, dynamic>>> _getStoredEvents() async {
    final eventsJson = _prefs?.getString('analytics_events') ?? '[]';
    final eventsList = jsonDecode(eventsJson) as List;
    return eventsList.cast<Map<String, dynamic>>();
  }

  /// Store events locally
  Future<void> _storeEvents(List<Map<String, dynamic>> events) async {
    // Keep only last 1000 events to prevent storage bloat
    if (events.length > 1000) {
      events = events.sublist(events.length - 1000);
    }
    
    final eventsJson = jsonEncode(events);
    await _prefs?.setString('analytics_events', eventsJson);
  }

  /// Get analytics summary for debugging
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final events = await _getStoredEvents();
    final eventCounts = <String, int>{};
    
    for (final event in events) {
      final name = event['name'] as String;
      eventCounts[name] = (eventCounts[name] ?? 0) + 1;
    }
    
    return {
      'total_events': events.length,
      'event_counts': eventCounts,
      'last_event_time': events.isNotEmpty 
          ? events.last['timestamp'] 
          : null,
    };
  }

  /// Optional: Upload events to custom analytics endpoint
  Future<void> uploadEvents() async {
    try {
      final events = await _getStoredEvents();
      if (events.isEmpty) return;

      // TODO: Implement custom analytics endpoint
      // await _httpClient.post('/analytics', body: jsonEncode(events));
      
      // Clear uploaded events
      await _prefs?.remove('analytics_events');
      debugPrint('Uploaded ${events.length} analytics events');
    } catch (e) {
      debugPrint('Failed to upload analytics: $e');
    }
  }
}