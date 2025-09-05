import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../providers/app_state_provider.dart';

class CameraProvider extends ChangeNotifier {
  final CameraServiceInterface _cameraService;
  final AppStateProvider _appStateProvider;
  
  bool _isInitializing = false;
  bool _isCapturing = false;
  String? _lastError;

  CameraProvider(this._cameraService, this._appStateProvider);

  // Getters
  CameraServiceInterface get cameraService => _cameraService;
  bool get isInitialized => _cameraService.isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isCapturing => _isCapturing;
  String? get lastError => _lastError;
  bool get hasPermission => _appStateProvider.state.camera.hasPermission;
  bool get isActive => _appStateProvider.state.camera.isActive;

  // Initialize camera
  Future<bool> initialize() async {
    if (_isInitializing || isInitialized) {
      return isInitialized;
    }

    _isInitializing = true;
    _lastError = null;
    notifyListeners();

    try {
      final bool success = await _cameraService.initialize();
      
      if (success) {
        _appStateProvider.setCameraActive(true);
        _appStateProvider.setCameraPermission(true);
        debugPrint('Camera provider: initialization successful');
      } else {
        _lastError = 'Failed to initialize camera';
        _appStateProvider.setCameraActive(false);
        debugPrint('Camera provider: initialization failed');
      }

      return success;
    } catch (e) {
      _lastError = 'Camera initialization error: $e';
      _appStateProvider.setCameraActive(false);
      debugPrint('Camera provider: initialization error: $e');
      return false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Dispose camera
  @override
  Future<void> dispose() async {
    try {
      await _cameraService.dispose();
      _appStateProvider.setCameraActive(false);
      _lastError = null;
      debugPrint('Camera provider: disposed');
    } catch (e) {
      debugPrint('Camera provider: dispose error: $e');
    }
    super.dispose();
  }

  // Capture photo
  Future<String?> capturePhoto() async {
    if (!isInitialized || _isCapturing) {
      debugPrint('Camera provider: cannot capture - not initialized or already capturing');
      return null;
    }

    _isCapturing = true;
    _lastError = null;
    notifyListeners();

    try {
      final String? imagePath = await _cameraService.capturePhoto();
      
      if (imagePath != null) {
        _appStateProvider.setLastCapturedImage(imagePath);
        debugPrint('Camera provider: photo captured successfully');
        return imagePath;
      } else {
        _lastError = 'Failed to capture photo';
        debugPrint('Camera provider: photo capture failed');
        return null;
      }
    } catch (e) {
      _lastError = 'Photo capture error: $e';
      debugPrint('Camera provider: capture error: $e');
      return null;
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }

  // Request camera permissions
  Future<bool> requestPermissions() async {
    try {
      final bool granted = await _cameraService.requestPermissions();
      _appStateProvider.setCameraPermission(granted);
      
      if (!granted) {
        _lastError = 'Camera permission denied';
      } else {
        _lastError = null;
      }
      
      notifyListeners();
      return granted;
    } catch (e) {
      _lastError = 'Permission request error: $e';
      debugPrint('Camera provider: permission request error: $e');
      notifyListeners();
      return false;
    }
  }

  // Check camera permissions
  Future<bool> checkPermissions() async {
    try {
      final bool granted = await _cameraService.checkPermissions();
      _appStateProvider.setCameraPermission(granted);
      notifyListeners();
      return granted;
    } catch (e) {
      debugPrint('Camera provider: permission check error: $e');
      return false;
    }
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    if (!isInitialized) return;

    try {
      await _cameraService.switchCamera();
      notifyListeners();
      debugPrint('Camera provider: camera switched');
    } catch (e) {
      _lastError = 'Camera switch error: $e';
      debugPrint('Camera provider: switch error: $e');
      notifyListeners();
    }
  }

  // Set flash mode
  Future<void> setFlashMode(FlashMode flashMode) async {
    if (!isInitialized) return;

    try {
      await _cameraService.setFlashMode(flashMode);
      notifyListeners();
      debugPrint('Camera provider: flash mode set to $flashMode');
    } catch (e) {
      _lastError = 'Flash mode error: $e';
      debugPrint('Camera provider: flash mode error: $e');
      notifyListeners();
    }
  }

  // Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (!isInitialized) return;

    try {
      await _cameraService.setZoomLevel(zoom);
      notifyListeners();
      debugPrint('Camera provider: zoom level set to $zoom');
    } catch (e) {
      _lastError = 'Zoom error: $e';
      debugPrint('Camera provider: zoom error: $e');
      notifyListeners();
    }
  }

  // Get zoom limits
  Future<double> getMaxZoomLevel() async {
    if (!isInitialized) return 1.0;
    return await _cameraService.getMaxZoomLevel();
  }

  Future<double> getMinZoomLevel() async {
    if (!isInitialized) return 1.0;
    return await _cameraService.getMinZoomLevel();
  }

  // Clear error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Cleanup old captures
  Future<void> cleanupOldCaptures({int maxAgeInDays = 7}) async {
    try {
      await _cameraService.cleanupOldCaptures(maxAgeInDays: maxAgeInDays);
      debugPrint('Camera provider: cleanup completed');
    } catch (e) {
      debugPrint('Camera provider: cleanup error: $e');
    }
  }
}

// Extension to make it easier to access the camera provider
extension CameraProviderContext on BuildContext {
  CameraProvider get cameraProvider => Provider.of<CameraProvider>(this, listen: false);
  CameraProvider watchCameraProvider() => Provider.of<CameraProvider>(this);
}