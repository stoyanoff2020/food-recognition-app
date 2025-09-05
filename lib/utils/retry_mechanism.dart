import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool exponentialBackoff;
  final List<Type> retryableExceptions;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.exponentialBackoff = true,
    this.retryableExceptions = const [],
  });

  /// Default configuration for network operations
  static const RetryConfig network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
    exponentialBackoff: true,
    retryableExceptions: [NetworkError, TimeoutException],
  );

  /// Default configuration for processing operations
  static const RetryConfig processing = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 5),
    backoffMultiplier: 1.5,
    exponentialBackoff: true,
    retryableExceptions: [ProcessingError],
  );

  /// Configuration for critical operations (fewer retries)
  static const RetryConfig critical = RetryConfig(
    maxAttempts: 1,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 1),
    backoffMultiplier: 1.0,
    exponentialBackoff: false,
  );
}

/// Result of a retry operation
class RetryResult<T> {
  final T? result;
  final dynamic lastError;
  final int attemptCount;
  final bool succeeded;
  final Duration totalDuration;

  const RetryResult({
    this.result,
    this.lastError,
    required this.attemptCount,
    required this.succeeded,
    required this.totalDuration,
  });

  /// Create a successful result
  factory RetryResult.success(T result, int attemptCount, Duration duration) {
    return RetryResult<T>(
      result: result,
      attemptCount: attemptCount,
      succeeded: true,
      totalDuration: duration,
    );
  }

  /// Create a failed result
  factory RetryResult.failure(dynamic error, int attemptCount, Duration duration) {
    return RetryResult<T>(
      lastError: error,
      attemptCount: attemptCount,
      succeeded: false,
      totalDuration: duration,
    );
  }
}

/// Callback for retry attempts
typedef RetryCallback = void Function(int attempt, dynamic error);

/// Service for handling retry logic with exponential backoff
class RetryMechanism {
  static final RetryMechanism _instance = RetryMechanism._internal();
  factory RetryMechanism() => _instance;
  RetryMechanism._internal();

  /// Execute an operation with retry logic
  Future<RetryResult<T>> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    RetryCallback? onRetry,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final stopwatch = Stopwatch()..start();
    dynamic lastError;
    
    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print('Retry attempt $attempt/${config.maxAttempts}');
        }
        
        final result = await operation();
        stopwatch.stop();
        
        return RetryResult.success(result, attempt, stopwatch.elapsed);
      } catch (error) {
        lastError = error;
        
        if (kDebugMode) {
          print('Attempt $attempt failed: $error');
        }
        
        // Check if we should retry this error
        if (!_shouldRetryError(error, config, shouldRetry)) {
          stopwatch.stop();
          return RetryResult.failure(error, attempt, stopwatch.elapsed);
        }
        
        // Don't delay after the last attempt
        if (attempt < config.maxAttempts) {
          onRetry?.call(attempt, error);
          await _delay(attempt, config);
        }
      }
    }
    
    stopwatch.stop();
    return RetryResult.failure(lastError, config.maxAttempts, stopwatch.elapsed);
  }

  /// Execute with simple retry (returns result or throws last error)
  Future<T> executeSimple<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    RetryCallback? onRetry,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final result = await execute(
      operation,
      config: config,
      onRetry: onRetry,
      shouldRetry: shouldRetry,
    );
    
    if (result.succeeded) {
      return result.result!;
    } else {
      throw result.lastError;
    }
  }

  /// Check if an error should be retried
  bool _shouldRetryError(
    dynamic error,
    RetryConfig config,
    bool Function(dynamic error)? customShouldRetry,
  ) {
    // Use custom retry logic if provided
    if (customShouldRetry != null) {
      return customShouldRetry(error);
    }
    
    // Check if error type is in retryable exceptions
    if (config.retryableExceptions.isNotEmpty) {
      return config.retryableExceptions.any((type) => error.runtimeType == type);
    }
    
    // Default retry logic for common error types
    if (error is NetworkError) {
      return error.recoverable;
    }
    
    if (error is ProcessingError) {
      return error.recoverable;
    }
    
    if (error is AppError) {
      return error.recoverable;
    }
    
    // Retry network-related exceptions
    if (error is TimeoutException || 
        error is SocketException ||
        error is HttpException) {
      return true;
    }
    
    return false;
  }

  /// Calculate delay for next retry attempt
  Future<void> _delay(int attempt, RetryConfig config) async {
    Duration delay;
    
    if (config.exponentialBackoff) {
      // Exponential backoff with jitter
      final exponentialDelay = config.initialDelay * 
          pow(config.backoffMultiplier, attempt - 1);
      
      // Add jitter (±25% of delay)
      final jitter = exponentialDelay * (Random().nextDouble() * 0.5 - 0.25);
      delay = exponentialDelay + jitter;
      
      // Cap at max delay
      if (delay > config.maxDelay) {
        delay = config.maxDelay;
      }
    } else {
      delay = config.initialDelay;
    }
    
    if (kDebugMode) {
      print('Waiting ${delay.inMilliseconds}ms before retry...');
    }
    
    await Future.delayed(delay);
  }
}

/// Mixin to add retry capabilities to services
mixin RetryCapable {
  RetryMechanism get _retryMechanism => RetryMechanism();

  /// Execute operation with network retry configuration
  Future<T> retryNetworkOperation<T>(Future<T> Function() operation) {
    return _retryMechanism.executeSimple(
      operation,
      config: RetryConfig.network,
      onRetry: (attempt, error) {
        if (kDebugMode) {
          print('Network operation retry $attempt: $error');
        }
      },
    );
  }

  /// Execute operation with processing retry configuration
  Future<T> retryProcessingOperation<T>(Future<T> Function() operation) {
    return _retryMechanism.executeSimple(
      operation,
      config: RetryConfig.processing,
      onRetry: (attempt, error) {
        if (kDebugMode) {
          print('Processing operation retry $attempt: $error');
        }
      },
    );
  }

  /// Execute operation with custom retry configuration
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    RetryCallback? onRetry,
  }) {
    return _retryMechanism.executeSimple(
      operation,
      config: config,
      onRetry: onRetry,
    );
  }

  /// Execute operation and get detailed retry result
  Future<RetryResult<T>> retryOperationWithResult<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    RetryCallback? onRetry,
  }) {
    return _retryMechanism.execute(
      operation,
      config: config,
      onRetry: onRetry,
    );
  }
}