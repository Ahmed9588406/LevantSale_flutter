import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../api/home/search_service.dart';
import '../../api/home/home_service.dart';
import '../../api/auth/auth_config.dart';
import '../../category/product_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({Key? key, required this.searchQuery})
    : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  List<Listing> _searchResults = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMoreResults = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Build full image URL from relative path
  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    // If already a full URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Prepend base URL to relative path
    final baseUrl = AuthConfig.baseUrl;
    // Remove trailing slash from baseUrl if present
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Ensure imageUrl starts with /
    final cleanImageUrl = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';

    return '$cleanBaseUrl$cleanImageUrl';
  }

  Future<void> _performSearch({bool resetPage = true}) async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = 'Please enter a search term';
      });
      return;
    }

    if (resetPage) {
      setState(() {
        _currentPage = 0;
        _searchResults = [];
      });
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await SearchService.searchListings(
        query: _searchController.text.trim(),
        page: _currentPage,
        size: _pageSize,
        sortBy: 'date_asc',
      );

      setState(() {
        if (resetPage) {
          _searchResults = results;
        } else {
          _searchResults.addAll(results);
        }
        _hasMoreResults = results.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching: ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _loadMore() {
    if (!_loading && _hasMoreResults) {
      _currentPage++;
      _performSearch(resetPage: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              // Search bar
              _buildSearchBar(),

              // Search results
              Expanded(child: _buildSearchContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF2B2B2A),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Search input field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'دور على موبايلات، عقارات، سيارات...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.clear,
                            color: Color(0xFFB0B0B0),
                          ),
                        )
                      : const Icon(Icons.search, color: Color(0xFF2B2B2A)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Search button
          InkWell(
            onTap: () => _performSearch(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1DAF52),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_loading && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }

    if (_error != null && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'icons/notification.svg',
              width: 64,
              height: 64,
              colorFilter: const ColorFilter.mode(
                Color(0xFFB0B0B0),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'لم يتم العثور على نتائج',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFFB0B0B0)),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'icons/notification.svg',
              width: 64,
              height: 64,
              colorFilter: const ColorFilter.mode(
                Color(0xFFB0B0B0),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على نتائج',
              style: TextStyle(fontSize: 16, color: Color(0xFFB0B0B0)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return _buildLoadMoreButton();
        }

        final listing = _searchResults[index];
        return _buildSearchResultCard(listing);
      },
    );
  }

  Widget _buildSearchResultCard(Listing listing) {
    // Get the full image URL
    final imageUrl = listing.imageUrls.isNotEmpty
        ? _getFullImageUrl(listing.imageUrls[0])
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              listingId: listing.id,
              initialProduct: {
                'id': listing.id,
                'title': listing.title,
                'description': listing.description,
                'price': listing.price,
                'currency': listing.currency,
                'location': listing.location,
                'imageUrls': listing.imageUrls,
                'createdAt': listing.createdAt,
                'categoryName': listing.categoryName,
                'categoryId': listing.categoryId,
                'userName': listing.userName,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
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
                          width: 120,
                          height: 120,
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
                      width: 120,
                      height: 120,
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2B2B2A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price and location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${listing.price.toStringAsFixed(2)} ${listing.currency.symbol}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1DAF52),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                listing.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFFB0B0B0),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Color(0xFF1DAF52))
            : ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DAF52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'تحميل المزيد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
