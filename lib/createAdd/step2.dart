import 'package:flutter/material.dart';
import 'step3.dart';
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
      home: const CarSellStep2(),
    );
  }
}

class CarSellStep2 extends StatefulWidget {
  const CarSellStep2({Key? key}) : super(key: key);

  @override
  State<CarSellStep2> createState() => _CarSellStep2State();
}

class _CarSellStep2State extends State<CarSellStep2> {
  // Selected attributes
  Set<String> selectedAttributes = {};
  bool _loadingAttrs = false;
  List<Map<String, dynamic>> _attrs = [];
  String? _categoryId;

  // Controllers
  final TextEditingController typeController = TextEditingController();
  final TextEditingController transmissionController = TextEditingController();
  final TextEditingController structureController = TextEditingController();
  final TextEditingController engineDisplacementController =
      TextEditingController();
  final TextEditingController energyController = TextEditingController();
  final TextEditingController conditioningController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAttributes();
  }

  Future<void> _initAttributes() async {
    setState(() {
      _loadingAttrs = true;
    });
    String? cid = AdFormDraft.instance.selectedSubcategoryId;
    cid ??= await CreateAdService.getDefaultSubcategoryId();
    if (cid != null) {
      final attrs = await CreateAdService.fetchAttributes(cid);
      setState(() {
        _categoryId = cid;
        _attrs = attrs;
        AdFormDraft.instance.selectedSubcategoryId ??= cid;
      });
    }
    setState(() {
      _loadingAttrs = false;
    });
  }

  List<Map<String, String>> _buildAttrOptions() {
    final List<Map<String, String>> options = [];
    for (final a in _attrs) {
      final String aid = (a['id'] ?? '').toString();
      final String aname = (a['name'] ?? '').toString();
      final String type = (a['type'] ?? '').toString();
      final List<dynamic> raw = (a['options'] is List)
          ? (a['options'] as List)
          : const [];
      if (type == 'CHECKBOX' || type == 'SELECT' || type == 'RADIO') {
        if (raw.isNotEmpty) {
          for (final o in raw) {
            options.add({'aid': aid, 'label': aname, 'value': o.toString()});
          }
        }
      }
    }
    return options;
  }

  void _syncSelectedToDraft() {
    final Map<String, List<String>> grouped = {};
    for (final key in selectedAttributes) {
      final parts = key.split('::');
      if (parts.length >= 2) {
        (grouped[parts[0]] ??= <String>[]).add(parts[1]);
      }
    }
    final Map<String, dynamic> map = {};
    grouped.forEach((aid, values) {
      if (values.length <= 1) {
        map[aid] = values.isEmpty ? null : values.first;
      } else {
        map[aid] = values;
      }
    });
    // Store attributes in formData instead of deprecated attributes field
    AdFormDraft.instance.formData.attributes = map;
  }

  @override
  void dispose() {
    typeController.dispose();
    transmissionController.dispose();
    structureController.dispose();
    engineDisplacementController.dispose();
    energyController.dispose();
    conditioningController.dispose();
    colorController.dispose();
    seatsController.dispose();
    sourceController.dispose();
    super.dispose();
  }

  void _showAttributesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'إضافات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDialogCheckbox(
                                'حدد الكل',
                                _buildAttrOptions().isNotEmpty &&
                                    selectedAttributes.length ==
                                        _buildAttrOptions().length,
                                (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedAttributes = _buildAttrOptions()
                                          .map(
                                            (o) => '${o['aid']}::${o['value']}',
                                          )
                                          .toSet();
                                    } else {
                                      selectedAttributes.clear();
                                    }
                                  });
                                  _syncSelectedToDraft();
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                              ..._buildAttrOptions().map(
                                (opt) => _buildDialogCheckbox(
                                  opt['value'] ?? '',
                                  selectedAttributes.contains(
                                    '${opt['aid']}::${opt['value']}',
                                  ),
                                  (value) {
                                    setDialogState(() {
                                      final key =
                                          '${opt['aid']}::${opt['value']}';
                                      if (value == true) {
                                        selectedAttributes.add(key);
                                      } else {
                                        selectedAttributes.remove(key);
                                      }
                                    });
                                    _syncSelectedToDraft();
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00A651),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
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
                      _buildProgressCircle('3', false),
                      _buildProgressLine(true),
                      _buildProgressCircle('2', true),
                      _buildProgressLine(false),
                      _buildProgressCircle('1', false),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تفاصيل السيارة والملحقة',
                    style: TextStyle(
                      color: Color(0xFF00A651),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مواصفات السيارة ووسائل الملحقة',
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
                    // نوع الوقود (Fuel Type)
                    _buildLabel('نوع الوقود'),
                    const SizedBox(height: 8),
                    _buildInputField(typeController, 'إختر نوع الوقود'),

                    const SizedBox(height: 24),

                    // ناقل الحركة (Transmission)
                    _buildLabel('ناقل الحركة'),
                    const SizedBox(height: 8),
                    _buildInputField(transmissionController, 'يدوي'),

                    const SizedBox(height: 24),

                    // هيكل السيارة (Car Structure)
                    _buildLabel('هيكل السيارة'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      structureController,
                      'إختر الهيكل و السيارة',
                    ),

                    const SizedBox(height: 24),

                    // المحرك (بس سي سي) (Engine Displacement)
                    _buildLabel('المحرك (بس سي سي)'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      engineDisplacementController,
                      'إدخال قيمة المحرك (بس سي سي)',
                    ),

                    const SizedBox(height: 24),

                    // الطاقة (قوة حصانية) (Power)
                    _buildLabel('الطاقة (قوة حصانية)'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      energyController,
                      'إدخال الطاقة (قوة حصانية)',
                    ),

                    const SizedBox(height: 24),

                    // الاستهلاك (لتر / 100 كم) (Fuel Consumption)
                    _buildLabel('الاستهلاك (لتر / 100 كم)'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      conditioningController,
                      'إدخال الاستهلاك (لتر / 100 كم)',
                    ),

                    const SizedBox(height: 24),

                    // التكييف (Air Conditioning)
                    _buildLabel('التكييف'),
                    const SizedBox(height: 8),
                    _buildInputField(conditioningController, 'إختر تكييف'),

                    const SizedBox(height: 24),

                    // اللون (Color)
                    _buildLabel('اللون'),
                    const SizedBox(height: 8),
                    _buildInputField(colorController, 'إختر اللون'),

                    const SizedBox(height: 24),

                    // عدد المقاعد (Number of Seats)
                    _buildLabel('عدد المقاعد'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildSeatOption('4/5')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSeatOption('2/3')),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // الإضافات (Additions/Features)
                    _buildLabel('الإضافات'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showAttributesDialog,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00A651),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF00A651),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Display selected attributes
                    if (selectedAttributes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAttributeItem(
                              'راديو AM/FM',
                              selectedAttributes.contains('راديو AM/FM'),
                            ),
                            _buildAttributeItem(
                              'عجلات / حنوط استثنائية',
                              selectedAttributes.contains(
                                'عجلات / حنوط استثنائية',
                              ),
                            ),
                            _buildAttributeItem(
                              'وسائد هوائية',
                              selectedAttributes.contains('وسائد هوائية'),
                            ),
                            _buildAttributeItem(
                              'نظام الفرامل المانعة للانغلاق',
                              selectedAttributes.contains(
                                'نظام الفرامل المانعة للانغلاق',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // عدد الملاكين (Number of Owners)
                    _buildLabel('عدد الملاكين'),
                    const SizedBox(height: 8),
                    _buildInputField(sourceController, 'إدخال عدد الملاكين'),

                    const SizedBox(height: 24),

                    // المصدر (Source)
                    _buildLabel('المصدر'),
                    const SizedBox(height: 8),
                    _buildInputField(sourceController, 'إختر المصدر'),

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
                          builder: (context) => const CarSellStep3(),
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

  Widget _buildInputField(TextEditingController controller, String hint) {
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
        ),
      ),
    );
  }

  Widget _buildSeatOption(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildAttributeItem(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: Color(0xFF00A651), size: 20),
        ],
      ),
    );
  }
}
