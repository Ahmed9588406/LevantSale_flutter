import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ad_form_model.dart';

/// Step 1: Basic Information - Title, Description, Images
/// Mirrors web Step1BasicInfo.tsx
class Step1BasicInfo extends StatefulWidget {
  final VoidCallback onNext;

  const Step1BasicInfo({Key? key, required this.onNext}) : super(key: key);

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _draft = AdFormDraft.instance;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _titleController.text = _draft.formData.title ?? '';
    _descriptionController.text = _draft.formData.description ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _draft.formData.images.isNotEmpty;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final xFile in pickedFiles) {
            _draft.formData.images.add(File(xFile.path));
            _draft.formData.imagePreviews.add(xFile.path);
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في اختيار الصور: $e')));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (photo != null) {
        setState(() {
          _draft.formData.images.add(File(photo.path));
          _draft.formData.imagePreviews.add(photo.path);
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في التقاط الصورة: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _draft.formData.images.length) {
        _draft.formData.images.removeAt(index);
      }
      if (index < _draft.formData.imagePreviews.length) {
        _draft.formData.imagePreviews.removeAt(index);
      }
    });
  }

  void _handleNext() {
    // Save data to draft
    _draft.formData.title = _titleController.text.trim();
    _draft.formData.description = _descriptionController.text.trim();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildLabel('العنوان', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'أدخل عنوان الإعلان',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          // Description
          _buildLabel('الوصف', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descriptionController,
            hint: 'أدخل وصف الإعلان',
            maxLines: 5,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          // Image Upload
          _buildLabel('الصور', required: true),
          const SizedBox(height: 8),

          // Upload Area
          InkWell(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'اضغط لتحميل الصور',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أو التقط صورة من الكاميرا',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Image Preview Grid
          if (_draft.formData.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'معاينة الصور (${_draft.formData.images.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _draft.formData.images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _draft.formData.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isValid ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'التالي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'اختر مصدر الصورة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceOption(
                        icon: Icons.photo_library,
                        label: 'المعرض',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImages();
                        },
                      ),
                      _buildImageSourceOption(
                        icon: Icons.camera_alt,
                        label: 'الكاميرا',
                        onTap: () {
                          Navigator.pop(context);
                          _takePhoto();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFF00A651)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
