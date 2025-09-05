import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/onboarding/feature_demo_widget.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('FeatureDemoWidget', () {
    testWidgets('displays camera demo correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeatureDemoWidget(
              demoType: 'camera_demo',
              title: 'Camera Demo',
              description: 'Test camera demo',
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify camera icon is present
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // Verify food item emojis are present
      expect(find.text('🍎'), findsOneWidget);
      expect(find.text('🥕'), findsOneWidget);
      expect(find.text('🧄'), findsOneWidget);

      // Verify confidence scores are displayed
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);

      // Verify description text
      expect(find.text('AI identifies ingredients with confidence scores'), findsOneWidget);
    });

    testWidgets('displays recipe demo correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeatureDemoWidget(
              demoType: 'recipe_demo',
              title: 'Recipe Demo',
              description: 'Test recipe demo',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify recipe book icon is present
      expect(find.byIcon(Icons.menu_book), findsOneWidget);

      // Verify recipe cards are present
      expect(find.text('Apple Cinnamon Oatmeal'), findsOneWidget);
      expect(find.text('Roasted Vegetable Medley'), findsOneWidget);
      expect(find.text('Garlic Herb Pasta'), findsOneWidget);

      // Verify cooking times are displayed
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);

      // Verify description text
      expect(find.text('Get personalized recipes ranked by ingredient match'), findsOneWidget);
    });

    testWidgets('displays customize demo correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeatureDemoWidget(
              demoType: 'customize_demo',
              title: 'Customize Demo',
              description: 'Test customize demo',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify add icon is present
      expect(find.byIcon(Icons.add_circle), findsOneWidget);

      // Verify ingredient chips are present
      expect(find.text('Detected: Apple'), findsOneWidget);
      expect(find.text('Detected: Carrot'), findsOneWidget);
      expect(find.text('+ Add: Onion'), findsOneWidget);
      expect(find.text('+ Add: Chicken'), findsOneWidget);

      // Verify arrow and result text
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text('More recipe options!'), findsOneWidget);
      expect(find.text('Add your own ingredients for better matches'), findsOneWidget);
    });

    testWidgets('displays default demo for unknown type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeatureDemoWidget(
              demoType: 'unknown_demo',
              title: 'Unknown Demo',
              description: 'Test unknown demo type',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify lightbulb icon is present (default)
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);

      // Verify title and description are displayed
      expect(find.text('Unknown Demo'), findsOneWidget);
      expect(find.text('Test unknown demo type'), findsOneWidget);
    });

    testWidgets('animates correctly on initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeatureDemoWidget(
              demoType: 'camera_demo',
              title: 'Camera Demo',
              description: 'Test camera demo',
            ),
          ),
        ),
      );

      // Verify initial state (should be animating)
      expect(find.byType(AnimatedBuilder), findsWidgets);
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsWidgets);

      // Pump through animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should be complete
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('handles TweenAnimationBuilder correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeatureDemoWidget(
              demoType: 'camera_demo',
              title: 'Camera Demo',
              description: 'Test camera demo',
            ),
          ),
        ),
      );

      // Find TweenAnimationBuilder widgets
      expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);

      // Pump through the animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify final state
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });
}