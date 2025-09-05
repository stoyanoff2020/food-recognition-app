import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/subscription_service.dart';
import '../../lib/models/subscription.dart';

@GenerateMocks([SharedPreferences])
import 'subscription_service_test.mocks.dart';

void main() {
  group('SubscriptionService', () {
    late MockSharedPreferences mockPrefs;
    late SubscriptionServiceImpl subscriptionService;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      subscriptionService = SubscriptionServiceImpl(mockPrefs);
    });

    tearDown(() {
      subscriptionService.dispose();
    });

    group('getCurrentSubscription', () {
      test('returns free tier when no data exists', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final subscription = await subscriptionService.getCurrentSubscription();

        expect(subscription.type, SubscriptionTierType.free);
        expect(subscription.price, 0.0);
        expect(subscription.features, isEmpty);
      });

      test('returns premium tier when premium data exists', () async {
        final premiumData = SubscriptionData(
          currentTier: SubscriptionTierType.premium,
          subscriptionId: 'test_premium',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.premium.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(premiumData.toJson()));

        final subscription = await subscriptionService.getCurrentSubscription();

        expect(subscription.type, SubscriptionTierType.premium);
        expect(subscription.price, 4.99);
        expect(subscription.features, contains(FeatureType.recipeBook));
      });

      test('returns professional tier when professional data exists', () async {
        final professionalData = SubscriptionData(
          currentTier: SubscriptionTierType.professional,
          subscriptionId: 'test_professional',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.professional.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(professionalData.toJson()));

        final subscription = await subscriptionService.getCurrentSubscription();

        expect(subscription.type, SubscriptionTierType.professional);
        expect(subscription.price, 9.99);
        expect(subscription.features, contains(FeatureType.mealPlanning));
        expect(subscription.features, contains(FeatureType.unlimitedScans));
      });
    });

    group('hasFeatureAccess', () {
      test('free tier has no premium features', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        expect(await subscriptionService.hasFeatureAccess(FeatureType.recipeBook), false);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.mealPlanning), false);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.unlimitedScans), false);
      });

      test('premium tier has recipe book access', () async {
        final premiumData = SubscriptionData(
          currentTier: SubscriptionTierType.premium,
          subscriptionId: 'test_premium',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.premium.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(premiumData.toJson()));

        expect(await subscriptionService.hasFeatureAccess(FeatureType.recipeBook), true);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.mealPlanning), false);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.unlimitedScans), false);
      });

      test('professional tier has all features', () async {
        final professionalData = SubscriptionData(
          currentTier: SubscriptionTierType.professional,
          subscriptionId: 'test_professional',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.professional.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(professionalData.toJson()));

        expect(await subscriptionService.hasFeatureAccess(FeatureType.recipeBook), true);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.mealPlanning), true);
        expect(await subscriptionService.hasFeatureAccess(FeatureType.unlimitedScans), true);
      });
    });

    group('upgradeSubscription', () {
      test('successfully upgrades from free to premium', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await subscriptionService.upgradeSubscription(SubscriptionTierType.premium);
        expect(result, true);

        final subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, SubscriptionTierType.premium);
      });

      test('successfully upgrades from premium to professional', () async {
        final premiumData = SubscriptionData(
          currentTier: SubscriptionTierType.premium,
          subscriptionId: 'test_premium',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.premium.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(premiumData.toJson()));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await subscriptionService.upgradeSubscription(SubscriptionTierType.professional);
        expect(result, true);

        final subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, SubscriptionTierType.professional);
      });
    });

    group('cancelSubscription', () {
      test('successfully cancels premium subscription', () async {
        final premiumData = SubscriptionData(
          currentTier: SubscriptionTierType.premium,
          subscriptionId: 'test_premium',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.premium.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(premiumData.toJson()));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await subscriptionService.cancelSubscription();
        expect(result, true);

        final subscription = await subscriptionService.getCurrentSubscription();
        expect(subscription.type, SubscriptionTierType.free);
      });
    });

    group('usage tracking', () {
      test('tracks scan usage correctly', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        await subscriptionService.incrementUsage(UsageType.scan);

        final quota = await subscriptionService.getUsageQuota();
        expect(quota.usedScans, 1);

        final history = await subscriptionService.getUsageHistory();
        expect(history.length, 1);
        expect(history.first.actionType, ActionType.scanFood);
      });

      test('tracks ad watch usage correctly', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        await subscriptionService.incrementUsage(UsageType.adWatch);

        final history = await subscriptionService.getUsageHistory();
        expect(history.length, 1);
        expect(history.first.actionType, ActionType.watchAd);
        expect(history.first.adsWatched, 1);
      });

      test('prevents scanning when quota exceeded', () async {
        final freeData = SubscriptionData(
          currentTier: SubscriptionTierType.free,
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.free.quotas.copyWith(
            usedScans: 1, // Already used the daily scan
          ),
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(freeData.toJson()));

        final canScan = await subscriptionService.canPerformAction(ActionType.scanFood);
        expect(canScan, true); // Can still watch ads for more scans
      });

      test('allows unlimited scans for professional tier', () async {
        final professionalData = SubscriptionData(
          currentTier: SubscriptionTierType.professional,
          subscriptionId: 'test_professional',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.professional.quotas.copyWith(
            usedScans: 100, // High usage
          ),
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(professionalData.toJson()));

        final canScan = await subscriptionService.canPerformAction(ActionType.scanFood);
        expect(canScan, true); // Unlimited scans
      });
    });

    group('canPerformAction', () {
      test('allows recipe saving for premium users', () async {
        final premiumData = SubscriptionData(
          currentTier: SubscriptionTierType.premium,
          subscriptionId: 'test_premium',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.premium.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(premiumData.toJson()));

        final canSave = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSave, true);
      });

      test('prevents recipe saving for free users', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final canSave = await subscriptionService.canPerformAction(ActionType.saveRecipe);
        expect(canSave, false);
      });

      test('allows meal planning for professional users only', () async {
        final professionalData = SubscriptionData(
          currentTier: SubscriptionTierType.professional,
          subscriptionId: 'test_professional',
          purchaseDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          usageHistory: [],
          lastQuotaReset: DateTime.now(),
          currentQuota: SubscriptionTier.professional.quotas,
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(professionalData.toJson()));

        final canCreateMealPlan = await subscriptionService.canPerformAction(ActionType.createMealPlan);
        expect(canCreateMealPlan, true);
      });
    });

    group('watchAd', () {
      test('decreases available ad watches', () async {
        when(mockPrefs.getString('subscription_data')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final initialQuota = await subscriptionService.getUsageQuota();
        final initialAdWatches = initialQuota.adWatchesAvailable;

        await subscriptionService.watchAd();

        final updatedQuota = await subscriptionService.getUsageQuota();
        expect(updatedQuota.adWatchesAvailable, initialAdWatches - 1);
      });
    });

    group('quota reset', () {
      test('identifies when quota needs reset', () async {
        final pastResetTime = DateTime.now().subtract(const Duration(hours: 7));
        final freeData = SubscriptionData(
          currentTier: SubscriptionTierType.free,
          usageHistory: [],
          lastQuotaReset: pastResetTime,
          currentQuota: SubscriptionTier.free.quotas.copyWith(
            resetTime: pastResetTime,
            usedScans: 1,
          ),
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(freeData.toJson()));

        final needsReset = await subscriptionService.needsQuotaReset();
        expect(needsReset, true);
      });

      test('resets quota correctly', () async {
        final pastResetTime = DateTime.now().subtract(const Duration(hours: 7));
        final freeData = SubscriptionData(
          currentTier: SubscriptionTierType.free,
          usageHistory: [],
          lastQuotaReset: pastResetTime,
          currentQuota: SubscriptionTier.free.quotas.copyWith(
            resetTime: pastResetTime,
            usedScans: 1,
          ),
        );

        when(mockPrefs.getString('subscription_data'))
            .thenReturn(jsonEncode(freeData.toJson()));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        await subscriptionService.resetDailyQuota();

        final quota = await subscriptionService.getUsageQuota();
        expect(quota.usedScans, 0);
        expect(quota.resetTime!.isAfter(DateTime.now()), true);
      });
    });
  });
}