import 'package:flutter/material.dart';
import 'package:levantsale/api/home/home_service.dart';
import 'package:levantsale/category/product_details_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Listing> _products = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalElements = 0;
  String _sortBy = 'date_desc';
  List<ApiCategory> _categories = [];
  String _selectedCategory = 'all';
  List<FilterAttribute> _attributes = [];
  Map<String, dynamic> _filters = {};
  bool _loadingFilters = false;
  Set<String> _expandedSections = {};
  List<City> _cities = [];
  String _selectedCity = 'all';
  String _minPrice = '';
  String _maxPrice = '';
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _fetchCategories();
    _fetchCities();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await HomeService.fetchCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchCities() async {
    try {
      const baseUrl = 'https://levantapi.twingroups.com';
      const url = '$baseUrl/api/cities/active';

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cities = data.map((e) => City.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  Future<void> _fetchAttributes() async {
    if (_selectedCategory == 'all' || _selectedCategory.isEmpty) {
      setState(() {
        _attributes = [];
        _loadingFilters = false;
      });
      return;
    }

    setState(() {
      _loadingFilters = true;
    });

    try {
      const baseUrl = 'https://levantapi.twingroups.com';
      final url =
          '$baseUrl/api/v1/listings/category/$_selectedCategory/filterable-attributes';

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        final filteredData = data
            .where(
              (attr) => attr['type'] == 'SELECT' || attr['type'] == 'RADIO',
            )
            .toList();

        filteredData.sort(
          (a, b) => (a['sortOrder'] ?? 0).compareTo(b['sortOrder'] ?? 0),
        );

        setState(() {
          _attributes = filteredData
              .map((e) => FilterAttribute.fromJson(e))
              .toList();
          _expandedSections = _attributes.map((attr) => attr.id).toSet();
          _loadingFilters = false;
        });
      } else {
        setState(() {
          _loadingFilters = false;
        });
      }
    } catch (e) {
      print('Error fetching attributes: $e');
      setState(() {
        _loadingFilters = false;
      });
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'PostmanRuntime/7.32.2',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = token.startsWith('Bearer')
            ? token
            : 'Bearer $token';
      }
    } catch (_) {}

    return headers;
  }

  Future<void> _performSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      const baseUrl = 'https://levantapi.twingroups.com';
      final page = _currentPage - 1;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      String url;
      final params = <String, String>{
        'page': page.toString(),
        'size': _pageSize.toString(),
        'sortBy': _sortBy,
        '_t': timestamp.toString(),
      };

      final query = _searchController.text.trim();

      // Add search query if provided
      if (query.isNotEmpty) {
        params['q'] = query;
      }

      // Add city filter
      if (_selectedCity != 'all' && _selectedCity.isNotEmpty) {
        params['cityId'] = _selectedCity;
      }

      // Add price filters
      if (_minPrice.trim().isNotEmpty) {
        params['minPrice'] = _minPrice.trim();
      }
      if (_maxPrice.trim().isNotEmpty) {
        params['maxPrice'] = _maxPrice.trim();
      }

      // Determine which endpoint to use - matching TypeScript logic
      if (_selectedCategory != 'all' &&
          _selectedCategory.isNotEmpty &&
          _selectedCity == 'all' &&
          _minPrice.trim().isEmpty &&
          _maxPrice.trim().isEmpty) {
        // Use category endpoint ONLY when no city or price filters are applied
        url = '$baseUrl/api/v1/listings/category/$_selectedCategory';

        // Add attribute filters - use attribute name as parameter
        _filters.forEach((attributeId, value) {
          if (value != null && value.toString().isNotEmpty) {
            final attribute = _attributes.firstWhere(
              (attr) => attr.id == attributeId,
              orElse: () => FilterAttribute.empty(),
            );
            if (attribute.id.isNotEmpty) {
              print('Adding filter: ${attribute.name} = $value');
              params[attribute.name] = value.toString();
            }
          }
        });
      } else if (_selectedCategory != 'all' &&
          _selectedCategory.isNotEmpty &&
          (_selectedCity != 'all' ||
              _minPrice.trim().isNotEmpty ||
              _maxPrice.trim().isNotEmpty)) {
        // Use search endpoint when category is selected AND city/price filters are applied
        url = '$baseUrl/api/v1/listings/search';

        // Add category as a filter parameter
        params['category'] = _selectedCategory;

        // If no search query, use empty query
        if (query.isEmpty) {
          params['q'] = '';
        }

        print('Using search endpoint with category and city/price filters');
        print(
          'Category: $_selectedCategory, City: $_selectedCity, MinPrice: $_minPrice, MaxPrice: $_maxPrice',
        );

        // Add attribute filters
        _filters.forEach((attributeId, value) {
          if (value != null && value.toString().isNotEmpty) {
            final attribute = _attributes.firstWhere(
              (attr) => attr.id == attributeId,
              orElse: () => FilterAttribute.empty(),
            );
            if (attribute.id.isNotEmpty) {
              params[attribute.name] = value.toString();
            }
          }
        });
      } else if (_selectedCity != 'all' ||
          _minPrice.trim().isNotEmpty ||
          _maxPrice.trim().isNotEmpty) {
        // For city/price filtering without category
        url = '$baseUrl/api/v1/listings/search';

        // If no search query, use empty query
        if (query.isEmpty) {
          params['q'] = '';
        }

        print('Trying search endpoint with city/price filters: $url');
      } else if (query.isNotEmpty) {
        // Use search endpoint with actual query
        url = '$baseUrl/api/v1/listings/search';
      } else {
        // No filters applied - show empty state
        setState(() {
          _products = [];
          _loading = false;
        });
        return;
      }

      print(
        'Search conditions: query=$query, category=$_selectedCategory, city=$_selectedCity, minPrice=$_minPrice, maxPrice=$_maxPrice',
      );
      print('Final URL parameters: $params');

      final uri = Uri.parse(url).replace(queryParameters: params);
      print('Fetching URL: $uri');
      print('Active filters: $_filters');

      final headers = await _getHeaders();

      http.Response response;
      try {
        response = await http.get(uri, headers: headers);

        // If we get a 500 error and we're using search endpoint with empty query, try alternative
        if (response.statusCode >= 500 &&
            url.contains('/search') &&
            (params['q'] == '' || !params.containsKey('q'))) {
          print(
            'Search endpoint with empty query failed, trying alternative approach',
          );

          // Try using a space as query
          params['q'] = ' ';
          final alternativeUri = Uri.parse(
            url,
          ).replace(queryParameters: params);
          print('Trying alternative URL: $alternativeUri');

          response = await http.get(alternativeUri, headers: headers);

          // If still failing, try with a minimal query
          if (response.statusCode >= 500) {
            params['q'] = '*';
            final wildcardUri = Uri.parse(url).replace(queryParameters: params);
            print('Trying wildcard URL: $wildcardUri');

            response = await http.get(wildcardUri, headers: headers);
          }
        }
      } catch (fetchError) {
        print('Fetch error: $fetchError');
        rethrow;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to fetch search results: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      print('API Response: $data');
      print('Total elements from API: ${data['totalElements']}');

      final List<dynamic> content = data['content'] ?? [];
      print('Listings count: ${content.length}');

      // Parse listings
      List<Listing> listings = content.map((e) => Listing.fromJson(e)).toList();

      // Apply client-side filtering if filters are active - matching TypeScript logic
      if (_filters.isNotEmpty &&
          listings.isNotEmpty &&
          content.isNotEmpty &&
          content[0]['attributes'] != null) {
        print('Applying client-side filters as backup');
        print('First listing attributes: ${content[0]['attributes']}');

        listings = listings.where((listing) {
          // Get the listing's attributes from the JSON
          final listingData = content.firstWhere(
            (item) => item['id'] == listing.id,
            orElse: () => null,
          );

          if (listingData == null || listingData['attributes'] == null) {
            print('No attributes for listing: ${listing.id}');
            return false; // Exclude if no attributes to check
          }

          final List<dynamic> listingAttributes = listingData['attributes'];

          // Check if all selected filters match
          final matches = _filters.entries.every((filterEntry) {
            final attributeId = filterEntry.key;
            final filterValue = filterEntry.value;

            if (filterValue == null || filterValue.toString().isEmpty) {
              return true;
            }

            // Find the attribute in the listing by attributeId
            final attribute = listingAttributes.firstWhere(
              (attr) => attr['attributeId'] == attributeId,
              orElse: () => null,
            );

            if (attribute == null) {
              print(
                'Attribute $attributeId not found in listing ${listing.id}',
              );
              return false;
            }

            // Get the actual value based on attribute type
            String? attributeValue;
            final attributeType = attribute['attributeType'];

            if (attributeType == 'NUMBER') {
              attributeValue =
                  attribute['valueNumber']?.toString() ??
                  attribute['valueString'];
            } else {
              attributeValue = attribute['valueString'];
            }

            final attributeName = attribute['attributeName'];
            print(
              'Checking: $attributeName, listing value: $attributeValue, filter: $filterValue',
            );

            // Compare values - matching TypeScript logic
            final match = attributeValue == filterValue.toString();
            print('Match result: $match');

            return match;
          });

          print('Listing ${listing.id} matches filters: $matches');
          return matches;
        }).toList();

        print('Filtered products count: ${listings.length}');
      }

      setState(() {
        _products = listings;
        _totalPages = data['totalPages'] ?? 1;
        // Update total elements to reflect actual count if client-side filtering was applied
        _totalElements =
            (_filters.isNotEmpty && listings.length != content.length)
            ? listings.length
            : (data['totalElements'] ?? 0);
        _loading = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _error = 'فشل تحميل النتائج';
        _products = [];
        _loading = false;
      });
    }
  }

  void _handlePageChange(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _performSearch();
  }

  void _handleSortChange(String newSort) {
    setState(() {
      _sortBy = newSort;
      _currentPage = 1;
    });
    _performSearch();
  }

  void _handleFilterChange(String attributeId, dynamic value) {
    setState(() {
      if (value == null || value.toString().isEmpty) {
        _filters.remove(attributeId);
      } else {
        _filters[attributeId] = value;
      }
      _currentPage = 1;
    });
    // Trigger search immediately when filter changes
    _performSearch();
  }

  void _handleClearFilters() {
    setState(() {
      _filters = {};
      _selectedCategory = 'all';
      _selectedCity = 'all';
      _minPrice = '';
      _maxPrice = '';
      _currentPage = 1;
    });
    _performSearch();
  }

  void _toggleSection(String attributeId) {
    setState(() {
      if (_expandedSections.contains(attributeId)) {
        _expandedSections.remove(attributeId);
      } else {
        _expandedSections.add(attributeId);
      }
    });
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الفلاتر',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2B2A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Category Selection
                        _buildBottomSheetSection(
                          title: 'الفئة',
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('جميع الفئات'),
                              ),
                              ..._categories.map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              setState(() {
                                _selectedCategory = value ?? 'all';
                                _filters = {};
                                _currentPage = 1;
                              });
                              setModalState(() {}); // Update modal UI
                              await _fetchAttributes(); // Wait for attributes
                              setModalState(() {}); // Update modal UI again
                              _performSearch();
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // City Selection
                        _buildBottomSheetSection(
                          title: 'المدينة',
                          child: DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('جميع المدن'),
                              ),
                              ..._cities.map(
                                (city) => DropdownMenuItem(
                                  value: city.id,
                                  child: Text('${city.name} - ${city.country}'),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value ?? 'all';
                                _currentPage = 1;
                              });
                              setModalState(() {});
                              _performSearch();
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Price Range
                        _buildBottomSheetSection(
                          title: 'نطاق السعر',
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: _minPrice,
                                decoration: InputDecoration(
                                  labelText: 'الحد الأدنى للسعر',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _minPrice = value;
                                    _currentPage = 1;
                                  });
                                  setModalState(() {});
                                  _performSearch();
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _maxPrice,
                                decoration: InputDecoration(
                                  labelText: 'الحد الأقصى للسعر',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _maxPrice = value;
                                    _currentPage = 1;
                                  });
                                  setModalState(() {});
                                  _performSearch();
                                },
                              ),
                            ],
                          ),
                        ),

                        // Attribute Filters
                        if (_selectedCategory != 'all' &&
                            _selectedCategory.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          if (_loadingFilters)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1DAF52),
                                ),
                              ),
                            )
                          else if (_attributes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'لا توجد فلاتر متاحة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            ..._attributes.map(
                              (attr) => _buildBottomSheetFilterInput(attr),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Bottom Actions
                  if (_filters.isNotEmpty ||
                      _selectedCity != 'all' ||
                      _minPrice.isNotEmpty ||
                      _maxPrice.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _handleClearFilters();
                                setModalState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF1DAF52),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'مسح الفلاتر',
                                style: TextStyle(
                                  color: Color(0xFF1DAF52),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DAF52),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'إغلاق',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSheetSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B2A),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildBottomSheetFilterInput(FilterAttribute attribute) {
    final isExpanded = _expandedSections.contains(attribute.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(attribute.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    attribute.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                      fontSize: 15,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B7280),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: attribute.type == 'SELECT'
                  ? DropdownButtonFormField<String>(
                      value: _filters[attribute.id]?.toString(),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('الكل'),
                        ),
                        ...?attribute.options?.map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          _handleFilterChange(attribute.id, value),
                    )
                  : Column(
                      children: [
                        ...?attribute.options?.map(
                          (option) => RadioListTile<String>(
                            title: Text(
                              option,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: option,
                            groupValue: _filters[attribute.id]?.toString(),
                            onChanged: (value) =>
                                _handleFilterChange(attribute.id, value),
                            activeColor: const Color(0xFF1DAF52),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _filters.isNotEmpty ||
        _selectedCategory != 'all' ||
        _selectedCity != 'all' ||
        _minPrice.isNotEmpty ||
        _maxPrice.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            style: const TextStyle(color: Colors.black),
            onSubmitted: (_) => _performSearch(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1DAF52)),
              onPressed: _performSearch,
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF2B2B2A)),
                  onPressed: () async {
                    // Pre-fetch attributes if not already loaded
                    if (_selectedCategory != 'all' &&
                        _selectedCategory.isNotEmpty &&
                        _attributes.isEmpty &&
                        !_loadingFilters) {
                      await _fetchAttributes();
                    }
                    _showFiltersBottomSheet();
                  },
                ),
                if (hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DAF52),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Sort and count bar
            if (_products.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_totalElements إعلان',
                      style: const TextStyle(
                        color: Color(0xFF1DAF52),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getSortLabel(_sortBy),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.sort,
                            size: 18,
                            color: Color(0xFF757575),
                          ),
                        ],
                      ),
                      onSelected: _handleSortChange,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'date_desc',
                          child: Text('الأحدث'),
                        ),
                        const PopupMenuItem(
                          value: 'date_asc',
                          child: Text('الأقدم'),
                        ),
                        const PopupMenuItem(
                          value: 'price_asc',
                          child: Text('السعر: من الأقل للأعلى'),
                        ),
                        const PopupMenuItem(
                          value: 'price_desc',
                          child: Text('السعر: من الأعلى للأقل'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1DAF52),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _performSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DAF52),
                            ),
                            child: const Text('حاول مرة أخرى'),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Color(0xFFD1D5DB),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لم يتم العثور على نتائج',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
            ),

            // Pagination
            if (_totalPages > 1 && !_loading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1
                          ? () => _handlePageChange(_currentPage - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: const Color(0xFF1DAF52),
                    ),
                    Text(
                      'الصفحة $_currentPage من $_totalPages',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < _totalPages
                          ? () => _handlePageChange(_currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: const Color(0xFF1DAF52),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'date_desc':
        return 'الأحدث';
      case 'date_asc':
        return 'الأقدم';
      case 'price_asc':
        return 'الأرخص';
      case 'price_desc':
        return 'الأغلى';
      default:
        return 'الترتيب';
    }
  }

  Widget _buildProductCard(Listing product) {
    final baseUrl = HomeService.baseUrl;
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first.startsWith('http')
              ? product.imageUrls.first
              : '$baseUrl${product.imageUrls.first}'
        : '';
    final price =
        '${product.price.toStringAsFixed(0)} ${product.currency.symbol}';
    final time = _formatTimeAgo(product.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(listingId: product.id),
          ),
        );
      },
      child: Container(
        height: 150, // Increased from 130 to accommodate larger verified badge
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product info on the left
            Expanded(
              child: Container(
                height: 150, // Increased from 130 to match parent
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - takes available space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2B2A),
                                height: 1.2,
                              ),
                            ),
                          ),
                          Text(
                            product.categoryName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0B0B0),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom info - fixed height
                    SizedBox(
                      height: 60, // Increased from 45 to accommodate 35px badge
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1DAF52),
                              height: 1.0,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Color(0xFFB0B0B0),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  product.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB0B0B0),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              if (product.isVerified)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Image.asset(
                                    'assets/done.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB0B0B0),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product image on the right
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 150,
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Color(0xFFB0B0B0),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 150,
                              height: 150,
                              color: const Color(0xFFF5F5F5),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1DAF52),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 150,
                          height: 150,
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                ),
                // Featured Badge
                if (product.isFeatured == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'مميز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.tryParse(dateString);
      if (date == null) return '';
      final diff = DateTime.now().difference(date);
      final hours = diff.inHours;
      if (hours < 24) {
        return 'منذ ${hours.abs()} ساعات';
      } else {
        final days = diff.inDays;
        return 'منذ ${days.abs()} أيام';
      }
    } catch (_) {
      return '';
    }
  }
}

class City {
  final String id;
  final String name;
  final String country;
  final String region;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  City({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      region: json['region'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class FilterAttribute {
  final String id;
  final String name;
  final String type;
  final List<String>? options;
  final bool required;
  final String? unit;
  final String categoryId;
  final int sortOrder;

  FilterAttribute({
    required this.id,
    required this.name,
    required this.type,
    this.options,
    required this.required,
    this.unit,
    required this.categoryId,
    required this.sortOrder,
  });

  factory FilterAttribute.fromJson(Map<String, dynamic> json) {
    return FilterAttribute(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      required: json['required'] ?? false,
      unit: json['unit'],
      categoryId: json['categoryId'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  factory FilterAttribute.empty() {
    return FilterAttribute(
      id: '',
      name: '',
      type: '',
      required: false,
      categoryId: '',
      sortOrder: 0,
    );
  }
}
