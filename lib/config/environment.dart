enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static const Environment _currentEnvironment = Environment.development;
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'https://api.openai.com/v1';
      case Environment.staging:
        return 'https://api.openai.com/v1';
      case Environment.production:
        return 'https://api.openai.com/v1';
    }
  }
  
  static String get appName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Food Recognition (Dev)';
      case Environment.staging:
        return 'Food Recognition (Staging)';
      case Environment.production:
        return 'Food Recognition';
    }
  }
  
  static bool get isDebugMode {
    switch (_currentEnvironment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }
  
  static Duration get apiTimeout {
    switch (_currentEnvironment) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 20);
      case Environment.production:
        return const Duration(seconds: 15);
    }
  }
}