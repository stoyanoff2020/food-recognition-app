#!/bin/bash

# Food Recognition App - Release Build Script
# This script automates the release build process for both Android and iOS

set -e  # Exit on any error

echo "🚀 Starting Food Recognition App Release Build Process"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Run code analysis
print_status "Running code analysis..."
flutter analyze
if [ $? -ne 0 ]; then
    print_error "Code analysis failed. Please fix the issues before building."
    exit 1
fi
print_success "Code analysis passed"

# Run tests
print_status "Running tests..."
flutter test
if [ $? -ne 0 ]; then
    print_error "Tests failed. Please fix the failing tests before building."
    exit 1
fi
print_success "All tests passed"

# Run release readiness tests
print_status "Running release readiness tests..."
flutter test test/release/
if [ $? -ne 0 ]; then
    print_warning "Release readiness tests failed. Please review before proceeding."
fi

# Generate app icons
print_status "Generating app icons..."
flutter pub run flutter_launcher_icons:main
print_success "App icons generated"

# Generate splash screens
print_status "Generating splash screens..."
flutter pub run flutter_native_splash:create
print_success "Splash screens generated"

# Build for Android
print_status "Building Android release..."

# Build APK
print_status "Building APK..."
flutter build apk --release --split-per-abi
if [ $? -eq 0 ]; then
    print_success "APK build completed"
    print_status "APK location: build/app/outputs/flutter-apk/"
    ls -la build/app/outputs/flutter-apk/
else
    print_error "APK build failed"
    exit 1
fi

# Build App Bundle (AAB)
print_status "Building App Bundle (AAB)..."
flutter build appbundle --release
if [ $? -eq 0 ]; then
    print_success "App Bundle build completed"
    print_status "AAB location: build/app/outputs/bundle/release/"
    ls -la build/app/outputs/bundle/release/
else
    print_error "App Bundle build failed"
    exit 1
fi

# Build for iOS (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building iOS release..."
    
    # Build iOS
    flutter build ios --release --no-codesign
    if [ $? -eq 0 ]; then
        print_success "iOS build completed"
    else
        print_error "iOS build failed"
        exit 1
    fi
    
    # Build IPA (requires proper signing)
    print_status "Building IPA..."
    flutter build ipa --release
    if [ $? -eq 0 ]; then
        print_success "IPA build completed"
        print_status "IPA location: build/ios/ipa/"
        ls -la build/ios/ipa/
    else
        print_warning "IPA build failed (this is normal if code signing is not configured)"
    fi
else
    print_warning "iOS build skipped (not running on macOS)"
fi

# Generate build report
print_status "Generating build report..."
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_REPORT="build_report_$(date '+%Y%m%d_%H%M%S').txt"

cat > "$BUILD_REPORT" << EOF
Food Recognition App - Build Report
===================================

Build Date: $BUILD_DATE
Flutter Version: $(flutter --version | head -n 1)
Dart Version: $(dart --version)

Build Artifacts:
- Android APK: build/app/outputs/flutter-apk/
- Android AAB: build/app/outputs/bundle/release/
EOF

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "- iOS IPA: build/ios/ipa/" >> "$BUILD_REPORT"
fi

cat >> "$BUILD_REPORT" << EOF

Build Status: SUCCESS
Code Analysis: PASSED
Tests: PASSED

Next Steps:
1. Test the built artifacts on physical devices
2. Upload to app stores for review
3. Monitor crash reports and analytics after release

EOF

print_success "Build report generated: $BUILD_REPORT"

# Final summary
echo ""
echo "🎉 Release Build Process Completed Successfully!"
echo "=============================================="
print_success "Android APK and AAB files are ready for distribution"
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_success "iOS build completed (IPA may require code signing)"
fi
print_status "Build report: $BUILD_REPORT"
echo ""
print_status "Next steps:"
echo "  1. Test builds on physical devices"
echo "  2. Upload to Google Play Console and App Store Connect"
echo "  3. Submit for store review"
echo "  4. Monitor analytics and crash reports post-release"
echo ""
print_warning "Remember to:"
echo "  - Update version numbers for next release"
echo "  - Tag this release in version control"
echo "  - Update release notes and changelog"