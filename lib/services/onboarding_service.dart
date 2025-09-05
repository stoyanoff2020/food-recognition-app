import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding.dart';

abstract class OnboardingService {
  Future<bool> isFirstLaunch();
  Future<void> markOnboardingComplete();
  Future<void> resetOnboarding();
  Future<int> getCurrentOnboardingStep();
  Future<void> setOnboardingStep(int step);
  Future<bool> shouldShowPermissionExplanation();
  Future<void> markPermissionExplanationSeen();
  Future<OnboardingData> getOnboardingData();
  Future<void> saveOnboardingData(OnboardingData data);
  Future<void> markStepCompleted(int stepId);
  List<OnboardingStep> getOnboardingSteps();
}

class OnboardingServiceImpl implements OnboardingService {
  static const String _onboardingDataKey = 'onboarding_data';
  static const String _firstLaunchKey = 'first_launch';

  @override
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  @override
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    
    final data = await getOnboardingData();
    final updatedData = data.copyWith(
      isComplete: true,
      completionDate: DateTime.now().toIso8601String(),
    );
    await saveOnboardingData(updatedData);
  }

  @override
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
    await prefs.remove(_onboardingDataKey);
  }

  @override
  Future<int> getCurrentOnboardingStep() async {
    final data = await getOnboardingData();
    return data.lastShownStep;
  }

  @override
  Future<void> setOnboardingStep(int step) async {
    final data = await getOnboardingData();
    final updatedData = data.copyWith(lastShownStep: step);
    await saveOnboardingData(updatedData);
  }

  @override
  Future<bool> shouldShowPermissionExplanation() async {
    final data = await getOnboardingData();
    return !data.hasSeenPermissionExplanation;
  }

  @override
  Future<void> markPermissionExplanationSeen() async {
    final data = await getOnboardingData();
    final updatedData = data.copyWith(hasSeenPermissionExplanation: true);
    await saveOnboardingData(updatedData);
  }

  @override
  Future<OnboardingData> getOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_onboardingDataKey);
    
    if (jsonString == null) {
      return const OnboardingData();
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return OnboardingData.fromJson(json);
    } catch (e) {
      // If there's an error parsing, return default data
      return const OnboardingData();
    }
  }

  @override
  Future<void> saveOnboardingData(OnboardingData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data.toJson());
    await prefs.setString(_onboardingDataKey, jsonString);
  }

  @override
  Future<void> markStepCompleted(int stepId) async {
    final data = await getOnboardingData();
    final completedSteps = List<int>.from(data.completedSteps);
    
    if (!completedSteps.contains(stepId)) {
      completedSteps.add(stepId);
    }
    
    final updatedData = data.copyWith(completedSteps: completedSteps);
    await saveOnboardingData(updatedData);
  }

  @override
  List<OnboardingStep> getOnboardingSteps() {
    return [
      const OnboardingStep(
        id: 0,
        title: 'Welcome to Food Recognition',
        description: 'Discover recipes instantly by taking photos of your ingredients. Let\'s get started!',
        type: OnboardingStepType.welcome,
        skipable: false,
      ),
      const OnboardingStep(
        id: 1,
        title: 'Snap & Identify',
        description: 'Take a photo of any food item and our AI will identify the ingredients with confidence scores.',
        visualDemo: 'camera_demo',
        type: OnboardingStepType.featureDemo,
      ),
      const OnboardingStep(
        id: 2,
        title: 'Get Recipe Suggestions',
        description: 'Receive personalized recipe recommendations based on your identified ingredients.',
        visualDemo: 'recipe_demo',
        type: OnboardingStepType.featureDemo,
      ),
      const OnboardingStep(
        id: 3,
        title: 'Customize Your Recipes',
        description: 'Add your own ingredients to get even more recipe options tailored to what you have.',
        visualDemo: 'customize_demo',
        type: OnboardingStepType.featureDemo,
      ),
      const OnboardingStep(
        id: 4,
        title: 'Camera Permission',
        description: 'We need camera access to take photos of your food. This is essential for ingredient recognition.',
        type: OnboardingStepType.permissionRequest,
        skipable: false,
      ),
      const OnboardingStep(
        id: 5,
        title: 'Try a Demo Scan',
        description: 'Ready to try it out? Take your first photo or skip to explore the app.',
        type: OnboardingStepType.demoScan,
      ),
    ];
  }
}

// Factory for creating onboarding service instances
class OnboardingServiceFactory {
  static OnboardingService create() {
    return OnboardingServiceImpl();
  }
}