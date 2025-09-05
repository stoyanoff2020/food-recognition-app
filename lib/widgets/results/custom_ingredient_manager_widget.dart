import 'package:flutter/material.dart';
import '../../services/custom_ingredient_service.dart';
import '../../services/storage_service.dart';

/// Enhanced widget for managing custom ingredients with validation and suggestions
class CustomIngredientManagerWidget extends StatefulWidget {
  final List<String> currentIngredients;
  final Function(String) onIngredientAdded;
  final Function(String) onIngredientRemoved;
  final bool showSuggestions;
  final bool showCategories;

  const CustomIngredientManagerWidget({
    super.key,
    required this.currentIngredients,
    required this.onIngredientAdded,
    required this.onIngredientRemoved,
    this.showSuggestions = true,
    this.showCategories = true,
  });

  @override
  State<CustomIngredientManagerWidget> createState() => _CustomIngredientManagerWidgetState();
}

class _CustomIngredientManagerWidgetState extends State<CustomIngredientManagerWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final CustomIngredientService _ingredientService;
  
  List<CustomIngredient> _savedIngredients = [];
  List<String> _suggestions = [];
  Map<String, int> _categoryCounts = {};
  String? _validationError;
  bool _isLoading = false;
  bool _showInput = false;

  @override
  void initState() {
    super.initState();
    _ingredientService = CustomIngredientService(StorageServiceFactory.create());
    _controller.addListener(_onTextChanged);
    _loadData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final ingredients = await _ingredientService.getCustomIngredients();
      final suggestions = await _ingredientService.getIngredientSuggestions();
      final categoryCounts = await _ingredientService.getIngredientCategoryCounts();
      
      if (mounted) {
        setState(() {
          _savedIngredients = ingredients;
          _suggestions = suggestions;
          _categoryCounts = categoryCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load ingredients: $e');
      }
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _validationError = null;
        _suggestions = [];
      });
      return;
    }

    // Validate input
    final validation = _ingredientService.validateIngredient(text);
    setState(() {
      _validationError = validation.isValid ? null : validation.error;
    });

    // Update suggestions based on input
    _updateSuggestions(text);
  }

  Future<void> _updateSuggestions(String query) async {
    try {
      final suggestions = await _ingredientService.getIngredientSuggestions(
        query: query,
        limit: 8,
      );
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e) {
      debugPrint('Error updating suggestions: $e');
    }
  }

  Future<void> _addIngredient([String? ingredientName]) async {
    final ingredient = ingredientName ?? _controller.text.trim();
    if (ingredient.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _ingredientService.addCustomIngredient(ingredient);
      
      if (result.success && result.ingredient != null) {
        widget.onIngredientAdded(result.ingredient!.name);
        _controller.clear();
        setState(() => _showInput = false);
        await _loadData(); // Refresh data
        
        _showSuccessSnackBar('Added "${result.ingredient!.name}" to your ingredients');
      } else {
        _showErrorSnackBar(result.error ?? 'Failed to add ingredient');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding ingredient: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeIngredient(String ingredientName) async {
    try {
      final success = await _ingredientService.removeCustomIngredient(ingredientName);
      
      if (success) {
        widget.onIngredientRemoved(ingredientName);
        await _loadData(); // Refresh data
        
        _showSuccessSnackBar('Removed "$ingredientName" from your ingredients');
      } else {
        _showErrorSnackBar('Failed to remove ingredient');
      }
    } catch (e) {
      _showErrorSnackBar('Error removing ingredient: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildCategoryChip(String category, int count) {
    final categoryNames = {
      'proteins': 'Proteins',
      'vegetables': 'Vegetables',
      'fruits': 'Fruits',
      'grains': 'Grains',
      'dairy': 'Dairy',
      'spices': 'Spices',
      'oils': 'Oils',
      'other': 'Other',
    };

    final categoryIcons = {
      'proteins': Icons.egg_outlined,
      'vegetables': Icons.eco,
      'fruits': Icons.apple,
      'grains': Icons.grain,
      'dairy': Icons.local_drink,
      'spices': Icons.grass,
      'oils': Icons.water_drop,
      'other': Icons.restaurant,
    };

    return Chip(
      avatar: Icon(
        categoryIcons[category] ?? Icons.restaurant,
        size: 16,
      ),
      label: Text('${categoryNames[category] ?? category} ($count)'),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_savedIngredients.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showManageDialog(),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Manage'),
                  ),
                IconButton(
                  icon: Icon(_showInput ? Icons.close : Icons.add),
                  onPressed: () {
                    setState(() {
                      _showInput = !_showInput;
                    });
                    if (_showInput) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _focusNode.requestFocus();
                      });
                    } else {
                      _controller.clear();
                    }
                  },
                  tooltip: _showInput ? 'Cancel' : 'Add Ingredient',
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Category overview (if enabled and has data)
        if (widget.showCategories && _categoryCounts.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Ingredients by Category',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _categoryCounts.entries
                        .map((entry) => _buildCategoryChip(entry.key, entry.value))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

        if (widget.showCategories && _categoryCounts.isNotEmpty)
          const SizedBox(height: 16),

        // Input section
        if (_showInput)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Custom Ingredient',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add ingredients that weren\'t detected or that you have available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input field
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g., Tomatoes, Onions, Garlic...',
                      prefixIcon: const Icon(Icons.add_circle_outline),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _controller.clear(),
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _validationError,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => _showInput = false);
                          _controller.clear();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _controller.text.trim().isNotEmpty && 
                                  _validationError == null && 
                                  !_isLoading
                            ? () => _addIngredient()
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Add Ingredient'),
                      ),
                    ],
                  ),

                  // Suggestions
                  if (widget.showSuggestions && _suggestions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Suggestions',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _suggestions.map((suggestion) {
                            final isAlreadyAdded = widget.currentIngredients
                                .any((ingredient) => ingredient.toLowerCase() == 
                                     suggestion.toLowerCase());
                            
                            return ActionChip(
                              label: Text(suggestion),
                              onPressed: isAlreadyAdded ? null : () => _addIngredient(suggestion),
                              backgroundColor: isAlreadyAdded 
                                  ? Colors.grey[200]
                                  : Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: isAlreadyAdded
                                    ? Colors.grey[600]
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                             color: Colors.blue[700], 
                             size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: Be specific with ingredient names for better recipe suggestions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_showInput) const SizedBox(height: 16),

        // Current ingredients display
        if (widget.currentIngredients.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Custom Ingredients (${widget.currentIngredients.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.currentIngredients.map((ingredient) {
                      return Chip(
                        label: Text(ingredient),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => widget.onIngredientRemoved(ingredient),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          )
        else if (!_showInput)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add custom ingredients to get more recipe suggestions',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showManageDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomIngredientManageDialog(
        ingredientService: _ingredientService,
        onChanged: _loadData,
      ),
    );
  }
}

/// Dialog for managing saved custom ingredients
class _CustomIngredientManageDialog extends StatefulWidget {
  final CustomIngredientService ingredientService;
  final VoidCallback onChanged;

  const _CustomIngredientManageDialog({
    required this.ingredientService,
    required this.onChanged,
  });

  @override
  State<_CustomIngredientManageDialog> createState() => _CustomIngredientManageDialogState();
}

class _CustomIngredientManageDialogState extends State<_CustomIngredientManageDialog> {
  List<CustomIngredient> _ingredients = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final ingredients = await widget.ingredientService.getCustomIngredients();
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<CustomIngredient> get _filteredIngredients {
    if (_searchQuery.isEmpty) return _ingredients;
    
    return _ingredients.where((ingredient) =>
        ingredient.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _deleteIngredient(CustomIngredient ingredient) async {
    final success = await widget.ingredientService.removeCustomIngredient(ingredient.name);
    if (success) {
      setState(() {
        _ingredients.removeWhere((item) => item.name == ingredient.name);
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Ingredients',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Ingredients list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredIngredients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty 
                                    ? 'No saved ingredients'
                                    : 'No ingredients found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = _filteredIngredients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  ingredient.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(ingredient.name),
                              subtitle: Text(
                                '${ingredient.category} • Used ${ingredient.usageCount} times',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteIngredient(ingredient),
                              ),
                            );
                          },
                        ),
            ),

            // Footer
            if (_ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_ingredients.length} total ingredients',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      onPressed: () => _showClearAllDialog(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Ingredients'),
        content: const Text(
          'Are you sure you want to delete all your custom ingredients? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await widget.ingredientService.clearAllCustomIngredients();
              if (mounted) {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close manage dialog
                widget.onChanged();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}