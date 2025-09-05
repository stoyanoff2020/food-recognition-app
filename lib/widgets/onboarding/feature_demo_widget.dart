import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class FeatureDemoWidget extends StatefulWidget {
  final String demoType;
  final String title;
  final String description;

  const FeatureDemoWidget({
    super.key,
    required this.demoType,
    required this.title,
    required this.description,
  });

  @override
  State<FeatureDemoWidget> createState() => _FeatureDemoWidgetState();
}

class _FeatureDemoWidgetState extends State<FeatureDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildDemoContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.demoType) {
      case 'camera_demo':
        return _buildCameraDemo(theme);
      case 'recipe_demo':
        return _buildRecipeDemo(theme);
      case 'customize_demo':
        return _buildCustomizeDemo(theme);
      default:
        return _buildDefaultDemo(theme);
    }
  }

  Widget _buildCameraDemo(ThemeData theme) {
    return Column(
      children: [
        // Camera icon with animation
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: value * 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacingL),
        
        // Demo food items
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFoodItem('🍎', 'Apple', 0.95),
            _buildFoodItem('🥕', 'Carrot', 0.88),
            _buildFoodItem('🧄', 'Garlic', 0.92),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        
        Text(
          'AI identifies ingredients with confidence scores',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecipeDemo(ThemeData theme) {
    return Column(
      children: [
        // Recipe book icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.recipeColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.menu_book,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        
        // Recipe cards
        Column(
          children: [
            _buildRecipeCard('Apple Cinnamon Oatmeal', '15 min', 0.95),
            const SizedBox(height: AppTheme.spacingS),
            _buildRecipeCard('Roasted Vegetable Medley', '25 min', 0.88),
            const SizedBox(height: AppTheme.spacingS),
            _buildRecipeCard('Garlic Herb Pasta', '20 min', 0.82),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        
        Text(
          'Get personalized recipes ranked by ingredient match',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCustomizeDemo(ThemeData theme) {
    return Column(
      children: [
        // Add icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.ingredientColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_circle,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        
        // Ingredient chips
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          alignment: WrapAlignment.center,
          children: [
            _buildIngredientChip('Detected: Apple', true),
            _buildIngredientChip('Detected: Carrot', true),
            _buildIngredientChip('+ Add: Onion', false),
            _buildIngredientChip('+ Add: Chicken', false),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        
        // Arrow pointing down
        Icon(
          Icons.keyboard_arrow_down,
          color: theme.colorScheme.primary,
          size: 32,
        ),
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'More recipe options!',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'Add your own ingredients for better matches',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDefaultDemo(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.lightbulb,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          widget.title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          widget.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFoodItem(String emoji, String name, double confidence) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: theme.ingredientColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Text(
            '${(confidence * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.ingredientColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(String title, String time, double match) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.recipeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              Icons.restaurant,
              color: theme.recipeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              '${(match * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChip(String label, bool isDetected) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: isDetected
            ? theme.ingredientColor.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDetected
              ? theme.ingredientColor.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDetected ? theme.ingredientColor : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}