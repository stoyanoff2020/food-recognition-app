import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/results/custom_ingredient_input_widget.dart';

void main() {
  group('CustomIngredientInputWidget', () {
    late TextEditingController controller;
    late FocusNode focusNode;
    bool onAddCalled = false;
    bool onCancelCalled = false;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
      onAddCalled = false;
      onCancelCalled = false;
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: CustomIngredientInputWidget(
            controller: controller,
            focusNode: focusNode,
            onAdd: () => onAddCalled = true,
            onCancel: () => onCancelCalled = true,
          ),
        ),
      );
    }

    testWidgets('displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add Custom Ingredient'), findsOneWidget);
      expect(find.text('Add ingredients that weren\'t detected or that you have available'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Ingredient'), findsOneWidget);
      expect(find.text('Tip: Be specific with ingredient names for better recipe suggestions'), findsOneWidget);
    });

    testWidgets('displays correct hint text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('e.g., Tomatoes, Onions, Garlic...'), findsOneWidget);
    });

    testWidgets('has correct text field configuration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller, equals(controller));
      expect(textField.focusNode, equals(focusNode));
      expect(textField.textCapitalization, equals(TextCapitalization.words));
      expect(textField.textInputAction, equals(TextInputAction.done));
    });

    testWidgets('add button is disabled when text is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final addButton = find.byIcon(Icons.add);
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: addButton, matching: find.byType(ElevatedButton)),
      );
      
      expect(elevatedButton.onPressed, isNull);

      final filledButton = find.widgetWithText(FilledButton, 'Add Ingredient');
      final filledButtonWidget = tester.widget<FilledButton>(filledButton);
      expect(filledButtonWidget.onPressed, isNull);
    });

    testWidgets('add button is enabled when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter text
      await tester.enterText(find.byType(TextField), 'Basil');
      await tester.pump();

      final addButton = find.byIcon(Icons.add);
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: addButton, matching: find.byType(ElevatedButton)),
      );
      
      expect(elevatedButton.onPressed, isNotNull);

      final filledButton = find.widgetWithText(FilledButton, 'Add Ingredient');
      final filledButtonWidget = tester.widget<FilledButton>(filledButton);
      expect(filledButtonWidget.onPressed, isNotNull);
    });

    testWidgets('calls onAdd when add icon button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter text
      await tester.enterText(find.byType(TextField), 'Basil');
      await tester.pump();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(onAddCalled, isTrue);
    });

    testWidgets('calls onAdd when Add Ingredient button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter text
      await tester.enterText(find.byType(TextField), 'Basil');
      await tester.pump();

      // Tap Add Ingredient button
      await tester.tap(find.text('Add Ingredient'));
      await tester.pump();

      expect(onAddCalled, isTrue);
    });

    testWidgets('calls onAdd when text field is submitted', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'Basil');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(onAddCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(onCancelCalled, isTrue);
    });

    testWidgets('does not call onAdd when text is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to submit empty text
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(onAddCalled, isFalse);
    });

    testWidgets('does not call onAdd when text is only whitespace', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter only whitespace
      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(onAddCalled, isFalse);
    });

    testWidgets('displays tip section with correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.text('Tip: Be specific with ingredient names for better recipe suggestions'), findsOneWidget);
    });

    testWidgets('has correct prefix icon in text field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration as InputDecoration;
      final prefixIcon = decoration.prefixIcon as Icon;
      
      expect(prefixIcon.icon, equals(Icons.add_circle_outline));
    });

    testWidgets('updates button state when text changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially disabled
      final addButton = find.byIcon(Icons.add);
      var elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: addButton, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, isNull);

      // Enter text - should enable
      await tester.enterText(find.byType(TextField), 'Basil');
      await tester.pump();

      elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: addButton, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, isNotNull);

      // Clear text - should disable again
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: addButton, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('has correct button icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('maintains focus node reference', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, equals(focusNode));
    });
  });
}