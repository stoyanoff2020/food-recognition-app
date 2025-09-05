import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:food_recognition_app/screens/results/results_screen.dart';
import 'package:food_recognition_app/providers/app_state_provider.dart';
import 'package:food_recognition_app/providers/ai_vision_provider.dart';
import 'package:food_recognition_app/services/ai_vision_service.dart';

import 'results_screen_test.mocks.dart';

@GenerateMocks([AIVisionServiceInterface])
void main() {
  group('ResultsScreen', () {
    late MockAIVisionServiceInterface mockAIVisionService;
    late AppStateProvider appStateProvider;
    late AIVisionProvider aiVisionProvider;

    setUp(() {
      mockAIVisionService = MockAIVisionServiceInterface();
      appStateProvider = AppStateProvider();
      aiVisionProvider = AIVisionProvider(aiVisionService: mockAIVisionService);
    });

    Widget createTestWidget({
      String? imagePath,
      FoodRecognitionResult? recognitionResult,
    }) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
            ChangeNotifierProvider<AIVisionProvider>.value(value: aiVisionProvider),
          ],
          child: ResultsScreen(
            imagePath: imagePath,
            recognitionResult: recognitionResult,
          ),
        ),
      );
    }

    testWidgets('displays loading state when recognition is processing', (WidgetTester tester) async {
      // Set processing state
      appStateProvider.setRecognitionProcessing(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analyzing your image...'), findsOneWidget);
    });

    testWidgets('displays error state with retry option', (WidgetTester tester) async {
      const errorMessage = 'Network error occurred';
      appStateProvider.setRecognitionError(errorMessage);

      await tester.pumpWidget(createTestWidget(imagePath: '/test/image.jpg'));

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Take New Photo'), findsOneWidget);
    });

    testWidgets('displays recognition results with ingredients', (WidgetTester tester) async {
      final ingredients = [
        const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable'),
        const Ingredient(name: 'Onion', confidence: 0.87, category: 'vegetable'),
        const Ingredient(name: 'Garlic', confidence: 0.72, category: 'vegetable'),
      ];

      final result = FoodRecognitionResult.success(
        ingredients: ingredients,
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Detected Ingredients'), findsOneWidget);
      expect(find.text('3 ingredients detected'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Onion'), findsOneWidget);
      expect(find.text('Garlic'), findsOneWidget);
      expect(find.text('Overall Confidence: High'), findsOneWidget);
    });

    testWidgets('displays no ingredients detected message', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [],
        confidence: 0.0,
        processingTime: 1500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('No ingredients detected'), findsOneWidget);
      expect(find.text('Try taking another photo or add ingredients manually'), findsOneWidget);
    });

    testWidgets('shows custom ingredient input when add button is tapped', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      // Find and tap the add button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Ingredient'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Add Ingredient'), findsOneWidget);
    });

    testWidgets('adds custom ingredient when submitted', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      // Open custom ingredient input
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter ingredient name
      await tester.enterText(find.byType(TextField), 'Basil');
      await tester.tap(find.text('Add Ingredient'));
      await tester.pumpAndSettle();

      // Verify ingredient was added
      expect(appStateProvider.state.recipes.customIngredients, contains('Basil'));
      expect(find.text('Basil'), findsOneWidget);
    });

    testWidgets('removes custom ingredient when delete is tapped', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);
      appStateProvider.addCustomIngredient('Basil');

      await tester.pumpWidget(createTestWidget());

      // Find and tap the delete button on the chip
      final deleteButton = find.byIcon(Icons.close);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify ingredient was removed
      expect(appStateProvider.state.recipes.customIngredients, isEmpty);
    });

    testWidgets('displays image when imagePath is provided', (WidgetTester tester) async {
      // Create a temporary test image file
      final testImagePath = '/tmp/test_image.jpg';
      
      // Mock the file existence and image loading
      await tester.pumpWidget(createTestWidget(imagePath: testImagePath));

      // The image widget should be present even if file doesn't exist (shows error state)
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows get recipe suggestions button', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Get Recipe Suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('shows refresh button when imagePath is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(imagePath: '/test/image.jpg'));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('hides refresh button when no imagePath is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('calls retry recognition when refresh button is tapped', (WidgetTester tester) async {
      const testImagePath = '/test/image.jpg';
      
      when(mockAIVisionService.analyzeImage(testImagePath))
          .thenAnswer((_) async => FoodRecognitionResult.success(
                ingredients: [const Ingredient(name: 'Apple', confidence: 0.9, category: 'fruit')],
                confidence: 0.9,
                processingTime: 2000,
              ));

      await tester.pumpWidget(createTestWidget(imagePath: testImagePath));

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Verify the service was called
      verify(mockAIVisionService.analyzeImage(testImagePath)).called(1);
    });

    testWidgets('displays confidence levels legend', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Confidence Levels'), findsOneWidget);
      expect(find.text('High (80%+)'), findsOneWidget);
      expect(find.text('Medium (60-79%)'), findsOneWidget);
      expect(find.text('Low (<60%)'), findsOneWidget);
    });

    testWidgets('shows custom ingredients placeholder when none added', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add custom ingredients to get more recipe suggestions'), findsOneWidget);
    });

    testWidgets('cancels custom ingredient input when cancel is tapped', (WidgetTester tester) async {
      final result = FoodRecognitionResult.success(
        ingredients: [const Ingredient(name: 'Tomato', confidence: 0.95, category: 'vegetable')],
        confidence: 0.85,
        processingTime: 2500,
      );

      appStateProvider.setRecognitionResults(result);

      await tester.pumpWidget(createTestWidget());

      // Open custom ingredient input
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter some text
      await tester.enterText(find.byType(TextField), 'Test ingredient');

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify input is hidden and text is cleared
      expect(find.text('Add Custom Ingredient'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}