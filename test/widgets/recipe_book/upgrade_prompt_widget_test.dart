import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/widgets/recipe_book/upgrade_prompt_widget.dart';

void main() {
  group('UpgradePromptWidget', () {
    testWidgets('should display feature information', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptWidget(
              feature: 'Recipe Book',
              description: 'Save and organize your favorite recipes',
              requiredTier: 'Premium',
            ),
          ),
        ),
      );

      // Should show feature title
      expect(find.text('Recipe Book'), findsOneWidget);
      
      // Should show description
      expect(find.text('Save and organize your favorite recipes'), findsOneWidget);
      
      // Should show upgrade button
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      
      // Should show feature icon
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });

    testWidgets('should display benefits list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptWidget(
              feature: 'Recipe Book',
              description: 'Save and organize your favorite recipes',
              requiredTier: 'Premium',
            ),
          ),
        ),
      );

      // Should show benefits header
      expect(find.text('With Premium you get:'), findsOneWidget);
      
      // Should show benefit items
      expect(find.text('Save unlimited recipes'), findsOneWidget);
      expect(find.text('Organize with categories and tags'), findsOneWidget);
      expect(find.text('Advanced search and filtering'), findsOneWidget);
      expect(find.text('Share your favorite recipes'), findsOneWidget);
      expect(find.text('Access recipes offline'), findsOneWidget);
      
      // Should show benefit icons
      expect(find.byIcon(Icons.bookmark_add), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('should show learn more button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptWidget(
              feature: 'Recipe Book',
              description: 'Save and organize your favorite recipes',
              requiredTier: 'Premium',
            ),
          ),
        ),
      );

      expect(find.text('Learn more about subscription plans'), findsOneWidget);
    });

    testWidgets('should show feature details dialog when learn more is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptWidget(
              feature: 'Recipe Book',
              description: 'Save and organize your favorite recipes',
              requiredTier: 'Premium',
            ),
          ),
        ),
      );

      // Tap learn more button
      await tester.tap(find.text('Learn more about subscription plans'));
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.text('Subscription Plans'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
      
      // Should show recommended badge for Premium
      expect(find.text('RECOMMENDED'), findsOneWidget);
    });

    testWidgets('should show different required tier', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptWidget(
              feature: 'Meal Planning',
              description: 'Plan your meals and track nutrition',
              requiredTier: 'Professional',
            ),
          ),
        ),
      );

      // Should show Professional tier
      expect(find.text('With Professional you get:'), findsOneWidget);
      expect(find.text('Upgrade to Professional'), findsOneWidget);
    });

    testWidgets('should close dialog when close button is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptWidget(
              feature: 'Recipe Book',
              description: 'Save and organize your favorite recipes',
              requiredTier: 'Premium',
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Learn more about subscription plans'));
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Subscription Plans'), findsNothing);
    });
  });
}