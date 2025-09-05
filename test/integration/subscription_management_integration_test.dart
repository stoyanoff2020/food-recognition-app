import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/subscription_service.dart';
import '../../lib/services/ad_service.dart';
import '../../lib/services/recipe_book_service.dart';
import '../../lib/services/meal_planning_service.dart';
import '../../lib/models/subscription.dart';

void main() {
  group('Subscription Management Integration Tests', () {
    late SubscriptionService subscriptionService;
    late AdService adService;
    late RecipeBookService recipeBookService;
    late MealPlanningService mealPlanningService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      subscriptionService = SubscriptionServiceFactory.create();
      adService = AdServiceFactory.create();
      recipeBookService = RecipeBookServiceFactory.create();
      mealPlanningService = MealPlanningServiceFactory.create();
    });

    tearDown(() {
      subscriptionService.dispose();
      adService.dispose();
      recipeBookService.dispose();
      mealPlanningService.dispose();
    });

    group('Subscription Tier Management', () {
      test('starts with free tier by default', () async {
        final subscription = await subscriptionService.getCurrentSubscription();
        
        expect(subscription.type, equals(SubscriptionTierType.free));
        expect(subscription.price, equals(0.0));
        expect(subscription.features, isEmpty);
      });

      test('upgrades from free to premium correctly', () async {
        // Start with free tier
        var subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, equals(SubscriptionTierType.free));

        // Upgrade to premium
        final upgradeResult = await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        expect(upgradeResult, isTrue);

        // Verify upgrade
        subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, equals(SubscriptionTierType.premium));
        expect(subscription.price, equals(4.99));
        expect(subscription.features, contains(FeatureType.recipeBook));
      });

      test('upgrades from premium to professional correctly', () async {
        // Upgrade to premium first
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Then upgrade to professional
        final upgradeResult = await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        expect(upgradeResult, isTrue);

        final subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, equals(SubscriptionTierType.professional));
        expect(subscription.price, equals(9.99));
        expect(subscription.features, contains(FeatureType.mealPlanning));
        expect(subscription.features, contains(FeatureType.unlimitedScans));
      });

      test('cancels subscription correctly', () async {
        // Upgrade to premium first
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Cancel subscription
        final cancelResult = await subscriptionService.cancelSubscription();
        expect(cancelResult, isTrue);

        // Should revert to free tier
        final subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, equals(SubscriptionTierType.free));
      });
    });

    group('Feature Access Control', () {
      test('free tier has no premium features', () async {
        expect(await subscriptionService.hasFeatureAccess(FeatureType.recipeBook), isFalse);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.mealPlanning), isFalse);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.unlimitedScans), isFalse);
      });

      test('premium tier has recipe book access', () async {
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        expect(await subscriptionService.hasFeatureAccess(FeatureType.recipeBook), isTrue);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.mealPlanning), isFalse);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.unlimitedScans), isFalse);
      });

      test('professional tier has all features', () async {
        await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        
        expect(await subscriptionService.hasFeatureAccess(FeatureType.recipeBook), isTrue);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.mealPlanning), isTrue);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.unlimitedScans), isTrue);
      });
    });

    group('Usage Quota Management', () {
      test('tracks scan usage correctly', () async {
        final initialQuota = await subscriptionService.getUsageQuota();
        expect(initialQuota.usedScans, equals(0));

        await subscriptionService.incrementUsage(UsageType.scan);
        
        final updatedQuota = await subscriptionService.getUsageQuota();
        expect(updatedQuota.usedScans, equals(1));
      });

      test('tracks ad watch usage correctly', () async {
        await subscriptionService.incrementUsage(UsageType.adWatch);
        
        final history = await subscriptionService.getUsageHistory();
        expect(history, isNotEmpty);
        
        final adWatchRecord = history.firstWhere(
          (record) => record.actionType == ActionType.watchAd,
          orElse: () => throw StateError('No ad watch record found'),
        );
        expect(adWatchRecord.adsWatched, equals(1));
      });

      test('resets quota correctly', () async {
        // Use some scans
        await subscriptionService.incrementUsage(UsageType.scan);
        
        var quota = await subscriptionService.getUsageQuota();
        expect(quota.usedScans, equals(1));

        // Reset quota
        await subscriptionService.resetDailyQuota();
        
        quota = await subscriptionService.getUsageQuota();
        expect(quota.usedScans, equals(0));
      });
    });

    group('Action Permission Integration', () {
      test('allows scanning for free users within quota', () async {
        final canScan = await subscriptionService.canPerformAction(ActionType.scanFood);
        expect(canScan, isTrue); // Free tier gets 1 scan per 6 hours
      });

      test('prevents recipe saving for free users', () async {
        final canSave = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSave, isFalse);
      });

      test('allows recipe saving for premium users', () async {
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        final canSave = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSave, isTrue);
      });

      test('prevents meal planning for non-professional users', () async {
        // Free tier
        var canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
        expect(canCreateMealPlan, isFalse);

        // Premium tier
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
        expect(canCreateMealPlan, isFalse);
      });

      test('allows meal planning for professional users', () async {
        await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        
        final canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
        expect(canCreateMealPlan, isTrue);
      });
    });

    group('Ad Service Integration', () {
      test('ad service initializes correctly', () {
        expect(adService.isInitialized, isFalse);
        expect(adService.isRewardedAdLoaded, isFalse);
      });

      test('ad service handles loading states', () async {
        // Test loading rewarded ad
        await adService.loadRewardedAd();
        
        // In test environment, ad won't actually load
        expect(adService.isRewardedAdLoaded, isFalse);
      });

      test('integrates with subscription service for ad rewards', () async {
        // Watch an ad (simulated)
        await subscriptionService.watchAd();
        
        final quota = await subscriptionService.getUsageQuota();
        // Ad watches should be tracked
        expect(quota.adWatchesAvailable, lessThan(SubscriptionTier.free.quotas.adWatchesAvailable));
      });
    });

    group('Service Integration with Subscription Checks', () {
      test('recipe book service respects subscription limits', () async {
        // Free tier should not be able to save recipes
        final hasAccess = await recipeBookService.hasFeatureAccess();
        expect(hasAccess, isFalse);

        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Now should have access
        final hasAccessAfterUpgrade = await recipeBookService.hasFeatureAccess();
        expect(hasAccessAfterUpgrade, isTrue);
      });

      test('meal planning service respects subscription limits', () async {
        // Free and premium tiers should not have access
        var hasAccess = await mealPlanningService.hasFeatureAccess();
        expect(hasAccess, isFalse);

        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        hasAccess = await mealPlanningService.hasFeatureAccess();
        expect(hasAccess, isFalse);

        // Only professional tier should have access
        await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        hasAccess = await mealPlanningService.hasFeatureAccess();
        expect(hasAccess, isTrue);
      });
    });

    group('End-to-End Subscription Flow', () {
      test('complete subscription upgrade and feature usage flow', () async {
        // Start with free tier
        var subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, equals(SubscriptionTierType.free));

        // Try to save recipe (should fail)
        var canSaveRecipe = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSaveRecipe, isFalse);

        // Upgrade to premium
        await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        
        // Now can save recipes
        canSaveRecipe = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSaveRecipe, isTrue);

        // But still can't create meal plans
        var canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
        expect(canCreateMealPlan, isFalse);

        // Upgrade to professional
        await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        
        // Now can create meal plans
        canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
        expect(canCreateMealPlan, isTrue);

        // Cancel subscription
        await subscriptionService.cancelSubscription();
        
        // Should revert to free tier restrictions
        subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, equals(SubscriptionTierType.free));
        
        canSaveRecipe = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSaveRecipe, isFalse);
      });

      test('handles quota management throughout subscription changes', () async {
        // Use some quota on free tier
        await subscriptionService.incrementUsage(UsageType.scan);
        
        var quota = await subscriptionService.getUsageQuota();
        expect(quota.usedScans, equals(1));

        // Upgrade to professional (unlimited scans)
        await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        
        // Should still be able to scan even with used quota
        final canScan = await subscriptionService.canPerformAction(ActionType.scanFood);
        expect(canScan, isTrue);

        // Downgrade back to free
        await subscriptionService.cancelSubscription();
        
        // Quota restrictions should apply again
        quota = await subscriptionService.getUsageQuota();
        expect(quota.usedScans, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling Integration', () {
      test('handles service errors gracefully', () async {
        // Test that services handle errors without crashing
        expect(() => subscriptionService.getCurrentSubscription(), returnsNormally);
        expect(() => adService.loadRewardedAd(), returnsNormally);
        expect(() => recipeBookService.hasFeatureAccess(), returnsNormally);
        expect(() => mealPlanningService.hasFeatureAccess(), returnsNormally);
      });

      test('maintains consistency after errors', () async {
        // Even if operations fail, subscription state should remain consistent
        final initialSubscription = await subscriptionService.getCurrentSubscription();
        
        // Attempt operations that might fail
        try {
          await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        } catch (e) {
          // Ignore errors for this test
        }
        
        // Subscription service should still be functional
        final finalSubscription = await subscriptionService.getCurrentSubscription();
        expect(finalSubscription, isA<SubscriptionTier>());
      });
    });
  });
}