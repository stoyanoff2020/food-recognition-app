import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/widgets/recipe_book/recipe_book_search_bar.dart';

void main() {
  group('RecipeBookSearchBar', () {
    testWidgets('should display search icon when collapsed', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookSearchBar(
              onSearchChanged: (query) => searchQuery = query,
              searchQuery: '',
            ),
          ),
        ),
      );

      // Should show search icon
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should expand search field when search icon is tapped', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookSearchBar(
              onSearchChanged: (query) => searchQuery = query,
              searchQuery: '',
            ),
          ),
        ),
      );

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Should show text field and close icon
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should call onSearchChanged when text is entered', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookSearchBar(
              onSearchChanged: (query) => searchQuery = query,
              searchQuery: '',
            ),
          ),
        ),
      );

      // Expand search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'pasta');
      
      expect(searchQuery, 'pasta');
    });

    testWidgets('should clear search when clear button is tapped', (tester) async {
      String searchQuery = 'pasta';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RecipeBookSearchBar(
                onSearchChanged: (query) {
                  setState(() {
                    searchQuery = query;
                  });
                },
                searchQuery: searchQuery,
              ),
            ),
          ),
        ),
      );

      // Expand search (should be expanded since searchQuery is not empty)
      await tester.pumpAndSettle();

      // Should show clear button
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(searchQuery, '');
    });

    testWidgets('should collapse search when close button is tapped', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookSearchBar(
              onSearchChanged: (query) => searchQuery = query,
              searchQuery: '',
            ),
          ),
        ),
      );

      // Expand search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should be collapsed
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(searchQuery, '');
    });

    testWidgets('should be expanded when searchQuery is not empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookSearchBar(
              onSearchChanged: (query) {},
              searchQuery: 'pasta',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should be expanded
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}