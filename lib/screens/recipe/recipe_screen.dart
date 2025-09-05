import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_recipe_service.dart';
import '../../services/sharing_service.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/recipe/recipe_filter_bar.dart';
import '../../widgets/recipe/recipe_sort_dropdown.dart';
import '../../config/app_router.dart';

class RecipeScreen extends StatefulWidget {
  final List<String>? ingredients;
  final List<Recipe>? initialRecipes;

  const RecipeScreen({
    super.key,
    this.ingredients,
    this.initialRecipes,
  });

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  String _sortBy = 'match'; // match, time, difficulty
  String _filterBy = 'all'; // all, easy, medium, hard
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late SharingServiceInterface _sharingService;

  @override
  void initState() {
    super.initState();
    _sharingService = SharingServiceFactory.create();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: widget.initialRecipes != null
          ? _buildWithInitialRecipes()
          : _buildWithProvider(),
    );
  }

  Widget _buildWithInitialRecipes() {
    final recipes = widget.initialRecipes!;
    
    if (recipes.isEmpty) {
      return _buildEmptyState();
    }

    final filteredRecipes = _filterAndSortRecipes(recipes);

    return Column(
      children: [
        _buildFilterAndSortBar(),
        Expanded(
          child: _buildRecipeGrid(filteredRecipes),
        ),
      ],
    );
  }

  Widget _buildWithProvider() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final recipeState = appState.state.recipes;
        final recipes = recipeState.suggestions;
        
        if (recipeState.isGeneratingRecipes) {
          return _buildLoadingState();
        }

        if (recipes.isEmpty) {
          return _buildEmptyState();
        }

        final filteredRecipes = _filterAndSortRecipes(recipes);

        return Column(
          children: [
            _buildFilterAndSortBar(),
            Expanded(
              child: _buildRecipeGrid(filteredRecipes),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Generating delicious recipes...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: RecipeFilterBar(
              selectedFilter: _filterBy,
              onFilterChanged: (filter) {
                setState(() {
                  _filterBy = filter;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          RecipeSortDropdown(
            selectedSort: _sortBy,
            onSortChanged: (sort) {
              setState(() {
                _sortBy = sort;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => _navigateToRecipeDetail(recipe),
          onShare: () => _shareRecipe(recipe),
        );
      },
    );
  }

  List<Recipe> _filterAndSortRecipes(List<Recipe> recipes) {
    List<Recipe> filtered = recipes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               recipe.ingredients.any((ingredient) => 
                 ingredient.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply difficulty filter
    if (_filterBy != 'all') {
      filtered = filtered.where((recipe) => recipe.difficulty == _filterBy).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'match':
        filtered.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
        break;
      case 'time':
        filtered.sort((a, b) => a.cookingTime.compareTo(b.cookingTime));
        break;
      case 'difficulty':
        filtered.sort((a, b) => _getDifficultyOrder(a.difficulty).compareTo(_getDifficultyOrder(b.difficulty)));
        break;
    }

    return filtered;
  }

  int _getDifficultyOrder(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 2;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Recipes'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by recipe name or ingredient...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    context.goToRecipeDetail(recipe.id, recipe: recipe);
  }

  Future<void> _shareRecipe(Recipe recipe) async {
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

      // Share with general platform (user can choose the app)
      await _sharingService.shareRecipe(recipe, SharingPlatform.general);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Recipe shared successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _shareRecipe(recipe),
            ),
          ),
        );
      }
    }
  }
}