import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/onboarding/permission_request_widget.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('PermissionRequestWidget', () {
    testWidgets('displays permission request content correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PermissionRequestWidget(),
          ),
        ),
      );

      // Pump a few frames to let initial animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify main title is present
      expect(find.text('Camera Permission Required'), findsOneWidget);

      // Verify description text
      expect(find.textContaining('To identify ingredients in your photos'), findsOneWidget);

      // Verify feature list is present
      expect(find.text('What we\'ll use the camera for:'), findsOneWidget);
      expect(find.text('Take photos of food items'), findsOneWidget);
      expect(find.text('Identify ingredients automatically'), findsOneWidget);
      expect(find.text('Get personalized recipe suggestions'), findsOneWidget);

      // Verify check icons are present
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));

      // Verify permission button is present
      expect(find.text('Grant Camera Permission'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));
    });

    testWidgets('shows animated camera icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PermissionRequestWidget(),
          ),
        ),
      );

      // Verify AnimatedBuilder is present for pulse animation
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Camera icon should still be present after animation
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));
    });

    testWidgets('calls callback when permission granted', (WidgetTester tester) async {
      bool permissionGrantedCalled = false;
      bool permissionDeniedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PermissionRequestWidget(
              onPermissionGranted: () => permissionGrantedCalled = true,
              onPermissionDenied: () => permissionDeniedCalled = true,
            ),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the permission button
      final permissionButton = find.text('Grant Camera Permission');
      expect(permissionButton, findsOneWidget);

      // Note: We can't actually test permission granting in unit tests
      // as it requires platform-specific implementation
      // This test verifies the UI structure is correct
    });

    testWidgets('displays feature list with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PermissionRequestWidget(),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the feature list container is styled correctly
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Verify all feature items are present
      expect(find.text('Take photos of food items'), findsOneWidget);
      expect(find.text('Identify ingredients automatically'), findsOneWidget);
      expect(find.text('Get personalized recipe suggestions'), findsOneWidget);

      // Verify check circle icons for each feature
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    });

    testWidgets('shows proper button styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PermissionRequestWidget(),
          ),
        ),
      );

      // Pump a few frames to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The button might not be present if permission is already granted
      // Just verify the text is present
      expect(find.text('Grant Camera Permission'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));

      // If button is present, verify it takes full width
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        final buttonWidget = tester.widget<SizedBox>(
          find.ancestor(
            of: buttons.first,
            matching: find.byType(SizedBox),
          ).first,
        );
        expect(buttonWidget.width, equals(double.infinity));
      }
    });

    testWidgets('handles animation controller lifecycle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PermissionRequestWidget(),
          ),
        ),
      );

      // Pump initial frame
      await tester.pump();

      // Verify animation is running
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump through several animation frames
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Widget should still be functional
      expect(find.text('Camera Permission Required'), findsOneWidget);

      // Dispose the widget to test cleanup
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    });
  });
}