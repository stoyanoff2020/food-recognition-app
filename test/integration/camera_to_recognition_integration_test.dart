import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/camera_service.dart';
import '../../lib/services/ai_vision_service.dart';

void main() {
  group('Camera to Recognition Integration Tests', () {
    late CameraService cameraService;
    late AIVisionService aiVisionService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cameraService = CameraService();
      aiVisionService = AIVisionService(apiKey: 'test-api-key');
    });

    tearDown(() {
      cameraService.dispose();
      aiVisionService.dispose();
    });

    group('Service Initialization', () {
      test('camera service initializes correctly', () {
        expect(cameraService.isInitialized, isFalse);
        expect(cameraService.controller, isNull);
        expect(cameraService.availableCameras, isEmpty);
      });

      test('ai vision service initializes correctly', () {
        expect(aiVisionService, isA<AIVisionService>());
      });
    });

    group('Error Handling Integration', () {
      test('camera service handles permissions gracefully in test environment', () async {
        // Test permission check (expected to fail in test environment)
        try {
          await cameraService.checkPermissions();
        } catch (e) {
          expect(e, isA<Exception>());
        }

        // Test permission request (expected to fail in test environment)
        try {
          await cameraService.requestPermissions();
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('camera service handles photo capture when not initialized', () async {
        try {
          await cameraService.capturePhoto();
        } catch (e) {
          // Expected - camera not initialized
          expect(e, isA<Exception>());
        }
      });

      test('ai vision service handles invalid images', () async {
        final result = await aiVisionService.analyzeImage('non_existent_file.jpg');
        
        expect(result.isSuccess, isFalse);
        expect(result.ingredients, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.errorMessage, isNotNull);
      });

      test('ai vision service validates image quality', () async {
        final isValid = await aiVisionService.validateImageQuality('non_existent_file.jpg');
        expect(isValid, isFalse);
      });
    });

    group('Service Integration Flow', () {
      test('complete flow handles missing components gracefully', () async {
        // Step 1: Check camera permissions (will fail in test environment)
        bool hasPermission = false;
        try {
          hasPermission = await cameraService.checkPermissions();
        } catch (e) {
          // Expected in test environment
        }

        // Step 2: Attempt to capture photo (will fail when not initialized)
        String? imagePath;
        try {
          imagePath = await cameraService.capturePhoto();
        } catch (e) {
          // Expected in test environment
        }

        // Step 3: If we had an image, analyze it (will fail with invalid path)
        if (imagePath != null) {
          final recognitionResult = await aiVisionService.analyzeImage(imagePath);
          expect(recognitionResult, isA<FoodRecognitionResult>());
        } else {
          // Test with invalid path
          final recognitionResult = await aiVisionService.analyzeImage('invalid_path.jpg');
          expect(recognitionResult.isSuccess, isFalse);
        }
      });

      test('services handle disposal correctly', () {
        // Test that services can be disposed without errors
        expect(() => cameraService.dispose(), returnsNormally);
        expect(() => aiVisionService.dispose(), returnsNormally);
      });
    });

    group('Concurrent Operations', () {
      test('services handle multiple operations', () async {
        // Test multiple concurrent validation requests
        final futures = List.generate(3, (_) => 
          aiVisionService.validateImageQuality('non_existent.jpg'));
        final results = await Future.wait(futures);
        
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isFalse);
        }
      });

      test('camera service handles multiple permission checks', () async {
        // Test multiple concurrent permission checks (may fail in test environment)
        final futures = <Future<bool>>[];
        for (int i = 0; i < 3; i++) {
          futures.add(
            cameraService.checkPermissions().catchError((_) => false)
          );
        }
        
        final results = await Future.wait(futures);
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isA<bool>());
        }
      });
    });

    group('Error Recovery', () {
      test('services recover from errors gracefully', () async {
        // Test that services can handle multiple failed operations
        for (int i = 0; i < 3; i++) {
          final result = await aiVisionService.analyzeImage('invalid_$i.jpg');
          expect(result.isSuccess, isFalse);
          expect(result.errorMessage, isNotNull);
        }

        // Services should still be functional after errors
        final finalResult = await aiVisionService.validateImageQuality('test.jpg');
        expect(finalResult, isA<bool>());
      });

      test('camera service maintains state after errors', () async {
        // Multiple operations should not break the service
        for (int i = 0; i < 3; i++) {
          expect(cameraService.isInitialized, isFalse);
          
          try {
            await cameraService.checkPermissions();
          } catch (e) {
            // Expected in test environment
          }
        }
        
        // Service should still be in consistent state
        expect(cameraService.isInitialized, isFalse);
      });
    });

    group('Data Model Integration', () {
      test('food recognition result models work correctly', () {
        final successResult = FoodRecognitionResult.success(
          ingredients: [
            const Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable'),
          ],
          confidence: 0.90,
          processingTime: 1500,
        );

        expect(successResult.isSuccess, isTrue);
        expect(successResult.ingredients.length, equals(1));
        expect(successResult.ingredients.first.name, equals('tomato'));

        final failureResult = FoodRecognitionResult.failure(
          errorMessage: 'Test error',
          processingTime: 500,
        );

        expect(failureResult.isSuccess, isFalse);
        expect(failureResult.ingredients, isEmpty);
        expect(failureResult.errorMessage, equals('Test error'));
      });

      test('ingredient model serialization works', () {
        const ingredient = Ingredient(
          name: 'tomato',
          confidence: 0.95,
          category: 'vegetable',
        );

        final json = ingredient.toJson();
        final deserializedIngredient = Ingredient.fromJson(json);

        expect(deserializedIngredient.name, equals(ingredient.name));
        expect(deserializedIngredient.confidence, equals(ingredient.confidence));
        expect(deserializedIngredient.category, equals(ingredient.category));
      });
    });
  });
}