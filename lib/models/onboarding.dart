class OnboardingStep {
  final int id;
  final String title;
  final String description;
  final String? visualDemo;
  final bool skipable;
  final OnboardingStepType type;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    this.visualDemo,
    this.skipable = true,
    required this.type,
  });
}

enum OnboardingStepType {
  welcome,
  featureDemo,
  permissionRequest,
  demoScan,
  completion,
}

class OnboardingData {
  final bool isComplete;
  final List<int> completedSteps;
  final int lastShownStep;
  final bool hasSeenPermissionExplanation;
  final String? completionDate;

  const OnboardingData({
    this.isComplete = false,
    this.completedSteps = const [],
    this.lastShownStep = 0,
    this.hasSeenPermissionExplanation = false,
    this.completionDate,
  });

  OnboardingData copyWith({
    bool? isComplete,
    List<int>? completedSteps,
    int? lastShownStep,
    bool? hasSeenPermissionExplanation,
    String? completionDate,
  }) {
    return OnboardingData(
      isComplete: isComplete ?? this.isComplete,
      completedSteps: completedSteps ?? this.completedSteps,
      lastShownStep: lastShownStep ?? this.lastShownStep,
      hasSeenPermissionExplanation: hasSeenPermissionExplanation ?? this.hasSeenPermissionExplanation,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isComplete': isComplete,
      'completedSteps': completedSteps,
      'lastShownStep': lastShownStep,
      'hasSeenPermissionExplanation': hasSeenPermissionExplanation,
      'completionDate': completionDate,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      isComplete: json['isComplete'] ?? false,
      completedSteps: List<int>.from(json['completedSteps'] ?? []),
      lastShownStep: json['lastShownStep'] ?? 0,
      hasSeenPermissionExplanation: json['hasSeenPermissionExplanation'] ?? false,
      completionDate: json['completionDate'],
    );
  }
}