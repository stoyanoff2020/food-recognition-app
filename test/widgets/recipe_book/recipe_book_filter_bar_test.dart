import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/widgets/recipe_book/recipe_book_filter_bar.dart';

void main() {
  group('RecipeBookFilterBar', () {
    testWidgets('should display category and sort dropdowns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookFilterBar(
              categories: ['Main Course', 'Dessert'],
              selectedCategory: null,
              sortBy: 'date',
              sortAscending: false,
              onCategoryChanged: (category) {},
              onSortChanged: (sortBy, ascending) {},
            ),
          ),
        ),
      );

      // Should show category dropdown
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);

      // Should show sort dropdown
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.text('Date Added'), findsOneWidget);

      // Should show sort direction button
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('should call onCategoryChanged when category is selected', (tester) async {
      String? selectedCategory;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookFilterBar(
              categories: ['Main Course', 'Dessert'],
              selectedCategory: null,
              sortBy: 'date',
              sortAscending: false,
              onCategoryChanged: (category) => selectedCategory = category,
              onSortChanged: (sortBy, ascending) {},
            ),
          ),
        ),
      );

      // Tap category dropdown
      await tester.tap(find.text('All Categories'));
      await tester.pumpAndSettle();

      // Select a category
      await tester.tap(find.text('Main Course').last);
      await tester.pumpAndSettle();

      expect(selectedCategory, 'Main Course');
    });

    testWidgets('should call onSortChanged when sort option is selected', (tester) async {
      String sortBy = 'date';
      bool sortAscending = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookFilterBar(
              categories: ['Main Course', 'Dessert'],
              selectedCategory: null,
              sortBy: sortBy,
              sortAscending: sortAscending,
              onCategoryChanged: (category) {},
              onSortChanged: (newSortBy, ascending) {
                sortBy = newSortBy;
                sortAscending = ascending;
              },
            ),
          ),
        ),
      );

      // Tap sort dropdown
      await tester.tap(find.text('Date Added'));
      await tester.pumpAndSettle();

      // Select name sort
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      expect(sortBy, 'name');
    });

    testWidgets('should toggle sort direction when arrow button is tapped', (tester) async {
      String sortBy = 'date';
      bool sortAscending = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RecipeBookFilterBar(
                categories: ['Main Course', 'Dessert'],
                selectedCategory: null,
                sortBy: sortBy,
                sortAscending: sortAscending,
                onCategoryChanged: (category) {},
                onSortChanged: (newSortBy, ascending) {
                  setState(() {
                    sortBy = newSortBy;
                    sortAscending = ascending;
                  });
                },
              ),
            ),
          ),
        ),
      );

      // Initially should show descending arrow
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      // Tap sort direction button
      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pump();

      expect(sortAscending, true);
    });

    testWidgets('should show selected category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookFilterBar(
              categories: ['Main Course', 'Dessert'],
              selectedCategory: 'Main Course',
              sortBy: 'date',
              sortAscending: false,
              onCategoryChanged: (category) {},
              onSortChanged: (sortBy, ascending) {},
            ),
          ),
        ),
      );

      expect(find.text('Main Course'), findsOneWidget);
    });

    testWidgets('should show ascending arrow when sortAscending is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookFilterBar(
              categories: ['Main Course', 'Dessert'],
              selectedCategory: null,
              sortBy: 'date',
              sortAscending: true,
              onCategoryChanged: (category) {},
              onSortChanged: (sortBy, ascending) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });
  });
}