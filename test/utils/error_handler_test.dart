import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
    });

    group('AppError', () {
      test('should create AppError with timestamp', () {
        final error = AppError.withTimestamp(
          type: ErrorType.network,
          message: 'Test error',
          recoverable: true,
        );

        expect(error.type, ErrorType.network);
        expect(error.message, 'Test error');
        expect(error.recoverable, true);
        expect(error.timestamp, isNotNull);
      });

      test('should have correct toString representation', () {
        final error = AppError.withTimestamp(
          type: ErrorType.camera,
          message: 'Camera error',
        );

        expect(error.toString(), contains('AppError: Camera error'));
        expect(error.toString(), contains('Type: ErrorType.camera'));
      });
    });

    group('CameraError', () {
      test('should create permission denied error', () {
        final error = CameraError.permissionDenied();

        expect(error.type, ErrorType.camera);
        expect(error.message, contains('Camera permission is required'));
        expect(error.recoverable, false);
      });

      test('should create hardware unavailable error', () {
        final error = CameraError.hardwareUnavailable();

        expect(error.type, ErrorType.camera);
        expect(error.message, contains('Camera is not available'));
        expect(error.recoverable, false);
      });

      test('should create capture failure error', () {
        final error = CameraError.captureFailure('Test details');

        expect(error.type, ErrorType.camera);
        expect(error.message, contains('Failed to capture photo'));
        expect(error.recoverable, true);
        expect(error.technicalDetails, 'Test details');
      });
    });

    group('NetworkError', () {
      test('should create no connection error', () {
        final error = NetworkError.noConnection();

        expect(error.type, ErrorType.network);
        expect(error.message, contains('No internet connection'));
        expect(error.recoverable, true);
      });

      test('should create timeout error', () {
        final error = NetworkError.timeout();

        expect(error.type, ErrorType.network);
        expect(error.message, contains('Request timed out'));
        expect(error.recoverable, true);
      });

      test('should create server error with status code', () {
        final error = NetworkError.serverError(500);

        expect(error.type, ErrorType.network);
        expect(error.message, contains('Server error occurred'));
        expect(error.technicalDetails, 'Status code: 500');
      });

      test('should create rate limited error', () {
        final error = NetworkError.rateLimited();

        expect(error.type, ErrorType.network);
        expect(error.message, contains('Too many requests'));
        expect(error.recoverable, true);
      });
    });

    group('ProcessingError', () {
      test('should create invalid image error', () {
        final error = ProcessingError.invalidImage();

        expect(error.type, ErrorType.processing);
        expect(error.message, contains('Invalid image format'));
        expect(error.recoverable, true);
      });

      test('should create no food detected error', () {
        final error = ProcessingError.noFoodDetected();

        expect(error.type, ErrorType.processing);
        expect(error.message, contains('No food items detected'));
        expect(error.recoverable, true);
      });

      test('should create service failure error', () {
        final error = ProcessingError.serviceFailure('API error');

        expect(error.type, ErrorType.processing);
        expect(error.message, contains('Failed to process image'));
        expect(error.technicalDetails, 'API error');
      });
    });

    group('StorageError', () {
      test('should create write failure error', () {
        final error = StorageError.writeFailure();

        expect(error.type, ErrorType.storage);
        expect(error.message, contains('Failed to save data'));
        expect(error.recoverable, true);
      });

      test('should create read failure error', () {
        final error = StorageError.readFailure();

        expect(error.type, ErrorType.storage);
        expect(error.message, contains('Failed to load data'));
        expect(error.recoverable, true);
      });

      test('should create corrupted data error', () {
        final error = StorageError.corruptedData();

        expect(error.type, ErrorType.storage);
        expect(error.message, contains('Data corruption detected'));
        expect(error.recoverable, false);
      });
    });

    group('SubscriptionError', () {
      test('should create payment failed error', () {
        final error = SubscriptionError.paymentFailed();

        expect(error.type, ErrorType.subscription);
        expect(error.message, contains('Payment processing failed'));
        expect(error.recoverable, true);
      });

      test('should create quota exceeded error', () {
        final error = SubscriptionError.quotaExceeded();

        expect(error.type, ErrorType.subscription);
        expect(error.message, contains('Daily scan limit reached'));
        expect(error.recoverable, false);
      });

      test('should create feature access denied error', () {
        final error = SubscriptionError.featureAccessDenied();

        expect(error.type, ErrorType.subscription);
        expect(error.message, contains('requires a premium subscription'));
        expect(error.recoverable, false);
      });
    });

    group('PermissionError', () {
      test('should create camera permission denied error', () {
        final error = PermissionError.cameraPermissionDenied();

        expect(error.type, ErrorType.permission);
        expect(error.message, contains('Camera permission is required'));
        expect(error.recoverable, false);
      });
    });

    group('handleError', () {
      test('should handle AppError correctly', () {
        final error = NetworkError.timeout();
        final message = errorHandler.handleError(error);

        expect(message, error.message);
      });

      test('should handle PlatformException correctly', () {
        final error = PlatformException(
          code: 'camera_access_denied',
          message: 'Camera access denied',
        );
        final message = errorHandler.handleError(error);

        expect(message, contains('Camera permission denied'));
      });

      test('should handle SocketException correctly', () {
        final error = const SocketException('Connection failed');
        final message = errorHandler.handleError(error);

        expect(message, contains('Network connection failed'));
      });

      test('should handle HttpException correctly', () {
        final error = const HttpException('HTTP error');
        final message = errorHandler.handleError(error);

        expect(message, contains('Network request failed'));
      });

      test('should handle generic error correctly', () {
        final error = Exception('Generic error');
        final message = errorHandler.handleError(error);

        expect(message, contains('An unexpected error occurred'));
      });
    });

    group('createAppError', () {
      test('should return AppError as-is', () {
        final originalError = NetworkError.timeout();
        final result = errorHandler.createAppError(originalError);

        expect(result, same(originalError));
      });

      test('should convert PlatformException to CameraError', () {
        final platformError = PlatformException(
          code: 'camera_access_denied',
          message: 'Access denied',
        );
        final result = errorHandler.createAppError(platformError);

        expect(result, isA<CameraError>());
        expect(result.message, contains('Camera permission is required'));
      });

      test('should convert SocketException to NetworkError', () {
        final socketError = const SocketException('Connection failed');
        final result = errorHandler.createAppError(socketError);

        expect(result, isA<NetworkError>());
        expect(result.message, contains('No internet connection'));
      });

      test('should convert HttpException to NetworkError', () {
        final httpError = const HttpException('HTTP error');
        final result = errorHandler.createAppError(httpError);

        expect(result, isA<NetworkError>());
        expect(result.message, contains('Server error occurred'));
      });

      test('should convert unknown error to generic AppError', () {
        final unknownError = Exception('Unknown error');
        final result = errorHandler.createAppError(unknownError);

        expect(result.type, ErrorType.unknown);
        expect(result.message, contains('An unexpected error occurred'));
      });
    });

    group('isRecoverable', () {
      test('should return correct recoverability for AppError', () {
        final recoverableError = NetworkError.timeout();
        final nonRecoverableError = CameraError.permissionDenied();

        expect(errorHandler.isRecoverable(recoverableError), true);
        expect(errorHandler.isRecoverable(nonRecoverableError), false);
      });

      test('should return true for non-AppError by default', () {
        final genericError = Exception('Generic error');
        expect(errorHandler.isRecoverable(genericError), true);
      });
    });

    group('getRetryAction', () {
      test('should return retry action for AppError with retry action', () {
        bool retryActionCalled = false;
        final error = AppError.withTimestamp(
          type: ErrorType.network,
          message: 'Test error',
          retryAction: () => retryActionCalled = true,
        );

        final retryAction = errorHandler.getRetryAction(error);
        expect(retryAction, isNotNull);

        retryAction!();
        expect(retryActionCalled, true);
      });

      test('should return null for AppError without retry action', () {
        final error = NetworkError.timeout();
        final retryAction = errorHandler.getRetryAction(error);

        expect(retryAction, isNull);
      });

      test('should return null for non-AppError', () {
        final error = Exception('Generic error');
        final retryAction = errorHandler.getRetryAction(error);

        expect(retryAction, isNull);
      });
    });
  });
}