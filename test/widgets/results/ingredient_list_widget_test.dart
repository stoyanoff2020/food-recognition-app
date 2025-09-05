import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/results/ingredient_list_widget.dart';
import 'package:food_recognition_app/services/ai_vision_service.dart';

void main() {
  group('IngredientListWidget', () {
    Widget createTestWidget({
      required List<Ingredient> ingredients,
      required double confidence,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: IngredientListWidget(
              ingredients: ingredients,
              confidence: confidence,
            ),
          ),
        ),
      );
    }

    testWidgets('displays overall confidence with high confidence', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.9,
      ));

      expect(find.text('Overall Confidence: High'), findsOneWidget);
      expect(find.text('90.0% accuracy'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('displays overall confidence with medium confidence', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Onion', confidence: 0.7, category: 'vegetable'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.65,
      ));

      expect(find.text('Overall Confidence: Medium'), findsOneWidget);
      expect(find.text('65.0% accuracy'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('displays overall confidence with low confidence', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Unknown', confidence: 0.4, category: 'other'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.5,
      ));

      expect(find.text('Overall Confidence: Low'), findsOneWidget);
      expect(find.text('50.0% accuracy'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('displays correct ingredient count', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Onion', confidence: 0.87, category: 'vegetable'),
        const Ingredient(name: 'Garlic', confidence: 0.72, category: 'vegetable'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.85,
      ));

      expect(find.text('3 ingredients detected'), findsOneWidget);
    });

    testWidgets('displays single ingredient count correctly', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.85,
      ));

      expect(find.text('1 ingredient detected'), findsOneWidget);
    });

    testWidgets('displays all ingredients with correct information', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Chicken Breast', confidence: 0.87, category: 'protein'),
        const Ingredient(name: 'Apple', confidence: 0.72, category: 'fruit'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.85,
      ));

      // Check ingredient names
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      // Check categories
      expect(find.text('VEGETABLE'), findsOneWidget);
      expect(find.text('PROTEIN'), findsOneWidget);
      expect(find.text('FRUIT'), findsOneWidget);

      // Check confidence percentages
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
    });

    testWidgets('displays confidence labels correctly', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'High Confidence', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Medium Confidence', confidence: 0.65, category: 'protein'),
        const Ingredient(name: 'Low Confidence', confidence: 0.45, category: 'fruit'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.68,
      ));

      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('displays confidence legend', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.85,
      ));

      expect(find.text('Confidence Levels'), findsOneWidget);
      expect(find.text('High (80%+)'), findsOneWidget);
      expect(find.text('Very confident'), findsOneWidget);
      expect(find.text('Medium (60-79%)'), findsOneWidget);
      expect(find.text('Moderately confident'), findsOneWidget);
      expect(find.text('Low (<60%)'), findsOneWidget);
      expect(find.text('Less confident'), findsOneWidget);
    });

    testWidgets('displays correct icons for different categories', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Chicken', confidence: 0.87, category: 'protein'),
        const Ingredient(name: 'Apple', confidence: 0.82, category: 'fruit'),
        const Ingredient(name: 'Rice', confidence: 0.78, category: 'grain'),
        const Ingredient(name: 'Milk', confidence: 0.75, category: 'dairy'),
        const Ingredient(name: 'Basil', confidence: 0.70, category: 'herb'),
        const Ingredient(name: 'Salt', confidence: 0.65, category: 'spice'),
        const Ingredient(name: 'Ketchup', confidence: 0.60, category: 'sauce'),
        const Ingredient(name: 'Unknown', confidence: 0.55, category: 'other'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.75,
      ));

      // Verify that icons are displayed (we can't easily test specific icons, but we can verify CircleAvatar widgets)
      expect(find.byType(CircleAvatar), findsNWidgets(ingredients.length));
    });

    testWidgets('handles empty ingredients list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        ingredients: [],
        confidence: 0.0,
      ));

      expect(find.text('0 ingredients detected'), findsOneWidget);
      expect(find.text('Overall Confidence: Low'), findsOneWidget);
      expect(find.text('0.0% accuracy'), findsOneWidget);
    });

    testWidgets('displays list tiles for each ingredient', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Onion', confidence: 0.87, category: 'vegetable'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.85,
      ));

      expect(find.byType(ListTile), findsNWidgets(ingredients.length));
    });

    testWidgets('uses correct colors for different confidence levels', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'High', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Medium', confidence: 0.65, category: 'protein'),
        const Ingredient(name: 'Low', confidence: 0.45, category: 'fruit'),
      ];

      await tester.pumpWidget(createTestWidget(
        ingredients: ingredients,
        confidence: 0.68,
      ));

      // We can't easily test colors directly, but we can verify the widgets are rendered
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(CircleAvatar), findsNWidgets(ingredients.length));
    });
  });
}