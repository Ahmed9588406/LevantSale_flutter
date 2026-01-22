# Troubleshooting Image Upload Issues

## Issue: Images Not Appearing After Selection

### What Was Fixed:
1. ✅ Added proper state management with `mounted` check
2. ✅ Added visual feedback (green border, success message)
3. ✅ Added error handling with `errorBuilder`
4. ✅ Added debug print statements
5. ✅ Fixed Google icon asset error in sign_in_screen

### How to Verify It's Working:

**Step 1: Check Permissions**
- Make sure you granted camera and storage permissions
- If denied, the app will show a dialog to open settings

**Step 2: Test Image Selection**
1. Go to verification Step 2 or Step 3
2. Tap an upload box
3. Choose camera or gallery
4. Select/capture an image
5. You should see:
   - ✅ Green snackbar: "تم اختيار الصورة"
   - ✅ Image appears in the box
   - ✅ Green border around the box
   - ✅ Small edit icon on top-right corner

**Step 3: Check Console Output**
Look for these debug messages:
```
Front image selected: /path/to/image.jpg
Back image selected: /path/to/image.jpg
Profile image selected: /path/to/image.jpg
```

### Common Issues:

#### 1. Permission Denied
**Symptom**: Dialog appears asking to open settings
**Solution**: 
- Tap "فتح الإعدادات" (Open Settings)
- Grant camera and photos permissions
- Return to app and try again

#### 2. Image Doesn't Display
**Symptom**: Box stays empty after selection
**Solution**:
- Check console for error messages
- Try selecting a different image
- Try using camera instead of gallery (or vice versa)
- Restart the app

#### 3. "Error loading image" Message
**Symptom**: Red error icon appears in the box
**Solution**:
- The image file may be corrupted
- Try selecting a different image
- Check if the file path is accessible

#### 4. App Crashes When Selecting Image
**Symptom**: App closes when trying to pick image
**Solution**:
- Check if permissions are granted
- Update Flutter: `flutter upgrade`
- Clean and rebuild: `flutter clean && flutter pub get`

### Testing on Different Platforms:

**Android:**
- Camera permission required
- Storage/Photos permission required (Android 13+ uses Photos)
- Test on physical device (emulator camera may not work properly)

**iOS:**
- Camera permission required
- Photo Library permission required
- Test on physical device or simulator with photos

### Debug Mode:

If images still don't appear, use the debug test screen:

```dart
import 'package:leventsale/verification/debug_image_test.dart';

// Navigate to debug screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DebugImageTestScreen(),
  ),
);
```

This will show:
- Image path
- File exists status
- File size
- Detailed error messages

### Still Having Issues?

1. Check Flutter version: `flutter --version`
2. Check dependencies: `flutter pub get`
3. Clean build: `flutter clean`
4. Rebuild: `flutter run`
5. Check console for error messages
6. Try on a different device

### Expected Behavior:

✅ **Working Correctly:**
- Tap upload box → Permission dialog (first time)
- Grant permission → Camera/Gallery opens
- Select image → Image appears immediately
- Green border and success message
- Can tap again to change image

❌ **Not Working:**
- No permission dialog appears
- Camera/Gallery doesn't open
- Image selected but box stays empty
- Error messages in console
- App crashes
