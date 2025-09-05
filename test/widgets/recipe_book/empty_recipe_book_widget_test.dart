import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/widgets/recipe_book/empty_recipe_book_widget.dart';

void main() {
  group('EmptyRecipeBookWidget', () {
    testWidgets('should display empty state message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyRecipeBookWidget(),
          ),
        ),
      );

      // Should show empty state title
      expect(find.text('Your Recipe Book is Empty'), findsOneWidget);
      
      // Should show description
      expect(find.text('Start building your personal recipe collection by saving recipes you discover.'), findsOneWidget);
      
      // Should show empty state icon
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });

    testWidgets('should display how-to instructions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyRecipeBookWidget(),
          ),
        ),
      );

      // Should show instructions header
      expect(find.text('How to save recipes'), findsOneWidget);
      
      // Should show lightbulb icon
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      
      // Should show step instructions
      expect(find.text('Take a photo of food to get recipe suggestions'), findsOneWidget);
      expect(find.text('Browse through the generated recipes'), findsOneWidget);
      expect(find.text('Tap the bookmark icon to save your favorites'), findsOneWidget);
    });

    testWidgets('should display action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyRecipeBookWidget(),
          ),
        ),
      );

      // Should show start scanning button
      expect(find.text('Start Scanning Food'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      
      // Should show browse recipes button
      expect(find.text('Browse Sample Recipes'), findsOneWidget);
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('should show numbered steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyRecipeBookWidget(),
          ),
        ),
      );

      // Should show step numbers
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should have proper styling for step numbers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyRecipeBookWidget(),
          ),
        ),
      );

      // Find step number containers
      final stepContainers = find.byWidgetPredicate(
        (widget) => widget is Container && 
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      
      expect(stepContainers, findsNWidgets(3));
    });
  });
}