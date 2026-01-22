# Authentication API

This folder contains all authentication-related API services and models.

## Files

### `auth_config.dart`
Configuration file for API endpoints and settings.
- Contains base URL and endpoint paths
- Centralized configuration for easy updates

### `auth_service.dart`
Main service class for authentication operations.
- `loginWithEmail()` - Login with email and password
- Handles HTTP requests and error handling
- Returns structured response with success status and data

### `auth_models.dart`
Data models for authentication.
- `LoginRequest` - Request model for login
- `LoginResponse` - Response model for login
- `UserData` - User information model

## Usage

### Login with Email

```dart
import 'package:leventsale/api/auth/auth_service.dart';

// Call the login method
final result = await AuthService.loginWithEmail(
  email: 'user@example.com',
  password: 'password123',
);

// Check result
if (result['success']) {
  print('Login successful');
  print(result['data']); // Contains user data and token
} else {
  print('Login failed: ${result['message']}');
}
```

### Login with Phone

```dart
import 'package:leventsale/api/auth/auth_service.dart';

// Call the login method
final result = await AuthService.loginWithPhone(
  phone: '+60123456789',
  password: 'password123',
);

// Check result
if (result['success']) {
  print('Login successful');
  print(result['data']); // Contains user data and token
} else {
  print('Login failed: ${result['message']}');
}
```

Before using the auth service, update the base URL in `auth_config.dart`:

```dart
static const String baseUrl = 'https://your-actual-api-url.com';
```

## API Endpoints

### Email Login

**Endpoint:** `POST /auth/login/email`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "User Name",
    "phone": "+1234567890"
  }
}
```

### Phone Login

**Endpoint:** `POST /auth/login/phone`

**Request Body:**
```json
{
  "phone": "+60123456789",
  "password": "password123"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "User Name",
    "phone": "+60123456789"
  }
}
```

**Response (Error - 401):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

## Error Handling

The service handles various error scenarios:
- Invalid credentials (401)
- Bad request (400)
- Server errors (5xx)
- Network timeouts
- Connection errors

All errors are returned in a consistent format with a success flag and message.

### Register New User

```dart
import 'package:leventsale/api/auth/auth_service.dart';

// Call the register method
final result = await AuthService.register(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password123',
  phone: '+60123456789',
  role: 'USER',
);

// Check result
if (result['success']) {
  print('Registration successful');
  print(result['data']); // Contains user data and token
} else {
  print('Registration failed: ${result['message']}');
}
```

### Registration Endpoint

**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "+60123456789",
  "role": "USER"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+60123456789"
  }
}
```

**Response (Error - 409 - Conflict):**
```json
{
  "success": false,
  "message": "Email or phone already exists"
}
```


## OTP and Password Reset Flow

### Account Activation After Registration

After successful registration, users need to activate their account using OTP:

```dart
// Activate account
final result = await AuthService.activateAccount(
  email: 'user@example.com',
  otp: '123456',
);
```

**Endpoint:** `POST /auth/activate`

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

### Resend OTP

```dart
// Resend OTP
final result = await AuthService.resendOtp(
  email: 'user@example.com',
);
```

**Endpoint:** `POST /auth/resend-otp`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

### Password Reset Flow

1. **Request Password Reset (sends OTP to email)**

```dart
final result = await AuthService.requestPasswordReset(
  email: 'user@example.com',
);
```

**Endpoint:** `POST /auth/forgot-password`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

2. **Verify Reset OTP**

```dart
final result = await AuthService.verifyResetOtp(
  email: 'user@example.com',
  otp: '123456',
);
```

**Endpoint:** `POST /auth/verify-reset-otp`

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

3. **Reset Password**

```dart
final result = await AuthService.resetPassword(
  email: 'user@example.com',
  otp: '123456',
  newPassword: 'newPassword123',
);
```

**Endpoint:** `POST /auth/reset-password`

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456",
  "newPassword": "newPassword123"
}
```

## Complete User Flows

### Registration Flow
1. User fills registration form → `AuthService.register()`
2. Success → Navigate to OTP verification screen
3. User enters OTP → `AuthService.activateAccount()`
4. Success → Navigate to login screen

### Forgot Password Flow
1. User enters email → `AuthService.requestPasswordReset()`
2. Success → Navigate to OTP verification screen
3. User enters OTP → `AuthService.verifyResetOtp()`
4. Success → Navigate to reset password screen
5. User enters new password → `AuthService.resetPassword()`
6. Success → Navigate to login screen

## Available Screens

- `EmailLoginScreen` - Email/password login
- `PhoneLoginScreen` - Phone/password login
- `EmailSignupScreen` - User registration
- `ForgotPasswordScreen` - Request password reset
- `OtpVerificationScreen` - Verify OTP (for activation or password reset)
- `ResetPasswordScreen` - Set new password after OTP verification
