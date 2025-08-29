class AppConfig {
  // OpenAI Configuration
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String gpt4VisionModel = 'gpt-4-vision-preview';
  static const String gpt4TextModel = 'gpt-4';
  
  // App Configuration
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Subscription Configuration
  static const int freeScansPerPeriod = 1;
  static const int freeScanPeriodHours = 6;
  static const int premiumScansPerDay = 5;
  static const int maxAdScansPerDay = 3;
  static const int premiumMaxAdScansPerDay = 10;
  
  // Storage Configuration
  static const int freeHistoryDays = 7;
  static const int premiumHistoryDays = 30;
  
  // Performance Configuration
  static const int maxImageSizeBytes = 4 * 1024 * 1024; // 4MB
  static const int imageCompressionQuality = 85;
  static const int maxRecipeSuggestions = 5;
  
  // Validation
  static bool get isConfigValid {
    return openAiApiKey.isNotEmpty;
  }
}