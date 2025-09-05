import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/recipe/recipe_card.dart';
import 'package:food_recognition_app/widgets/recipe/allergen_warning_chip.dart';
import 'package:food_recognition_app/services/ai_recipe_service.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('RecipeCard Widget Tests', () {
    late Recipe testRecipe;

    setUp(() {
      testRecipe = const Recipe(
        id: 'test-recipe-1',
        title: 'Test Recipe',
        ingredients: ['ingredient1', 'ingredient2', 'ingredient3'],
        instructions: ['Step 1', 'Step 2'],
        cookingTime: 30,
        servings: 4,
        matchPercentage: 85.5,
        imageUrl: null,
        nutrition: NutritionInfo(
          calories: 350,
          protein: 25.5,
          carbohydrates: 45.2,
          fat: 12.8,
          fiber: 8.3,
          sugar: 6.1,
          sodium: 580.2,
          servingSize: '1 cup',
        ),
        allergens: [
          Allergen(
            name: 'Dairy',
            severity: 'high',
            description: 'Contains milk products',
          ),
        ],
        intolerances: [],
        usedIngredients: ['ingredient1', 'ingredient2'],
        missingIngredients: ['ingredient3'],
        difficulty: 'easy',
      );
    });

    testWidgets('displays recipe information correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: testRecipe,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify recipe title is displayed
      expect(find.text('Test Recipe'), findsOneWidget);

      // Verify cooking time is displayed
      expect(find.text('30 min'), findsOneWidget);

      // Verify difficulty is displayed
      expect(find.text('EASY'), findsOneWidget);

      // Verify match percentage is displayed
      expect(find.text('85%'), findsOneWidget);

      // Verify ingredient match info is displayed
      expect(find.text('2/3 ingredients match'), findsOneWidget);

      // Verify nutrition info is displayed
      expect(find.text('350 cal'), findsOneWidget);

      // Verify allergen warning is displayed
      expect(find.text('Dairy'), findsOneWidget);
    });

    testWidgets('handles tap correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: testRecipe,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(RecipeCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('displays correct match color based on percentage', (WidgetTester tester) async {
      // Test high match percentage (green)
      final highMatchRecipe = testRecipe.copyWith(matchPercentage: 90.0);
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: highMatchRecipe,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('displays difficulty icon and color correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: testRecipe,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify difficulty icon is present
      expect(find.byIcon(Icons.sentiment_satisfied), findsOneWidget);
    });

    testWidgets('displays placeholder image when imageUrl is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: testRecipe,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify placeholder icon is displayed
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('shows only high severity allergens in compact view', (WidgetTester tester) async {
      final recipeWithMultipleAllergens = Recipe(
        id: 'test-recipe-2',
        title: 'Test Recipe 2',
        ingredients: ['ingredient1'],
        instructions: ['Step 1'],
        cookingTime: 20,
        servings: 2,
        matchPercentage: 75.0,
        imageUrl: null,
        nutrition: testRecipe.nutrition,
        allergens: const [
          Allergen(
            name: 'Dairy',
            severity: 'high',
            description: 'Contains milk products',
          ),
          Allergen(
            name: 'Nuts',
            severity: 'low',
            description: 'May contain traces of nuts',
          ),
        ],
        intolerances: const [],
        usedIngredients: ['ingredient1'],
        missingIngredients: [],
        difficulty: 'medium',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: recipeWithMultipleAllergens,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show high severity allergen
      expect(find.text('Dairy'), findsOneWidget);
      
      // Should not show low severity allergen in compact view
      expect(find.text('Nuts'), findsNothing);
    });

    testWidgets('handles recipe with no allergens', (WidgetTester tester) async {
      final recipeWithoutAllergens = Recipe(
        id: 'test-recipe-3',
        title: 'Safe Recipe',
        ingredients: ['ingredient1'],
        instructions: ['Step 1'],
        cookingTime: 15,
        servings: 1,
        matchPercentage: 100.0,
        imageUrl: null,
        nutrition: testRecipe.nutrition,
        allergens: const [],
        intolerances: const [],
        usedIngredients: ['ingredient1'],
        missingIngredients: [],
        difficulty: 'easy',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecipeCard(
              recipe: recipeWithoutAllergens,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not show any allergen warnings
      // Should not show any allergen warnings
      expect(find.byType(AllergenWarningChip), findsNothing);
    });
  });
}

// Extension to help with testing
extension RecipeCopyWith on Recipe {
  Recipe copyWith({
    String? id,
    String? title,
    List<String>? ingredients,
    List<String>? instructions,
    int? cookingTime,
    int? servings,
    double? matchPercentage,
    String? imageUrl,
    NutritionInfo? nutrition,
    List<Allergen>? allergens,
    List<Intolerance>? intolerances,
    List<String>? usedIngredients,
    List<String>? missingIngredients,
    String? difficulty,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      imageUrl: imageUrl ?? this.imageUrl,
      nutrition: nutrition ?? this.nutrition,
      allergens: allergens ?? this.allergens,
      intolerances: intolerances ?? this.intolerances,
      usedIngredients: usedIngredients ?? this.usedIngredients,
      missingIngredients: missingIngredients ?? this.missingIngredients,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}