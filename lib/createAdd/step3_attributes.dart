import 'package:flutter/material.dart';
import 'ad_form_model.dart';
import 'create_ad_service.dart';

/// Step 3: Dynamic Attributes based on category
/// Mirrors web Step3Attributes.tsx
class Step3Attributes extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isSubmitting;

  const Step3Attributes({
    Key? key,
    required this.onNext,
    required this.onBack,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<Step3Attributes> createState() => _Step3AttributesState();
}

class _Step3AttributesState extends State<Step3Attributes> {
  final _draft = AdFormDraft.instance;
  List<AttributeModel> _attributes = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _attributeValues = {};
  Map<String, bool> _openDropdowns = {};

  @override
  void initState() {
    super.initState();
    _fetchAttributes();
  }

  Future<void> _fetchAttributes() async {
    final subcategoryId = _draft.formData.subcategoryId;
    if (subcategoryId == null || subcategoryId.isEmpty) {
      setState(() {
        _isLoading = false;
        _attributes = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attributes = await CreateAdService.fetchAttributeModels(
        subcategoryId,
      );

      // Initialize attribute values from existing formData or empty
      final Map<String, dynamic> initialValues = {};
      for (final attr in attributes) {
        if (_draft.formData.attributes[attr.id] != null) {
          initialValues[attr.id] = _draft.formData.attributes[attr.id];
        } else {
          // Initialize based on type
          if (attr.type == 'CHECKBOX') {
            initialValues[attr.id] = <String>[];
          } else {
            initialValues[attr.id] = '';
          }
        }
      }

      setState(() {
        _attributes = attributes;
        _attributeValues = initialValues;
        _draft.attributes = attributes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching attributes: $e');
      setState(() {
        _isLoading = false;
        _error = 'فشل تحميل الخصائص';
      });
    }
  }

  void _handleAttributeChange(String attributeId, dynamic value) {
    setState(() {
      _attributeValues[attributeId] = value;
      _draft.formData.attributes[attributeId] = value;
    });
  }

  void _toggleDropdown(String attributeId) {
    setState(() {
      _openDropdowns[attributeId] = !(_openDropdowns[attributeId] ?? false);
    });
  }

  bool _requiredAttributesFilled() {
    final missingRequired = _attributes.where((attr) => attr.required).where((
      attr,
    ) {
      final value = _attributeValues[attr.id];
      if (value == null) return true;
      if (value is String && value.isEmpty) return true;
      if (value is List && value.isEmpty) return true;
      return false;
    }).toList();

    return missingRequired.isEmpty;
  }

  void _handleSubmit() {
    if (!_requiredAttributesFilled()) {
      final missingAttrs = _attributes
          .where((attr) => attr.required)
          .where((attr) {
            final value = _attributeValues[attr.id];
            return value == null ||
                (value is String && value.isEmpty) ||
                (value is List && value.isEmpty);
          })
          .map((attr) => attr.name)
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء الحقول المطلوبة: $missingAttrs')),
      );
      return;
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00A651)),
                    SizedBox(height: 16),
                    Text('جاري تحميل الخصائص...'),
                  ],
                ),
              ),
            ),
          ] else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_attributes.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'لا توجد خصائص لهذه الفئة',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._attributes.map((attribute) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(attribute.name, required: attribute.required),
                    const SizedBox(height: 8),
                    _buildAttributeField(attribute),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 16),

          // Navigation Buttons
          Row(
            children: [
              // Back Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: widget.isSubmitting ? null : widget.onBack,
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
              // Submit Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        widget.isSubmitting ||
                            (_attributes.isNotEmpty &&
                                !_requiredAttributesFilled())
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: widget.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'نشر الإعلان',
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

  Widget _buildAttributeField(AttributeModel attribute) {
    final value = _attributeValues[attribute.id] ?? '';

    switch (attribute.type) {
      case 'TEXT':
        return _buildTextInput(attribute, value.toString());

      case 'NUMBER':
        return Row(
          children: [
            Expanded(
              child: _buildTextInput(
                attribute,
                value.toString(),
                keyboardType: TextInputType.number,
              ),
            ),
            if (attribute.unit != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attribute.unit!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ],
        );

      case 'SELECT':
      case 'RADIO':
        return _buildDropdownField(attribute, value.toString());

      case 'CHECKBOX':
        return _buildCheckboxField(
          attribute,
          value is List ? value.cast<String>() : [],
        );

      case 'DATE':
        return _buildDateField(attribute, value.toString());

      default:
        return _buildTextInput(attribute, value.toString());
    }
  }

  Widget _buildTextInput(
    AttributeModel attribute,
    String value, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        textAlign: TextAlign.right,
        keyboardType: keyboardType,
        onChanged: (newValue) => _handleAttributeChange(attribute.id, newValue),
        decoration: InputDecoration(
          hintText: 'أدخل ${attribute.name}',
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

  Widget _buildDropdownField(AttributeModel attribute, String value) {
    final isOpen = _openDropdowns[attribute.id] ?? false;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _toggleDropdown(attribute.id),
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
                    value.isNotEmpty ? value : 'اختر',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      color: value.isNotEmpty
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
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
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: attribute.options.length,
              itemBuilder: (context, index) {
                final option = attribute.options[index];
                return InkWell(
                  onTap: () {
                    _handleAttributeChange(attribute.id, option);
                    _toggleDropdown(attribute.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxField(
    AttributeModel attribute,
    List<String> selectedValues,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: attribute.options.map((option) {
          final isSelected = selectedValues.contains(option);
          return InkWell(
            onTap: () {
              final newValues = List<String>.from(selectedValues);
              if (isSelected) {
                newValues.remove(option);
              } else {
                newValues.add(option);
              }
              _handleAttributeChange(attribute.id, newValues);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00A651)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00A651)
                            : Colors.grey[400]!,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateField(AttributeModel attribute, String value) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF00A651),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          _handleAttributeChange(
            attribute.id,
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
        }
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
                value.isNotEmpty ? value : 'اختر التاريخ',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  color: value.isNotEmpty ? Colors.black87 : Colors.grey[400],
                ),
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400]),
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
}
