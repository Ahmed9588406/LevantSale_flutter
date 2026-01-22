# Signup Flow Debug Guide

## Complete Flow Overview

### 1. Registration (email_signup_screen.dart)
**User Action:** Fill form and click "موافقة وإنشاء حساب"

**API Call:** `POST https://levant.twingroups.com/auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "123456",
  "phone": "+60123456789",
  "role": "USER"
}
```

**Expected Response:** 200/201 with JSON or plain text

**On Success:**
- Shows green snackbar: "تم إنشاء الحساب بنجاح. الرجاء التحقق من بريدك الإلكتروني"
- Navigates to OTP verification screen

### 2. OTP Verification (otp_verification_screen.dart)
**User Action:** Enter 6-digit OTP (left to right)

**API Call:** `POST https://levant.twingroups.com/auth/activate`

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**On Success:**
- Shows green snackbar: "تم تفعيل الحساب بنجاح"
- Navigates to login screen

### 3. Resend OTP (if needed)
**User Action:** Click "إعادة إرسال الرمز"

**API Call:** `POST https://levant.twingroups.com/auth/resend-otp`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

## Debug Steps

### Step 1: Check Console Logs

When you click the signup button, you should see:
```
Registering user: John Doe, user@example.com, +60123456789
URL: https://levant.twingroups.com/auth/register
Register response status: 200 (or 201)
Register response body: {...}
```

### Step 2: Check for Errors

If you see an error dialog, note the exact message. Common issues:

1. **"Network error: ..."** - Check internet connection
2. **"Email or phone already exists"** - User already registered
3. **"Connection timeout"** - API is slow or unreachable
4. **"Server error: XXX"** - API returned error status code

### Step 3: Verify Navigation

After successful registration:
1. Green snackbar should appear
2. After 500ms, should navigate to OTP screen
3. OTP screen should show your email address

### Step 4: Test OTP Entry

On OTP screen:
1. Enter digits from LEFT to RIGHT
2. Auto-focus should move to next box
3. After entering 6 digits, click "تحقق"

Console should show:
```
Activating account for: user@example.com with OTP: 123456
URL: https://levant.twingroups.com/auth/activate
Activate response status: 200
Activate response body: {...}
```

## Troubleshooting

### Issue: Button does nothing when clicked

**Check:**
1. Is the checkbox checked? (Terms agreement)
2. Are all fields filled?
3. Is loading spinner showing?
4. Check console for any errors

### Issue: Shows error dialog immediately

**Possible causes:**
1. Email format invalid
2. Password less than 6 characters
3. Passwords don't match
4. Phone format invalid (must be +XXX with 10+ digits)
5. Terms not agreed

### Issue: API call fails

**Check:**
1. Base URL is correct: `https://levant.twingroups.com`
2. Internet connection is working
3. API server is running
4. CORS is configured (if testing on web)

### Issue: OTP screen doesn't appear

**Check:**
1. Console logs for navigation
2. Is `result['success']` true?
3. Is `mounted` check passing?
4. Any navigation errors in console?

## API Response Handling

The code handles both JSON and plain text responses:

**JSON Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {...}
}
```

**Plain Text Response:**
```
User registered successfully
```

Both are treated as success if status code is 200/201.

## Testing Checklist

- [ ] Fill all form fields
- [ ] Check terms checkbox
- [ ] Click signup button
- [ ] Check console logs
- [ ] Verify snackbar appears
- [ ] Verify navigation to OTP screen
- [ ] Enter OTP (left to right)
- [ ] Click verify button
- [ ] Check console logs
- [ ] Verify navigation to login screen

## Common Error Messages (Arabic)

- "الرجاء ملء جميع الحقول" - Fill all fields
- "الرجاء إدخال بريد إلكتروني صحيح" - Invalid email
- "كلمة المرور يجب أن تكون 6 أحرف على الأقل" - Password too short
- "كلمات المرور غير متطابقة" - Passwords don't match
- "الرجاء إدخال رقم هاتف صحيح" - Invalid phone
- "يجب الموافقة على الشروط والأحكام" - Must agree to terms
