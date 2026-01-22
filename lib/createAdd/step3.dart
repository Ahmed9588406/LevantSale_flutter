import 'package:flutter/material.dart';
import 'payment_screen.dart';
import 'dart:io';
import 'create_ad_service.dart';
import 'ad_form_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بيع سيارتك',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Cairo'),
      home: const CarSellStep3(),
    );
  }
}

class CarSellStep3 extends StatefulWidget {
  const CarSellStep3({Key? key}) : super(key: key);

  @override
  State<CarSellStep3> createState() => _CarSellStep3State();
}

class _CarSellStep3State extends State<CarSellStep3> {
  // Controllers
  final TextEditingController adTitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Payment method
  String paymentMethod = 'cash';

  // Contact method
  String contactMethod = 'phone';

  // Backend integration
  bool _submitting = false;
  String? editingId;
  final List<File> _images = <File>[];

  @override
  void dispose() {
    adTitleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    priceController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_submitting) return;
    final title = adTitleController.text.trim();
    final desc = descriptionController.text.trim();
    final loc = locationController.text.trim();
    final priceStr = priceController.text.trim();
    final phone = phoneController.text.trim();

    if (title.isEmpty ||
        desc.isEmpty ||
        loc.isEmpty ||
        priceStr.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      // Determine category: use a default subcategory (like web uses selected subcategory)
      final chosenSubcat = AdFormDraft.instance.selectedSubcategoryId;
      final subcatId =
          chosenSubcat ?? await CreateAdService.getDefaultSubcategoryId();
      if (subcatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد الفئة، حاول لاحقاً')),
        );
        return;
      }

      final data = <String, dynamic>{
        'title': title,
        'description': desc,
        'categoryId': subcatId,
        'price': double.tryParse(priceStr) ?? 0,
        'currency': 'EGP',
        'location': loc,
        'phone': phone,
        'condition': 'USED',
        'attributes': <Map<String, dynamic>>[],
      };

      // Map dynamic attributes from draft to backend schema
      final attrsMap = AdFormDraft.instance.attributes;
      if (attrsMap.isNotEmpty) {
        final List<Map<String, dynamic>> attrsList = [];
        attrsMap.forEach((attrId, value) {
          if (value == null) return;
          if (value is String && value.trim().isEmpty) return;
          if (value is List && value.isEmpty) return;

          if (value is bool) {
            attrsList.add({'attributeId': attrId, 'valueBoolean': value});
          } else if (value is num) {
            attrsList.add({
              'attributeId': attrId,
              'valueNumber': value,
              'valueString': value.toString(),
            });
          } else if (value is List) {
            attrsList.add({
              'attributeId': attrId,
              'valueString': value.map((e) => e.toString()).join(', '),
            });
          } else {
            // Try to parse numeric string
            final parsed = double.tryParse(value.toString());
            if (parsed != null) {
              attrsList.add({
                'attributeId': attrId,
                'valueNumber': parsed,
                'valueString': value.toString(),
              });
            } else {
              attrsList.add({
                'attributeId': attrId,
                'valueString': value.toString(),
              });
            }
          }
        });
        data['attributes'] = attrsList;
      }

      // Try to capture editing id from route if provided
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['id'] is String) {
        editingId = args['id'] as String;
      } else if (args is String) {
        editingId = args;
      }

      final resp = editingId == null
          ? await CreateAdService.createListing(data: data, images: _images)
          : await CreateAdService.updateListing(
              id: editingId!,
              data: data,
              images: _images,
            );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editingId == null
                  ? 'تم نشر الإعلان بنجاح'
                  : 'تم تحديث الإعلان بنجاح',
            ),
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        final body = resp.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل العملية (${resp.statusCode}): $body')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'بيع سيارتك',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey[200], height: 1),
          ),
        ),
        body: Column(
          children: [
            // Progress Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  // Progress Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressCircle('3', true),
                      _buildProgressLine(true),
                      _buildProgressCircle('2', false),
                      _buildProgressLine(true),
                      _buildProgressCircle('1', false),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تفاصيل الإعلان وبيانات الاتصال',
                    style: TextStyle(
                      color: Color(0xFF00A651),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تفاصيل الإعلان والسعر وبيانات التواصل',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الإعلان (Ad Title)
                    _buildLabel('اسم الإعلان'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      adTitleController,
                      'أدخل العنوان',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يجب أن تحتوي خانة العنوان على ما لا يقل عن 5 أحرف لنجاحة.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    // الوصف (Description)
                    _buildLabel('الوصف'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      descriptionController,
                      'أوصف المنتج الذي تريد بيعة',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يجب أن تحتوي خانة الوصف على ما لا يقل عن 10 أحرف لنجاحة.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    // الموقع (Location)
                    _buildLabel('الموقع'),
                    const SizedBox(height: 8),
                    _buildSearchField(locationController, 'إختر الموقع'),

                    const SizedBox(height: 24),

                    // طريقة الدفع (Payment Method)
                    _buildLabel('طريقة الدفع'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            'كاش',
                            paymentMethod == 'cash',
                            () => setState(() => paymentMethod = 'cash'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            'تقسيط',
                            paymentMethod == 'installment',
                            () => setState(() => paymentMethod = 'installment'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            'قابل للتفاوض',
                            paymentMethod == 'negotiable',
                            () => setState(() => paymentMethod = 'negotiable'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // السعر (Price)
                    _buildLabel('السعر'),
                    const SizedBox(height: 8),
                    _buildInputField(priceController, 'إختر تكييف'),

                    const SizedBox(height: 24),

                    // الاسم (Name)
                    _buildLabel('الاسم'),
                    const SizedBox(height: 8),
                    _buildInputField(nameController, 'محمد عبودي'),

                    const SizedBox(height: 24),

                    // رقم الهاتف المحمول (Mobile Number)
                    _buildLabel('رقم الهاتف المحمول'),
                    const SizedBox(height: 8),
                    _buildInputField(phoneController, '+964'),

                    const SizedBox(height: 24),

                    // طريقة التواصل (Contact Method)
                    _buildLabel('طريقة التواصل'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            'رقم التليفون',
                            contactMethod == 'phone',
                            () => setState(() => contactMethod = 'phone'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            'شات leventsale',
                            contactMethod == 'chat',
                            () => setState(() => contactMethod = 'chat'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            'الاثنين',
                            contactMethod == 'both',
                            () => setState(() => contactMethod = 'both'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A651),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ترقية إعلانك',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _submitting ? null : _publish,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF00A651),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'نشر',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00A651),
                            ),
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
    );
  }

  Widget _buildProgressCircle(String number, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF00A651) : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 60,
      height: 2,
      color: isActive ? const Color(0xFF00A651) : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
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

  Widget _buildSearchField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: Icon(Icons.search, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A651) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? const Color(0xFF00A651) : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
