import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for different environments
class FirebaseConfig {
  static const String _projectId = 'food-recognition-app';
  
  /// Firebase options for different platforms and environments
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-api-key',
    appId: '1:123456789:web:abcdef123456',
    messagingSenderId: '123456789',
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: '$_projectId.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );

  /// Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: '1:123456789:android:abcdef123456',
    messagingSenderId: '123456789',
    projectId: _projectId,
    storageBucket: '$_projectId.appspot.com',
  );

  /// iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: '1:123456789:ios:abcdef123456',
    messagingSenderId: '123456789',
    projectId: _projectId,
    storageBucket: '$_projectId.appspot.com',
    iosBundleId: 'com.foodrecognition.food-recognition-app',
  );

  /// macOS configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: '1:123456789:ios:abcdef123456',
    messagingSenderId: '123456789',
    projectId: _projectId,
    storageBucket: '$_projectId.appspot.com',
    iosBundleId: 'com.foodrecognition.food-recognition-app',
  );

  /// Windows configuration
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-windows-api-key',
    appId: '1:123456789:web:abcdef123456',
    messagingSenderId: '123456789',
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: '$_projectId.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );
}

/// Instructions for setting up Firebase:
/// 
/// 1. Create a Firebase project at https://console.firebase.google.com/
/// 2. Add your app for each platform (Android, iOS, Web)
/// 3. Download the configuration files:
///    - google-services.json for Android (place in android/app/)
///    - GoogleService-Info.plist for iOS (place in ios/Runner/)
/// 4. Replace the placeholder values above with your actual Firebase config
/// 5. Enable Analytics and Crashlytics in the Firebase console
/// 6. Follow platform-specific setup instructions in the Firebase documentation