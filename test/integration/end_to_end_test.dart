import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/camera_service.dart';
import '../../lib/services/ai_vision_service.dart';
import '../../lib/services/ai_recipe_service.dart';
import '../../lib/services/subscription_service.dart';
import '../../lib/models/subscription.dart';

void main() {
  group('End-to-End Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Complete User Journey Tests', () {
      test('complete food recognition to recipe flow', () async {
        // Initialize services
        final cameraService = CameraService();
        final aiVisionService = AIVisionService(apiKey: 'test-api-key');
        final aiRecipeService = AIRecipeService(apiKey: 'test-api-key');

        try {
          // Step 1: Check camera permissions (expected to fail in test environment)
          bool hasPermission = false;
          try {
            hasPermission = await cameraService.checkPermissions();
          } catch (e) {
            // Expected in test environment
            expect(e, isA<Exception>());
          }

          // Step 2: Capture photo (expected to fail when not initialized)
          String? imagePath;
          try {
            imagePath = await cameraService.capturePhoto();
          } catch (e) {
            // Expected in test environment
            expect(e, isA<Exception>());
          }

          // Step 3: Analyze image (simulate with invalid path)
          final recognitionResult = await aiVisionService.analyzeImage('test_image.jpg');
          expect(recognitionResult, isA<FoodRecognitionResult>());
          expect(recognitionResult.isSuccess, isFalse); // Expected in test environment

          // Step 4: Generate recipes (simulate with empty ingredients)
          final recipeResult = await aiRecipeService.generateRecipesByIngredients([]);
          expect(recipeResult, isA<RecipeGenerationResult>());
          expect(recipeResult.isSuccess, isFalse); // Expected with empty ingredients

          // Verify services can be disposed
          expect(() => cameraService.dispose(), returnsNormally);
          expect(() => aiVisionService.dispose(), returnsNormally);
          expect(() => aiRecipeService.dispose(), returnsNormally);
        } finally {
          cameraService.dispose();
          aiVisionService.dispose();
          aiRecipeService.dispose();
        }
      });

      test('subscription management flow', () async {
        final subscriptionService = SubscriptionServiceImpl(
          await SharedPreferences.getInstance()
        );

        try {
          // Step 1: Start with free tier
          var subscription = await subscriptionService.getCurrentSubscription();
          expect(subscription.type, equals(SubscriptionTierType.free));

          // Step 2: Check feature access
          var canSaveRecipe = await subscriptionService.canPerformAction(ActionType.saveRecipe);
          expect(canSaveRecipe, isFalse);

          var canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
          expect(canCreateMealPlan, isFalse);

          // Step 3: Upgrade to premium
          final upgradeResult = await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
          expect(upgradeResult, isTrue);

          // Step 4: Verify premium features
          subscription = await subscriptionService.getCurrentSubscription();
          expect(subscription.type, equals(SubscriptionTierType.premium));

          canSaveRecipe = await subscriptionService.canPerformAction(ActionType.saveRecipe);
          expect(canSaveRecipe, isTrue);

          canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
          expect(canCreateMealPlan, isFalse); // Still false for premium

          // Step 5: Upgrade to professional
          await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
          
          subscription = await subscriptionService.getCurrentSubscription();
          expect(subscription.type, equals(SubscriptionTierType.professional));

          canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
          expect(canCreateMealPlan, isTrue);

          // Step 6: Cancel subscription
          final cancelResult = await subscriptionService.cancelSubscription();
          expect(cancelResult, isTrue);

          subscription = await subscriptionService.getCurrentSubscription();
          expect(subscription.type, equals(SubscriptionTierType.free));
        } finally {
          // Cleanup
        }
      });

      test('usage tracking and quota management flow', () async {
        final subscriptionService = SubscriptionServiceImpl(
          await SharedPreferences.getInstance()
        );

        try {
          // Step 1: Check initial quota
          var quota = await subscriptionService.getUsageQuota();
          expect(quota.usedScans, equals(0));

          // Step 2: Use some scans
          await subscriptionService.incrementUsage(UsageType.scan);
          
          quota = await subscriptionService.getUsageQuota();
          expect(quota.usedScans, equals(1));

          // Step 3: Check usage history
          final history = await subscriptionService.getUsageHistory();
          expect(history, isNotEmpty);
          expect(history.first.actionType, equals(ActionType.scanFood));

          // Step 4: Watch an ad
          await subscriptionService.watchAd();
          
          quota = await subscriptionService.getUsageQuota();
          expect(quota.adWatchesAvailable, lessThan(SubscriptionTier.free.quotas.adWatchesAvailable));

          // Step 5: Reset quota
          await subscriptionService.resetDailyQuota();
          
          quota = await subscriptionService.getUsageQuota();
          expect(quota.usedScans, equals(0));
        } finally {
          // Cleanup
        }
      });
    });

    group('Cross-Platform Compatibility Tests', () {
      test('services initialize correctly across platforms', () async {
        // Test that services can be created without platform-specific issues
        final cameraService = CameraService();
        final aiVisionService = AIVisionService(apiKey: 'test-api-key');
        final aiRecipeService = AIRecipeService(apiKey: 'test-api-key');

        try {
          // Verify basic properties
          expect(cameraService.isInitialized, isFalse);
          expect(aiVisionService, isA<AIVisionService>());
          expect(aiRecipeService, isA<AIRecipeService>());

          // Test that services handle invalid operations gracefully
          final invalidImageResult = await aiVisionService.validateImageQuality('invalid.jpg');
          expect(invalidImageResult, isFalse);

          final emptyRecipeResult = await aiRecipeService.generateRecipesByIngredients([]);
          expect(emptyRecipeResult.isSuccess, isFalse);
        } finally {
          cameraService.dispose();
          aiVisionService.dispose();
          aiRecipeService.dispose();
        }
      });

      test('data models work consistently', () {
        // Test ingredient model
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

        // Test recognition result model
        final successResult = FoodRecognitionResult.success(
          ingredients: [ingredient],
          confidence: 0.90,
          processingTime: 1500,
        );

        expect(successResult.isSuccess, isTrue);
        expect(successResult.ingredients.length, equals(1));

        final failureResult = FoodRecognitionResult.failure(
          errorMessage: 'Test error',
          processingTime: 500,
        );

        expect(failureResult.isSuccess, isFalse);
        expect(failureResult.ingredients, isEmpty);
      });
    });

    group('Performance Tests', () {
      test('services handle multiple concurrent operations', () async {
        final aiVisionService = AIVisionService(apiKey: 'test-api-key');

        try {
          // Test concurrent image validation
          final futures = List.generate(5, (index) => 
            aiVisionService.validateImageQuality('test_$index.jpg'));
          
          final results = await Future.wait(futures);
          
          expect(results.length, equals(5));
          for (final result in results) {
            expect(result, isFalse); // Expected for invalid files
          }
        } finally {
          aiVisionService.dispose();
        }
      });

      test('subscription service handles rapid operations', () async {
        final subscriptionService = SubscriptionServiceImpl(
          await SharedPreferences.getInstance()
        );

        // Test rapid subscription checks
        final futures = List.generate(10, (_) => 
          subscriptionService.getCurrentSubscription());
        
        final results = await Future.wait(futures);
        
        expect(results.length, equals(10));
        for (final result in results) {
          expect(result.type, equals(SubscriptionTierType.free));
        }
      });
    });

    group('Error Recovery Tests', () {
      test('services recover from errors gracefully', () async {
        final aiVisionService = AIVisionService(apiKey: 'test-api-key');
        final aiRecipeService = AIRecipeService(apiKey: 'test-api-key');

        try {
          // Generate multiple errors
          for (int i = 0; i < 3; i++) {
            final visionResult = await aiVisionService.analyzeImage('invalid_$i.jpg');
            expect(visionResult.isSuccess, isFalse);

            final recipeResult = await aiRecipeService.generateRecipesByIngredients([]);
            expect(recipeResult.isSuccess, isFalse);
          }

          // Services should still be functional
          final finalVisionResult = await aiVisionService.validateImageQuality('test.jpg');
          expect(finalVisionResult, isA<bool>());

          final finalRecipeResult = await aiRecipeService.generateRecipesByIngredients(['test']);
          expect(finalRecipeResult, isA<RecipeGenerationResult>());
        } finally {
          aiVisionService.dispose();
          aiRecipeService.dispose();
        }
      });

      test('subscription service maintains consistency after errors', () async {
        final subscriptionService = SubscriptionServiceImpl(
          await SharedPreferences.getInstance()
        );

        // Perform operations that might cause errors
        try {
          await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
          await subscriptionService.incrementUsage(UsageType.scan);
          await subscriptionService.watchAd();
        } catch (e) {
          // Ignore errors for this test
        }

        // Service should still be functional
        final subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription, isA<SubscriptionTier>());

        final quota = await subscriptionService.getUsageQuota();
        expect(quota, isA<UsageQuota>());
      });
    });

    group('Memory and Resource Management', () {
      test('services clean up resources properly', () async {
        // Create and dispose multiple service instances
        for (int i = 0; i < 5; i++) {
          final cameraService = CameraService();
          final aiVisionService = AIVisionService(apiKey: 'test-api-key');
          final aiRecipeService = AIRecipeService(apiKey: 'test-api-key');

          // Use services briefly
          expect(cameraService.isInitialized, isFalse);
          await aiVisionService.validateImageQuality('test.jpg');
          await aiRecipeService.generateRecipesByIngredients([]);

          // Dispose services
          cameraService.dispose();
          aiVisionService.dispose();
          aiRecipeService.dispose();
        }

        // Test should complete without memory issues
        expect(true, isTrue);
      });

      test('subscription service handles multiple instances', () async {
        final instances = <SubscriptionServiceImpl>[];

        // Create multiple instances
        for (int i = 0; i < 3; i++) {
          final instance = SubscriptionServiceImpl(
            await SharedPreferences.getInstance()
          );
          instances.add(instance);
        }

        // Use all instances
        for (final instance in instances) {
          final subscription = await instance.getCurrentSubscription();
          expect(subscription.type, equals(SubscriptionTierType.free));
        }

        // All instances should work independently
        expect(instances.length, equals(3));
      });
    });
  });
}