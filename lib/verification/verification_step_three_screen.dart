import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'image_picker_helper.dart';
import 'success_dialog.dart';
import 'verification_draft.dart';
import '../profile/profile_service.dart';
import 'verification_service.dart';

class VerificationStepThreeScreen extends StatefulWidget {
  const VerificationStepThreeScreen({Key? key}) : super(key: key);

  @override
  State<VerificationStepThreeScreen> createState() =>
      _VerificationStepThreeScreenState();
}

class _VerificationStepThreeScreenState
    extends State<VerificationStepThreeScreen> {
  File? _profileImage;
  String? _phoneNumber;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final image = await ImagePickerHelper.showImageSourceDialog(context);
    if (image != null && mounted) {
      setState(() {
        _profileImage = image;
        print('Profile image selected: ${image.path}');
      });
      // persist to draft
      VerificationDraft.instance.facePhoto = image;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم اختيار الصورة الشخصية'),
          backgroundColor: Color(0xFF1DAF52),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final draft = VerificationDraft.instance;
    if (_profileImage == null ||
        draft.nationalIdFront == null ||
        draft.nationalIdBack == null ||
        (draft.fullName == null || draft.fullName!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إكمال جميع الخطوات (الاسم، صور البطاقة، وصورة الوجه)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      String phone = _phoneNumber ?? '';
      if (phone.isEmpty) {
        final prof = await ProfileService.fetchProfile();
        phone = (prof?['phone'] ?? prof?['phoneNumber'] ?? '').toString();
      }
      final ok = await VerificationService.submitVerification(
        fullName: draft.fullName ?? '',
        aboutYou: draft.aboutYou ?? '',
        gender: draft.gender,
        phoneNumber: phone,
        nationalIdFront: draft.nationalIdFront!,
        nationalIdBack: draft.nationalIdBack!,
        facePhoto: _profileImage!,
      );
      if (!mounted) return;
      if (ok) {
        SuccessDialog.show(
          context: context,
          title: 'تم رفع بياناتك بنجاح!',
          message: 'سيتم مراجعة البيانات بعد الإرسال',
          onClose: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إرسال طلب التوثيق'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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

                // Progress bar - Full completion
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
                          // Progress bar - Full width
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DAF52),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Circle indicator at the end
                          Positioned(
                            right: 0,
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
                          'ارفق صور شخصية',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'صورة للوجه :',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Single centered image upload box
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 240,
                              height: 200,
                              decoration: BoxDecoration(
                                color: _profileImage != null
                                    ? Colors.black12
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _profileImage != null
                                      ? const Color(0xFF1DAF52)
                                      : const Color(0xFFE0E0E0),
                                  width: _profileImage != null ? 2 : 1.5,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _profileImage == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            placeholderBuilder: (context) =>
                                                const Icon(
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
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  print(
                                                    'Error loading image: $error',
                                                  );
                                                  return Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 48,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'فشل تحميل الصورة',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
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
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
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
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DAF52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'إرسال البيانات',
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
}
