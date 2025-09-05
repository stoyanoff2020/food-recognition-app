# Splash Screen Assets Placeholder

This is a placeholder for splash screen assets. In a real implementation, you would create:

## Required Assets:

1. **splash_icon.png** (512x512) - Main splash screen icon
2. **splash_icon_dark.png** (512x512) - Dark mode version
3. **branding.png** (optional) - App name/logo below the icon
4. **branding_dark.png** (optional) - Dark mode branding

## Design Guidelines:

- Keep the splash icon simple and recognizable
- Use vector-based designs that scale well
- Ensure good contrast against both light and dark backgrounds
- Consider the app's loading time - splash should be brief but branded
- Follow platform guidelines (Material Design for Android, Human Interface Guidelines for iOS)

## Colors Used:
- Light background: #ffffff (white)
- Dark background: #042a49 (dark blue)
- Icon background: matches the background colors

The flutter_native_splash package will generate platform-specific splash screens automatically.