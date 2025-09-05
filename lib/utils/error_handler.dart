import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enum defining different types of errors in the application
enum ErrorType {
  camera,
  network,
  processing,
  storage,
  subscription,
  onboarding,
  permission,
  unknown
}

/// Base class for all application errors
abstract class AppError implements Exception {
  final ErrorType type;
  final String message;
  final bool recoverable;
  final VoidCallback? retryAction;
  final String? technicalDetails;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.message,
    this.recoverable = true,
    this.retryAction,
    this.technicalDetails,
  }) : timestamp = DateTime.now();

  AppError._withTimestamp({
    required this.type,
    required this.message,
    this.recoverable = true,
    this.retryAction,
    this.technicalDetails,
    required this.timestamp,
  });

  factory AppError.withTimestamp({
    required ErrorType type,
    required String message,
    bool recoverable = true,
    VoidCallback? retryAction,
    String? technicalDetails,
  }) {
    return _AppErrorImpl._withTimestamp(
      type: type,
      message: message,
      recoverable: recoverable,
      retryAction: retryAction,
      technicalDetails: technicalDetails,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() => 'AppError: $message (Type: $type)';
}

class _AppErrorImpl extends AppError {
  _AppErrorImpl({
    required super.type,
    required super.message,
    super.recoverable,
    super.retryAction,
    super.technicalDetails,
  });

  _AppErrorImpl._withTimestamp({
    required super.type,
    required super.message,
    super.recoverable,
    super.retryAction,
    super.technicalDetails,
    required super.timestamp,
  }) : super._withTimestamp();
}

/// Camera-specific errors
class CameraError extends AppError {
  CameraError({
    required super.message,
    super.recoverable = true,
    super.retryAction,
    super.technicalDetails,
  }) : super(type: ErrorType.camera);

  factory CameraError.permissionDenied() => CameraError(
        message: 'Camera permission is required to scan food items',
        recoverable: false,
      );

  factory CameraError.hardwareUnavailable() => CameraError(
        message: 'Camera is not available on this device',
        recoverable: false,
      );

  factory CameraError.captureFailure([String? details]) => CameraError(
        message: 'Failed to capture photo. Please try again.',
        technicalDetails: details,
      );
}

/// Network-specific errors
class NetworkError extends AppError {
  NetworkError({
    required super.message,
    super.recoverable = true,
    super.retryAction,
    super.technicalDetails,
  }) : super(type: ErrorType.network);

  factory NetworkError.noConnection() => NetworkError(
        message: 'No internet connection. Please check your network settings.',
        recoverable: true,
      );

  factory NetworkError.timeout() => NetworkError(
        message: 'Request timed out. Please try again.',
        recoverable: true,
      );

  factory NetworkError.serverError([int? statusCode]) => NetworkError(
        message: 'Server error occurred. Please try again later.',
        technicalDetails: statusCode != null ? 'Status code: $statusCode' : null,
      );

  factory NetworkError.rateLimited() => NetworkError(
        message: 'Too many requests. Please wait a moment before trying again.',
        recoverable: true,
      );
}

/// Processing-specific errors
class ProcessingError extends AppError {
  ProcessingError({
    required super.message,
    super.recoverable = true,
    super.retryAction,
    super.technicalDetails,
  }) : super(type: ErrorType.processing);

  factory ProcessingError.invalidImage() => ProcessingError(
        message: 'Invalid image format. Please capture a new photo.',
        recoverable: true,
      );

  factory ProcessingError.noFoodDetected() => ProcessingError(
        message: 'No food items detected in the image. Please try a clearer photo.',
        recoverable: true,
      );

  factory ProcessingError.serviceFailure([String? details]) => ProcessingError(
        message: 'Failed to process image. Please try again.',
        technicalDetails: details,
      );
}

/// Storage-specific errors
class StorageError extends AppError {
  StorageError({
    required super.message,
    super.recoverable = true,
    super.retryAction,
    super.technicalDetails,
  }) : super(type: ErrorType.storage);

  factory StorageError.writeFailure() => StorageError(
        message: 'Failed to save data. Please try again.',
      );

  factory StorageError.readFailure() => StorageError(
        message: 'Failed to load data. Please restart the app.',
      );

  factory StorageError.corruptedData() => StorageError(
        message: 'Data corruption detected. App will reset to defaults.',
        recoverable: false,
      );
}

/// Subscription-specific errors
class SubscriptionError extends AppError {
  SubscriptionError({
    required super.message,
    super.recoverable = true,
    super.retryAction,
    super.technicalDetails,
  }) : super(type: ErrorType.subscription);

  factory SubscriptionError.paymentFailed() => SubscriptionError(
        message: 'Payment processing failed. Please check your payment method.',
        recoverable: true,
      );

  factory SubscriptionError.quotaExceeded() => SubscriptionError(
        message: 'Daily scan limit reached. Upgrade or watch an ad for more scans.',
        recoverable: false,
      );

  factory SubscriptionError.featureAccessDenied() => SubscriptionError(
        message: 'This feature requires a premium subscription.',
        recoverable: false,
      );
}

/// Permission-specific errors
class PermissionError extends AppError {
  PermissionError({
    required super.message,
    super.recoverable = false,
    super.retryAction,
    super.technicalDetails,
  }) : super(type: ErrorType.permission);

  factory PermissionError.cameraPermissionDenied() => PermissionError(
        message: 'Camera permission is required to use this feature.',
      );
}

/// Main error handler class
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Handle different types of errors and provide appropriate user feedback
  String handleError(dynamic error) {
    if (error is AppError) {
      return _handleAppError(error);
    }

    // Handle platform-specific errors
    if (error is PlatformException) {
      return _handlePlatformException(error);
    }

    if (error is SocketException) {
      return _handleSocketException(error);
    }

    if (error is HttpException) {
      return _handleHttpException(error);
    }

    // Generic error handling
    return _handleGenericError(error);
  }

  String _handleAppError(AppError error) {
    // Log error for debugging
    if (kDebugMode) {
      print('AppError: ${error.type} - ${error.message}');
      if (error.technicalDetails != null) {
        print('Technical details: ${error.technicalDetails}');
      }
    }

    return error.message;
  }

  String _handlePlatformException(PlatformException error) {
    switch (error.code) {
      case 'camera_access_denied':
        return 'Camera permission denied. Please enable camera access in settings.';
      case 'camera_not_available':
        return 'Camera is not available on this device.';
      default:
        return 'A system error occurred: ${error.message ?? 'Unknown error'}';
    }
  }

  String _handleSocketException(SocketException error) {
    return 'Network connection failed. Please check your internet connection.';
  }

  String _handleHttpException(HttpException error) {
    return 'Network request failed: ${error.message}';
  }

  String _handleGenericError(dynamic error) {
    if (kDebugMode) {
      print('Unhandled error: $error');
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Create appropriate AppError from common exceptions
  AppError createAppError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
          return CameraError.permissionDenied();
        case 'camera_not_available':
          return CameraError.hardwareUnavailable();
        default:
          return AppError.withTimestamp(
            type: ErrorType.unknown,
            message: error.message ?? 'Platform error occurred',
            technicalDetails: error.code,
          );
      }
    }

    if (error is SocketException) {
      return NetworkError.noConnection();
    }

    if (error is HttpException) {
      return NetworkError.serverError();
    }

    return AppError.withTimestamp(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred',
      technicalDetails: error.toString(),
    );
  }

  /// Check if an error is recoverable
  bool isRecoverable(dynamic error) {
    if (error is AppError) {
      return error.recoverable;
    }
    return true; // Assume recoverable by default
  }

  /// Get retry action for an error if available
  VoidCallback? getRetryAction(dynamic error) {
    if (error is AppError) {
      return error.retryAction;
    }
    return null;
  }
}