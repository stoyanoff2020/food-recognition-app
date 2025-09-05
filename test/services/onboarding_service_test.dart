import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/models/onboarding.dart';
import '../../lib/services/onboarding_service.dart';

@GenerateMocks([SharedPreferences])
import 'onboarding_service_test.mocks.dart';

void main() {
  group('OnboardingService', () {
    late OnboardingServiceImpl onboardingService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      onboardingService = OnboardingServiceImpl();
      
      // Mock SharedPreferences.getInstance()
      SharedPreferences.setMockInitialValues({});
    });

    group('isFirstLaunch', () {
      test('returns true when first launch key is not set', () async {
        when(mockPrefs.getBool('first_launch')).thenReturn(null);
        
        // Since we can't easily mock SharedPreferences.getInstance(),
        // we'll test the actual implementation
        final result = await onboardingService.isFirstLaunch();
        expect(result, isTrue);
      });

      test('returns false when first launch key is false', () async {
        SharedPreferences.setMockInitialValues({'first_launch': false});
        
        final result = await onboardingService.isFirstLaunch();
        expect(result, isFalse);
      });

      test('returns true when first launch key is true', () async {
        SharedPreferences.setMockInitialValues({'first_launch': true});
        
        final result = await onboardingService.isFirstLaunch();
        expect(result, isTrue);
      });
    });

    group('markOnboardingComplete', () {
      test('sets first launch to false and updates onboarding data', () async {
        SharedPreferences.setMockInitialValues({});
        
        await onboardingService.markOnboardingComplete();
        
        final isFirstLaunch = await onboardingService.isFirstLaunch();
        expect(isFirstLaunch, isFalse);
        
        final data = await onboardingService.getOnboardingData();
        expect(data.isComplete, isTrue);
        expect(data.completionDate, isNotNull);
      });
    });

    group('resetOnboarding', () {
      test('resets first launch to true and clears onboarding data', () async {
        SharedPreferences.setMockInitialValues({
          'first_launch': false,
          'onboarding_data': '{"isComplete": true}'
        });
        
        await onboardingService.resetOnboarding();
        
        final isFirstLaunch = await onboardingService.isFirstLaunch();
        expect(isFirstLaunch, isTrue);
        
        final data = await onboardingService.getOnboardingData();
        expect(data.isComplete, isFalse);
      });
    });

    group('getCurrentOnboardingStep', () {
      test('returns 0 when no step is set', () async {
        SharedPreferences.setMockInitialValues({});
        
        final step = await onboardingService.getCurrentOnboardingStep();
        expect(step, equals(0));
      });

      test('returns saved step when set', () async {
        const testStep = 3;
        await onboardingService.setOnboardingStep(testStep);
        
        final step = await onboardingService.getCurrentOnboardingStep();
        expect(step, equals(testStep));
      });
    });

    group('setOnboardingStep', () {
      test('saves the onboarding step', () async {
        const testStep = 2;
        
        await onboardingService.setOnboardingStep(testStep);
        
        final step = await onboardingService.getCurrentOnboardingStep();
        expect(step, equals(testStep));
      });
    });

    group('shouldShowPermissionExplanation', () {
      test('returns true when permission explanation has not been seen', () async {
        SharedPreferences.setMockInitialValues({});
        
        final shouldShow = await onboardingService.shouldShowPermissionExplanation();
        expect(shouldShow, isTrue);
      });

      test('returns false when permission explanation has been seen', () async {
        await onboardingService.markPermissionExplanationSeen();
        
        final shouldShow = await onboardingService.shouldShowPermissionExplanation();
        expect(shouldShow, isFalse);
      });
    });

    group('markPermissionExplanationSeen', () {
      test('marks permission explanation as seen', () async {
        await onboardingService.markPermissionExplanationSeen();
        
        final shouldShow = await onboardingService.shouldShowPermissionExplanation();
        expect(shouldShow, isFalse);
      });
    });

    group('getOnboardingData', () {
      test('returns default data when no data is stored', () async {
        SharedPreferences.setMockInitialValues({});
        
        final data = await onboardingService.getOnboardingData();
        expect(data.isComplete, isFalse);
        expect(data.completedSteps, isEmpty);
        expect(data.lastShownStep, equals(0));
        expect(data.hasSeenPermissionExplanation, isFalse);
      });

      test('returns stored data when available', () async {
        const testData = OnboardingData(
          isComplete: true,
          completedSteps: [1, 2, 3],
          lastShownStep: 3,
          hasSeenPermissionExplanation: true,
          completionDate: '2023-01-01T00:00:00.000Z',
        );
        
        await onboardingService.saveOnboardingData(testData);
        
        final data = await onboardingService.getOnboardingData();
        expect(data.isComplete, isTrue);
        expect(data.completedSteps, equals([1, 2, 3]));
        expect(data.lastShownStep, equals(3));
        expect(data.hasSeenPermissionExplanation, isTrue);
        expect(data.completionDate, equals('2023-01-01T00:00:00.000Z'));
      });

      test('returns default data when stored data is corrupted', () async {
        SharedPreferences.setMockInitialValues({
          'onboarding_data': 'invalid json'
        });
        
        final data = await onboardingService.getOnboardingData();
        expect(data.isComplete, isFalse);
        expect(data.completedSteps, isEmpty);
      });
    });

    group('saveOnboardingData', () {
      test('saves onboarding data correctly', () async {
        const testData = OnboardingData(
          isComplete: true,
          completedSteps: [1, 2],
          lastShownStep: 2,
          hasSeenPermissionExplanation: true,
        );
        
        await onboardingService.saveOnboardingData(testData);
        
        final savedData = await onboardingService.getOnboardingData();
        expect(savedData.isComplete, equals(testData.isComplete));
        expect(savedData.completedSteps, equals(testData.completedSteps));
        expect(savedData.lastShownStep, equals(testData.lastShownStep));
        expect(savedData.hasSeenPermissionExplanation, equals(testData.hasSeenPermissionExplanation));
      });
    });

    group('markStepCompleted', () {
      test('adds step to completed steps list', () async {
        await onboardingService.markStepCompleted(1);
        await onboardingService.markStepCompleted(3);
        
        final data = await onboardingService.getOnboardingData();
        expect(data.completedSteps, contains(1));
        expect(data.completedSteps, contains(3));
      });

      test('does not add duplicate steps', () async {
        await onboardingService.markStepCompleted(1);
        await onboardingService.markStepCompleted(1);
        
        final data = await onboardingService.getOnboardingData();
        expect(data.completedSteps.where((step) => step == 1).length, equals(1));
      });
    });

    group('getOnboardingSteps', () {
      test('returns correct number of onboarding steps', () {
        final steps = onboardingService.getOnboardingSteps();
        expect(steps.length, equals(6));
      });

      test('returns steps with correct properties', () {
        final steps = onboardingService.getOnboardingSteps();
        
        // Check welcome step
        final welcomeStep = steps.firstWhere((step) => step.type == OnboardingStepType.welcome);
        expect(welcomeStep.title, equals('Welcome to Food Recognition'));
        expect(welcomeStep.skipable, isFalse);
        
        // Check feature demo steps
        final featureDemoSteps = steps.where((step) => step.type == OnboardingStepType.featureDemo).toList();
        expect(featureDemoSteps.length, equals(3));
        
        // Check permission request step
        final permissionStep = steps.firstWhere((step) => step.type == OnboardingStepType.permissionRequest);
        expect(permissionStep.title, equals('Camera Permission'));
        expect(permissionStep.skipable, isFalse);
        
        // Check demo scan step
        final demoScanStep = steps.firstWhere((step) => step.type == OnboardingStepType.demoScan);
        expect(demoScanStep.title, equals('Try a Demo Scan'));
      });

      test('returns steps with sequential IDs', () {
        final steps = onboardingService.getOnboardingSteps();
        
        for (int i = 0; i < steps.length; i++) {
          expect(steps[i].id, equals(i));
        }
      });
    });

    group('OnboardingServiceFactory', () {
      test('creates OnboardingServiceImpl instance', () {
        final service = OnboardingServiceFactory.create();
        expect(service, isA<OnboardingServiceImpl>());
      });
    });
  });
}