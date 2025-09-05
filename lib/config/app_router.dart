import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/recipe/recipe_detail_screen.dart';
import '../screens/recipe_book/recipe_book_screen.dart';
import '../screens/meal_planning/meal_planning_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/subscription/subscription_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String camera = '/camera';
  static const String results = '/results';
  static const String recipeDetail = '/recipe/:id';
  static const String recipeBook = '/recipe-book';
  static const String mealPlanning = '/meal-planning';
  static const String settings = '/settings';
  static const String subscription = '/subscription';

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: home,
      redirect: (context, state) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final onboardingState = appState.state.onboarding;
        
        // Redirect to onboarding if it's the first launch and not completed
        if (onboardingState.isFirstLaunch && 
            !onboardingState.isComplete && 
            state.matchedLocation != onboarding) {
          return onboarding;
        }
        
        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'camera',
              name: 'camera',
              builder: (context, state) => const CameraScreen(),
            ),
            GoRoute(
              path: 'results',
              name: 'results',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return ResultsScreen(
                  imagePath: extra?['imagePath'] as String?,
                  recognitionResult: extra?['recognitionResult'],
                );
              },
            ),
            GoRoute(
              path: 'recipe/:id',
              name: 'recipe-detail',
              builder: (context, state) {
                final recipeId = state.pathParameters['id']!;
                final extra = state.extra as Map<String, dynamic>?;
                return RecipeDetailScreen(
                  recipeId: recipeId,
                  recipe: extra?['recipe'],
                );
              },
            ),
            GoRoute(
              path: 'recipe-book',
              name: 'recipe-book',
              builder: (context, state) => const RecipeBookScreen(),
            ),
            GoRoute(
              path: 'meal-planning',
              name: 'meal-planning',
              builder: (context, state) => const MealPlanningScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'subscription',
              name: 'subscription',
              builder: (context, state) => const SubscriptionScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.matchedLocation}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation helper extension
extension AppNavigation on BuildContext {
  void goToOnboarding() => go(AppRouter.onboarding);
  void goToHome() => go(AppRouter.home);
  void goToCamera() => go('${AppRouter.home}/camera');
  void goToResults({String? imagePath, dynamic recognitionResult}) {
    go(
      '${AppRouter.home}/results',
      extra: {
        'imagePath': imagePath,
        'recognitionResult': recognitionResult,
      },
    );
  }
  void goToRecipeDetail(String recipeId, {dynamic recipe}) {
    go(
      '${AppRouter.home}/recipe/$recipeId',
      extra: {'recipe': recipe},
    );
  }
  void goToRecipeBook() => go('${AppRouter.home}/recipe-book');
  void goToMealPlanning() => go('${AppRouter.home}/meal-planning');
  void goToSettings() => go('${AppRouter.home}/settings');
  void goToSubscription() => go('${AppRouter.home}/subscription');
  
  // Navigation with replacement
  void replaceWithHome() => pushReplacement(AppRouter.home);
  void replaceWithOnboarding() => pushReplacement(AppRouter.onboarding);
  
  // Check if can navigate back
  bool canPop() => GoRouter.of(this).canPop();
  
  // Pop current route
  void popRoute() => pop();
}