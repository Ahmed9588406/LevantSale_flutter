import 'dart:io';

class AdFormData {
  String? title;
  String? description;
  String? categoryId; // will hold subcategoryId per web logic
  String? price;
  String currency = 'EGP';
  String? location;
  String? phone;
  String condition = 'USED';
  List<File> images = <File>[];
  Map<String, dynamic> attributes = <String, dynamic>{};

  String? editingId;

  AdFormData({this.editingId});
}

class AdFormDraft {
  AdFormDraft._internal();
  static final AdFormDraft instance = AdFormDraft._internal();

  String? selectedCategoryId;
  String? selectedSubcategoryId;
  Map<String, dynamic> attributes = <String, dynamic>{};
  List<File> images = <File>[];

  void reset() {
    selectedCategoryId = null;
    selectedSubcategoryId = null;
    attributes = <String, dynamic>{};
    images = <File>[];
  }
}
