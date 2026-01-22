import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'verification_step_three_screen.dart';
import 'image_picker_helper.dart';

class VerificationStepTwoScreen extends StatefulWidget {
  const VerificationStepTwoScreen({Key? key}) : super(key: key);

  @override
  State<VerificationStepTwoScreen> createState() =>
      _VerificationStepTwoScreenState();
}

class _VerificationStepTwoScreenState extends State<VerificationStepTwoScreen> {
  File? _frontImage;
  File? _backImage;

  Future<void> _pickImage(bool isFront) async {
    final image = await ImagePickerHelper.showImageSourceDialog(context);
    if (image != null && mounted) {
      setState(() {
        if (isFront) {
          _frontImage = image;
          print('Front image selected: ${image.path}');
        } else {
          _backImage = image;
          print('Back image selected: ${image.path}');
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFront ? 'تم اختيار الصورة الأمامية' : 'تم اختيار الصورة الخلفية',
          ),
          backgroundColor: const Color(0xFF1DAF52),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative shape
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1DAF52).withOpacity(0.08),
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                // Top bar with back and close buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                ),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          // Background bar
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Progress bar
                          FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DAF52),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          // Circle indicator
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.5 - 60,
                            top: -5,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF1DAF52),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Title
                        const Text(
                          'ارفق صور بطاقة الرقم القومي',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'ارفق صورة أمامية و خلفية',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Image upload boxes
                        Row(
                          children: [
                            Expanded(
                              child: _buildImageUploadBox(
                                image: _backImage,
                                onTap: () => _pickImage(false),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildImageUploadBox(
                                image: _frontImage,
                                onTap: () => _pickImage(true),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_frontImage != null && _backImage != null) {
                                // Navigate to step three
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const VerificationStepThreeScreen(),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى رفع الصورتين'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DAF52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'حفظ و متابعة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Help text
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                              children: [
                                TextSpan(text: 'هل تحتاج إلى المساعدة؟ '),
                                TextSpan(
                                  text: 'تواصل مع خدمة العملاء',
                                  style: TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadBox({
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: image != null ? Colors.black12 : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null
                ? const Color(0xFF1DAF52)
                : const Color(0xFFE0E0E0),
            width: image != null ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'icons/camera.svg',
                      width: 64,
                      height: 64,
                      colorFilter: const ColorFilter.mode(
                        Color(0x809E9E9E),
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Color(0x809E9E9E),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'فشل تحميل الصورة',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                    // Edit overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
