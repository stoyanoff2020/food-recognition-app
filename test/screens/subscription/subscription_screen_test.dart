import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:food_recognition_app/screens/subscription/subscription_screen.dart';
import 'package:food_recognition_app/services/subscription_service.dart';
import 'package:food_recognition_app/models/subscription.dart';

// Mock implementation
class MockSubscriptionService implements SubscriptionService {
  @override
  Future<SubscriptionTier> getCurrentSubscription() async {
    return SubscriptionTier.free;
  }

  @override
  Future<UsageQuota> getUsageQuota() async {
    return const UsageQuota(
      dailyScans: 1,
      usedScans: 0,
      adWatchesAvailable: 3,
      historyDays: 7,
    );
  }

  @override
  Future<bool> hasFeatureAccess(FeatureType feature) async => false;

  @override
  Future<bool> upgradeSubscription(SubscriptionTierType tier) async => true;

  @override
  Future<bool> cancelSubscription() async => true;

  @override
  Future<void> incrementUsage(UsageType type) async {}

  @override
  Future<bool> canPerformAction(ActionType action) async => true;

  @override
  Future<void> resetDailyQuota() async {}

  @override
  Future<List<UsageRecord>> getUsageHistory() async => [];

  @override
  Future<void> watchAd() async {}

  @override
  Future<bool> needsQuotaReset() async => false;

  @override
  Stream<SubscriptionData> get subscriptionStream => Stream.empty();
}

void main() {
  group('SubscriptionScreen', () {
    Widget createTestWidget() {
      return Provider<SubscriptionService>.value(
        value: MockSubscriptionService(),
        child: const MaterialApp(
          home: SubscriptionScreen(),
        ),
      );
    }

    testWidgets('displays subscription screen with all sections', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Current Plan'), findsOneWidget);
      expect(find.text('Available Plans'), findsOneWidget);
      expect(find.text('Feature Comparison'), findsOneWidget);
    });

    testWidgets('displays subscription tiers', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Free'), findsWidgets);
      expect(find.text('Premium'), findsWidgets);
      expect(find.text('Professional'), findsWidgets);
    });
  });
}