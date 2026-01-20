import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  
  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 57;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 57;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Check if all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      // Auto-verify when all digits are entered
      _verifyOtp();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyOtp() {
    String otp = _controllers.map((c) => c.text).join();
    // TODO: Implement OTP verification logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم التحقق من الرمز: $otp'),
        backgroundColor: const Color(0xFF1DAF52),
      ),
    );
  }

  void _resendOtp() {
    _startTimer();
    // TODO: Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إعادة إرسال الرمز'),
        backgroundColor: Color(0xFF1DAF52),
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
                            'أدخل رمز التأكيد',
                            style: TextStyle(
                              color: Color(0xFF2B2B2A),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'أدخل الرمز المكون من 4 أرقام الذي تم إرساله عبر\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // OTP Input Fields
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                return Container(
                                  width: 46,
                                  height: 56,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _controllers[index].text.isNotEmpty
                                          ? const Color(0xFFC47F08)
                                          : const Color(0xFFE5E5E5),
                                      width: _controllers[index].text.isNotEmpty ? 2 : 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2B2B2A),
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _onChanged(value, index);
                                      });
                                    },
                                    onTap: () {
                                      _controllers[index].selection = TextSelection.fromPosition(
                                        TextPosition(offset: _controllers[index].text.length),
                                      );
                                    },
                                    onEditingComplete: () {
                                      if (index < 5) {
                                        _focusNodes[index + 1].requestFocus();
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Timer text
                          Text(
                            'بعد $_secondsRemaining ثانية يمكنك',
                            style: const TextStyle(
                              color: Color(0xFF2B2B2A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Resend link
                          TextButton(
                            onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                            child: Text(
                              'إعادة إرسال الرمز عن طريق الواتساب',
                              style: TextStyle(
                                color: _secondsRemaining == 0 
                                    ? const Color(0xFF1DAF52) 
                                    : const Color(0xFFB0B0B0),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Help text
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'إذا لم تكن قد تلقيت الرمز عن طريق الواتساب، فيرجى طلب ذلك',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Resend button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _resendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DAF52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'إعادة إرسال رمز',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
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
