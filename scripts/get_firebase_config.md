# How to Get Real Firebase Configuration

## Important Note
The current Firebase configuration uses **placeholder values**. You need to replace them with real values from your Firebase Console.

## Step-by-Step Guide

### 1. Access Firebase Console

1. Go to: https://console.firebase.google.com/
2. Sign in with your Google account
3. Select your project: **levant-sale**

### 2. Get Android Configuration

1. In Firebase Console, click the **gear icon** (⚙️) next to "Project Overview"
2. Select **Project settings**
3. Scroll down to **Your apps** section
4. Click on the **Android** app icon (or add a new Android app if none exists)
5. If adding new app:
   - Android package name: `com.example.leventsale`
   - App nickname: `Leventsale Android`
   - Click **Register app**
6. Click **Download google-services.json**
7. Replace the file at: `android/app/google-services.json`

### 3. Get iOS Configuration

1. In the same **Project settings** page
2. Click on the **iOS** app icon (or add a new iOS app if none exists)
3. If adding new app:
   - iOS bundle ID: `com.example.leventsale`
   - App nickname: `Leventsale iOS`
   - Click **Register app**
4. Click **Download GoogleService-Info.plist**
5. Replace the file at: `ios/Runner/GoogleService-Info.plist`

### 4. Get Web/Flutter Configuration

1. In **Project settings**, scroll to **Your apps**
2. Look for the **Web app** or click **Add app** > **Web**
3. You'll see configuration like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "levant-sale.firebaseapp.com",
  projectId: "levant-sale",
  storageBucket: "levant-sale.appspot.com",
  messagingSenderId: "107218449369",
  appId: "1:107218449369:web:..."
};
```

4. Copy these values and update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'levant-sale',
  authDomain: 'levant-sale.firebaseapp.com',
  storageBucket: 'levant-sale.appspot.com',
);
```

5. Do the same for `android`, `ios`, and `macos` configurations

### 5. Enable Cloud Messaging

1. In Firebase Console, go to **Build** > **Cloud Messaging**
2. Click **Get started** if not already enabled
3. Enable **Cloud Messaging API (Legacy)** if needed
4. Note your **Server Key** (needed for backend)

### 6. Configure iOS Push Notifications (iOS Only)

#### A. In Apple Developer Portal:

1. Go to: https://developer.apple.com/account/
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** in the sidebar
4. Click the **+** button to create a new key
5. Give it a name (e.g., "Leventsale APNs Key")
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** and then **Register**
8. Download the `.p8` key file (you can only download it once!)
9. Note the **Key ID** and **Team ID**

#### B. In Firebase Console:

1. Go to **Project settings** > **Cloud Messaging** tab
2. Scroll to **Apple app configuration**
3. Click **Upload** under APNs Authentication Key
4. Upload your `.p8` file
5. Enter your **Key ID** and **Team ID**
6. Click **Upload**

#### C. In Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and check:
   - ☑️ Remote notifications

### 7. Verify Configuration

After updating all files, verify:

```bash
# Check Android configuration
cat android/app/google-services.json

# Check iOS configuration  
cat ios/Runner/GoogleService-Info.plist

# Check Flutter configuration
cat lib/firebase_options.dart
```

### 8. Test the Setup

1. Run the app:
   ```bash
   flutter run
   ```

2. Check the console for FCM token:
   ```
   FCM token: [your-device-token]
   ```

3. Send a test notification from Firebase Console:
   - Go to **Cloud Messaging**
   - Click **Send your first message**
   - Enter title and body
   - Click **Next**
   - Select your app
   - Click **Review** and **Publish**

## Common Issues

### Issue: "Default FirebaseApp is not initialized"
**Solution**: Make sure Firebase.initializeApp() is called in main.dart before runApp()

### Issue: "No matching client found for package name"
**Solution**: Verify package name in google-services.json matches android/app/build.gradle.kts

### Issue: iOS notifications not working
**Solution**: 
- Check APNs key is uploaded to Firebase
- Verify Push Notifications capability is enabled in Xcode
- Test on a real device (not simulator)

### Issue: Background notifications not working on Android
**Solution**:
- Disable battery optimization for your app
- Check that background handler is registered before runApp()

## Security Reminder

⚠️ **IMPORTANT**: Never commit these files to public repositories:
- `firebase-service-account.json`
- `google-services.json` (if it contains sensitive data)
- `GoogleService-Info.plist` (if it contains sensitive data)

Add them to `.gitignore`:
```
firebase-service-account.json
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

## Need Help?

If you encounter issues:
1. Check Firebase Console for error messages
2. Review device logs for error details
3. Verify all configuration files are correct
4. Test with Firebase Console test messages first
5. Check that all required permissions are granted

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
