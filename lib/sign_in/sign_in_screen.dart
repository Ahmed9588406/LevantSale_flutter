import 'package:flutter/material.dart';
import 'phone_login_screen.dart';
import 'email_signup_screen.dart';
import 'email_login_screen.dart';
import '../api/auth/google_auth_service.dart';
import '../home/home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isGoogleLoading = false;

  /// Handle Google Sign-In button tap
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('مرحباً ${result['name'] ?? ''}!'),
            backgroundColor: const Color(0xFF1DAF52),
          ),
        );

        // Navigate to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else if (result['cancelled'] == true) {
        // User cancelled - do nothing
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل تسجيل الدخول بجوجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Widget _authButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2B2B2A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                icon,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2B2B2A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                icon,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Stack(
          children: [
            // Decorative background shape
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3F8E1).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Title
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        color: Color(0xFF2B2B2A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Phone button
                    _authButton(
                      label: 'تسجيل الدخول باستخدام رقم هاتف',
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DAF52).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: Color(0xFF1DAF52),
                          size: 18,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneLoginScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email button
                    _authButton(
                      label: 'تسجيل الدخول باستخدام البريد الإلكتروني',
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DAF52).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF1DAF52),
                          size: 18,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmailLoginScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // OR separator
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF2B2B2A),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'أو',
                            style: TextStyle(
                              color: Color(0xFF2B2B2A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF2B2B2A),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Google button
                    _isGoogleLoading
                        ? Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                                ),
                              ),
                            ),
                          )
                        : _socialButton(
                            label: 'تسجيل الدخول باستخدام جوجل',
                            icon: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ),
                            onTap: _handleGoogleSignIn,
                          ),
                    
                    const SizedBox(height: 16),
                    
                    // Facebook button
                    _socialButton(
                      label: 'سجل الدخول بحساب فيسبوك',
                      icon: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'f',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Sign up text
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmailSignupScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFC47F08),
                          ),
                          children: [
                            TextSpan(
                              text: 'ليس لديك حساب في ',
                            ),
                            TextSpan(
                              text: 'leventsale',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' قم بتسجيل الدخول الآن',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
