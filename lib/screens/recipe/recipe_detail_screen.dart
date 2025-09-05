import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_recipe_service.dart';
import '../../services/sharing_service.dart';
import '../../widgets/recipe/nutrition_summary_widget.dart';
import '../../widgets/recipe/allergen_warning_chip.dart';
import '../../config/app_theme.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final Recipe? recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Recipe? _recipe;
  late SharingServiceInterface _sharingService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _recipe = widget.recipe;
    _sharingService = SharingServiceFactory.create();
    
    // If no recipe provided, try to find it in app state
    if (_recipe == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _findRecipeInState();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _findRecipeInState() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final recipes = appState.state.recipes.suggestions;
    
    try {
      _recipe = recipes.firstWhere((recipe) => recipe.id == widget.recipeId);
      setState(() {});
    } catch (e) {
      // Recipe not found in current suggestions
      debugPrint('Recipe not found in current suggestions: ${widget.recipeId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Details'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading recipe details...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildRecipeHeader(),
                _buildTabBar(),
                _buildTabBarView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _recipe!.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_recipe!.imageUrl != null)
              Image.network(
                _recipe!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              )
            else
              _buildPlaceholderImage(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            
            // Match percentage badge
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: _getMatchColor(_recipe!.matchPercentage),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Text(
                  '${_recipe!.matchPercentage.toInt()}% Match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecipeHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time,
                '${_recipe!.cookingTime} min',
                AppTheme.infoColor,
              ),
              const SizedBox(width: AppTheme.spacingS),
              _buildInfoChip(
                Icons.restaurant,
                '${_recipe!.servings} servings',
                AppTheme.successColor,
              ),
              const SizedBox(width: AppTheme.spacingS),
              _buildInfoChip(
                _getDifficultyIcon(_recipe!.difficulty),
                _recipe!.difficulty.toUpperCase(),
                _getDifficultyColor(_recipe!.difficulty),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Allergen warnings
          if (_recipe!.allergens.isNotEmpty) ...[
            AllergenWarningList(
              allergens: _recipe!.allergens,
              chipSize: AllergenChipSize.medium,
              maxItems: 4,
              onShowAll: () => _showAllAllergens(),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
          
          // Used vs Missing ingredients
          _buildIngredientSummary(),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredient Match',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildIngredientCount(
                    'You Have',
                    _recipe!.usedIngredients.length,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildIngredientCount(
                    'Need to Buy',
                    _recipe!.missingIngredients.length,
                    AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Instructions', icon: Icon(Icons.list_alt)),
        Tab(text: 'Ingredients', icon: Icon(Icons.shopping_cart)),
        Tab(text: 'Nutrition', icon: Icon(Icons.restaurant)),
        Tab(text: 'Allergens', icon: Icon(Icons.warning)),
      ],
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInstructionsTab(),
          _buildIngredientsTab(),
          _buildNutritionTab(),
          _buildAllergensTab(),
        ],
      ),
    );
  }

  Widget _buildInstructionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _recipe!.instructions.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    _recipe!.instructions[index],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIngredientsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _recipe!.ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _recipe!.ingredients[index];
        final isUsed = _recipe!.usedIngredients.contains(ingredient);
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
          child: ListTile(
            leading: Icon(
              isUsed ? Icons.check_circle : Icons.shopping_cart,
              color: isUsed ? AppTheme.successColor : AppTheme.warningColor,
            ),
            title: Text(
              ingredient,
              style: TextStyle(
                decoration: isUsed ? null : TextDecoration.none,
                color: isUsed ? null : Colors.grey[600],
              ),
            ),
            trailing: isUsed
                ? const Text(
                    'You have this',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const Text(
                    'Need to buy',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          NutritionSummaryWidget(
            nutrition: _recipe!.nutrition,
            showDetails: true,
          ),
          const SizedBox(height: AppTheme.spacingM),
          NutritionVisualizationWidget(
            nutrition: _recipe!.nutrition,
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensTab() {
    if (_recipe!.allergens.isEmpty && _recipe!.intolerances.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppTheme.successColor,
            ),
            SizedBox(height: 16),
            Text(
              'No Known Allergens',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This recipe appears to be free of common allergens.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recipe!.allergens.isNotEmpty) ...[
            AllergenWarningList(
              allergens: _recipe!.allergens,
              chipSize: AllergenChipSize.large,
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
          
          if (_recipe!.intolerances.isNotEmpty) ...[
            Text(
              'Intolerances',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ..._recipe!.intolerances.map((intolerance) => Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: ListTile(
                    leading: Icon(
                      Icons.info,
                      color: AppTheme.infoColor,
                    ),
                    title: Text(intolerance.name),
                    subtitle: Text(intolerance.description),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        intolerance.type.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.infoColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
          
          // Safety disclaimer
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingL),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Always verify ingredients and consult healthcare professionals for severe allergies or medical dietary restrictions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _shareRecipe,
      icon: const Icon(Icons.share),
      label: const Text('Share Recipe'),
    );
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 80) {
      return AppTheme.successColor;
    } else if (percentage >= 60) {
      return AppTheme.warningColor;
    } else {
      return Colors.grey[600]!;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'hard':
        return AppTheme.errorColor;
      default:
        return Colors.grey[600]!;
    }
  }

  void _showAllAllergens() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Allergens',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            AllergenWarningList(
              allergens: _recipe!.allergens,
              chipSize: AllergenChipSize.large,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _shareRecipe() {
    if (_recipe == null) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    Text(
                      'Share Recipe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Choose how you\'d like to share "${_recipe!.title}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildShareOption(
                icon: Icons.share,
                title: 'General Share',
                subtitle: 'Share via any app',
                onTap: () => _handleShare(SharingPlatform.general),
              ),
              _buildShareOption(
                icon: Icons.public,
                title: 'Social Media',
                subtitle: 'Optimized for social platforms',
                onTap: () => _handleShare(SharingPlatform.social),
              ),
              _buildShareOption(
                icon: Icons.email,
                title: 'Email',
                subtitle: 'Send detailed recipe via email',
                onTap: () => _handleShare(SharingPlatform.email),
              ),
              _buildShareOption(
                icon: Icons.message,
                title: 'Messaging',
                subtitle: 'Quick share for messaging apps',
                onTap: () => _handleShare(SharingPlatform.messaging),
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleShare(SharingPlatform platform) async {
    if (_recipe == null) return;

    Navigator.of(context).pop(); // Close the bottom sheet

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing recipe to share...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      await _sharingService.shareRecipe(_recipe!, platform);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Recipe shared successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to share recipe: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleShare(platform),
            ),
          ),
        );
      }
    }
  }
}