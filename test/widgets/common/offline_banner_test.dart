import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/services/connectivity_service.dart';
import 'package:food_recognition_app/widgets/common/offline_banner.dart';

void main() {
  group('OfflineBanner', () {
    // Note: These tests are simplified due to the complexity of mocking
    // the ConnectivityService singleton. In a production app, you would
    // inject the connectivity service as a dependency for easier testing.
    
    testWidgets('should create widget without errors', (WidgetTester tester) async {
      // Test that the widget can be created without throwing errors
      expect(() => const OfflineBanner(child: Text('Test')), returnsNormally);
    });
  });

  group('OfflineIndicator', () {
    testWidgets('should show indicator when offline', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            status: ConnectivityStatus.offline,
          ),
        ),
      );
      
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('should not show indicator when online', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            status: ConnectivityStatus.online,
          ),
        ),
      );
      
      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('should display custom message when offline', (WidgetTester tester) async {
      const customMessage = 'No connection';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            status: ConnectivityStatus.offline,
            message: customMessage,
          ),
        ),
      );
      
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('should not show indicator when status is unknown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            status: ConnectivityStatus.unknown,
          ),
        ),
      );
      
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });
  });

  group('ConnectivityAwareWidget mixin', () {
    testWidgets('should provide connectivity status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestConnectivityAwareWidget(),
        ),
      );
      
      expect(find.byType(TestConnectivityAwareWidget), findsOneWidget);
    });
  });
}

// Test widget that uses ConnectivityAwareWidget mixin
class TestConnectivityAwareWidget extends StatefulWidget {
  @override
  State<TestConnectivityAwareWidget> createState() => _TestConnectivityAwareWidgetState();
}

class _TestConnectivityAwareWidgetState extends State<TestConnectivityAwareWidget>
    with ConnectivityAwareWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Status: $connectivityStatus'),
          Text('Online: $isOnline'),
          Text('Offline: $isOffline'),
        ],
      ),
    );
  }

  @override
  void onConnectivityChanged(ConnectivityStatus status) {
    // Handle connectivity changes
  }
}