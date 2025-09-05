# 🍽️ Food Recognition App

An AI-powered mobile application that identifies food ingredients from photos and suggests personalized recipes. Built with Flutter and powered by OpenAI's GPT-4 Vision API.

## ✨ Features

### 🔍 **Smart Food Recognition**
- Instant ingredient identification from photos
- High-accuracy AI powered by GPT-4 Vision
- Confidence scores for each detected ingredient
- Support for fruits, vegetables, proteins, grains, and more

### 👨‍🍳 **Personalized Recipe Suggestions**
- Get 5 curated recipes ranked by ingredient match
- Detailed cooking instructions with step-by-step guidance
- Complete nutrition information and calorie counts
- Allergen warnings and dietary restriction compatibility

### 💎 **Premium Features**
- **Free Tier**: 1 scan per 6 hours + watch ads for extra scans
- **Premium ($4.99/month)**: 5 daily scans + Recipe Book functionality
- **Professional ($9.99/month)**: Unlimited scans + Meal Planning with nutrition tracking

### 📱 **User Experience**
- Intuitive camera interface with real-time preview
- Fast image processing with progress indicators
- Offline access to saved recipes
- Cross-platform compatibility (iOS and Android)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.24.0 or later)
- Dart SDK (3.9.0 or later)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/food-recognition-app.git
   cd food-recognition-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For release
   flutter run --release
   ```

## 📱 Installation on Android Phone

### Method 1: Download APK from GitHub Releases
1. Go to the [Releases](https://github.com/yourusername/food-recognition-app/releases) page
2. Download the latest APK file
3. Enable "Install from unknown sources" in Android settings
4. Install the APK on your device

### Method 2: Build from Source
See [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) for detailed instructions.

## 🏗️ Architecture

The app follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── config/          # App configuration and themes
├── models/          # Data models and entities
├── providers/       # State management (Provider pattern)
├── screens/         # UI screens and pages
├── services/        # Business logic and API services
├── utils/           # Utility functions and helpers
└── widgets/         # Reusable UI components
```

### Key Components

- **Camera Service**: Handles camera operations and image capture
- **AI Vision Service**: Integrates with OpenAI GPT-4 Vision API
- **Recipe Service**: Manages recipe generation and caching
- **Storage Service**: Local data persistence and caching
- **Subscription Service**: Handles in-app purchases and tier management

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run performance tests
flutter test test/performance/
```

## 🔧 Development

### Code Generation
```bash
# Generate code for models and services
flutter packages pub run build_runner build

# Watch for changes and regenerate
flutter packages pub run build_runner watch
```

### Building for Release

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release

# Build IPA
flutter build ipa --release
```

## 📊 Analytics and Monitoring

The app includes comprehensive analytics and crash reporting:

- **Firebase Analytics**: User behavior and feature usage tracking
- **Firebase Crashlytics**: Crash reporting and error monitoring
- **Performance Monitoring**: API response times and app performance metrics

## 🔒 Security and Privacy

- All API communications use HTTPS encryption
- User photos are processed securely and not permanently stored
- Local data is encrypted using industry-standard methods
- Privacy-compliant data handling following GDPR guidelines

## 🌍 Supported Platforms

- **Android**: 5.0 (API level 21) and later
- **iOS**: iOS 12.0 and later
- **Web**: Modern browsers (limited functionality)

## 📋 Requirements

### Minimum Device Requirements
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 100MB free space
- **Camera**: Required for food recognition
- **Internet**: Required for AI processing and recipe generation

### Permissions
- **Camera**: To take photos of food
- **Storage**: To save photos and cache data
- **Internet**: To process images and fetch recipes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the [docs](docs/) folder
- **Issues**: Report bugs via [GitHub Issues](https://github.com/yourusername/food-recognition-app/issues)
- **Email**: support@foodrecognitionapp.com
- **FAQ**: See [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)

## 🗺️ Roadmap

- [ ] Barcode scanning for packaged foods
- [ ] Voice-guided cooking instructions
- [ ] Social features for sharing recipes
- [ ] Integration with grocery delivery services
- [ ] Offline food recognition capabilities
- [ ] Support for more dietary restrictions and cuisines

## 📈 Performance

- **App startup time**: < 3 seconds
- **Image processing**: < 10 seconds average
- **Recipe generation**: < 5 seconds average
- **Crash-free rate**: 99.5%+

## 🙏 Acknowledgments

- OpenAI for the GPT-4 Vision API
- Flutter team for the amazing framework
- Firebase for analytics and crash reporting
- All beta testers and contributors

---

**Happy Cooking! 👨‍🍳👩‍🍳**

Made with ❤️ using Flutter