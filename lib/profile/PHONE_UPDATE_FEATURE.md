# Phone Number Update Feature

## Overview
Added phone number update functionality to the Update Profile tab with a separate endpoint and dedicated UI.

## Implementation Details

### API Endpoint
- **URL**: `{{baseUrl}}/api/v1/users/profile/phone`
- **Method**: PUT
- **Headers**: Authorization Bearer token
- **Request Body**:
```json
{
  "phone": "+1234567890"
}
```

### Key Features

1. **Separate Update Button**
   - Phone field has its own update button next to it
   - Independent from the main profile update button
   - Visual indicator that phone requires separate action

2. **Validation**
   - Phone number must not be empty
   - Must match format: `+` followed by 10-15 digits
   - Regex pattern: `^\+?[0-9]{10,15}$`

3. **Confirmation Dialog**
   - Shows confirmation dialog before updating
   - Displays the new phone number for user verification
   - User can cancel or confirm the update

4. **User Feedback**
   - Success toast: "تم تحديث رقم الهاتف بنجاح"
   - Error toast: "فشل تحديث رقم الهاتف"
   - Loading state on update button during API call

5. **Auto-Refresh**
   - After successful update, profile is automatically refreshed
   - Ensures displayed phone number is up-to-date

## UI Components

### Phone Field Layout
```
┌─────────────────────────────────────────────────┐
│  Phone Field (TextField)        [Update Button] │
└─────────────────────────────────────────────────┘
  Note: Phone number requires separate update
```

### Field Properties
- Label: "رقم الهاتف"
- Icon: Phone icon
- Placeholder: "+1234567890"
- Keyboard Type: Phone
- Update Button: Green with update icon

## Code Structure

### Method: `_updatePhone()`
1. Validates phone number format
2. Shows confirmation dialog
3. Calls `ProfileService.updatePhone()`
4. Refreshes profile on success
5. Shows appropriate toast notification

### Controller
- `_phoneController`: TextEditingController for phone input
- Initialized with current phone from profile
- Disposed properly in widget lifecycle

## Usage Flow

1. User navigates to "تحديث الملف" tab
2. User sees current phone number in info card (read-only)
3. User enters new phone number in editable field
4. User clicks update button next to phone field
5. Confirmation dialog appears
6. User confirms
7. API call is made to update phone
8. Success/error feedback is shown
9. Profile refreshes with new phone number

## Integration

### ProfileService
The `updatePhone()` method already exists in `ProfileService`:
```dart
static Future<bool> updatePhone(String phone) async {
  try {
    final res = await http.put(
      Uri.parse('$baseUrl/api/v1/users/profile/phone'),
      headers: await _headers(),
      body: jsonEncode({'phone': phone}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (_) {
    return false;
  }
}
```

## Error Handling

- Empty phone: "الرجاء إدخال رقم الهاتف"
- Invalid format: "رقم الهاتف غير صالح. يجب أن يبدأ بـ + ويحتوي على 10-15 رقم"
- API failure: "فشل تحديث رقم الهاتف"
- Network errors are caught and handled gracefully

## Testing Checklist

- [ ] Phone field displays current phone number
- [ ] Validation works for empty phone
- [ ] Validation works for invalid format
- [ ] Confirmation dialog appears
- [ ] Cancel button works in dialog
- [ ] Update button makes API call
- [ ] Success toast appears on success
- [ ] Error toast appears on failure
- [ ] Profile refreshes after update
- [ ] Loading state shows during update
- [ ] Button is disabled during update
