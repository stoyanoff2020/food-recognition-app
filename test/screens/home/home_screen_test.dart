import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:food_recognition_app/screens/home/home_screen.dart';
import 'package:food_recognition_app/providers/app_state_provider.dart';
import 'package:food_recognition_app/providers/camera_provider.dart';
import 'package:food_recognition_app/services/camera_service.dart';
import 'package:food_recognition_app/models/app_state.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([
  AppStateProvider,
  CameraProvider,
  CameraServiceInterface,
])
void main() {
  group('HomeScreen Widget Tests', () {
    late MockAppStateProvider mockAppStateProvider;
    late MockCameraProvider mockCameraProvider;
    late MockCameraServiceInterface mockCameraService;

    setUp(() {
      mockAppStateProvider = MockAppStateProvider();
      mockCameraProvider = MockCameraProvider();
      mockCameraService = MockCameraServiceInterface();

      // Setup default app state
      final appState = AppState(
        camera: const CameraState(
          isActive: false,
          hasPermission: true,
          lastCapturedImage: null,
        ),
        recognition: const RecognitionState(
          isProcessing: false,
          results: null,
          error: null,
        ),
        recipes: const RecipeState(
          suggestions: [],
          selectedRecipe: null,
          isLoading: false,
          customIngredients: [],
        ),
        user: const UserState(
          preferences: UserPreferences(
            dietaryRestrictions: [],
            preferredCuisines: [],
            skillLevel: 'beginner',
          ),
          favoriteRecipes: [],
          recentSearches: [],
        ),
        onboarding: const OnboardingState(
          isFirstLaunch: false,
          currentStep: 0,
          isComplete: true,
        ),
        subscription: SubscriptionState(
          currentTier: SubscriptionTier(
            type: 'free',
            features: const [],
            quotas: UsageQuota(
              dailyScans: 1,
              usedScans: 0,
              resetTime: DateTime.now(),
              adWatchesAvailable: 3,
              historyDays: 7,
            ),
            price: 0,
            billingPeriod: 'monthly',
          ),
          usageQuota: UsageQuota(
            dailyScans: 1,
            usedScans: 0,
            resetTime: DateTime.now(),
            adWatchesAvailable: 3,
            historyDays: 7,
          ),
          isLoading: false,
          lastUpdated: DateTime.now(),
        ),
      );

      when(mockAppStateProvider.state).thenReturn(appState);
      when(mockAppStateProvider.hasFeatureAccess(any)).thenReturn(false);
      
      // Setup camera provider defaults
      when(mockCameraProvider.isInitialized).thenReturn(false);
      when(mockCameraProvider.isInitializing).thenReturn(false);
      when(mockCameraProvider.isCapturing).thenReturn(false);
      when(mockCameraProvider.lastError).thenReturn(null);
      when(mockCameraProvider.cameraService).thenReturn(mockCameraService);
      when(mockCameraProvider.initialize()).thenAnswer((_) async => true);
      when(mockCameraProvider.dispose()).thenAnswer((_) async {});
      when(mockCameraProvider.capturePhoto()).thenAnswer((_) async => '/test/path.jpg');
      when(mockCameraProvider.getMaxZoomLevel()).thenAnswer((_) async => 4.0);
      when(mockCameraProvider.getMinZoomLevel()).thenAnswer((_) async => 1.0);
      
      // Setup camera service defaults
      when(mockCameraService.isInitialized).thenReturn(false);
      when(mockCameraService.controller).thenReturn(null);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: mockAppStateProvider),
          ChangeNotifierProvider<CameraProvider>.value(value: mockCameraProvider),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
        ),
      );
    }

    testWidgets('displays app branding when camera preview is hidden', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Food Recognition App'), findsOneWidget);
      expect(find.text('Capture food photos to discover recipes'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('displays camera section with placeholder when camera is not active', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Tap to open camera'), findsOneWidget);
      expect(find.text('Open Camera'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('displays quick actions section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Full Screen Camera'), findsOneWidget);
      expect(find.text('Recipe Book (Premium)'), findsOneWidget);
      expect(find.text('Meal Planning (Professional)'), findsOneWidget);
    });

    testWidgets('shows unlocked features for premium users', (WidgetTester tester) async {
      when(mockAppStateProvider.hasFeatureAccess('recipe_book')).thenReturn(true);
      when(mockAppStateProvider.hasFeatureAccess('meal_planning')).thenReturn(true);
      
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Recipe Book'), findsOneWidget);
      expect(find.text('Meal Planning'), findsOneWidget);
      expect(find.text('Recipe Book (Premium)'), findsNothing);
      expect(find.text('Meal Planning (Professional)'), findsNothing);
    });

    testWidgets('displays subscription information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Current Plan: FREE'), findsOneWidget);
      expect(find.text('Daily scans: 0/1'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
    });

    testWidgets('displays bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows camera preview toggle button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show camera toggle button
      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));
      
      // Tap the camera toggle button
      await tester.tap(find.byIcon(Icons.camera_alt).first);
      await tester.pump();

      // Verify camera initialization was called
      verify(mockCameraProvider.initialize()).called(1);
    });

    testWidgets('displays loading indicator when camera is initializing', (WidgetTester tester) async {
      when(mockCameraProvider.isInitializing).thenReturn(true);
      
      await tester.pumpWidget(createTestWidget());

      // Toggle camera preview
      await tester.tap(find.byIcon(Icons.camera_alt).first);
      await tester.pump();

      expect(find.text('Initializing camera...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('displays error message when camera initialization fails', (WidgetTester tester) async {
      when(mockCameraProvider.isInitialized).thenReturn(false);
      when(mockCameraProvider.lastError).thenReturn('Camera not available');
      
      await tester.pumpWidget(createTestWidget());

      // Toggle camera preview
      await tester.tap(find.byIcon(Icons.camera_alt).first);
      await tester.pump();

      expect(find.text('Camera not available'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}