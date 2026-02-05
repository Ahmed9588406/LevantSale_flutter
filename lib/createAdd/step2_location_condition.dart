import 'package:flutter/material.dart';
import 'ad_form_model.dart';

/// Step 2: Location, Condition, Price, Phone
/// Mirrors web Step2LocationCondition.tsx
class Step2LocationCondition extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2LocationCondition({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<Step2LocationCondition> createState() => _Step2LocationConditionState();
}

class _Step2LocationConditionState extends State<Step2LocationCondition> {
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _draft = AdFormDraft.instance;

  bool _showConditionDropdown = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _locationController.text = _draft.formData.location ?? '';
    _phoneController.text = _draft.formData.phone ?? '';
    _priceController.text = _draft.formData.price ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _locationController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _draft.formData.condition.isNotEmpty;
  }

  void _handleNext() {
    // Save data to draft
    _draft.formData.location = _locationController.text.trim();
    _draft.formData.phone = _phoneController.text.trim();
    _draft.formData.price = _priceController.text.trim();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final conditions = [
      {'value': 'NEW', 'label': 'جديد'},
      {'value': 'USED', 'label': 'مستعمل'},
    ];

    final selectedCondition = conditions.firstWhere(
      (c) => c['value'] == _draft.formData.condition,
      orElse: () => conditions[1],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          _buildLabel('الموقع', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hint: 'أدخل الموقع',
            suffixIcon: Icons.location_on_outlined,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          // Phone
          _buildLabel('رقم الهاتف', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'أدخل رقم الهاتف',
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          // Condition
          _buildLabel('الحالة', required: true),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() => _showConditionDropdown = !_showConditionDropdown);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCondition['label']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _showConditionDropdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (_showConditionDropdown)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: conditions.map((condition) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _draft.formData.condition = condition['value']!;
                        _showConditionDropdown = false;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        condition['label']!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Price and Currency
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('السعر', required: true),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _priceController,
                      hint: 'أدخل السعر',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Currency
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('العملة'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _draft.formData.currency,
                          isExpanded: true,
                          isDense: true,
                          items: _draft.currencies.isEmpty
                              ? [
                                  const DropdownMenuItem(
                                    value: 'EGP',
                                    child: Text('EGP'),
                                  ),
                                ]
                              : _draft.currencies.map((c) {
                                  return DropdownMenuItem(
                                    value: c.code,
                                    child: Text(
                                      '${c.code}${c.symbol != null ? ' (${c.symbol})' : ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _draft.formData.currency = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              // Back Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'السابق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Next Button
              Expanded(
                child: SizedBox(
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
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
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
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.grey[400])
              : null,
        ),
      ),
    );
  }
}
