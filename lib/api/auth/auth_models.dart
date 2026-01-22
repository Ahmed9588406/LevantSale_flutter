class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class LoginResponse {
  final bool success;
  final String? token;
  final UserData? user;
  final String? message;

  LoginResponse({required this.success, this.token, this.user, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      message: json['message'],
    );
  }
}

class UserData {
  final String id;
  final String email;
  final String? name;
  final String? phone;

  UserData({required this.id, required this.email, this.name, this.phone});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      phone: json['phone'],
    );
  }
}

class PhoneLoginRequest {
  final String phone;
  final String password;

  PhoneLoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'password': password};
  }
}

class PhoneLoginResponse {
  final bool success;
  final String? token;
  final UserData? user;
  final String? message;

  PhoneLoginResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
  });

  factory PhoneLoginResponse.fromJson(Map<String, dynamic> json) {
    return PhoneLoginResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      message: json['message'],
    );
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.role = 'USER',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    };
  }
}

class RegisterResponse {
  final bool success;
  final String? token;
  final UserData? user;
  final String? message;

  RegisterResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      message: json['message'],
    );
  }
}
