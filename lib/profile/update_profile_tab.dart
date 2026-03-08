import 'package:flutter/material.dart';
import 'profile_service.dart';
import '../services/toast_service.dart' show AppToast;

class UpdateProfileTab extends StatefulWidget {
  const UpdateProfileTab({super.key});

  @override
  State<UpdateProfileTab> createState() => _UpdateProfileTabState();
}

class _UpdateProfileTabState extends State<UpdateProfileTab> {
  bool _loading = true;
  bool _updating = false;
  String? _error;

  // User profile data
  Map<String, dynamic>? _profile;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final List<TextEditingController> _socialLinkControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    for (var controller in _socialLinkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final profile = await ProfileService.fetchProfile();

    if (!mounted) return;

    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile['name']?.toString() ?? '';
        _emailController.text = profile['email']?.toString() ?? '';
        _phoneController.text = profile['phone']?.toString() ?? '';
        _bioController.text = profile['bio']?.toString() ?? '';

        // Initialize social links
        final socialLinks = profile['socialLinks'] as List?;
        if (socialLinks != null && socialLinks.isNotEmpty) {
          _socialLinkControllers.clear();
          for (var link in socialLinks) {
            final controller = TextEditingController(text: link.toString());
            _socialLinkControllers.add(controller);
          }
        }

        _loading = false;
      });
    } else {
      setState(() {
        _error = 'فشل تحميل الملف الشخصي';
        _loading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      AppToast.showError(context, 'الرجاء إدخال الاسم');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      AppToast.showError(context, 'الرجاء إدخال البريد الإلكتروني');
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      AppToast.showError(context, 'البريد الإلكتروني غير صالح');
      return;
    }

    setState(() => _updating = true);

    // Prepare social links
    final socialLinks = _socialLinkControllers
        .map((c) => c.text.trim())
        .where((link) => link.isNotEmpty)
        .toList();

    // Prepare update data
    final updateData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      'socialLinks': socialLinks,
    };

    final result = await ProfileService.updateProfile(updateData);

    if (!mounted) return;

    setState(() => _updating = false);

    if (result != null) {
      setState(() => _profile = result);
      AppToast.showSuccess(context, 'تم تحديث الملف الشخصي بنجاح');
    } else {
      AppToast.showError(context, 'فشل تحديث الملف الشخصي');
    }
  }

  void _addSocialLink() {
    setState(() {
      _socialLinkControllers.add(TextEditingController());
    });
  }

  void _removeSocialLink(int index) {
    setState(() {
      _socialLinkControllers[index].dispose();
      _socialLinkControllers.removeAt(index);
    });
  }

  Future<void> _updatePhone() async {
    // Validate phone number
    if (_phoneController.text.trim().isEmpty) {
      AppToast.showError(context, 'الرجاء إدخال رقم الهاتف');
      return;
    }

    // Phone validation (basic check for + and numbers)
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      AppToast.showError(
        context,
        'رقم الهاتف غير صالح. يجب أن يبدأ بـ + ويحتوي على 10-15 رقم',
      );
      return;
    }

    // Show confirmation dialog
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث رقم الهاتف'),
        content: Text(
          'هل أنت متأكد من تحديث رقم الهاتف إلى:\n${_phoneController.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1DAF52),
            ),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) return;

    setState(() => _updating = true);

    final success = await ProfileService.updatePhone(
      _phoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _updating = false);

    if (success) {
      // Refresh profile to get updated data
      await _fetchProfile();
      if (!mounted) return;
      AppToast.showSuccess(context, 'تم تحديث رقم الهاتف بنجاح');
    } else {
      AppToast.showError(context, 'فشل تحديث رقم الهاتف');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
              ),
              child: const Text('حاول مرة أخرى'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF1DAF52),
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?['name']?.toString() ?? 'المستخدم',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _profile?['verified'] == true
                                      ? Icons.verified
                                      : Icons.verified_outlined,
                                  size: 16,
                                  color: _profile?['verified'] == true
                                      ? const Color(0xFF1DAF52)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _profile?['verified'] == true
                                      ? 'موثق'
                                      : 'غير موثق',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _profile?['verified'] == true
                                        ? const Color(0xFF1DAF52)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.phone,
                    'رقم الهاتف',
                    _profile?['phone']?.toString() ?? 'غير متوفر',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person,
                    'الدور',
                    _profile?['role']?.toString() ?? 'USER',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.language,
                    'اللغة المفضلة',
                    _profile?['preferredLanguage']?.toString() == 'ar'
                        ? 'العربية'
                        : 'English',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Update Form
          const Text(
            'تحديث المعلومات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'الاسم',
            icon: Icons.person,
            hint: 'أدخل اسمك الكامل',
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email,
            hint: 'أدخل بريدك الإلكتروني',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Phone Field with separate update button
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone,
                  hint: '+1234567890',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _updating ? null : _updatePhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DAF52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _updating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.update, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'ملاحظة: رقم الهاتف يتطلب تحديث منفصل',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bio Field
          _buildTextField(
            controller: _bioController,
            label: 'نبذة عنك',
            icon: Icons.info,
            hint: 'أخبرنا عن نفسك',
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          // Social Links Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'روابط التواصل الاجتماعي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addSocialLink,
                icon: const Icon(Icons.add_circle, color: Color(0xFF1DAF52)),
                tooltip: 'إضافة رابط',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Social Links List
          ..._socialLinkControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'رابط ${index + 1}',
                        hintText: 'https://example.com/profile',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1DAF52),
                            width: 2,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeSocialLink(index),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    tooltip: 'حذف الرابط',
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Update Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _updating ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _updating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'تحديث الملف الشخصي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1DAF52), width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
