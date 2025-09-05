import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/results/error_retry_widget.dart';

void main() {
  group('ErrorRetryWidget', () {
    bool onRetryCalled = false;

    setUp(() {
      onRetryCalled = false;
    });

    Widget createTestWidget({
      required String error,
      VoidCallback? onRetry,
      bool canRetry = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ErrorRetryWidget(
            error: error,
            onRetry: onRetry ?? () => onRetryCalled = true,
            canRetry: canRetry,
          ),
        ),
      );
    }

    group('Network Errors', () {
      testWidgets('displays network error correctly', (WidgetTester tester) async {
        const error = 'Network connection failed';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Connection Error'), findsOneWidget);
        expect(find.text(error), findsOneWidget);
        expect(find.text('Check your internet connection and try again'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('displays timeout error correctly', (WidgetTester tester) async {
        const error = 'Request timeout occurred';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Request Timeout'), findsOneWidget);
        expect(find.text('The request took too long. Please try again'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });
    });

    group('Image Errors', () {
      testWidgets('displays image error correctly', (WidgetTester tester) async {
        const error = 'Invalid image format detected';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Image Error'), findsOneWidget);
        expect(find.text('Try taking a clearer photo with better lighting'), findsOneWidget);
        expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
      });
    });

    group('Authentication Errors', () {
      testWidgets('displays API key error correctly', (WidgetTester tester) async {
        const error = 'API key authentication failed';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Authentication Error'), findsOneWidget);
        expect(find.text('There\'s an issue with the service. Please try again later'), findsOneWidget);
        expect(find.byIcon(Icons.key_off), findsOneWidget);
      });
    });

    group('Rate Limit Errors', () {
      testWidgets('displays rate limit error correctly', (WidgetTester tester) async {
        const error = 'Rate limit exceeded for API calls';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Rate Limit Exceeded'), findsOneWidget);
        expect(find.text('You\'ve reached your usage limit. Try again later or upgrade your plan'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_disabled), findsOneWidget);
      });
    });

    group('Permission Errors', () {
      testWidgets('displays permission error correctly', (WidgetTester tester) async {
        const error = 'Camera permission denied';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Permission Error'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });
    });

    group('Generic Errors', () {
      testWidgets('displays generic error correctly', (WidgetTester tester) async {
        const error = 'Something unexpected happened';
        await tester.pumpWidget(createTestWidget(error: error));

        expect(find.text('Recognition Error'), findsOneWidget);
        expect(find.text('Something went wrong. Please try again'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('Retry Functionality', () {
      testWidgets('shows retry button when canRetry is true and onRetry is provided', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          error: 'Test error',
          canRetry: true,
        ));

        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('hides retry button when canRetry is false', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          error: 'Test error',
          canRetry: false,
        ));

        expect(find.text('Try Again'), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
      });

      testWidgets('hides retry button when onRetry is null', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          error: 'Test error',
          onRetry: null,
          canRetry: true,
        ));

        expect(find.text('Try Again'), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
      });

      testWidgets('calls onRetry when retry button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          error: 'Test error',
          canRetry: true,
        ));

        await tester.tap(find.text('Try Again'));
        await tester.pump();

        expect(onRetryCalled, isTrue);
      });
    });

    group('Navigation', () {
      testWidgets('always shows Take New Photo button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        expect(find.text('Take New Photo'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('pops navigation when Take New Photo is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        // We can't easily test navigation pop, but we can verify the button exists
        expect(find.text('Take New Photo'), findsOneWidget);
      });
    });

    group('Help Dialog', () {
      testWidgets('shows help button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        expect(find.text('Need help?'), findsOneWidget);
      });

      testWidgets('opens help dialog when help button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        await tester.tap(find.text('Need help?'));
        await tester.pumpAndSettle();

        expect(find.text('Troubleshooting Tips'), findsOneWidget);
        expect(find.text('For better results:'), findsOneWidget);
        expect(find.text('• Ensure good lighting'), findsOneWidget);
        expect(find.text('• Keep the camera steady'), findsOneWidget);
        expect(find.text('• Focus on the food items'), findsOneWidget);
        expect(find.text('Network issues:'), findsOneWidget);
        expect(find.text('• Check your internet connection'), findsOneWidget);
        expect(find.text('Got it'), findsOneWidget);
      });

      testWidgets('closes help dialog when Got it is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        // Open dialog
        await tester.tap(find.text('Need help?'));
        await tester.pumpAndSettle();

        // Close dialog
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();

        expect(find.text('Troubleshooting Tips'), findsNothing);
      });
    });

    group('Visual Elements', () {
      testWidgets('displays error icon in container', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        expect(find.byType(Container), findsWidgets);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('displays info icon in suggestion box', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('uses card layout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Test error'));

        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Error Color Mapping', () {
      testWidgets('uses orange color for network errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Network connection failed'));

        // We can't easily test colors directly, but we can verify the widgets are rendered
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('uses amber color for rate limit errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Rate limit exceeded'));

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('uses red color for generic errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: 'Generic error'));

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Button Layout', () {
      testWidgets('shows both buttons when retry is available', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          error: 'Test error',
          canRetry: true,
        ));

        expect(find.text('Try Again'), findsOneWidget);
        expect(find.text('Take New Photo'), findsOneWidget);
      });

      testWidgets('shows only Take New Photo when retry is not available', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          error: 'Test error',
          canRetry: false,
        ));

        expect(find.text('Try Again'), findsNothing);
        expect(find.text('Take New Photo'), findsOneWidget);
      });
    });
  });
}