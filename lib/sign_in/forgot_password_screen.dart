import 'package:flutter/material.dart';
import 'email_signup_screen.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
              child: Column(
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2A)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Title
                          const Text(
                            'نسيت كلمة السر',
                            style: TextStyle(
                              color: Color(0xFF2B2B2A),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Email label
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'ادخل بريد الإلكتروني',
                              style: TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Email input
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                hintText: 'ali.obaidy178@mail.com',
                                hintStyle: TextStyle(
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Send button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_emailController.text.isNotEmpty) {
                                  // Navigate to OTP screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OtpVerificationScreen(
                                        email: _emailController.text,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('الرجاء إدخال البريد الإلكتروني'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DAF52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'إرسال',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
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
                                    text: 'عضو جديد في ',
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
          ],
        ),
      ),
    );
  }
}
