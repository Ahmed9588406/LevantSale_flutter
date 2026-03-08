import 'package:flutter/material.dart';
import 'step2.dart';
import 'create_ad_screen.dart';

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
      // Use new CreateAdScreen for full backend integration
      home: const CreateAdScreen(),
    );
  }
}

/// Legacy widget - kept for backward compatibility
/// For new implementations, use CreateAdScreen instead
class CarSellForm extends StatefulWidget {
  const CarSellForm({Key? key}) : super(key: key);

  @override
  State<CarSellForm> createState() => _CarSellFormState();
}

class _CarSellFormState extends State<CarSellForm> {
  String carType = 'automatic';
  String condition = 'new';
  String selectedDepartment = 'سيارات';

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
            onPressed: () {},
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
                      _buildProgressCircle('3', false),
                      _buildProgressLine(false),
                      _buildProgressCircle('2', false),
                      _buildProgressLine(false),
                      _buildProgressCircle('1', true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'البيانات الأساسية للسيارة',
                    style: TextStyle(
                      color: Color(0xFF00A651),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الفئة والموديل والبيانات الأساسية',
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
                    // القسم (Department)
                    _buildLabel('القسم'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedDepartment,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                items: ['سيارات'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDepartment = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(
                              Icons.directions_car,
                              color: Color(0xFF00A651),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ناقل الحركة (Transmission)
                    _buildLabel('ناقل الحركة'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            'أوتوماتيك',
                            carType == 'automatic',
                            () => setState(() => carType = 'automatic'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            'يدوي',
                            carType == 'manual',
                            () => setState(() => carType = 'manual'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // هيكل السيارة (Car Structure/Photos)
                    _buildLabel('هيكل السيارة'),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildPhotoBox(false),
                        _buildPhotoBox(false),
                        _buildPhotoBox(true),
                        _buildPhotoBox(false),
                        _buildPhotoBox(false),
                        _buildPhotoBox(false),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // الماركة (Brand)
                    _buildLabel('الماركة'),
                    const SizedBox(height: 8),
                    _buildSearchField('إختر الماركة'),

                    const SizedBox(height: 24),

                    // الموديل (Model)
                    _buildLabel('الموديل'),
                    const SizedBox(height: 8),
                    _buildInputField('أدخل الموديل'),

                    const SizedBox(height: 24),

                    // النسخة (Version)
                    _buildLabel('النسخة'),
                    const SizedBox(height: 8),
                    _buildDropdownField('أدخل النسخة'),

                    const SizedBox(height: 24),

                    // الحالة (Condition)
                    _buildLabel('الحالة'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            'جديد',
                            condition == 'new',
                            () => setState(() => condition = 'new'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            'مستعمل',
                            condition == 'used',
                            () => setState(() => condition = 'used'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // كيلو مترات (Kilometers)
                    _buildLabel('كيلو مترات'),
                    const SizedBox(height: 8),
                    _buildInputField('أدخل كيلومترات مثال 42,500 كم'),

                    const SizedBox(height: 24),

                    // السنة (Year)
                    _buildLabel('السنة'),
                    const SizedBox(height: 8),
                    _buildInputField('أدخل السنة'),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarSellStep2(),
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
                      'التالي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
      color: Colors.grey[300],
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
              fontSize: 16,
              color: isSelected ? const Color(0xFF00A651) : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBox(bool hasPlus) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPlus ? const Color(0xFF00A651) : Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: hasPlus
            ? Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A651),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              )
            : Icon(
                Icons.camera_alt_outlined,
                color: Colors.grey[400],
                size: 32,
              ),
      ),
    );
  }

  Widget _buildSearchField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
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

  Widget _buildInputField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        textAlign: TextAlign.right,
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

  Widget _buildDropdownField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
