import 'dart:io';

/// Model representing a category from the backend
class CategoryModel {
  final String id;
  final String name;
  final String nameAr;
  final String? icon;
  final String? iconUrl;
  final String? parentId;
  final List<CategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameAr,
    this.icon,
    this.iconUrl,
    this.parentId,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      iconUrl: json['iconUrl']?.toString(),
      parentId: json['parentId']?.toString(),
      subcategories: [],
    );
  }

  CategoryModel copyWith({List<CategoryModel>? subcategories}) {
    return CategoryModel(
      id: id,
      name: name,
      nameAr: nameAr,
      icon: icon,
      iconUrl: iconUrl,
      parentId: parentId,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}

/// Model representing a currency from the backend
class CurrencyModel {
  final String id;
  final String code;
  final String name;
  final String? symbol;
  final bool active;

  CurrencyModel({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.active = true,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString(),
      active: json['active'] == true,
    );
  }
}

/// Model representing an attribute from the backend
class AttributeModel {
  final String id;
  final String name;
  final String type; // TEXT, NUMBER, SELECT, RADIO, CHECKBOX, DATE
  final List<String> options;
  final bool required;
  final String? unit;

  AttributeModel({
    required this.id,
    required this.name,
    required this.type,
    this.options = const [],
    this.required = false,
    this.unit,
  });

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawOptions = json['options'] is List
        ? json['options']
        : [];
    return AttributeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      options: rawOptions.map((e) => e.toString()).toList(),
      required: json['required'] == true,
      unit: json['unit']?.toString(),
    );
  }
}

/// Complete form data for creating/editing an ad
class AdFormData {
  String? title;
  String? description;
  String? categoryId; // parent category ID
  String? subcategoryId; // actual category ID sent to backend
  String? price;
  String currency = 'EGP';
  String? location;
  String? phone;
  String condition = 'USED';
  List<File> images = <File>[];
  List<String> imagePreviews = <String>[];
  Map<String, dynamic> attributes = <String, dynamic>{};

  String? editingId;

  AdFormData({this.editingId});

  /// Convert form data to the JSON structure expected by the backend
  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> attributesList = [];

    attributes.forEach((attrId, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;

      if (value is bool) {
        attributesList.add({'attributeId': attrId, 'valueBoolean': value});
      } else if (value is num) {
        attributesList.add({
          'attributeId': attrId,
          'valueNumber': value,
          'valueString': value.toString(),
        });
      } else if (value is List) {
        attributesList.add({
          'attributeId': attrId,
          'valueString': value.map((e) => e.toString()).join(', '),
        });
      } else {
        // Try to parse numeric string
        final parsed = double.tryParse(value.toString());
        if (parsed != null) {
          attributesList.add({
            'attributeId': attrId,
            'valueNumber': parsed,
            'valueString': value.toString(),
          });
        } else {
          attributesList.add({
            'attributeId': attrId,
            'valueString': value.toString(),
          });
        }
      }
    });

    return {
      'title': title?.trim() ?? '',
      'description': description?.trim() ?? '',
      'categoryId':
          subcategoryId ??
          categoryId ??
          '', // Use subcategoryId as the main categoryId
      'price': double.tryParse(price ?? '0') ?? 0,
      'currency': currency,
      'location': location?.trim() ?? '',
      'phone': phone?.trim() ?? '',
      'condition': condition,
      'attributes': attributesList,
    };
  }

  /// Reset all form data
  void reset() {
    title = null;
    description = null;
    categoryId = null;
    subcategoryId = null;
    price = null;
    currency = 'EGP';
    location = null;
    phone = null;
    condition = 'USED';
    images = <File>[];
    imagePreviews = <String>[];
    attributes = <String, dynamic>{};
    editingId = null;
  }
}

/// Singleton to hold draft form data across steps
class AdFormDraft {
  AdFormDraft._internal();
  static final AdFormDraft instance = AdFormDraft._internal();

  final AdFormData formData = AdFormData();
  CategoryModel? selectedCategory;
  CategoryModel? selectedSubcategory;
  List<CategoryModel> categories = [];
  List<CurrencyModel> currencies = [];
  List<AttributeModel> attributes = [];

  String? get selectedCategoryId => formData.categoryId;
  set selectedCategoryId(String? value) => formData.categoryId = value;

  String? get selectedSubcategoryId => formData.subcategoryId;
  set selectedSubcategoryId(String? value) => formData.subcategoryId = value;

  void reset() {
    formData.reset();
    selectedCategory = null;
    selectedSubcategory = null;
    attributes = [];
  }
}
