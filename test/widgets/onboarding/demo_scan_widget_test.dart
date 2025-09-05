import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/onboarding/demo_scan_widget.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('DemoScanWidget', () {
    testWidgets('displays demo scan content correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DemoScanWidget(),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify main title and description
      expect(find.text('Ready to Try It Out?'), findsOneWidget);
      expect(find.textContaining('Take your first photo to see the magic happen'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Take Demo Photo'), findsOneWidget);
      expect(find.text('Skip Demo'), findsOneWidget);

      // Verify camera icon is present (might be multiple due to buttons)
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));

      // Verify food emojis are present
      expect(find.text('🍎'), findsOneWidget);
      expect(find.text('🥕'), findsOneWidget);
      expect(find.text('🧄'), findsOneWidget);
    });

    testWidgets('displays tips section correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DemoScanWidget(),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify tips section title
      expect(find.text('Tips for Better Results'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);

      // Verify all tips are present
      expect(find.text('Use good lighting for best results'), findsOneWidget);
      expect(find.text('Focus on the food items clearly'), findsOneWidget);
      expect(find.text('Hold the camera steady'), findsOneWidget);

      // Verify tip icons
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });

    testWidgets('calls onDemoScan callback when demo button tapped', (WidgetTester tester) async {
      bool demoScanCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DemoScanWidget(
              onDemoScan: () => demoScanCalled = true,
            ),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap the demo scan button
      final demoButton = find.text('Take Demo Photo');
      expect(demoButton, findsOneWidget);

      await tester.tap(demoButton);
      await tester.pump();

      expect(demoScanCalled, isTrue);
    });

    testWidgets('calls onSkipDemo callback when skip button tapped', (WidgetTester tester) async {
      bool skipDemoCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DemoScanWidget(
              onSkipDemo: () => skipDemoCalled = true,
            ),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap the skip button
      final skipButton = find.text('Skip Demo');
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pump();

      expect(skipDemoCalled, isTrue);
    });

    testWidgets('displays animated demo illustration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DemoScanWidget(),
          ),
        ),
      );

      // Verify animation builders are present
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump initial frame
      await tester.pump();

      // Verify camera icon is present (there might be multiple due to buttons)
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));

      // Pump through animation
      await tester.pump(const Duration(milliseconds: 500));

      // Verify floating emojis are still present after animation
      expect(find.text('🍎'), findsOneWidget);
      expect(find.text('🥕'), findsOneWidget);
      expect(find.text('🧄'), findsOneWidget);
    });

    testWidgets('has proper button styling and layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DemoScanWidget(),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify button texts are present
      expect(find.text('Take Demo Photo'), findsOneWidget);
      expect(find.text('Skip Demo'), findsOneWidget);

      // Verify buttons have icons
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.skip_next), findsOneWidget);

      // Verify SizedBox widgets are present (for button layout)
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('handles TweenAnimationBuilder for floating emojis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DemoScanWidget(),
          ),
        ),
      );

      // Find TweenAnimationBuilder widgets (for floating emojis)
      expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);

      // Pump through animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Emojis should still be present after animation
      expect(find.text('🍎'), findsOneWidget);
      expect(find.text('🥕'), findsOneWidget);
      expect(find.text('🧄'), findsOneWidget);
    });

    testWidgets('handles animation controller lifecycle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DemoScanWidget(),
          ),
        ),
      );

      // Pump initial frame
      await tester.pump();

      // Verify animations are running
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump through several animation cycles
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Widget should still be functional
      expect(find.text('Ready to Try It Out?'), findsOneWidget);

      // Dispose the widget to test cleanup
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    });
  });
}