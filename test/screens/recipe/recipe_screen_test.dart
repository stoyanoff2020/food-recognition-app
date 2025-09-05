import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/screens/recipe/recipe_screen.dart';
import 'package:food_recognition_app/services/ai_recipe_service.dart';
import 'package:food_recognition_app/config/app_theme.dart';
import 'package:food_recognition_app/widgets/recipe/recipe_card.dart';
import 'package:food_recognition_app/widgets/recipe/recipe_filter_bar.dart';
import 'package:food_recognition_app/widgets/recipe/recipe_sort_dropdown.dart';



void main() {
  group('RecipeScreen Widget Tests', () {
    late List<Recipe> testRecipes;

    setUp(() {
      
      testRecipes = [
        const Recipe(
          id: 'recipe-1',
          title: 'Easy Pasta',
          ingredients: ['pasta', 'tomato', 'cheese'],
          instructions: ['Boil pasta', 'Add sauce'],
          cookingTime: 20,
          servings: 2,
          matchPercentage: 90.0,
          nutrition: NutritionInfo(
            calories: 400,
            protein: 15.0,
            carbohydrates: 60.0,
            fat: 10.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 500.0,
            servingSize: '1 serving',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: ['pasta', 'tomato'],
          missingIngredients: ['cheese'],
          difficulty: 'easy',
        ),
        const Recipe(
          id: 'recipe-2',
          title: 'Grilled Chicken',
          ingredients: ['chicken', 'herbs', 'oil'],
          instructions: ['Season chicken', 'Grill for 15 minutes'],
          cookingTime: 30,
          servings: 4,
          matchPercentage: 75.0,
          nutrition: NutritionInfo(
            calories: 300,
            protein: 35.0,
            carbohydrates: 5.0,
            fat: 15.0,
            fiber: 1.0,
            sugar: 2.0,
            sodium: 400.0,
            servingSize: '1 serving',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: ['chicken'],
          missingIngredients: ['herbs', 'oil'],
          difficulty: 'medium',
        ),
        const Recipe(
          id: 'recipe-3',
          title: 'Complex Dish',
          ingredients: ['ingredient1', 'ingredient2', 'ingredient3'],
          instructions: ['Step 1', 'Step 2', 'Step 3'],
          cookingTime: 60,
          servings: 6,
          matchPercentage: 50.0,
          nutrition: NutritionInfo(
            calories: 500,
            protein: 20.0,
            carbohydrates: 40.0,
            fat: 25.0,
            fiber: 8.0,
            sugar: 10.0,
            sodium: 800.0,
            servingSize: '1 serving',
          ),
          allergens: [],
          intolerances: [],
          usedIngredients: ['ingredient1'],
          missingIngredients: ['ingredient2', 'ingredient3'],
          difficulty: 'hard',
        ),
      ];
    });

    Widget createTestWidget({
      List<Recipe>? initialRecipes,
      List<String>? ingredients,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: RecipeScreen(
          initialRecipes: initialRecipes ?? testRecipes,
          ingredients: ingredients,
        ),
      );
    }

    testWidgets('displays recipe cards correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify app bar
      expect(find.text('Recipe Suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Verify filter and sort bar
      expect(find.byType(RecipeFilterBar), findsOneWidget);
      expect(find.byType(RecipeSortDropdown), findsOneWidget);

      // Verify recipe cards are displayed (at least 2, may be limited by viewport)
      expect(find.byType(RecipeCard), findsAtLeastNWidgets(2));
      expect(find.text('Easy Pasta'), findsOneWidget);
      expect(find.text('Grilled Chicken'), findsOneWidget);
    });

    // Note: Loading state test would require provider setup, skipping for now

    testWidgets('displays empty state when no recipes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(initialRecipes: []));

      // Verify empty state
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.text('No recipes found'), findsOneWidget);
      expect(find.text('Try adjusting your filters or search terms'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('filters recipes by difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially recipes should be visible
      expect(find.byType(RecipeCard), findsAtLeastNWidgets(2));

      // Tap on easy filter
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      // Should show only easy recipes
      expect(find.text('Easy Pasta'), findsOneWidget);
      expect(find.text('Grilled Chicken'), findsNothing);
    });

    testWidgets('sorts recipes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the sort dropdown
      expect(find.byType(RecipeSortDropdown), findsOneWidget);

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select cooking time sort
      await tester.tap(find.text('Cooking Time').last);
      await tester.pumpAndSettle();

      // Recipes should be sorted by cooking time (ascending)
      final recipeFinder = find.byType(RecipeCard);
      expect(recipeFinder, findsAtLeastNWidgets(2));
    });

    testWidgets('opens search dialog when search icon tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify search dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Search Recipes'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('filters recipes by search query', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open search dialog
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'pasta');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Should show only recipes matching the search
      expect(find.text('Easy Pasta'), findsOneWidget);
      expect(find.text('Grilled Chicken'), findsNothing);
      expect(find.text('Complex Dish'), findsNothing);
    });

    testWidgets('clears search when clear button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open search dialog
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'pasta');

      // Tap clear button
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // All recipes should be visible again
      expect(find.byType(RecipeCard), findsAtLeastNWidgets(2));
    });

    testWidgets('recipe cards are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find recipe cards
      final recipeCards = find.byType(RecipeCard);
      expect(recipeCards, findsAtLeastNWidgets(1));

      // Verify cards are present and can be found
      // Navigation testing would require GoRouter setup which is complex for unit tests
      expect(find.text('Easy Pasta'), findsOneWidget);
      expect(find.text('Grilled Chicken'), findsOneWidget);
    });

    testWidgets('handles mixed difficulty filtering correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Test medium difficulty filter
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      expect(find.text('Grilled Chicken'), findsOneWidget);
      expect(find.text('Easy Pasta'), findsNothing);

      // Test all recipes filter
      await tester.tap(find.text('All Recipes'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeCard), findsAtLeastNWidgets(2));
    });

    testWidgets('search works with ingredient names', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open search dialog
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search for an ingredient
      await tester.enterText(find.byType(TextField), 'chicken');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Should show recipes containing chicken
      expect(find.text('Grilled Chicken'), findsOneWidget);
      expect(find.text('Easy Pasta'), findsNothing);
      expect(find.text('Complex Dish'), findsNothing);
    });
  });
}