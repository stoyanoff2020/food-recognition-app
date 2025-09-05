import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../lib/widgets/results/custom_ingredient_manager_widget.dart';
import '../../../lib/services/custom_ingredient_service.dart';

// Generate mocks
@GenerateMocks([CustomIngredientService])
import 'custom_ingredient_manager_widget_test.mocks.dart';

void main() {
  group('CustomIngredientManagerWidget', () {
    late MockCustomIngredientService mockService;
    late List<String> currentIngredients;
    late List<String> addedIngredients;
    late List<String> removedIngredients;

    setUp(() {
      mockService = MockCustomIngredientService();
      currentIngredients = [];
      addedIngredients = [];
      removedIngredients = [];

      // Setup default mock responses
      when(mockService.getCustomIngredients())
          .thenAnswer((_) async => []);
      when(mockService.getIngredientSuggestions())
          .thenAnswer((_) async => ['Tomato', 'Onion', 'Garlic']);
      when(mockService.getIngredientCategoryCounts())
          .thenAnswer((_) async => <String, int>{});
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

    testWidgets('should show suggestions when enabled', (tester) async {
      when(mockService.getIngredientSuggestions(query: any, limit: any))
          .thenAnswer((_) async => ['Tomato', 'Onion', 'Garlic']);

      await tester.pumpWidget(createWidget(showSuggestions: true));
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text to trigger suggestions
      await tester.enterText(find.byType(TextField), 'tom');
      await tester.pumpAndSettle();

      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.byType(ActionChip), findsWidgets);
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

    testWidgets('should show category overview when enabled and has data', (tester) async {
      when(mockService.getIngredientCategoryCounts())
          .thenAnswer((_) async => {'vegetables': 2, 'proteins': 1});

      await tester.pumpWidget(createWidget(showCategories: true));
      await tester.pumpAndSettle();

      expect(find.text('Your Ingredients by Category'), findsOneWidget);
      expect(find.text('Vegetables (2)'), findsOneWidget);
      expect(find.text('Proteins (1)'), findsOneWidget);
    });

    testWidgets('should not show category overview when disabled', (tester) async {
      when(mockService.getIngredientCategoryCounts())
          .thenAnswer((_) async => {'vegetables': 2, 'proteins': 1});

      await tester.pumpWidget(createWidget(showCategories: false));
      await tester.pumpAndSettle();

      expect(find.text('Your Ingredients by Category'), findsNothing);
    });

    testWidgets('should show manage button when has saved ingredients', (tester) async {
      when(mockService.getCustomIngredients()).thenAnswer((_) async => [
        CustomIngredient(
          name: 'Tomato',
          category: 'vegetables',
          addedDate: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manage'), findsOneWidget);
    });

    testWidgets('should not show manage button when no saved ingredients', (tester) async {
      when(mockService.getCustomIngredients())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manage'), findsNothing);
    });

    testWidgets('should show empty state when no current ingredients', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add custom ingredients to get more recipe suggestions'), findsOneWidget);
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

    testWidgets('should show loading indicator when processing', (tester) async {
      // Setup mock to simulate loading
      when(mockService.addCustomIngredient(any))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 1));
            return CustomIngredientResult(
              success: true,
              ingredient: CustomIngredient(
                name: 'Tomato',
                category: 'vegetables',
                addedDate: DateTime.now(),
              ),
            );
          });

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'tomato');
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.widgetWithText(FilledButton, 'Add Ingredient'));
      await tester.pump(); // Don't settle, so we can see loading state

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

    testWidgets('should disable suggestion chips for already added ingredients', (tester) async {
      currentIngredients.add('Tomato');
      
      when(mockService.getIngredientSuggestions(query: any, limit: any))
          .thenAnswer((_) async => ['Tomato', 'Onion']);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text to show suggestions
      await tester.enterText(find.byType(TextField), 'tom');
      await tester.pumpAndSettle();

      // Find suggestion chips
      final tomatoChip = find.widgetWithText(ActionChip, 'Tomato');
      final onionChip = find.widgetWithText(ActionChip, 'Onion');

      // Tomato should be disabled (already added)
      expect(tester.widget<ActionChip>(tomatoChip).onPressed, null);
      // Onion should be enabled
      expect(tester.widget<ActionChip>(onionChip).onPressed, isNotNull);
    });

    testWidgets('should handle suggestion chip tap', (tester) async {
      when(mockService.getIngredientSuggestions(query: any, limit: any))
          .thenAnswer((_) async => ['Tomato']);
      when(mockService.addCustomIngredient('Tomato'))
          .thenAnswer((_) async => CustomIngredientResult(
            success: true,
            ingredient: CustomIngredient(
              name: 'Tomato',
              category: 'vegetables',
              addedDate: DateTime.now(),
            ),
          ));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text to show suggestions
      await tester.enterText(find.byType(TextField), 'tom');
      await tester.pumpAndSettle();

      // Tap suggestion chip
      await tester.tap(find.widgetWithText(ActionChip, 'Tomato'));
      await tester.pumpAndSettle();

      expect(addedIngredients, contains('Tomato'));
    });
  });

  group('CustomIngredientManagerWidget Error Handling', () {
    late MockCustomIngredientService mockService;
    late List<String> currentIngredients;
    late List<String> addedIngredients;
    late List<String> removedIngredients;

    setUp(() {
      mockService = MockCustomIngredientService();
      currentIngredients = [];
      addedIngredients = [];
      removedIngredients = [];
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: CustomIngredientManagerWidget(
            currentIngredients: currentIngredients,
            onIngredientAdded: (ingredient) => addedIngredients.add(ingredient),
            onIngredientRemoved: (ingredient) => removedIngredients.add(ingredient),
          ),
        ),
      );
    }

    testWidgets('should handle service errors gracefully', (tester) async {
      when(mockService.getCustomIngredients())
          .thenThrow(Exception('Service error'));
      when(mockService.getIngredientSuggestions())
          .thenThrow(Exception('Service error'));
      when(mockService.getIngredientCategoryCounts())
          .thenThrow(Exception('Service error'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should still display the widget without crashing
      expect(find.text('Custom Ingredients'), findsOneWidget);
    });

    testWidgets('should show error snackbar for failed ingredient addition', (tester) async {
      when(mockService.addCustomIngredient(any))
          .thenAnswer((_) async => const CustomIngredientResult(
            success: false,
            error: 'Failed to add ingredient',
          ));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Show input field
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter text and add
      await tester.enterText(find.byType(TextField), 'tomato');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Ingredient'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Failed to add ingredient'), findsOneWidget);
      expect(addedIngredients, isEmpty);
    });

    testWidgets('should show error snackbar for failed ingredient removal', (tester) async {
      currentIngredients.add('Tomato');
      when(mockService.removeCustomIngredient(any))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap delete button on chip
      final deleteButton = find.descendant(
        of: find.byType(Chip),
        matching: find.byIcon(Icons.close),
      );
      
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Failed to remove ingredient'), findsOneWidget);
    });
  });
}