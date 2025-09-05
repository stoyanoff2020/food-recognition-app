import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/subscription.dart';
import '../../services/recipe_book_service.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_service.dart';
import '../../services/sharing_service.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/recipe_book/recipe_book_search_bar.dart';
import '../../widgets/recipe_book/recipe_book_filter_bar.dart';
import '../../widgets/recipe_book/upgrade_prompt_widget.dart';
import '../../widgets/recipe_book/empty_recipe_book_widget.dart';

class RecipeBookScreen extends StatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  State<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends State<RecipeBookScreen> {
  late RecipeBookService _recipeBookService;
  late SharingServiceInterface _sharingService;
  List<SavedRecipe> _recipes = [];
  List<SavedRecipe> _filteredRecipes = [];
  List<String> _categories = [];
  List<String> _tags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'date'; // date, name, cookingTime
  bool _sortAscending = false;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _sharingService = SharingServiceFactory.create();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final storageService = StorageServiceFactory.create();
    await storageService.initialize();
    
    final subscriptionService = context.read<SubscriptionService>();
    
    _recipeBookService = RecipeBookServiceFactory.create(
      storageService: storageService,
      subscriptionService: subscriptionService,
    );
    
    await _checkAccess();
    if (_hasAccess) {
      await _loadData();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkAccess() async {
    try {
      _hasAccess = await _recipeBookService.hasRecipeBookAccess();
    } catch (e) {
      _hasAccess = false;
    }
  }

  Future<void> _loadData() async {
    try {
      final recipes = await _recipeBookService.getSavedRecipes();
      final categories = await _recipeBookService.getCategories();
      final tags = await _recipeBookService.getTags();
      
      setState(() {
        _recipes = recipes;
        _categories = categories;
        _tags = tags;
        _filteredRecipes = recipes;
      });
      
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<SavedRecipe> filtered = List.from(_recipes);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               recipe.ingredients.any((ingredient) => 
                   ingredient.toLowerCase().contains(_searchQuery.toLowerCase())) ||
               recipe.tags.any((tag) => 
                   tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((recipe) => recipe.category == _selectedCategory).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.title.compareTo(b.title);
          break;
        case 'cookingTime':
          comparison = a.cookingTime.compareTo(b.cookingTime);
          break;
        case 'date':
        default:
          comparison = DateTime.parse(a.savedDate).compareTo(DateTime.parse(b.savedDate));
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredRecipes = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _onSortChanged(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
    });
    _applyFilters();
  }

  Future<void> _deleteRecipe(SavedRecipe recipe) async {
    try {
      await _recipeBookService.deleteRecipe(recipe.id);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${recipe.title}" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // In a real implementation, we'd implement undo functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Undo not implemented yet')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting recipe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editRecipe(SavedRecipe recipe) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RecipeEditDialog(
        recipe: recipe,
        categories: _categories,
        tags: _tags,
      ),
    );
    
    if (result != null) {
      try {
        await _recipeBookService.updateRecipeMetadata(
          recipe.id,
          category: result['category'],
          tags: List<String>.from(result['tags']),
          personalNotes: result['notes'],
        );
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating recipe: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareRecipe(SavedRecipe recipe) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Book'),
        actions: [
          if (_hasAccess && _recipes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Toggle search bar visibility
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? const UpgradePromptWidget(
                  feature: 'Recipe Book',
                  description: 'Save and organize your favorite recipes with Premium or Professional subscription.',
                  requiredTier: 'Premium',
                )
              : _recipes.isEmpty
                  ? const EmptyRecipeBookWidget()
                  : Column(
                      children: [
                        RecipeBookSearchBar(
                          onSearchChanged: _onSearchChanged,
                          searchQuery: _searchQuery,
                        ),
                        RecipeBookFilterBar(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          sortBy: _sortBy,
                          sortAscending: _sortAscending,
                          onCategoryChanged: _onCategoryChanged,
                          onSortChanged: _onSortChanged,
                        ),
                        Expanded(
                          child: _filteredRecipes.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No recipes found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your search or filters',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _filteredRecipes.length,
                                  itemBuilder: (context, index) {
                                    final recipe = _filteredRecipes[index];
                                    return RecipeCard(
                                      recipe: recipe,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/recipe-detail',
                                          arguments: recipe,
                                        );
                                      },
                                      showActions: true,
                                      onShare: () => _shareRecipe(recipe),
                                      onEdit: () => _editRecipe(recipe),
                                      onDelete: () => _deleteRecipe(recipe),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}

class _RecipeEditDialog extends StatefulWidget {
  final SavedRecipe recipe;
  final List<String> categories;
  final List<String> tags;

  const _RecipeEditDialog({
    required this.recipe,
    required this.categories,
    required this.tags,
  });

  @override
  State<_RecipeEditDialog> createState() => _RecipeEditDialogState();
}

class _RecipeEditDialogState extends State<_RecipeEditDialog> {
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.recipe.category);
    _notesController = TextEditingController(text: widget.recipe.personalNotes ?? '');
    _selectedTags = List.from(widget.recipe.tags);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit "${widget.recipe.title}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.categories.contains(_categoryController.text) 
                  ? _categoryController.text 
                  : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select or enter category',
              ),
              items: [
                ...widget.categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom...'),
                ),
              ],
              onChanged: (value) {
                if (value == 'custom') {
                  // Show text field for custom category
                } else if (value != null) {
                  _categoryController.text = value;
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Tags'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ...widget.tags.map((tag) => FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Personal Notes'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add your personal notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'category': _categoryController.text,
              'tags': _selectedTags,
              'notes': _notesController.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}