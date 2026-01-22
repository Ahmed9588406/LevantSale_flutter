# Verification Module

This module handles the user verification process with a 3-step flow.

## Features

- **Step 1**: Basic Information (Name, Description, Birth Date, Gender)
- **Step 2**: National ID Card Photos (Front & Back)
- **Step 3**: Profile Photo Upload

## Image Upload Functionality

The module uses `image_picker` and `permission_handler` packages to handle:
- **Automatic permission requests** (Camera & Photos/Storage)
- Camera capture
- Gallery selection
- Image compression (max 1920x1920, 85% quality)
- Error handling with Arabic messages
- Permission denied handling with settings redirect

## Permission Handling

### Automatic Permission Flow
1. User taps to upload image
2. App checks if permission is granted
3. If not granted, shows permission request dialog
4. If permanently denied, shows dialog with "Open Settings" button
5. User can grant permission from app settings

### Permissions Required

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

#### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>نحتاج إلى الوصول إلى الكاميرا لالتقاط صور التوثيق</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>نحتاج إلى الوصول إلى معرض الصور لاختيار صور التوثيق</string>
```

## Usage

Navigate to verification from the bottom navigation bar:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const VerificationStepOneScreen(),
  ),
);
```

## Files

- `verification_step_one_screen.dart` - Basic information form
- `verification_step_two_screen.dart` - ID card photo upload
- `verification_step_three_screen.dart` - Profile photo upload
- `image_picker_helper.dart` - Reusable image picker utility with permission handling

## Permission States

### Granted
- User can access camera/gallery immediately

### Denied (First Time)
- Shows system permission dialog
- User can allow or deny

### Permanently Denied
- Shows custom dialog with Arabic message
- Provides "Open Settings" button
- User must grant permission from app settings

## Testing

To test the image picker:
1. Run on a physical device (camera won't work on emulator)
2. Tap upload box - permission will be requested automatically
3. Grant or deny permission to test different flows
4. Test "Open Settings" button if permission is permanently denied
5. Verify images are displayed correctly after selection
