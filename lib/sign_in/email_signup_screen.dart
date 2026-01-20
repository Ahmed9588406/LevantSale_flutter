import 'package:flutter/material.dart';

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({Key? key}) : super(key: key);

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+964');
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
                          const SizedBox(height: 10),
                          
                          // Title
                          const Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(
                              color: Color(0xFF2B2B2A),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subtitle
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'لتأمين حسابك وتسجيل الدخول بشكل أسرع اختر كلمة سرية قوية لم تستخدمها من قبل.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
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
                          
                          const SizedBox(height: 24),
                          
                          // Password label
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'كلمة المرور',
                              style: TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Password input
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                hintText: '••••••',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB0B0B0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFFB0B0B0),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Confirm Password label
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'كلمة المرور',
                              style: TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Confirm Password input
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                hintText: '••••••',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB0B0B0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFFB0B0B0),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Phone label
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'رقم الهاتف',
                              style: TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Phone input
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: Color(0xFF2B2B2A),
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Terms and conditions checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeToTerms = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF1DAF52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B6B6B),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'بالنقر على "موافقة وإنشاء حساب" فإنك توافق على ',
                                      ),
                                      TextSpan(
                                        text: 'شروط و أحكام وسياسة الخصوصية',
                                        style: TextStyle(
                                          color: Color(0xFF1DAF52),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Signup button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _agreeToTerms ? () {} : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DAF52),
                                disabledBackgroundColor: const Color(0xFF1DAF52).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'موافقة وإنشاء حساب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login text
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
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
                                    text: 'هل لديك حساب بالفعل ؟ ',
                                  ),
                                  TextSpan(
                                    text: 'سجل الدخول الآن',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
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
