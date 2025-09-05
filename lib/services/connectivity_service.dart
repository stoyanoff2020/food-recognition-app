import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';

/// Enum for different connectivity states
enum ConnectivityStatus {
  online,
  offline,
  unknown
}

/// Service to monitor network connectivity and provide offline detection
class ConnectivityService {
  static ConnectivityService? _instance;
  factory ConnectivityService() => _instance ??= ConnectivityService._internal();
  ConnectivityService._internal();
  
  // For testing purposes
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  final StreamController<ConnectivityStatus> _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _connectivityTimer;
  bool _isMonitoring = false;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Check if device is currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if device is currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Start monitoring connectivity
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _checkConnectivity();
    
    // Check connectivity every 10 seconds
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _isMonitoring = false;
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  /// Manually check connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    await _checkConnectivity();
    return _currentStatus;
  }

  /// Internal method to check connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await _performConnectivityCheck();
      _updateStatus(result);
    } catch (e) {
      if (kDebugMode) {
        print('Connectivity check failed: $e');
      }
      _updateStatus(ConnectivityStatus.offline);
    }
  }

  /// Perform actual connectivity check
  Future<ConnectivityStatus> _performConnectivityCheck() async {
    try {
      // Try to connect to a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return ConnectivityStatus.online;
      } else {
        return ConnectivityStatus.offline;
      }
    } on SocketException catch (_) {
      return ConnectivityStatus.offline;
    } on TimeoutException catch (_) {
      return ConnectivityStatus.offline;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected connectivity check error: $e');
      }
      return ConnectivityStatus.offline;
    }
  }

  /// Update connectivity status and notify listeners
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = newStatus;
      
      if (kDebugMode) {
        print('Connectivity changed: $previousStatus -> $newStatus');
      }
      
      _connectivityController.add(newStatus);
    }
  }

  /// Check if a network operation should be allowed
  bool canPerformNetworkOperation() {
    return isOnline;
  }

  /// Get user-friendly message for current connectivity status
  String getConnectivityMessage() {
    switch (_currentStatus) {
      case ConnectivityStatus.online:
        return 'Connected to internet';
      case ConnectivityStatus.offline:
        return 'No internet connection. Some features may not be available.';
      case ConnectivityStatus.unknown:
        return 'Checking connection...';
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    if (!_connectivityController.isClosed) {
      _connectivityController.close();
    }
  }
}

/// Mixin to add connectivity awareness to services
mixin ConnectivityAware {
  ConnectivityService get _connectivityService => ConnectivityService();

  /// Check if network operations are allowed
  bool get canUseNetwork => _connectivityService.canPerformNetworkOperation();

  /// Get current connectivity status
  ConnectivityStatus get connectivityStatus => _connectivityService.currentStatus;

  /// Throw appropriate error if offline
  void requireNetwork() {
    if (!canUseNetwork) {
      throw NetworkError(
        message: 'This feature requires an internet connection.',
        recoverable: true,
      );
    }
  }

  /// Execute operation with network check
  Future<T> executeWithNetworkCheck<T>(Future<T> Function() operation) async {
    requireNetwork();
    return await operation();
  }
}