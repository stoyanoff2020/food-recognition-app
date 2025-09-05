# Food Recognition App - Installation Guide

## For Android Phone Installation

### Method 1: Build APK Locally (Requires Android Studio)

#### Prerequisites
1. **Install Android Studio**
   - Download from: https://developer.android.com/studio
   - Follow the installation wizard
   - Install Android SDK (API level 21 or higher)

2. **Set up Flutter for Android**
   ```bash
   # Check Flutter setup
   flutter doctor
   
   # Accept Android licenses
   flutter doctor --android-licenses
   ```

#### Build and Install
1. **Clean and get dependencies**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build debug APK** (for testing)
   ```bash
   flutter build apk --debug
   ```

3. **Build release APK** (for production)
   ```bash
   flutter build apk --release
   ```

4. **Find your APK**
   - Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
   - Release APK: `build/app/outputs/flutter-apk/app-release.apk`

5. **Install on your phone**
   - Transfer APK to your phone via USB, email, or cloud storage
   - Enable "Install from unknown sources" in Android Settings > Security
   - Tap the APK file to install

### Method 2: Use GitHub Actions (No local setup required)

1. **Push code to GitHub**
   ```bash
   git add .
   git commit -m "Add build workflow"
   git push origin main
   ```

2. **Trigger build**
   - Go to your GitHub repository
   - Click "Actions" tab
   - Click "Build Android APK" workflow
   - Click "Run workflow" button

3. **Download APK**
   - Wait for build to complete (5-10 minutes)
   - Download APK from "Artifacts" section
   - Transfer to your phone and install

### Method 3: Direct USB Installation (Requires Android Studio)

1. **Enable Developer Options on your phone**
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"

2. **Connect phone to computer**
   ```bash
   # Check if device is connected
   flutter devices
   ```

3. **Install directly**
   ```bash
   # Install debug version directly to phone
   flutter install
   
   # Or run the app directly
   flutter run
   ```

## Troubleshooting

### Common Issues

1. **"No Android SDK found"**
   - Install Android Studio
   - Set ANDROID_HOME environment variable
   - Run `flutter doctor` to verify setup

2. **"Install from unknown sources" disabled**
   - Go to Android Settings > Security
   - Enable "Unknown sources" or "Install unknown apps"
   - For newer Android versions, enable per-app when prompted

3. **App crashes on startup**
   - Check if your phone has Android 5.0+ (API level 21)
   - Ensure camera permissions are granted
   - Check internet connection for API calls

4. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Update Flutter: `flutter upgrade`
   - Check `flutter doctor` for issues

### Performance Tips

- **For better performance**: Use release APK instead of debug
- **For smaller file size**: Use `flutter build apk --split-per-abi`
- **For testing**: Debug APK includes debugging tools

## App Requirements

### Minimum Requirements
- **Android**: 5.0 (API level 21) or higher
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 100MB free space
- **Camera**: Required for food recognition
- **Internet**: Required for AI processing and recipe generation

### Permissions Required
- **Camera**: To take photos of food
- **Storage**: To save photos and cache data
- **Internet**: To process images and fetch recipes
- **Notifications**: For subscription and app updates (optional)

## First Time Setup

1. **Grant Permissions**
   - Allow camera access when prompted
   - Allow storage access for saving recipes (Premium users)

2. **Complete Onboarding**
   - Follow the guided tour
   - Try the demo scan feature
   - Choose your subscription tier

3. **Test the App**
   - Take a photo of some food
   - Wait for ingredient recognition
   - Browse suggested recipes

## Getting Help

- **In-app Help**: Settings > Help & Support
- **Email**: support@foodrecognitionapp.com
- **Issues**: Report bugs via GitHub Issues
- **Updates**: Check Google Play Store for updates

## Next Steps

Once installed:
1. Complete the onboarding process
2. Try scanning different foods
3. Explore recipe suggestions
4. Consider upgrading to Premium for Recipe Book
5. Try Professional tier for Meal Planning

Enjoy cooking with AI-powered food recognition! 🍽️📱