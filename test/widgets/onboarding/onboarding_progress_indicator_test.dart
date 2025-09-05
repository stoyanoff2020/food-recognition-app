import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('OnboardingProgressIndicator', () {
    testWidgets('displays correct progress bar and step indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 2,
              totalSteps: 5,
            ),
          ),
        ),
      );

      // Verify step counter text
      expect(find.text('3 of 5'), findsOneWidget);

      // Verify progress bar is present
      expect(find.byType(FractionallySizedBox), findsOneWidget);

      // Verify step indicators are present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows custom progress when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 1,
              totalSteps: 4,
              progress: 0.75,
            ),
          ),
        ),
      );

      // Verify step counter still shows current step
      expect(find.text('2 of 4'), findsOneWidget);

      // Progress bar should use custom progress value
      final progressBar = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(progressBar.widthFactor, equals(0.75));
    });

    testWidgets('handles edge cases correctly', (WidgetTester tester) async {
      // Test first step
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 0,
              totalSteps: 3,
            ),
          ),
        ),
      );

      expect(find.text('1 of 3'), findsOneWidget);

      // Test last step
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 2,
              totalSteps: 3,
            ),
          ),
        ),
      );

      expect(find.text('3 of 3'), findsOneWidget);
    });

    testWidgets('animates step indicators correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 1,
              totalSteps: 3,
            ),
          ),
        ),
      );

      // Find all animated containers (step indicators)
      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsNWidgets(3));

      // Pump animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}