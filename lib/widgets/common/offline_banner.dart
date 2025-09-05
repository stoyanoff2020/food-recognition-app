import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';

/// Widget that displays an offline banner when there's no internet connection
class OfflineBanner extends StatefulWidget {
  final Widget child;
  final bool showWhenOffline;
  final String? customMessage;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration animationDuration;

  const OfflineBanner({
    Key? key,
    required this.child,
    this.showWhenOffline = true,
    this.customMessage,
    this.backgroundColor,
    this.textColor,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityStatus = _connectivityService.currentStatus;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((status) {
      if (mounted) {
        setState(() {
          _connectivityStatus = status;
        });
        _updateBannerVisibility();
      }
    });

    // Start monitoring connectivity
    _connectivityService.startMonitoring();
    _updateBannerVisibility();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateBannerVisibility() {
    final shouldShow = widget.showWhenOffline && 
                      _connectivityStatus == ConnectivityStatus.offline;
    
    if (shouldShow) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 60),
              child: _connectivityStatus == ConnectivityStatus.offline &&
                      widget.showWhenOffline
                  ? _buildOfflineBanner(context)
                  : const SizedBox.shrink(),
            );
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? 
                           theme.colorScheme.error.withOpacity(0.9);
    final textColor = widget.textColor ?? theme.colorScheme.onError;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.customMessage ?? 
                'No internet connection. Some features may not be available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _connectivityService.checkConnectivity();
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple offline indicator widget
class OfflineIndicator extends StatelessWidget {
  final ConnectivityStatus status;
  final String? message;

  const OfflineIndicator({
    Key? key,
    required this.status,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (status == ConnectivityStatus.offline) {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              color: Theme.of(context).colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              message ?? 'Offline',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}

/// Mixin for widgets that need connectivity awareness
mixin ConnectivityAwareWidget<T extends StatefulWidget> on State<T> {
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;
  late ConnectivityService _connectivityService;

  ConnectivityStatus get connectivityStatus => _connectivityStatus;
  bool get isOnline => _connectivityStatus == ConnectivityStatus.online;
  bool get isOffline => _connectivityStatus == ConnectivityStatus.offline;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityStatus = _connectivityService.currentStatus;

    _connectivityService.connectivityStream.listen((status) {
      if (mounted) {
        setState(() {
          _connectivityStatus = status;
        });
        onConnectivityChanged(status);
      }
    });

    _connectivityService.startMonitoring();
  }

  /// Override this method to handle connectivity changes
  void onConnectivityChanged(ConnectivityStatus status) {}

  /// Show offline message to user
  void showOfflineMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('No internet connection'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _connectivityService.checkConnectivity();
            },
          ),
        ),
      );
    }
  }

  /// Check if network operation can be performed, show message if not
  bool checkNetworkAndShowMessage() {
    if (isOffline) {
      showOfflineMessage();
      return false;
    }
    return true;
  }
}