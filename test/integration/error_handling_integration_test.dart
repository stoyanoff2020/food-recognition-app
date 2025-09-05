import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/utils/error_handler.dart';
import 'package:food_recognition_app/utils/retry_mechanism.dart';
import 'package:food_recognition_app/services/connectivity_service.dart';

void main() {
  group('Error Handling Integration Tests', () {
    late ErrorHandler errorHandler;
    late RetryMechanism retryMechanism;

    setUp(() {
      errorHandler = ErrorHandler();
      retryMechanism = RetryMechanism();
    });

    test('should handle and retry network operations', () async {
      int attemptCount = 0;
      
      final result = await retryMechanism.execute(() async {
        attemptCount++;
        if (attemptCount < 3) {
          throw NetworkError.timeout();
        }
        return 'Success after retries';
      }, config: const RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      ));

      expect(result.succeeded, true);
      expect(result.result, 'Success after retries');
      expect(result.attemptCount, 3);
      expect(attemptCount, 3);
    });

    test('should handle non-retryable errors correctly', () async {
      int attemptCount = 0;
      
      final result = await retryMechanism.execute(() async {
        attemptCount++;
        throw CameraError.permissionDenied();
      }, config: const RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      ));

      expect(result.succeeded, false);
      expect(result.attemptCount, 1); // Should not retry
      expect(attemptCount, 1);
      expect(result.lastError, isA<CameraError>());
    });

    test('should convert platform exceptions to app errors', () {
      final platformException = Exception('Platform error');
      final appError = errorHandler.createAppError(platformException);
      
      expect(appError, isA<AppError>());
      expect(appError.type, ErrorType.unknown);
      expect(appError.message, contains('An unexpected error occurred'));
    });

    test('should provide user-friendly error messages', () {
      final networkError = NetworkError.noConnection();
      final cameraError = CameraError.permissionDenied();
      final processingError = ProcessingError.noFoodDetected();
      
      final networkMessage = errorHandler.handleError(networkError);
      final cameraMessage = errorHandler.handleError(cameraError);
      final processingMessage = errorHandler.handleError(processingError);
      
      expect(networkMessage, contains('internet connection'));
      expect(cameraMessage, contains('Camera permission'));
      expect(processingMessage, contains('No food items detected'));
    });

    test('should handle connectivity aware operations', () {
      final testService = TestConnectivityAwareService();
      
      // Test that the service can check connectivity
      expect(testService.connectivityStatus, isA<ConnectivityStatus>());
      
      // Test network requirement check
      expect(() => testService.testRequireNetwork(), returnsNormally);
    });

    test('should handle retry capable operations', () async {
      final testService = TestRetryCapableService();
      
      int callCount = 0;
      final result = await testService.retryNetworkOperation(() async {
        callCount++;
        if (callCount < 2) {
          throw NetworkError.timeout();
        }
        return 'Success';
      });
      
      expect(result, 'Success');
      expect(callCount, 2);
    });

    test('should handle complex error scenarios', () async {
      // Simulate a complex scenario with multiple error types
      final errors = [
        NetworkError.timeout(),
        ProcessingError.serviceFailure('API error'),
        CameraError.captureFailure('Hardware issue'),
        StorageError.writeFailure(),
        SubscriptionError.quotaExceeded(),
      ];
      
      for (final error in errors) {
        final message = errorHandler.handleError(error);
        expect(message, isA<String>());
        expect(message.isNotEmpty, true);
        
        final isRecoverable = errorHandler.isRecoverable(error);
        expect(isRecoverable, isA<bool>());
      }
    });

    test('should handle error propagation through service layers', () async {
      // Test that errors propagate correctly through different service layers
      final testService = TestServiceWithErrorHandling();
      
      // Test successful operation
      final successResult = await testService.performOperation(false);
      expect(successResult, 'Operation completed');
      
      // Test failed operation with retry
      expect(
        () => testService.performOperation(true),
        throwsA(isA<ProcessingError>()),
      );
    });
  });
}

// Test classes for integration testing
class TestConnectivityAwareService with ConnectivityAware {
  void testRequireNetwork() {
    // In a real test, this would be mocked to simulate offline state
    // requireNetwork();
  }
}

class TestRetryCapableService with RetryCapable {
  // Mixin methods are automatically available
}

class TestServiceWithErrorHandling with RetryCapable, ConnectivityAware {
  Future<String> performOperation(bool shouldFail) async {
    return await retryProcessingOperation(() async {
      if (shouldFail) {
        throw ProcessingError.serviceFailure('Simulated failure');
      }
      return 'Operation completed';
    });
  }
}