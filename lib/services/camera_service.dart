import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/error_handler.dart';

// Camera service interface
abstract class CameraServiceInterface {
  Future<bool> initialize();
  Future<void> dispose();
  Future<String?> capturePhoto();
  Future<bool> requestPermissions();
  Future<bool> checkPermissions();
  bool get isInitialized;
  CameraController? get controller;
  List<CameraDescription> get availableCameras;
  
  // Additional camera controls
  Future<void> switchCamera();
  Future<void> setFlashMode(FlashMode flashMode);
  Future<void> setZoomLevel(double zoom);
  Future<double> getMaxZoomLevel();
  Future<double> getMinZoomLevel();
  Future<void> cleanupOldCaptures({int maxAgeInDays = 7});
}

// Camera service implementation
class CameraService implements CameraServiceInterface {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  @override
  CameraController? get controller => _controller;

  @override
  List<CameraDescription> get availableCameras => _cameras;

  @override
  bool get isInitialized => _isInitialized && _controller?.value.isInitialized == true;

  @override
  Future<bool> initialize() async {
    try {
      // Check permissions first
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) {
          debugPrint('Camera permission denied');
          return false;
        }
      }

      // Get available cameras
      _cameras = availableCameras;
      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Initialize camera controller with the first available camera (usually back camera)
      final camera = _cameras.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      
      debugPrint('Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      debugPrint('Camera disposed');
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }

  @override
  Future<String?> capturePhoto() async {
    if (!isInitialized) {
      throw CameraError(
        message: 'Camera not initialized. Please restart the app.',
        recoverable: false,
      );
    }

    try {
      // Get the application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String captureDir = path.join(appDir.path, 'captures');
      
      // Create captures directory if it doesn't exist
      final Directory dir = Directory(captureDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'capture_$timestamp.jpg';
      final String filePath = path.join(captureDir, fileName);

      // Capture the image
      final XFile image = await _controller!.takePicture();
      
      // Move the image to our captures directory
      final File capturedFile = File(image.path);
      final File savedFile = await capturedFile.copy(filePath);
      
      // Clean up the temporary file
      await capturedFile.delete();

      debugPrint('Photo captured: $filePath');
      return savedFile.path;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      throw CameraError.captureFailure(e.toString());
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final PermissionStatus status = await Permission.camera.request();
      final bool granted = status == PermissionStatus.granted;
      
      debugPrint('Camera permission ${granted ? 'granted' : 'denied'}');
      
      if (!granted) {
        throw CameraError.permissionDenied();
      }
      
      return granted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      if (e is CameraError) {
        rethrow;
      }
      throw CameraError(
        message: 'Failed to request camera permission',
        technicalDetails: e.toString(),
      );
    }
  }

  @override
  Future<bool> checkPermissions() async {
    try {
      final PermissionStatus status = await Permission.camera.status;
      final bool granted = status == PermissionStatus.granted;
      
      debugPrint('Camera permission status: $status');
      return granted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  // Additional utility methods
  @override
  Future<void> switchCamera() async {
    if (_cameras.length < 2 || !isInitialized) {
      debugPrint('Cannot switch camera: insufficient cameras or not initialized');
      return;
    }

    try {
      // Find the next camera
      final currentCamera = _controller!.description;
      final currentIndex = _cameras.indexOf(currentCamera);
      final nextIndex = (currentIndex + 1) % _cameras.length;
      final nextCamera = _cameras[nextIndex];

      // Dispose current controller
      await _controller!.dispose();

      // Initialize with new camera
      _controller = CameraController(
        nextCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      debugPrint('Switched to camera: ${nextCamera.name}');
    } catch (e) {
      debugPrint('Error switching camera: $e');
      // Try to reinitialize with original camera
      await initialize();
    }
  }

  @override
  Future<void> setFlashMode(FlashMode flashMode) async {
    if (!isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      await _controller!.setFlashMode(flashMode);
      debugPrint('Flash mode set to: $flashMode');
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    if (!isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      final double maxZoom = await _controller!.getMaxZoomLevel();
      final double minZoom = await _controller!.getMinZoomLevel();
      final double clampedZoom = zoom.clamp(minZoom, maxZoom);
      
      await _controller!.setZoomLevel(clampedZoom);
      debugPrint('Zoom level set to: $clampedZoom');
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
    }
  }

  @override
  Future<double> getMaxZoomLevel() async {
    if (!isInitialized) return 1.0;
    
    try {
      return await _controller!.getMaxZoomLevel();
    } catch (e) {
      debugPrint('Error getting max zoom level: $e');
      return 1.0;
    }
  }

  @override
  Future<double> getMinZoomLevel() async {
    if (!isInitialized) return 1.0;
    
    try {
      return await _controller!.getMinZoomLevel();
    } catch (e) {
      debugPrint('Error getting min zoom level: $e');
      return 1.0;
    }
  }

  // Clean up old captured images
  @override
  Future<void> cleanupOldCaptures({int maxAgeInDays = 7}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String captureDir = path.join(appDir.path, 'captures');
      final Directory dir = Directory(captureDir);
      
      if (!await dir.exists()) return;

      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      final List<FileSystemEntity> files = await dir.list().toList();
      
      int deletedCount = 0;
      for (final FileSystemEntity file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      debugPrint('Cleaned up $deletedCount old capture files');
    } catch (e) {
      debugPrint('Error cleaning up old captures: $e');
    }
  }
}

// Camera service errors
class CameraServiceException implements Exception {
  final String message;
  final String? code;
  
  const CameraServiceException(this.message, {this.code});
  
  @override
  String toString() => 'CameraServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Camera service factory
class CameraServiceFactory {
  static CameraServiceInterface create() {
    return CameraService();
  }
}