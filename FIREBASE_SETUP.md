# Firebase Setup Instructions

## Current Status
The app is currently running with **placeholder Firebase configuration files**. This allows the app to build and run, but Firebase features (push notifications) will not work until you configure it with real credentials.

### Temporary Files Created
- `android/app/google-services.json` - Dummy Android config
- `ios/Runner/GoogleService-Info.plist` - Dummy iOS config
- `lib/firebase_options.dart` - Placeholder Dart config

**⚠️ These are DUMMY files with fake credentials. Replace them with real ones from your Firebase project!**

## What You Need to Do When You Get Firebase Config

### Option 1: Using google-services.json (Recommended)

1. **Get the files from your backend team:**
   - `google-services.json` (for Android)
   - `GoogleService-Info.plist` (for iOS)

2. **Place the files:**
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

3. **Run FlutterFire CLI to regenerate firebase_options.dart:**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This will automatically update `lib/firebase_options.dart` with the correct values.

### Option 2: Manual Configuration (If you only have API keys)

If you only receive API keys and project IDs, update `lib/firebase_options.dart` manually:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',           // Replace this
  appId: 'YOUR_ANDROID_APP_ID',             // Replace this
  messagingSenderId: 'YOUR_SENDER_ID',      // Replace this
  projectId: 'YOUR_PROJECT_ID',             // Replace this
  storageBucket: 'YOUR_STORAGE_BUCKET',     // Replace this
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',               // Replace this
  appId: 'YOUR_IOS_APP_ID',                 // Replace this
  messagingSenderId: 'YOUR_SENDER_ID',      // Replace this
  projectId: 'YOUR_PROJECT_ID',             // Replace this
  storageBucket: 'YOUR_STORAGE_BUCKET',     // Replace this
  iosBundleId: 'com.example.leventsale',    // Update if different
);
```

## Current Placeholder Values

The current `lib/firebase_options.dart` contains dummy values:
- Project ID: `leventsale-temp`
- API Keys: All start with `AIzaSyDummyKey...`
- App IDs: All use `1:123456789:...`

**These will NOT work for real push notifications!**

## Testing Without Firebase

The app will run normally without Firebase configured. The following features will work:
- ✅ User authentication
- ✅ Browsing products
- ✅ Creating listings
- ✅ Messaging
- ✅ All UI features

The following features will NOT work until Firebase is configured:
- ❌ Push notifications
- ❌ FCM token registration

## After Configuration

Once you update the Firebase configuration:

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test push notifications:**
   - Check that FCM token is generated
   - Verify token is sent to backend
   - Test receiving notifications

## Questions?

If you need help with Firebase setup, contact your backend team for:
- Firebase project credentials
- google-services.json file
- GoogleService-Info.plist file
- Or the specific API keys and IDs needed
