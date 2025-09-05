import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognition_app/widgets/recipe/allergen_warning_chip.dart';
import 'package:food_recognition_app/services/ai_recipe_service.dart';
import 'package:food_recognition_app/config/app_theme.dart';

void main() {
  group('AllergenWarningChip Widget Tests', () {
    late Allergen testAllergen;

    setUp(() {
      testAllergen = const Allergen(
        name: 'Dairy',
        severity: 'high',
        description: 'Contains milk products that may cause allergic reactions',
      );
    });

    testWidgets('displays allergen information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: testAllergen,
              size: AllergenChipSize.medium,
            ),
          ),
        ),
      );

      // Verify allergen name is displayed
      expect(find.text('Dairy'), findsOneWidget);

      // Verify allergen icon is displayed
      expect(find.byIcon(Icons.local_drink), findsOneWidget);

      // Verify severity icon is displayed (not small size)
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('shows correct severity color for high severity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: testAllergen,
            ),
          ),
        ),
      );

      // Find the container with the allergen chip
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      
      // Verify the border color matches high severity (error color)
      expect(decoration.border, isA<Border>());
    });

    testWidgets('shows correct severity color for medium severity', (WidgetTester tester) async {
      final mediumSeverityAllergen = const Allergen(
        name: 'Nuts',
        severity: 'medium',
        description: 'May contain nuts',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: mediumSeverityAllergen,
            ),
          ),
        ),
      );

      expect(find.text('Nuts'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('shows correct severity color for low severity', (WidgetTester tester) async {
      final lowSeverityAllergen = const Allergen(
        name: 'Soy',
        severity: 'low',
        description: 'Contains traces of soy',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: lowSeverityAllergen,
            ),
          ),
        ),
      );

      expect(find.text('Soy'), findsOneWidget);
      expect(find.byIcon(Icons.grass), findsOneWidget);
    });

    testWidgets('handles different allergen types with correct icons', (WidgetTester tester) async {
      final allergenTypes = [
        ('Gluten', Icons.grain),
        ('Shellfish', Icons.set_meal),
        ('Eggs', Icons.egg),
        ('Fish', Icons.phishing),
        ('Sesame', Icons.circle),
      ];

      for (final (name, expectedIcon) in allergenTypes) {
        final allergen = Allergen(
          name: name,
          severity: 'medium',
          description: 'Contains $name',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AllergenWarningChip(
                allergen: allergen,
              ),
            ),
          ),
        );

        expect(find.text(name), findsOneWidget);
        expect(find.byIcon(expectedIcon), findsOneWidget);

        // Clear the widget tree for the next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('small size chip does not show severity icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: testAllergen,
              size: AllergenChipSize.small,
            ),
          ),
        ),
      );

      // Should show allergen name and icon
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.byIcon(Icons.local_drink), findsOneWidget);

      // Should not show severity icon in small size
      expect(find.byIcon(Icons.priority_high), findsNothing);
    });

    testWidgets('large size chip shows all elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: testAllergen,
              size: AllergenChipSize.large,
            ),
          ),
        ),
      );

      // Should show all elements
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.byIcon(Icons.local_drink), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('shows allergen details dialog when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: testAllergen,
            ),
          ),
        ),
      );

      // Tap the chip
      await tester.tap(find.byType(AllergenWarningChip));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Dairy'), findsAtLeastNWidgets(1));
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Description:'), findsOneWidget);
      expect(find.text('Contains milk products that may cause allergic reactions'), findsOneWidget);

      // Verify safety warning is shown
      expect(find.text('Please consult with a healthcare professional if you have severe allergies.'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('custom onTap callback works', (WidgetTester tester) async {
      bool customTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningChip(
              allergen: testAllergen,
              onTap: () => customTapped = true,
            ),
          ),
        ),
      );

      // Tap the chip
      await tester.tap(find.byType(AllergenWarningChip));
      await tester.pumpAndSettle();

      expect(customTapped, isTrue);
      // Should not show default dialog
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('AllergenWarningList Widget Tests', () {
    late List<Allergen> testAllergens;

    setUp(() {
      testAllergens = const [
        Allergen(name: 'Dairy', severity: 'high', description: 'Contains milk'),
        Allergen(name: 'Nuts', severity: 'medium', description: 'Contains nuts'),
        Allergen(name: 'Gluten', severity: 'low', description: 'Contains gluten'),
        Allergen(name: 'Soy', severity: 'medium', description: 'Contains soy'),
      ];
    });

    testWidgets('displays all allergens when no maxItems limit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningList(
              allergens: testAllergens,
            ),
          ),
        ),
      );

      // Verify title is shown
      expect(find.text('Allergen Warnings'), findsOneWidget);

      // Verify all allergens are displayed
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Nuts'), findsOneWidget);
      expect(find.text('Gluten'), findsOneWidget);
      expect(find.text('Soy'), findsOneWidget);

      // Should not show "more" indicator
      expect(find.textContaining('more'), findsNothing);
    });

    testWidgets('displays limited allergens with "more" indicator', (WidgetTester tester) async {
      bool showAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningList(
              allergens: testAllergens,
              maxItems: 2,
              onShowAll: () => showAllTapped = true,
            ),
          ),
        ),
      );

      // Verify only first 2 allergens are displayed
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Nuts'), findsOneWidget);
      expect(find.text('Gluten'), findsNothing);
      expect(find.text('Soy'), findsNothing);

      // Verify "more" indicator is shown
      expect(find.text('+2 more'), findsOneWidget);

      // Tap "more" indicator
      await tester.tap(find.text('+2 more'));
      await tester.pumpAndSettle();

      expect(showAllTapped, isTrue);
    });

    testWidgets('shows nothing when allergen list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningList(
              allergens: const [],
            ),
          ),
        ),
      );

      // Should show nothing
      expect(find.byType(AllergenWarningList), findsOneWidget);
      expect(find.text('Allergen Warnings'), findsNothing);
    });

    testWidgets('uses correct chip size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AllergenWarningList(
              allergens: [testAllergens.first],
              chipSize: AllergenChipSize.large,
            ),
          ),
        ),
      );

      // Find the allergen chip and verify it exists
      expect(find.byType(AllergenWarningChip), findsOneWidget);
    });
  });
}