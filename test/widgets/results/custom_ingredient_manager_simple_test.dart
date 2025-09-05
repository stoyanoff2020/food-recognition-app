import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/widgets/results/custom_ingredient_manager_widget.dart';

void main() {
  group('CustomIngredientManagerWidget', () {
    late List<String> currentIngredients;
    late List<String> addedIngredients;
    late List<String> removedIngredients;

    setUp(() {
      currentIngredients = [];
      addedIngredients = [];
      removedIngredients = [];
    });

    Widget createWidget({
      bool showSuggestions = true,
      bool showCategories = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CustomIngredientManagerWidget(
            currentIngredients: currentIngredients,
            onIngredientAdded: (ingredient) => addedIngredients.add(ingredient),
            onIngredientRemoved: (ingredient) => removedIngredients.add(ingredient),
            showSuggestions: showSuggestions,
            showCategories: showCategories,
          ),
        ),
      );
    }

    testWidgets('should display title and add button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Custom Ingredients'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should show input field when add button is tapped', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Ingredient'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should hide input field when close button is tapped', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Hide input field
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Ingredient'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should display current ingredients as chips', (tester) async {
      currentIngredients.addAll(['Tomato', 'Onion']);
      
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Current Custom Ingredients (2)'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Onion'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('should call onIngredientRemoved when chip is deleted', (tester) async {
      currentIngredients.add('Tomato');
      
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap the delete button on the chip
      final deleteButton = find.descendant(
        of: find.byType(Chip),
        matching: find.byIcon(Icons.close),
      );
      
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(removedIngredients, contains('Tomato'));
    });

    testWidgets('should show empty state when no current ingredients', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add custom ingredients to get more recipe suggestions'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid input', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter invalid text (too short)
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Ingredient name must be at least 2 characters long'), findsOneWidget);
    });

    testWidgets('should clear input when cancel is tapped', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'tomato');
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Input should be hidden and cleared
      expect(find.text('Add Custom Ingredient'), findsNothing);
      
      // Show input again to verify it's cleared
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should show tips section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Tip: Be specific with ingredient names for better recipe suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('should not show suggestions when disabled', (tester) async {
      await tester.pumpWidget(createWidget(showSuggestions: false));
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'tom');
      await tester.pumpAndSettle();

      expect(find.text('Suggestions'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('should enable add button only when text is valid', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Find the "Add Ingredient" button
      final addButton = find.widgetWithText(FilledButton, 'Add Ingredient');
      
      // Should be disabled initially
      expect(tester.widget<FilledButton>(addButton).onPressed, null);

      // Enter valid text
      await tester.enterText(find.byType(TextField), 'tomato');
      await tester.pumpAndSettle();

      // Should be enabled now
      expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);
    });
  });
}