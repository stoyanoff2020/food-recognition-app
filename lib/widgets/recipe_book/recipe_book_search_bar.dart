import 'package:flutter/material.dart';

class RecipeBookSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String searchQuery;

  const RecipeBookSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.searchQuery,
  });

  @override
  State<RecipeBookSearchBar> createState() => _RecipeBookSearchBarState();
}

class _RecipeBookSearchBarState extends State<RecipeBookSearchBar> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _isExpanded = widget.searchQuery.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _controller.clear();
        widget.onSearchChanged('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isExpanded ? 48 : 0,
              child: _isExpanded
                  ? TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Search recipes, ingredients, or tags...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  widget.onSearchChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: widget.onSearchChanged,
                      autofocus: true,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (!_isExpanded) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: 'Search recipes',
            ),
          ] else ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
              tooltip: 'Close search',
            ),
          ],
        ],
      ),
    );
  }
}