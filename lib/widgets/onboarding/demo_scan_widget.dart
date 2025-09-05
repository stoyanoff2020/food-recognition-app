import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class DemoScanWidget extends StatefulWidget {
  final VoidCallback? onDemoScan;
  final VoidCallback? onSkipDemo;

  const DemoScanWidget({
    super.key,
    this.onDemoScan,
    this.onSkipDemo,
  });

  @override
  State<DemoScanWidget> createState() => _DemoScanWidgetState();
}

class _DemoScanWidgetState extends State<DemoScanWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _bounceController.forward();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Demo scan illustration
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: _buildDemoIllustration(theme),
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Title and description
          Text(
            'Ready to Try It Out?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          Text(
            'Take your first photo to see the magic happen, or skip to explore the app.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Action buttons
          _buildActionButtons(theme),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Tips section
          _buildTipsSection(theme),
        ],
      ),
    );
  }

  Widget _buildDemoIllustration(ThemeData theme) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                    end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Camera icon with food items
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFloatingEmoji('🍎', -20, -10),
                  _buildFloatingEmoji('🥕', 20, -15),
                  _buildFloatingEmoji('🧄', 0, 25),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingEmoji(String emoji, double dx, double dy) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 2),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -5 * (0.5 - (value - 0.5).abs())),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Primary action - Demo scan
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onDemoScan,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Demo Photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Secondary action - Skip
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onSkipDemo,
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip Demo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(ThemeData theme) {
    final tips = [
      {
        'icon': Icons.wb_sunny,
        'text': 'Use good lighting for best results',
      },
      {
        'icon': Icons.center_focus_strong,
        'text': 'Focus on the food items clearly',
      },
      {
        'icon': Icons.straighten,
        'text': 'Hold the camera steady',
      },
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
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Tips for Better Results',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: Row(
              children: [
                Icon(
                  tip['icon'] as IconData,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    tip['text'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}