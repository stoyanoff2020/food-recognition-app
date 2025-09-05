import 'package:flutter/foundation.dart';
import '../models/onboarding.dart';
import '../services/onboarding_service.dart';

class OnboardingProvider extends ChangeNotifier {
  final OnboardingService _onboardingService;
  
  OnboardingData _data = const OnboardingData();
  List<OnboardingStep> _steps = [];
  int _currentStepIndex = 0;
  bool _isLoading = false;
  String? _error;

  OnboardingProvider(this._onboardingService) {
    _steps = _onboardingService.getOnboardingSteps();
    _loadOnboardingData();
  }

  // Getters
  OnboardingData get data => _data;
  List<OnboardingStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  OnboardingStep get currentStep => _steps[_currentStepIndex];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep => _currentStepIndex == _steps.length - 1;
  double get progress => (_currentStepIndex + 1) / _steps.length;
  bool get canSkipCurrentStep => currentStep.skipable;

  Future<void> _loadOnboardingData() async {
    _setLoading(true);
    try {
      _data = await _onboardingService.getOnboardingData();
      _currentStepIndex = _data.lastShownStep;
      _clearError();
    } catch (e) {
      _setError('Failed to load onboarding data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> nextStep() async {
    if (isLastStep) {
      await completeOnboarding();
      return;
    }

    _currentStepIndex++;
    await _updateCurrentStep();
  }

  Future<void> previousStep() async {
    if (isFirstStep) return;

    _currentStepIndex--;
    await _updateCurrentStep();
  }

  Future<void> goToStep(int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= _steps.length) return;

    _currentStepIndex = stepIndex;
    await _updateCurrentStep();
  }

  Future<void> skipStep() async {
    if (!canSkipCurrentStep) return;

    await markStepCompleted(_currentStepIndex);
    await nextStep();
  }

  Future<void> skipOnboarding() async {
    // Mark all skippable steps as completed
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].skipable) {
        await markStepCompleted(i);
      }
    }
    await completeOnboarding();
  }

  Future<void> markStepCompleted(int stepIndex) async {
    try {
      await _onboardingService.markStepCompleted(stepIndex);
      
      // Update local data
      final completedSteps = List<int>.from(_data.completedSteps);
      if (!completedSteps.contains(stepIndex)) {
        completedSteps.add(stepIndex);
        _data = _data.copyWith(completedSteps: completedSteps);
      }
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark step as completed: $e');
    }
  }

  Future<void> completeOnboarding() async {
    _setLoading(true);
    try {
      await _onboardingService.markOnboardingComplete();
      _data = _data.copyWith(
        isComplete: true,
        completionDate: DateTime.now().toIso8601String(),
      );
      _clearError();
    } catch (e) {
      _setError('Failed to complete onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetOnboarding() async {
    _setLoading(true);
    try {
      await _onboardingService.resetOnboarding();
      _data = const OnboardingData();
      _currentStepIndex = 0;
      _clearError();
    } catch (e) {
      _setError('Failed to reset onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markPermissionExplanationSeen() async {
    try {
      await _onboardingService.markPermissionExplanationSeen();
      _data = _data.copyWith(hasSeenPermissionExplanation: true);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark permission explanation as seen: $e');
    }
  }

  bool isStepCompleted(int stepIndex) {
    return _data.completedSteps.contains(stepIndex);
  }

  Future<void> _updateCurrentStep() async {
    try {
      await _onboardingService.setOnboardingStep(_currentStepIndex);
      _data = _data.copyWith(lastShownStep: _currentStepIndex);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update current step: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}