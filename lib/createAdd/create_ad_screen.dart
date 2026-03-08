import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_form_model.dart';
import 'create_ad_service.dart';
import 'step1_basic_info.dart';
import 'step2_location_condition.dart';
import 'step3_attributes.dart';

/// Main screen for creating/editing an ad - mirrors the web postAd/page.tsx
class CreateAdScreen extends StatefulWidget {
  final String? editingId;

  const CreateAdScreen({Key? key, this.editingId}) : super(key: key);

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  // Current view state
  String _step = 'category'; // 'category' or 'form'
  int _currentFormStep = 1; // 1, 2, or 3

  // Loading states
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _loadingListing = false;

  // Data
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  CategoryModel? _selectedSubcategory;
  String? _hoveredCategoryId;

  // Form data singleton
  final _draft = AdFormDraft.instance;

  @override
  void initState() {
    super.initState();
    _draft.reset();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is authenticated
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
          );
        }
        return;
      }

      // Fetch categories, currencies, and cities in parallel
      final results = await Future.wait([
        CreateAdService.fetchCategoriesTree(),
        CreateAdService.fetchCurrencies(),
        CreateAdService.fetchCities(),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _draft.categories = _categories;
      _draft.currencies = results[1] as List<CurrencyModel>;
      _draft.cities = results[2] as List<CityModel>;

      // Set default currency ID if available
      if (_draft.currencies.isNotEmpty && _draft.formData.currencyId == null) {
        _draft.formData.currencyId = _draft.currencies.first.id;
      }

      // If editing, load the listing data
      if (widget.editingId != null) {
        await _loadListingForEdit();
      }
    } catch (e) {
      print('Error initializing create ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadListingForEdit() async {
    if (widget.editingId == null) return;

    setState(() => _loadingListing = true);

    try {
      final listing = await CreateAdService.fetchListing(widget.editingId!);
      if (listing == null) {
        throw Exception('Failed to load listing');
      }

      // Populate form data
      _draft.formData.editingId = widget.editingId;
      _draft.formData.title = listing['title']?.toString();
      _draft.formData.description = listing['description']?.toString();
      _draft.formData.price = listing['price']?.toString();
      _draft.formData.currencyId =
          listing['currencyId']?.toString() ?? listing['currency']?.toString();
      _draft.formData.location = listing['location']?.toString();
      _draft.formData.phone = listing['phoneNumber']?.toString();
      _draft.formData.condition = listing['condition']?.toString() ?? 'USED';
      _draft.formData.cityId = listing['cityId']?.toString();

      // Handle category/subcategory
      final categoryId = listing['categoryId']?.toString();
      final subcategoryId = listing['subcategoryId']?.toString() ?? categoryId;

      // Find category and subcategory
      for (final cat in _categories) {
        if (cat.id == categoryId) {
          _selectedCategory = cat;
          _draft.selectedCategory = cat;
          _draft.formData.categoryId = cat.id;
          break;
        }
        for (final sub in cat.subcategories) {
          if (sub.id == categoryId || sub.id == subcategoryId) {
            _selectedCategory = cat;
            _selectedSubcategory = sub;
            _draft.selectedCategory = cat;
            _draft.selectedSubcategory = sub;
            _draft.formData.categoryId = cat.id;
            _draft.formData.subcategoryId = sub.id;
            break;
          }
        }
      }

      // Load existing attributes
      if (listing['attributes'] is List) {
        final Map<String, dynamic> attrsMap = {};
        for (final attr in listing['attributes']) {
          final attrId = attr['attributeId']?.toString();
          if (attrId == null) continue;
          if (attr['valueString'] != null) {
            attrsMap[attrId] = attr['valueString'];
          } else if (attr['valueNumber'] != null) {
            attrsMap[attrId] = attr['valueNumber'];
          } else if (attr['valueBoolean'] != null) {
            attrsMap[attrId] = attr['valueBoolean'];
          }
        }
        _draft.formData.attributes = attrsMap;
      }

      // Move to form step
      _step = 'form';
    } catch (e) {
      print('Error loading listing for edit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل بيانات الإعلان')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _loadingListing = false);
      }
    }
  }

  void _handleCategorySelect(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = null;
      _draft.selectedCategory = category;
      _draft.selectedSubcategory = null;
      _draft.formData.categoryId = category.id;
      _draft.formData.subcategoryId = null;

      // If category has no subcategories, proceed to form directly
      if (category.subcategories.isEmpty) {
        _draft.formData.subcategoryId = category.id;
        _step = 'form';
        _currentFormStep = 1;
      }
    });
  }

  void _handleSubcategorySelect(CategoryModel subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
      _draft.selectedSubcategory = subcategory;
      _draft.formData.subcategoryId = subcategory.id;
      _step = 'form';
      _currentFormStep = 1;
    });
  }

  void _handleCategoryProceed() {
    // Allow proceeding with just main category if no subcategory selected
    if (_selectedCategory != null) {
      setState(() {
        if (_draft.formData.subcategoryId == null) {
          _draft.formData.subcategoryId = _selectedCategory!.id;
        }
        _step = 'form';
        _currentFormStep = 1;
      });
    }
  }

  void _handleFormStepNext() {
    if (_currentFormStep < 3) {
      setState(() => _currentFormStep++);
    } else {
      _handleSubmit();
    }
  }

  void _handleFormStepBack() {
    if (_currentFormStep > 1) {
      setState(() => _currentFormStep--);
    }
  }

  Future<void> _handleSubmit() async {
    // Validate form
    final validationErrors = <String>[];
    final fd = _draft.formData;

    if (fd.title == null || fd.title!.trim().isEmpty) {
      validationErrors.add('العنوان مطلوب');
    }
    if (fd.description == null || fd.description!.trim().isEmpty) {
      validationErrors.add('الوصف مطلوب');
    }
    if (fd.subcategoryId == null || fd.subcategoryId!.isEmpty) {
      validationErrors.add('الفئة مطلوبة');
    }
    if (fd.price == null || fd.price!.trim().isEmpty) {
      validationErrors.add('السعر مطلوب');
    }
    if (fd.cityId == null || fd.cityId!.trim().isEmpty) {
      validationErrors.add('المدينة مطلوبة');
    }
    if (fd.phone == null || fd.phone!.trim().isEmpty) {
      validationErrors.add('رقم الهاتف مطلوب');
    }
    // Only require images for new listings
    if (fd.editingId == null && fd.images.isEmpty) {
      validationErrors.add('الصور مطلوبة');
    }

    if (validationErrors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationErrors.join('\n'))));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = fd.toJson();
      print('📋 Submitting listing data: $data');
      print('📸 Images count: ${fd.images.length}');

      final response = fd.editingId == null
          ? await CreateAdService.createListing(data: data, images: fd.images)
          : await CreateAdService.updateListing(
              id: fd.editingId!,
              data: data,
              images: fd.images,
            );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fd.editingId == null
                  ? 'تم نشر الإعلان بنجاح'
                  : 'تم تحديث الإعلان بنجاح',
            ),
            backgroundColor: const Color(0xFF00A651),
          ),
        );
        _draft.reset();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final errorMsg = response.body;
        print('❌ Error response: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل العملية (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('❌ Error submitting: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
          title: Text(
            widget.editingId != null ? 'تعديل الإعلان' : 'انشر إعلانك',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey[200], height: 1),
          ),
        ),
        body: _isLoading || _loadingListing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00A651)),
                    SizedBox(height: 16),
                    Text('جاري التحميل...'),
                  ],
                ),
              )
            : _step == 'category'
            ? _buildCategorySelection()
            : _buildFormSteps(),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر الفئة الرئيسية',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر فئة رئيسية أو فئة فرعية لإعلانك',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Categories Grid
        Expanded(
          child: _categories.isEmpty
              ? const Center(child: Text('لا توجد فئات متاحة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    final isHovered = _hoveredCategoryId == category.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          // Main Category Card
                          InkWell(
                            onTap: () {
                              _handleCategorySelect(category);
                              if (category.subcategories.isNotEmpty) {
                                setState(() {
                                  _hoveredCategoryId =
                                      _hoveredCategoryId == category.id
                                      ? null
                                      : category.id;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00A651)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child:
                                          category.iconUrl != null &&
                                              category.iconUrl!.isNotEmpty
                                          ? Image.network(
                                              category.iconUrl!.startsWith(
                                                    'http',
                                                  )
                                                  ? category.iconUrl!
                                                  : '${CreateAdService.baseUrl}${category.iconUrl}',
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.category,
                                                    size: 24,
                                                    color: Color(0xFF00A651),
                                                  ),
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                    if (progress == null) {
                                                      return child;
                                                    }
                                                    return const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              Color(0xFF00A651),
                                                            ),
                                                      ),
                                                    );
                                                  },
                                            )
                                          : const Icon(
                                              Icons.category,
                                              size: 24,
                                              color: Color(0xFF00A651),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Name & count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.nameAr,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category.subcategories.isEmpty
                                              ? 'لا توجد فئات فرعية'
                                              : '${category.subcategories.length} فئة فرعية',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (category.subcategories.isNotEmpty)
                                    Icon(
                                      isHovered
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey[400],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Subcategories (expanded)
                          if (isHovered && category.subcategories.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00A651),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'الفئات الفرعية',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ...category.subcategories.map((sub) {
                                    final isSubSelected =
                                        _selectedSubcategory?.id == sub.id;
                                    return InkWell(
                                      onTap: () =>
                                          _handleSubcategorySelect(sub),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSubSelected
                                              ? const Color(
                                                  0xFF00A651,
                                                ).withValues(alpha: 0.1)
                                              : null,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Center(
                                                child:
                                                    sub.iconUrl != null &&
                                                        sub.iconUrl!.isNotEmpty
                                                    ? Image.network(
                                                        sub.iconUrl!.startsWith(
                                                              'http',
                                                            )
                                                            ? sub.iconUrl!
                                                            : '${CreateAdService.baseUrl}${sub.iconUrl}',
                                                        width: 20,
                                                        height: 20,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => const Icon(
                                                              Icons
                                                                  .category_outlined,
                                                              size: 16,
                                                              color: Color(
                                                                0xFF00A651,
                                                              ),
                                                            ),
                                                        loadingBuilder:
                                                            (
                                                              context,
                                                              child,
                                                              progress,
                                                            ) {
                                                              if (progress ==
                                                                  null) {
                                                                return child;
                                                              }
                                                              return const SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      1.5,
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        Color(
                                                                          0xFF00A651,
                                                                        ),
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                      )
                                                    : const Icon(
                                                        Icons.category_outlined,
                                                        size: 16,
                                                        color: Color(
                                                          0xFF00A651,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                sub.nameAr,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSubSelected
                                                      ? const Color(0xFF00A651)
                                                      : Colors.black87,
                                                  fontWeight: isSubSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Colors.grey[400],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Continue with selected category button
        if (_selectedCategory != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleCategoryProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedSubcategory != null
                        ? 'متابعة مع: ${_selectedSubcategory!.nameAr}'
                        : 'متابعة مع: ${_selectedCategory!.nameAr}',
                    style: const TextStyle(
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
    );
  }

  Widget _buildFormSteps() {
    return Column(
      children: [
        // Step Indicator
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepCircle(3, _currentFormStep >= 3),
                  _buildStepLine(_currentFormStep >= 3),
                  _buildStepCircle(2, _currentFormStep >= 2),
                  _buildStepLine(_currentFormStep >= 2),
                  _buildStepCircle(1, _currentFormStep >= 1),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  color: Color(0xFF00A651),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getStepSubtitle(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),

        // Form Content
        Expanded(
          child: _currentFormStep == 1
              ? Step1BasicInfo(onNext: _handleFormStepNext)
              : _currentFormStep == 2
              ? Step2LocationCondition(
                  onNext: _handleFormStepNext,
                  onBack: _handleFormStepBack,
                )
              : Step3Attributes(
                  onNext: _handleFormStepNext,
                  onBack: _handleFormStepBack,
                  isSubmitting: _isSubmitting,
                ),
        ),

        // Back to Category Button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextButton(
            onPressed: () {
              setState(() {
                _step = 'category';
                _currentFormStep = 1;
              });
            },
            child: const Text(
              '← اختر فئة أخرى',
              style: TextStyle(
                color: Color(0xFF00A651),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int number, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF00A651) : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 60,
      height: 2,
      color: isActive ? const Color(0xFF00A651) : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _getStepTitle() {
    switch (_currentFormStep) {
      case 1:
        return 'البيانات الأساسية';
      case 2:
        return 'تفاصيل المكان والسعر';
      case 3:
        return 'الخصائص والتفاصيل';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentFormStep) {
      case 1:
        return 'العنوان والوصف والصور';
      case 2:
        return 'الموقع والسعر والحالة';
      case 3:
        return 'خصائص إضافية للإعلان';
      default:
        return '';
    }
  }
}
