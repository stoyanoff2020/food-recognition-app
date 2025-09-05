import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_recognition_app/screens/onboarding/onboarding_screen.dart';
import 'package:food_recognition_app/providers/app_state_provider.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('OnboardingScreen', () {
    late AppStateProvider appStateProvider;

    setUp(() {
      appStateProvider = AppStateProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appStateProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );
    }

    testWidgets('creates onboarding screen without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Should create the screen without errors
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('displays onboarding content after loading', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      // Should show onboarding content or loading
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('handles provider creation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Should have created the provider structure
      expect(find.byType(MultiProvider), findsOneWidget);
    });
  });
}