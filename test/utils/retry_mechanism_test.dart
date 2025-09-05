import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/utils/error_handler.dart';
import 'package:food_recognition_app/utils/retry_mechanism.dart';

void main() {
  group('RetryMechanism', () {
    late RetryMechanism retryMechanism;

    setUp(() {
      retryMechanism = RetryMechanism();
    });

    group('RetryConfig', () {
      test('should have default values', () {
        const config = RetryConfig();
        
        expect(config.maxAttempts, 3);
        expect(config.initialDelay, const Duration(seconds: 1));
        expect(config.maxDelay, const Duration(seconds: 30));
        expect(config.backoffMultiplier, 2.0);
        expect(config.exponentialBackoff, true);
        expect(config.retryableExceptions, isEmpty);
      });

      test('should have network configuration', () {
        const config = RetryConfig.network;
        
        expect(config.maxAttempts, 3);
        expect(config.initialDelay, const Duration(seconds: 2));
        expect(config.maxDelay, const Duration(seconds: 10));
        expect(config.retryableExceptions, contains(NetworkError));
      });

      test('should have processing configuration', () {
        const config = RetryConfig.processing;
        
        expect(config.maxAttempts, 2);
        expect(config.initialDelay, const Duration(seconds: 1));
        expect(config.retryableExceptions, contains(ProcessingError));
      });

      test('should have critical configuration', () {
        const config = RetryConfig.critical;
        
        expect(config.maxAttempts, 1);
        expect(config.exponentialBackoff, false);
      });
    });

    group('RetryResult', () {
      test('should create successful result', () {
        final result = RetryResult.success('test', 2, const Duration(seconds: 1));
        
        expect(result.succeeded, true);
        expect(result.result, 'test');
        expect(result.attemptCount, 2);
        expect(result.totalDuration, const Duration(seconds: 1));
        expect(result.lastError, isNull);
      });

      test('should create failed result', () {
        final error = Exception('test error');
        final result = RetryResult.failure(error, 3, const Duration(seconds: 2));
        
        expect(result.succeeded, false);
        expect(result.result, isNull);
        expect(result.attemptCount, 3);
        expect(result.totalDuration, const Duration(seconds: 2));
        expect(result.lastError, error);
      });
    });

    group('execute', () {
      test('should succeed on first attempt', () async {
        int callCount = 0;
        
        final result = await retryMechanism.execute(() async {
          callCount++;
          return 'success';
        });
        
        expect(result.succeeded, true);
        expect(result.result, 'success');
        expect(result.attemptCount, 1);
        expect(callCount, 1);
      });

      test('should retry on failure and eventually succeed', () async {
        int callCount = 0;
        
        final result = await retryMechanism.execute(() async {
          callCount++;
          if (callCount < 3) {
            throw NetworkError.timeout();
          }
          return 'success';
        }, config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ));
        
        expect(result.succeeded, true);
        expect(result.result, 'success');
        expect(result.attemptCount, 3);
        expect(callCount, 3);
      });

      test('should fail after max attempts', () async {
        int callCount = 0;
        
        final result = await retryMechanism.execute(() async {
          callCount++;
          throw NetworkError.timeout();
        }, config: const RetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(milliseconds: 10),
        ));
        
        expect(result.succeeded, false);
        expect(result.attemptCount, 2);
        expect(result.lastError, isA<NetworkError>());
        expect(callCount, 2);
      });

      test('should not retry non-retryable errors', () async {
        int callCount = 0;
        
        final result = await retryMechanism.execute(() async {
          callCount++;
          throw CameraError.permissionDenied();
        }, config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ));
        
        expect(result.succeeded, false);
        expect(result.attemptCount, 1);
        expect(callCount, 1);
      });

      test('should use custom shouldRetry function', () async {
        int callCount = 0;
        
        final result = await retryMechanism.execute(() async {
          callCount++;
          throw Exception('custom error');
        }, 
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        shouldRetry: (error) => error.toString().contains('custom'));
        
        expect(result.succeeded, false);
        expect(result.attemptCount, 3);
        expect(callCount, 3);
      });

      test('should call onRetry callback', () async {
        int retryCallCount = 0;
        final List<int> retryAttempts = [];
        
        await retryMechanism.execute(() async {
          throw NetworkError.timeout();
        }, 
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        onRetry: (attempt, error) {
          retryCallCount++;
          retryAttempts.add(attempt);
        });
        
        expect(retryCallCount, 2); // Called for attempts 1 and 2, not 3
        expect(retryAttempts, [1, 2]);
      });
    });

    group('executeSimple', () {
      test('should return result on success', () async {
        final result = await retryMechanism.executeSimple(() async {
          return 'success';
        });
        
        expect(result, 'success');
      });

      test('should throw last error on failure', () async {
        expect(() => retryMechanism.executeSimple(() async {
          throw NetworkError.timeout();
        }, config: const RetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(milliseconds: 10),
        )), throwsA(isA<NetworkError>()));
      });
    });

    group('RetryCapable mixin', () {
      test('should provide network retry functionality', () async {
        final testService = TestRetryCapableService();
        
        int callCount = 0;
        final result = await testService.retryNetworkOperation(() async {
          callCount++;
          if (callCount < 2) {
            throw NetworkError.timeout();
          }
          return 'success';
        });
        
        expect(result, 'success');
        expect(callCount, 2);
      });

      test('should provide processing retry functionality', () async {
        final testService = TestRetryCapableService();
        
        int callCount = 0;
        final result = await testService.retryProcessingOperation(() async {
          callCount++;
          if (callCount < 2) {
            throw ProcessingError.serviceFailure('test');
          }
          return 'success';
        });
        
        expect(result, 'success');
        expect(callCount, 2);
      });

      test('should provide custom retry functionality', () async {
        final testService = TestRetryCapableService();
        
        final result = await testService.retryOperation(() async {
          return 'success';
        }, config: const RetryConfig(maxAttempts: 1));
        
        expect(result, 'success');
      });

      test('should provide retry with result functionality', () async {
        final testService = TestRetryCapableService();
        
        final result = await testService.retryOperationWithResult(() async {
          return 'success';
        });
        
        expect(result.succeeded, true);
        expect(result.result, 'success');
      });
    });
  });
}

// Test class that uses RetryCapable mixin
class TestRetryCapableService with RetryCapable {
  // Mixin methods are automatically available
}