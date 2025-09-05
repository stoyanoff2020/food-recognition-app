import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/app_theme.dart';

class PermissionRequestWidget extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionRequestWidget({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<PermissionRequestWidget> createState() => _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState extends State<PermissionRequestWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _permissionStatus = status;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final status = await Permission.camera.request();
      
      if (mounted) {
        setState(() {
          _permissionStatus = status;
          _isRequesting = false;
        });

        if (status.isGranted) {
          widget.onPermissionGranted?.call();
        } else {
          widget.onPermissionDenied?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Animated camera icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _getIconColor(theme),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getIconColor(theme).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(),
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Permission status and explanation
        _buildPermissionContent(theme),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Action buttons
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildPermissionContent(ThemeData theme) {
    switch (_permissionStatus) {
      case PermissionStatus.granted:
        return _buildGrantedContent(theme);
      case PermissionStatus.denied:
        return _buildDeniedContent(theme);
      case PermissionStatus.permanentlyDenied:
        return _buildPermanentlyDeniedContent(theme);
      case PermissionStatus.restricted:
        return _buildRestrictedContent(theme);
      default:
        return _buildDeniedContent(theme);
    }
  }

  Widget _buildGrantedContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Camera Access Granted! ✅',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.successColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          'Perfect! You\'re all set to start identifying food ingredients.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeniedContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Camera Permission Required',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          'To identify ingredients in your photos, we need access to your camera. This is the core feature of the app.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingL),
        _buildFeatureList(theme),
      ],
    );
  }

  Widget _buildPermanentlyDeniedContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Camera Access Blocked',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.warningColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          'Camera permission has been permanently denied. Please enable it in your device settings to use the app.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRestrictedContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Camera Access Restricted',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.warningColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          'Camera access is restricted on this device. Please check your device settings or contact your administrator.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    final features = [
      'Take photos of food items',
      'Identify ingredients automatically',
      'Get personalized recipe suggestions',
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What we\'ll use the camera for:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.successColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    feature,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (_permissionStatus.isGranted) {
      return const SizedBox.shrink();
    }

    if (_permissionStatus.isPermanentlyDenied) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openAppSettings,
          icon: const Icon(Icons.settings),
          label: const Text('Open Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.warningColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRequesting ? null : _requestPermission,
        icon: _isRequesting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.camera_alt),
        label: Text(_isRequesting ? 'Requesting...' : 'Grant Camera Permission'),
      ),
    );
  }

  Color _getIconColor(ThemeData theme) {
    switch (_permissionStatus) {
      case PermissionStatus.granted:
        return theme.successColor;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return theme.warningColor;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getIconData() {
    switch (_permissionStatus) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return Icons.warning;
      default:
        return Icons.camera_alt;
    }
  }
}