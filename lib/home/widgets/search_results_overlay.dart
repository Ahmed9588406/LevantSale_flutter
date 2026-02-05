import 'package:flutter/material.dart';
import '../../api/home/search_service.dart';
import '../../api/home/home_service.dart';
import '../../api/auth/auth_config.dart';
import '../../category/product_details_screen.dart';

/// A widget that displays search results as an overlay dropdown
class SearchResultsOverlay extends StatefulWidget {
  final String searchQuery;
  final VoidCallback onClose;
  final Function(String) onSearchChanged;

  const SearchResultsOverlay({
    Key? key,
    required this.searchQuery,
    required this.onClose,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  State<SearchResultsOverlay> createState() => _SearchResultsOverlayState();
}

class _SearchResultsOverlayState extends State<SearchResultsOverlay> {
  List<Listing> _searchResults = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.searchQuery.isNotEmpty) {
      _performSearch(widget.searchQuery);
    }
  }

  @override
  void didUpdateWidget(SearchResultsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      if (widget.searchQuery.isNotEmpty) {
        _performSearch(widget.searchQuery);
      } else {
        setState(() {
          _searchResults = [];
          _error = null;
        });
      }
    }
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await SearchService.searchListings(
        query: query.trim(),
        page: 0,
        size: 10,
        sortBy: 'date_asc',
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error searching: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نتائج البحث (${_searchResults.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B2B2A),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB0B0B0)),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Color(0xFFB0B0B0)),
              SizedBox(height: 8),
              Text(
                'لم يتم العثور على نتائج',
                style: TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final listing = _searchResults[index];
        return _buildResultItem(listing);
      },
    );
  }

  Widget _buildResultItem(Listing listing) {
    // Get the full image URL
    final imageUrl = listing.imageUrls.isNotEmpty
        ? _getFullImageUrl(listing.imageUrls[0])
        : '';

    return InkWell(
      onTap: () {
        widget.onClose();
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Color(0xFFB0B0B0),
                            size: 24,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1DAF52),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFFB0B0B0),
                        size: 24,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2B2A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.categoryName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.price.toStringAsFixed(0)} ${listing.currency.symbol}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1DAF52),
                    ),
                  ),
                ],
              ),
            ),

            // Location
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: Color(0xFFB0B0B0),
                ),
                const SizedBox(width: 2),
                Text(
                  listing.location.length > 10
                      ? '${listing.location.substring(0, 10)}...'
                      : listing.location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
