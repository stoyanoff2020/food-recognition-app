import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:food_recognition_app/screens/settings/settings_screen.dart';
import 'package:food_recognition_app/services/subscription_service.dart';
import 'package:food_recognition_app/models/subscription.dart';
import 'package:food_recognition_app/providers/app_state_provider.dart';

// Mock implementations
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
  group('SettingsScreen', () {
    testWidgets('displays settings screen with basic structure', (WidgetTester tester) async {
      // Arrange
      final mockSubscriptionService = MockSubscriptionService();
      final appStateProvider = AppStateProvider();

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubscriptionService>.value(value: mockSubscriptionService),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Subscription'), findsAtLeastNWidgets(1));
      expect(find.text('App Preferences'), findsOneWidget);
      expect(find.text('Privacy & Data'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('shows help dialog when tapped', (WidgetTester tester) async {
      // Arrange
      final mockSubscriptionService = MockSubscriptionService();
      final appStateProvider = AppStateProvider();

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubscriptionService>.value(value: mockSubscriptionService),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final helpTile = find.text('Help & FAQ');
      await tester.tap(helpTile);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Help & FAQ'), findsWidgets);
      expect(find.text('How to use the app:'), findsOneWidget);
    });
  });
}