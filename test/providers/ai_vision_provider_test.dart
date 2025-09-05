import 'package:flutter_test/flutter_test.dart';

import '../../lib/providers/ai_vision_provider.dart';
import '../../lib/services/ai_vision_service.dart';

// Simple mock implementation for testing
class MockAIVisionService implements AIVisionServiceInterface {
  FoodRecognitionResult? _mockResult;
  Exception? _mockException;
  bool _shouldThrow = false;

  void setMockResult(FoodRecognitionResult result) {
    _mockResult = result;
    _shouldThrow = false;
  }

  void setMockException(Exception exception) {
    _mockException = exception;
    _shouldThrow = true;
  }

  @override
  Future<FoodRecognitionResult> analyzeImage(String imageUri) async {
    if (_shouldThrow && _mockException != null) {
      throw _mockException!;
    }
    return _mockResult ?? FoodRecognitionResult.failure(
      errorMessage: 'No mock result set',
      processingTime: 0,
    );
  }

  @override
  Future<bool> validateImageQuality(String imageUri) async => true;

  @override
  Future<String> processImageForAPI(String imageUri) async => 'mock_base64';

  @override
  void dispose() {}
}

void main() {
  group('AIVisionProvider', () {
    late MockAIVisionService mockAIVisionService;
    late AIVisionProvider aiVisionProvider;

    setUp(() {
      mockAIVisionService = MockAIVisionService();
      aiVisionProvider = AIVisionProvider(aiVisionService: mockAIVisionService);
    });

    tearDown(() {
      aiVisionProvider.dispose();
    });

    group('initial state', () {
      test('should have correct initial values', () {
        expect(aiVisionProvider.lastResult, isNull);
        expect(aiVisionProvider.isAnalyzing, isFalse);
        expect(aiVisionProvider.error, isNull);
        expect(aiVisionProvider.ingredients, isEmpty);
        expect(aiVisionProvider.confidence, equals(0.0));
        expect(aiVisionProvider.hasResults, isFalse);
      });
    });

    group('analyzeImage', () {
      test('should update state correctly during successful analysis', () async {
        // Arrange
        const ingredients = [
          Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable'),
          Ingredient(name: 'basil', confidence: 0.85, category: 'herb'),
        ];
        
        final successResult = FoodRecognitionResult.success(
          ingredients: ingredients,
          confidence: 0.90,
          processingTime: 1500,
        );

        mockAIVisionService.setMockResult(successResult);

        // Track state changes
        final stateChanges = <String>[];
        aiVisionProvider.addListener(() {
          if (aiVisionProvider.isAnalyzing) {
            stateChanges.add('analyzing');
          } else if (aiVisionProvider.hasResults) {
            stateChanges.add('success');
          } else if (aiVisionProvider.error != null) {
            stateChanges.add('error');
          }
        });

        // Act
        await aiVisionProvider.analyzeImage('test_image.jpg');

        // Assert
        expect(stateChanges, contains('analyzing'));
        expect(stateChanges, contains('success'));
        expect(aiVisionProvider.isAnalyzing, isFalse);
        expect(aiVisionProvider.hasResults, isTrue);
        expect(aiVisionProvider.lastResult, equals(successResult));
        expect(aiVisionProvider.ingredients, hasLength(2));
        expect(aiVisionProvider.ingredients[0].name, equals('tomato'));
        expect(aiVisionProvider.confidence, equals(0.90));
        expect(aiVisionProvider.error, isNull);
      });

      test('should handle analysis failure correctly', () async {
        // Arrange
        final failureResult = FoodRecognitionResult.failure(
          errorMessage: 'No food detected',
          processingTime: 500,
        );

        mockAIVisionService.setMockResult(failureResult);

        // Act
        await aiVisionProvider.analyzeImage('test_image.jpg');

        // Assert
        expect(aiVisionProvider.isAnalyzing, isFalse);
        expect(aiVisionProvider.hasResults, isFalse);
        expect(aiVisionProvider.lastResult, equals(failureResult));
        expect(aiVisionProvider.ingredients, isEmpty);
        expect(aiVisionProvider.confidence, equals(0.0));
        expect(aiVisionProvider.error, equals('No food detected'));
      });

      test('should handle service exceptions correctly', () async {
        // Arrange
        mockAIVisionService.setMockException(
          const AIVisionServiceException('Network error')
        );

        // Act
        await aiVisionProvider.analyzeImage('test_image.jpg');

        // Assert
        expect(aiVisionProvider.isAnalyzing, isFalse);
        expect(aiVisionProvider.hasResults, isFalse);
        expect(aiVisionProvider.lastResult, isNull);
        expect(aiVisionProvider.error, contains('Network error'));
      });

      test('should clear previous results before new analysis', () async {
        // Arrange - Set up initial successful result
        const initialIngredients = [
          Ingredient(name: 'apple', confidence: 0.90, category: 'fruit'),
        ];
        
        final initialResult = FoodRecognitionResult.success(
          ingredients: initialIngredients,
          confidence: 0.90,
          processingTime: 1000,
        );

        mockAIVisionService.setMockResult(initialResult);
        await aiVisionProvider.analyzeImage('first_image.jpg');
        expect(aiVisionProvider.hasResults, isTrue);

        // Arrange - Set up second analysis that will fail
        mockAIVisionService.setMockException(
          const AIVisionServiceException('Network error')
        );

        // Act
        await aiVisionProvider.analyzeImage('second_image.jpg');

        // Assert - Previous results should be cleared
        expect(aiVisionProvider.hasResults, isFalse);
        expect(aiVisionProvider.lastResult, isNull);
        expect(aiVisionProvider.error, contains('Network error'));
      });
    });

    group('clearResults', () {
      test('should clear results and error', () async {
        // Arrange - Set up some results first
        const ingredients = [
          Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable'),
        ];
        
        final result = FoodRecognitionResult.success(
          ingredients: ingredients,
          confidence: 0.90,
          processingTime: 1500,
        );

        mockAIVisionService.setMockResult(result);
        await aiVisionProvider.analyzeImage('test_image.jpg');
        expect(aiVisionProvider.hasResults, isTrue);

        // Act
        aiVisionProvider.clearResults();

        // Assert
        expect(aiVisionProvider.lastResult, isNull);
        expect(aiVisionProvider.error, isNull);
        expect(aiVisionProvider.hasResults, isFalse);
        expect(aiVisionProvider.ingredients, isEmpty);
        expect(aiVisionProvider.confidence, equals(0.0));
      });
    });

    group('clearError', () {
      test('should clear only error, keeping results', () async {
        // Arrange - Set up a failure first
        final failureResult = FoodRecognitionResult.failure(
          errorMessage: 'Test error',
          processingTime: 500,
        );

        mockAIVisionService.setMockResult(failureResult);
        await aiVisionProvider.analyzeImage('test_image.jpg');
        expect(aiVisionProvider.error, isNotNull);
        expect(aiVisionProvider.lastResult, isNotNull);

        // Act
        aiVisionProvider.clearError();

        // Assert
        expect(aiVisionProvider.error, isNull);
        expect(aiVisionProvider.lastResult, isNotNull); // Should still have the result
      });
    });

    group('getters', () {
      test('should return correct values when no results', () {
        expect(aiVisionProvider.ingredients, isEmpty);
        expect(aiVisionProvider.confidence, equals(0.0));
        expect(aiVisionProvider.hasResults, isFalse);
      });

      test('should return correct values when has results', () async {
        // Arrange
        const ingredients = [
          Ingredient(name: 'carrot', confidence: 0.88, category: 'vegetable'),
          Ingredient(name: 'onion', confidence: 0.75, category: 'vegetable'),
        ];
        
        final result = FoodRecognitionResult.success(
          ingredients: ingredients,
          confidence: 0.82,
          processingTime: 1200,
        );

        mockAIVisionService.setMockResult(result);

        // Act
        await aiVisionProvider.analyzeImage('test_image.jpg');

        // Assert
        expect(aiVisionProvider.ingredients, hasLength(2));
        expect(aiVisionProvider.ingredients[0].name, equals('carrot'));
        expect(aiVisionProvider.ingredients[1].name, equals('onion'));
        expect(aiVisionProvider.confidence, equals(0.82));
        expect(aiVisionProvider.hasResults, isTrue);
      });
    });
  });
}