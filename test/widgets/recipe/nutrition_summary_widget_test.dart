import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/recipe/nutrition_summary_widget.dart';
import 'package:food_recognition_app/services/ai_recipe_service.dart';
import 'package:food_recognition_app/models/app_state.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('NutritionSummaryWidget Tests', () {
    late NutritionInfo testNutrition;

    setUp(() {
      testNutrition = const NutritionInfo(
        calories: 350,
        protein: 25.5,
        carbohydrates: 45.2,
        fat: 12.8,
        fiber: 8.3,
        sugar: 6.1,
        sodium: 580.2,
        servingSize: '1 cup',
      );
    });

    testWidgets('displays compact view correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionSummaryWidget(
              nutrition: testNutrition,
              isCompact: true,
            ),
          ),
        ),
      );

      // Verify compact view shows calories
      expect(find.text('350 cal'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

      // Should not show detailed nutrition in compact view
      expect(find.text('Nutrition Facts'), findsNothing);
    });

    testWidgets('displays detailed view correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionSummaryWidget(
              nutrition: testNutrition,
              isCompact: false,
            ),
          ),
        ),
      );

      // Verify detailed view shows title and serving size
      expect(find.text('Nutrition Facts'), findsOneWidget);
      expect(find.text('Per 1 cup'), findsOneWidget);

      // Verify main nutrients are displayed
      expect(find.text('350kcal'), findsOneWidget); // calories
      expect(find.text('25.5g'), findsOneWidget); // protein
      expect(find.text('45.2g'), findsOneWidget); // carbs
      expect(find.text('12.8g'), findsOneWidget); // fat

      // Verify nutrient labels
      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
    });

    testWidgets('shows additional nutrients when showDetails is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionSummaryWidget(
              nutrition: testNutrition,
              isCompact: false,
              showDetails: true,
            ),
          ),
        ),
      );

      // Verify additional nutrients section
      expect(find.text('Additional Nutrients'), findsOneWidget);
      expect(find.text('Fiber'), findsOneWidget);
      expect(find.text('Sugar'), findsOneWidget);
      expect(find.text('Sodium'), findsOneWidget);

      // Verify values
      expect(find.text('8.3g'), findsOneWidget); // fiber
      expect(find.text('6.1g'), findsOneWidget); // sugar
      expect(find.text('580.2mg'), findsOneWidget); // sodium
    });

    testWidgets('displays correct nutrient icons and colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionSummaryWidget(
              nutrition: testNutrition,
              isCompact: false,
            ),
          ),
        ),
      );

      // Verify nutrient icons are present
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget); // calories
      expect(find.byIcon(Icons.fitness_center), findsOneWidget); // protein
      expect(find.byIcon(Icons.grain), findsOneWidget); // carbs
      expect(find.byIcon(Icons.opacity), findsOneWidget); // fat
    });
  });

  group('NutritionVisualizationWidget Tests', () {
    late NutritionInfo testNutrition;
    late NutritionGoals testGoals;

    setUp(() {
      testNutrition = const NutritionInfo(
        calories: 350,
        protein: 25.5,
        carbohydrates: 45.2,
        fat: 12.8,
        fiber: 8.3,
        sugar: 6.1,
        sodium: 580.2,
        servingSize: '1 cup',
      );

      testGoals = const NutritionGoals(
        dailyCalories: 2000,
        dailyProtein: 150.0,
        dailyCarbohydrates: 250.0,
        dailyFat: 65.0,
        dailyFiber: 25.0,
        dailySodium: 2300.0,
      );
    });

    testWidgets('displays macronutrient breakdown chart', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionVisualizationWidget(
              nutrition: testNutrition,
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('Nutrition Breakdown'), findsOneWidget);

      // Verify macronutrient percentages are calculated and displayed
      // Total macros = 25.5 + 45.2 + 12.8 = 83.5
      // Protein: 25.5/83.5 ≈ 30%
      // Carbs: 45.2/83.5 ≈ 54%
      // Fat: 12.8/83.5 ≈ 15%
      expect(find.textContaining('%'), findsAtLeastNWidgets(3));

      // Verify legend items
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
    });

    testWidgets('displays goal progress when goals are provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionVisualizationWidget(
              nutrition: testNutrition,
              goals: testGoals,
            ),
          ),
        ),
      );

      // Verify goal progress section
      expect(find.text('Daily Goal Progress'), findsOneWidget);

      // Verify progress bars for each nutrient
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(4));

      // Verify nutrient labels in progress section
      expect(find.text('Calories'), findsAtLeastNWidgets(1));
      expect(find.text('Protein'), findsAtLeastNWidgets(1));
      expect(find.text('Carbs'), findsAtLeastNWidgets(1));
      expect(find.text('Fat'), findsAtLeastNWidgets(1));
    });

    testWidgets('handles zero macronutrients gracefully', (WidgetTester tester) async {
      const zeroNutrition = NutritionInfo(
        calories: 0,
        protein: 0.0,
        carbohydrates: 0.0,
        fat: 0.0,
        fiber: 0.0,
        sugar: 0.0,
        sodium: 0.0,
        servingSize: '1 serving',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionVisualizationWidget(
              nutrition: zeroNutrition,
            ),
          ),
        ),
      );

      // Should show message when no macronutrient data
      expect(find.text('No macronutrient data available'), findsOneWidget);
    });

    testWidgets('calculates progress percentages correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionVisualizationWidget(
              nutrition: testNutrition,
              goals: testGoals,
            ),
          ),
        ),
      );

      // Calories: 350/2000 = 17.5% ≈ 17%
      // Protein: 25.5/150 = 17%
      // Carbs: 45.2/250 = 18.08% ≈ 18%
      // Fat: 12.8/65 = 19.69% ≈ 19%

      expect(find.text('17%'), findsAtLeastNWidgets(1)); // calories or protein
      expect(find.text('18%'), findsOneWidget); // carbs
      expect(find.text('19%'), findsOneWidget); // fat
    });

    testWidgets('does not show goal progress when goals are null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionVisualizationWidget(
              nutrition: testNutrition,
              goals: null,
            ),
          ),
        ),
      );

      // Should not show goal progress section
      expect(find.text('Daily Goal Progress'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('handles progress over 100%', (WidgetTester tester) async {
      const highNutrition = NutritionInfo(
        calories: 3000, // Over daily goal of 2000
        protein: 200.0, // Over daily goal of 150
        carbohydrates: 300.0, // Over daily goal of 250
        fat: 80.0, // Over daily goal of 65
        fiber: 30.0,
        sugar: 10.0,
        sodium: 2500.0,
        servingSize: '1 large serving',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NutritionVisualizationWidget(
              nutrition: highNutrition,
              goals: testGoals,
            ),
          ),
        ),
      );

      // Should show actual percentages even over 100%
      // Just verify that progress bars are shown for over 100% values
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(4));
      expect(find.textContaining('%'), findsAtLeastNWidgets(4));
    });
  });
}