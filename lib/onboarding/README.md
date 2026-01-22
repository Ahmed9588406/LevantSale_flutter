# Onboarding Screen

This onboarding screen appears before the sign-in screen when the app is launched for the first time.

## Features

- 3 swipeable pages with custom illustrations
- Smooth page indicators
- Skip button to bypass onboarding
- "ابدأ" (Start) button on the last page
- Saves completion state using SharedPreferences
- RTL (Right-to-Left) support for Arabic text

## How it works

1. When the app launches, it checks if onboarding has been completed
2. If not completed, shows the onboarding screen
3. User can swipe through pages or tap "التالي" (Next)
4. User can skip onboarding with "تخطي" (Skip) button
5. After completion, the state is saved and user is taken to sign-in screen
6. On subsequent launches, sign-in screen shows directly

## Testing

To reset the onboarding and see it again during development:

### Option 1: Clear app data (Recommended)
- Android: Settings > Apps > Leventsale > Storage > Clear Data
- iOS: Uninstall and reinstall the app

### Option 2: Add a reset button in your app
Add this code to any screen during development:

```dart
ElevatedButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    // Restart app or navigate to onboarding
  },
  child: Text('Reset Onboarding'),
)
```

## Customization

### Change colors
Edit the colors in `onboarding_screen.dart`:
- Background: `Color(0xFFB8E6D5)`
- Primary button: `Color(0xFF1DAF52)`
- Text: `Color(0xFF2B2B2A)`

### Change text
Edit the `_pages` list in `onboarding_screen.dart`:
```dart
final List<OnboardingPage> _pages = [
  OnboardingPage(
    title: 'Your Title',
    description: 'Your Description',
    ...
  ),
];
```

### Change illustration
The illustration is drawn using Flutter widgets in `onboarding_illustration.dart`.
You can modify the design or replace it with your own images.
