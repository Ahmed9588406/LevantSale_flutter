# Testing Guide for Verification Module

## Prerequisites

1. **Physical Device Required**: Camera functionality doesn't work on emulators
2. **Permissions**: Make sure to grant camera and storage permissions when prompted

## Testing Steps

### Step 1: Basic Information
1. Click the "التوثيق" (Verification) button in the bottom navigation bar
2. Fill in the form:
   - Enter your name (ادخل اسمك)
   - Enter description (وصف عنك)
   - Select birth date (تاريخ الميلاد) - tap to open date picker
   - Select gender (النوع) - choose from dropdown
3. Click "حفظ و متابعة" (Save and Continue)
4. ✅ Should navigate to Step 2

### Step 2: National ID Photos
1. Verify progress bar shows ~50% completion
2. Test Front Image Upload:
   - Tap the right upload box
   - Choose "التقاط صورة" (Take Photo) or "اختيار من المعرض" (Choose from Gallery)
   - Camera: Take a photo and confirm
   - Gallery: Select an image
   - ✅ Image should display in the box
3. Test Back Image Upload:
   - Tap the left upload box
   - Repeat the same process
   - ✅ Image should display in the box
4. Click "حفظ و متابعة" without images
   - ✅ Should show error: "يرجى رفع الصورتين"
5. Click "حفظ و متابعة" with both images
   - ✅ Should navigate to Step 3

### Step 3: Profile Photo
1. Verify progress bar shows 100% completion (fully green)
2. Test Profile Image Upload:
   - Tap the center upload box
   - Choose camera or gallery
   - ✅ Image should display in the box
3. Click "إرسال البيانات" without image
   - ✅ Should show error: "يرجى رفع صورة شخصية"
4. Click "إرسال البيانات" with image
   - ✅ Should show success dialog
   - ✅ Click "حسناً" to return to home

## Common Issues

### Camera Not Opening
- **Solution**: Check if camera permissions are granted in device settings
- **Android**: Settings > Apps > Leventsale > Permissions > Camera
- **iOS**: Settings > Leventsale > Camera

### Gallery Not Opening
- **Solution**: Check if storage/photos permissions are granted
- **Android**: Settings > Apps > Leventsale > Permissions > Storage/Photos
- **iOS**: Settings > Leventsale > Photos

### Image Not Displaying
- **Solution**: 
  - Check if the image file size is reasonable (< 10MB)
  - Try selecting a different image
  - Restart the app

## Expected Behavior

✅ **Camera**:
- Opens device camera
- Allows taking a photo
- Returns to app with photo displayed

✅ **Gallery**:
- Opens device photo gallery
- Allows selecting an existing photo
- Returns to app with photo displayed

✅ **Image Quality**:
- Images are automatically compressed to max 1920x1920 pixels
- Quality set to 85% to balance size and clarity

✅ **Error Handling**:
- Shows Arabic error messages
- Validates required fields
- Prevents navigation without required images

## Performance Notes

- Image compression happens automatically
- Large images may take 1-2 seconds to process
- This is normal and ensures optimal app performance
