# Food Recognition App

AI-powered mobile application that identifies food items from photos and provides recipe suggestions using computer vision and OpenAI's GPT-4 Vision API.

## Features

- **Food Recognition**: Capture photos of food items and get ingredient identification with confidence scores
- **Recipe Suggestions**: Automatically generated recipes based on detected ingredients
- **Custom Ingredients**: Add additional ingredients to customize recipe suggestions
- **Subscription Tiers**: Free, Premium, and Professional plans with different feature sets
- **Cross-Platform**: Built with Flutter for iOS and Android

## Project Structure

```
lib/
├── config/          # Environment and app configuration
├── models/          # Data models and entities
├── screens/         # UI screens and pages
├── services/        # Business logic and API services
├── utils/           # Utility functions and helpers
└── widgets/         # Reusable UI components

assets/
├── images/          # Image assets
└── icons/           # Icon assets
```

## Environment Setup

### Prerequisites

- Flutter SDK (3.35.2 or later)
- Dart SDK (3.9.0 or later)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- OpenAI API key

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd food_recognition_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   - Copy `.env.development` to `.env`
   - Add your OpenAI API key to the `.env` file

4. Run the app:
   ```bash
   flutter run
   ```

## Environment Configuration

The app supports three environments:

- **Development** (`.env.development`): For local development
- **Staging** (`.env.staging`): For testing and QA
- **Production** (`.env.production`): For production releases

## API Integration

The app integrates with OpenAI's APIs:

- **GPT-4 Vision**: For food recognition and ingredient identification
- **GPT-4**: For recipe generation and nutrition information

## Subscription Model

- **Free Tier**: 1 scan per 6 hours, ad-supported
- **Premium Tier** ($4.99/month): 5 scans per day, recipe book, ad-free
- **Professional Tier** ($9.99/month): Unlimited scans, meal planning, nutrition tracking

## Development

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

### Building for Release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
