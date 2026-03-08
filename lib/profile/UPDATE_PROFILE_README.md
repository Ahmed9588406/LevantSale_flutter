# Update Profile Feature

## Overview
A new tab has been added to the profile screen that allows users to view and update their profile information.

## API Endpoints

### Get Profile
- **Endpoint**: `{{baseUrl}}/api/v1/users/profile`
- **Method**: GET
- **Headers**: 
  - `Authorization`: Bearer token (required)
- **Response**:
```json
{
  "id": "f27e25c5-bd5e-4e3e-ab22-f2f633b48ccb",
  "name": "Admin Levant",
  "email": "levantsale@gmail.com",
  "phone": "+60123456789",
  "bio": null,
  "socialLinks": [],
  "verified": false,
  "role": "ADMIN",
  "createdAt": "2026-02-12T10:53:41.839799",
  "updatedAt": "2026-02-12T10:53:41.839804",
  "lastSeen": "2026-02-15T12:23:45.821186",
  "preferredLanguage": "en",
  "online": false
}
```

### Update Profile
- **Endpoint**: `{{baseUrl}}/api/v1/users/profile`
- **Method**: PUT
- **Headers**: 
  - `Authorization`: Bearer token (required)
  - `Content-Type`: application/json
- **Request Body**:
```json
{
  "name": "John Doe",
  "email": "bidoahmed955@gmail.com",
  "bio": "Passionate about technology and innovation",
  "socialLinks": [
    "https://facebook.com/johndoe",
    "https://linkedin.com/in/johndoe"
  ]
}
```

### Update Phone Number
- **Endpoint**: `{{baseUrl}}/api/v1/users/profile/phone`
- **Method**: PUT
- **Headers**: 
  - `Authorization`: Bearer token (required)
  - `Content-Type`: application/json
- **Request Body**:
```json
{
  "phone": "+1234567890"
}
```
- **Note**: Phone number update is handled separately from other profile fields

## Features

### Profile Information Display
- Shows user avatar with first letter of name
- Displays verification status
- Shows phone number, role, and preferred language
- All information is read-only in the info card

### Editable Fields
1. **Name** - Full name of the user
2. **Email** - Email address with validation
3. **Phone Number** - Phone number with separate update button
   - Has its own dedicated endpoint
   - Requires confirmation dialog before update
   - Format validation (+country code and 10-15 digits)
4. **Bio** - Optional text area for user description
5. **Social Links** - Dynamic list of social media URLs
   - Add multiple links
   - Remove links individually
   - URL format validation

### Validation
- Name is required
- Email is required and must be valid format
- Phone number must start with + and contain 10-15 digits
- Phone update requires user confirmation
- Bio is optional
- Social links are optional and can be empty

### User Experience
- Loading state while fetching profile
- Error handling with retry option
- Success/error toast notifications
- Disabled button during update
- RTL (Right-to-Left) support for Arabic

## Files Created/Modified

### New Files
- `lib/profile/update_profile_tab.dart` - Main update profile tab widget

### Modified Files
- `lib/profile/profile_screen.dart` - Added new tab to TabController
- `lib/profile/profile_service.dart` - Already had the required methods

## Usage

The update profile tab is automatically available in the profile screen as the 5th tab. Users can:

1. View their current profile information
2. Edit name, email, bio
3. Update phone number separately with confirmation
4. Add/remove social media links
5. Save changes with validation
6. See success/error feedback

### Phone Number Update Flow
1. User enters new phone number in the phone field
2. User clicks the update button next to the phone field
3. Confirmation dialog appears showing the new number
4. Upon confirmation, phone is updated via separate endpoint
5. Profile is refreshed to show updated phone number
6. Success/error toast notification is displayed

## Integration

The feature integrates with:
- `ProfileService` for API calls
- `SessionService` for authentication token
- `AppToast` for user notifications
- Existing profile screen tab structure
