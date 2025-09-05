import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/camera_provider.dart';
import '../../config/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showCameraPreview = false;
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraProvider = context.read<CameraProvider>();
    
    if (!cameraProvider.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // App is inactive, dispose camera
      cameraProvider.dispose();
      if (mounted) {
        setState(() {
          _showCameraPreview = false;
        });
      }
    } else if (state == AppLifecycleState.resumed && _showCameraPreview) {
      // App is resumed and camera was active, reinitialize camera
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameraProvider = context.read<CameraProvider>();
    
    final success = await cameraProvider.initialize();
    if (success && mounted) {
      // Get zoom limits
      _maxZoom = await cameraProvider.getMaxZoomLevel();
      _minZoom = await cameraProvider.getMinZoomLevel();
      _currentZoom = _minZoom;
      setState(() {});
    }
  }

  Future<void> _toggleCameraPreview() async {
    if (_showCameraPreview) {
      // Hide camera preview
      final cameraProvider = context.read<CameraProvider>();
      await cameraProvider.dispose();
      setState(() {
        _showCameraPreview = false;
      });
    } else {
      // Show camera preview
      setState(() {
        _showCameraPreview = true;
      });
      await _initializeCamera();
    }
  }

  Future<void> _capturePhoto() async {
    final cameraProvider = context.read<CameraProvider>();
    
    if (!cameraProvider.isInitialized || cameraProvider.isCapturing) {
      return;
    }

    final imagePath = await cameraProvider.capturePhoto();
    
    if (imagePath != null && mounted) {
      // Hide camera preview and navigate to results
      setState(() {
        _showCameraPreview = false;
      });
      await cameraProvider.dispose();
      
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
    final cameraProvider = context.read<CameraProvider>();
    
    if (!cameraProvider.isInitialized) return;

    final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    await cameraProvider.setFlashMode(newFlashMode);
    
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<void> _switchCamera() async {
    final cameraProvider = context.read<CameraProvider>();
    
    if (!cameraProvider.isInitialized) return;

    await cameraProvider.switchCamera();
    
    // Reset zoom when switching cameras
    _currentZoom = 1.0;
    _maxZoom = await cameraProvider.getMaxZoomLevel();
    _minZoom = await cameraProvider.getMinZoomLevel();
    setState(() {});
  }

  void _onZoomChanged(double zoom) {
    final cameraProvider = context.read<CameraProvider>();
    
    if (!cameraProvider.isInitialized) return;

    setState(() {
      _currentZoom = zoom;
    });
    
    cameraProvider.setZoomLevel(zoom);
  }

  Widget _buildCameraPreview() {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        if (cameraProvider.isInitializing) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
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
            ),
          );
        }

        if (!cameraProvider.isInitialized) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
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
            ),
          );
        }

        return Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Camera preview
                if (cameraProvider.cameraService.controller != null)
                  Positioned.fill(
                    child: CameraPreview(cameraProvider.cameraService.controller!),
                  ),
                
                // Camera controls overlay
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flash toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                      // Camera switch
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                          ),
                          onPressed: _switchCamera,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Zoom slider
                if (_maxZoom > _minZoom)
                  Positioned(
                    right: 8,
                    top: 60,
                    bottom: 60,
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
                    right: 8,
                    top: 50,
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
                
                // Capture button
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: cameraProvider.isCapturing ? null : _capturePhoto,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: cameraProvider.isCapturing
                            ? const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ),
                
                // Error message overlay
                if (cameraProvider.lastError != null)
                  Positioned(
                    top: 60,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cameraProvider.lastError!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: cameraProvider.clearError,
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Food Recognition'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.goToSettings(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App branding section
                if (!_showCameraPreview) ...[
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Food Recognition App',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Capture food photos to discover recipes',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Camera section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Camera',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _showCameraPreview ? Icons.close : Icons.camera_alt,
                              ),
                              onPressed: _toggleCameraPreview,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (_showCameraPreview) ...[
                          _buildCameraPreview(),
                          const SizedBox(height: 16),
                          const Text(
                            'Point your camera at food and tap the capture button',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tap to open camera',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Capture food photos to identify ingredients\nand discover recipes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _toggleCameraPreview,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Open Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick actions section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Alternative camera access
                        OutlinedButton.icon(
                          onPressed: () => context.goToCamera(),
                          icon: const Icon(Icons.fullscreen),
                          label: const Text('Full Screen Camera'),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Recipe book access
                        if (appState.hasFeatureAccess('recipe_book'))
                          OutlinedButton.icon(
                            onPressed: () => context.goToRecipeBook(),
                            icon: const Icon(Icons.book),
                            label: const Text('Recipe Book'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.goToSubscription(),
                            icon: const Icon(Icons.lock),
                            label: const Text('Recipe Book (Premium)'),
                          ),
                        
                        const SizedBox(height: 12),
                        
                        // Meal planning access
                        if (appState.hasFeatureAccess('meal_planning'))
                          OutlinedButton.icon(
                            onPressed: () => context.goToMealPlanning(),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Meal Planning'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.goToSubscription(),
                            icon: const Icon(Icons.lock),
                            label: const Text('Meal Planning (Professional)'),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subscription info
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Plan: ${appState.state.subscription.currentTier.type.toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (appState.state.subscription.usageQuota.dailyScans > 0)
                                Text(
                                  'Daily scans: ${appState.state.subscription.usageQuota.usedScans}/${appState.state.subscription.usageQuota.dailyScans}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.goToSubscription(),
                          child: const Text('Manage'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: 'Camera',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Recipes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home
                  break;
                case 1:
                  context.goToCamera();
                  break;
                case 2:
                  context.goToRecipeBook();
                  break;
                case 3:
                  context.goToSettings();
                  break;
              }
            },
          ),
        );
      },
    );
  }
}