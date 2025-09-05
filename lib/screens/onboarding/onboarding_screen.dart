import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_router.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding.dart';
import '../../widgets/onboarding/onboarding_progress_indicator.dart';
import '../../widgets/onboarding/feature_demo_widget.dart';
import '../../widgets/onboarding/permission_request_widget.dart';
import '../../widgets/onboarding/demo_scan_widget.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OnboardingProvider(OnboardingServiceFactory.create()),
      child: const _OnboardingScreenContent(),
    );
  }
}

class _OnboardingScreenContent extends StatefulWidget {
  const _OnboardingScreenContent();

  @override
  State<_OnboardingScreenContent> createState() => _OnboardingScreenContentState();
}

class _OnboardingScreenContentState extends State<_OnboardingScreenContent> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Listen to onboarding provider changes to sync page controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
      _pageController = PageController(initialPage: onboardingProvider.currentStepIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<OnboardingProvider>(
      builder: (context, onboardingProvider, child) {
        if (onboardingProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spacingL),
                  Text(
                    'Loading...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        if (onboardingProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text(
                    'Error loading onboarding',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    onboardingProvider.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  ElevatedButton(
                    onPressed: () => context.goToHome(),
                    child: const Text('Skip to App'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Header with progress and skip button
                _buildHeader(context, onboardingProvider, theme),
                
                // Main content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingProvider.steps.length,
                    onPageChanged: (index) {
                      onboardingProvider.goToStep(index);
                    },
                    itemBuilder: (context, index) {
                      final step = onboardingProvider.steps[index];
                      return _buildStepContent(context, step, onboardingProvider);
                    },
                  ),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(context, onboardingProvider, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, OnboardingProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          // Skip button and progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo or app name
              Text(
                'Food Recognition',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              
              // Skip button (only show if current step is skippable)
              if (provider.canSkipCurrentStep)
                TextButton(
                  onPressed: () => _showSkipDialog(context, provider),
                  child: const Text('Skip All'),
                ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Progress indicator
          OnboardingProgressIndicator(
            currentStep: provider.currentStepIndex,
            totalSteps: provider.steps.length,
            progress: provider.progress,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, OnboardingStep step, OnboardingProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          // Step content based on type
          _buildStepWidget(context, step, provider),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Step title and description (for non-demo steps)
          if (step.type != OnboardingStepType.featureDemo) ...[
            Text(
              step.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepWidget(BuildContext context, OnboardingStep step, OnboardingProvider provider) {
    switch (step.type) {
      case OnboardingStepType.welcome:
        return _buildWelcomeWidget(context);
      case OnboardingStepType.featureDemo:
        return FeatureDemoWidget(
          demoType: step.visualDemo ?? 'default',
          title: step.title,
          description: step.description,
        );
      case OnboardingStepType.permissionRequest:
        return PermissionRequestWidget(
          onPermissionGranted: () {
            provider.markPermissionExplanationSeen();
            provider.markStepCompleted(step.id);
          },
          onPermissionDenied: () {
            // Still mark as seen, but don't mark as completed
            provider.markPermissionExplanationSeen();
          },
        );
      case OnboardingStepType.demoScan:
        return DemoScanWidget(
          onDemoScan: () => _handleDemoScan(context, provider),
          onSkipDemo: () => _handleSkipDemo(context, provider),
        );
      case OnboardingStepType.completion:
        return _buildCompletionWidget(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeWidget(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // App icon/logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 60,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Welcome message
        Text(
          '👋 Welcome!',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Feature highlights
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Column(
            children: [
              _buildFeatureHighlight(
                context,
                Icons.camera_alt,
                'Snap Photos',
                'Take pictures of any food',
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildFeatureHighlight(
                context,
                Icons.psychology,
                'AI Recognition',
                'Identify ingredients instantly',
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildFeatureHighlight(
                context,
                Icons.restaurant,
                'Get Recipes',
                'Discover personalized recipes',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHighlight(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionWidget(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.successColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 50,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        Text(
          'All Set! 🎉',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.successColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        Text(
          'You\'re ready to start discovering amazing recipes!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, OnboardingProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        children: [
          // Back button
          if (!provider.isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  provider.previousStep();
                  _pageController.previousPage(
                    duration: AppTheme.animationMedium,
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Back'),
              ),
            ),
          
          if (!provider.isFirstStep) const SizedBox(width: AppTheme.spacingM),
          
          // Next/Continue button
          Expanded(
            flex: provider.isFirstStep ? 1 : 1,
            child: ElevatedButton(
              onPressed: () => _handleNextStep(context, provider),
              child: Text(
                provider.isLastStep ? 'Get Started' : 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep(BuildContext context, OnboardingProvider provider) {
    final currentStep = provider.currentStep;
    
    // Mark current step as completed if it's not a permission request
    if (currentStep.type != OnboardingStepType.permissionRequest) {
      provider.markStepCompleted(currentStep.id);
    }
    
    if (provider.isLastStep) {
      _completeOnboarding(context, provider);
    } else {
      provider.nextStep();
      _pageController.nextPage(
        duration: AppTheme.animationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleDemoScan(BuildContext context, OnboardingProvider provider) {
    // Mark demo step as completed and go to camera
    provider.markStepCompleted(provider.currentStep.id);
    _completeOnboarding(context, provider);
    // Navigate to camera screen for demo
    context.goToCamera();
  }

  void _handleSkipDemo(BuildContext context, OnboardingProvider provider) {
    // Mark demo step as completed and finish onboarding
    provider.markStepCompleted(provider.currentStep.id);
    _completeOnboarding(context, provider);
  }

  void _completeOnboarding(BuildContext context, OnboardingProvider provider) {
    provider.completeOnboarding().then((_) {
      // Update app state to reflect onboarding completion
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      appStateProvider.updateOnboardingState(
        appStateProvider.state.onboarding.copyWith(
          isComplete: true,
          isFirstLaunch: false,
        ),
      );
      
      // Navigate to home
      context.goToHome();
    });
  }

  void _showSkipDialog(BuildContext context, OnboardingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'Are you sure you want to skip the introduction? You can always replay it later from settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.skipOnboarding().then((_) {
                _completeOnboarding(context, provider);
              });
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}