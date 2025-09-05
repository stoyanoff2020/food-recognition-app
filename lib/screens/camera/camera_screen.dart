import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../providers/camera_provider.dart';
import '../../config/app_router.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraProvider = context.cameraProvider;
    
    if (!cameraProvider.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // App is inactive, dispose camera
      cameraProvider.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed, reinitialize camera
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameraProvider = context.cameraProvider;
    
    final success = await cameraProvider.initialize();
    if (success && mounted) {
      // Get zoom limits
      _maxZoom = await cameraProvider.getMaxZoomLevel();
      _minZoom = await cameraProvider.getMinZoomLevel();
      setState(() {});
    }
  }

  Future<void> _capturePhoto() async {
    final cameraProvider = context.cameraProvider;
    
    if (!cameraProvider.isInitialized || cameraProvider.isCapturing) {
      return;
    }

    final imagePath = await cameraProvider.capturePhoto();
    
    if (imagePath != null && mounted) {
      // Navigate to results screen with the captured image
      context.goToResults(imagePath: imagePath);
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cameraProvider.lastError ?? 'Failed to capture photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFlash() async {
    final cameraProvider = context.cameraProvider;
    
    if (!cameraProvider.isInitialized) return;

    final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    await cameraProvider.setFlashMode(newFlashMode);
    
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<void> _switchCamera() async {
    final cameraProvider = context.cameraProvider;
    
    if (!cameraProvider.isInitialized) return;

    await cameraProvider.switchCamera();
    
    // Reset zoom when switching cameras
    _currentZoom = 1.0;
    _maxZoom = await cameraProvider.getMaxZoomLevel();
    _minZoom = await cameraProvider.getMinZoomLevel();
    setState(() {});
  }

  void _onZoomChanged(double zoom) {
    final cameraProvider = context.cameraProvider;
    
    if (!cameraProvider.isInitialized) return;

    setState(() {
      _currentZoom = zoom;
    });
    
    cameraProvider.setZoomLevel(zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Flash toggle
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          // Camera switch
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Consumer<CameraProvider>(
        builder: (context, cameraProvider, child) {
          if (cameraProvider.isInitializing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!cameraProvider.isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cameraProvider.lastError ?? 'Camera not available',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeCamera,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Camera preview
              Positioned.fill(
                child: CameraPreview(cameraProvider.cameraService.controller!),
              ),
              
              // Zoom slider
              if (_maxZoom > _minZoom)
                Positioned(
                  right: 16,
                  top: 100,
                  bottom: 200,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: _currentZoom,
                      min: _minZoom,
                      max: _maxZoom,
                      divisions: 10,
                      onChanged: _onZoomChanged,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white54,
                    ),
                  ),
                ),
              
              // Zoom level indicator
              if (_maxZoom > _minZoom)
                Positioned(
                  right: 16,
                  top: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentZoom.toStringAsFixed(1)}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              
              // Capture button and controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button (placeholder)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Capture button
                      GestureDetector(
                        onTap: cameraProvider.isCapturing ? null : _capturePhoto,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: cameraProvider.isCapturing
                              ? const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                  size: 32,
                                ),
                        ),
                      ),
                      
                      // Settings button (placeholder)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Error message overlay
              if (cameraProvider.lastError != null)
                Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cameraProvider.lastError!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: cameraProvider.clearError,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}