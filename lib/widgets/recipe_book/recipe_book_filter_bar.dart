import 'package:flutter/material.dart';

class RecipeBookFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final String sortBy;
  final bool sortAscending;
  final Function(String?) onCategoryChanged;
  final Function(String, bool) onSortChanged;

  const RecipeBookFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.sortBy,
    required this.sortAscending,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Category filter
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...categories.map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                )),
              ],
              onChanged: onCategoryChanged,
            ),
          ),
          const SizedBox(width: 16),
          // Sort options
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'date',
                  child: Text('Date Added'),
                ),
                DropdownMenuItem<String>(
                  value: 'name',
                  child: Text('Name'),
                ),
                DropdownMenuItem<String>(
                  value: 'cookingTime',
                  child: Text('Cooking Time'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value, sortAscending);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sort direction
          IconButton(
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () => onSortChanged(sortBy, !sortAscending),
            tooltip: sortAscending ? 'Sort ascending' : 'Sort descending',
          ),
        ],
      ),
    );
  }
}