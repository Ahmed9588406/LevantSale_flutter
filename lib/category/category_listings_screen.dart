import 'package:flutter/material.dart';
import 'package:levantsale/api/home/home_service.dart';
import 'product_details_screen.dart';

class CategoryListingsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryListingsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryListingsScreen> createState() => _CategoryListingsScreenState();
}

class _CategoryListingsScreenState extends State<CategoryListingsScreen> {
  late Future<List<Listing>> _listingsFuture;
  String _sortBy = 'الأحدث'; // Default sort

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    _listingsFuture = HomeService.fetchListings(page: 0, size: 100);
  }

  List<Listing> _sortListings(List<Listing> listings) {
    final sorted = List<Listing>.from(listings);
    switch (_sortBy) {
      case 'السعر: من الأقل للأعلى':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'السعر: من الأعلى للأقل':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'الأحدث':
      default:
        sorted.sort((a, b) {
          final dateA = DateTime.tryParse(a.createdAt) ?? DateTime.now();
          final dateB = DateTime.tryParse(b.createdAt) ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
    }
    return sorted;
  }

  String _formatTimeAgo(String createdAt) {
    try {
      final date = DateTime.tryParse(createdAt);
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

  String _resolveImageUrl(List<String> urls) {
    if (urls.isEmpty) return '';
    final first = urls.first;
    if (first.startsWith('http')) return first;
    if (first.startsWith('/')) return '${HomeService.baseUrl}$first';
    return first;
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
          title: Text(
            widget.categoryName,
            style: const TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2A)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Color(0xFF2B2B2A)),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'الأحدث',
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: Color(0xFF1DAF52),
                      ),
                      SizedBox(width: 8),
                      Text('الأحدث'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'السعر: من الأقل للأعلى',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 20,
                        color: Color(0xFF1DAF52),
                      ),
                      SizedBox(width: 8),
                      Text('السعر: من الأقل للأعلى'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'السعر: من الأعلى للأقل',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 20,
                        color: Color(0xFF1DAF52),
                      ),
                      SizedBox(width: 8),
                      Text('السعر: من الأعلى للأقل'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: FutureBuilder<List<Listing>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'حدث خطأ أثناء تحميل الإعلانات',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadListings();
                        });
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final allListings = snapshot.data ?? [];
            final categoryListings = allListings
                .where((listing) => listing.categoryId == widget.categoryId)
                .toList();

            if (categoryListings.isEmpty) {
              return const Center(
                child: Text('لا توجد إعلانات في هذه الفئة حالياً'),
              );
            }

            // Apply sorting
            final sortedListings = _sortListings(categoryListings);

            return Column(
              children: [
                // Sort indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sort,
                        size: 18,
                        color: Color(0xFF757575),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الترتيب: $_sortBy',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${sortedListings.length} إعلان',
                        style: const TextStyle(
                          color: Color(0xFF1DAF52),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedListings.length,
                    itemBuilder: (context, index) {
                      final listing = sortedListings[index];
                      return _buildListingCard(listing);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    final img = _resolveImageUrl(listing.imageUrls);
    final price =
        '${listing.price.toStringAsFixed(0)} ${listing.currency.symbol}';
    final time = _formatTimeAgo(listing.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(listingId: listing.id),
          ),
        );
      },
      child: Container(
        height: 130,
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Title and category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2B2B2A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          listing.categoryName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price, location, and time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1DAF52),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFFB0B0B0),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                listing.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          textAlign: TextAlign.left,
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
            ),

            // Product image on the right
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: img.isNotEmpty
                      ? Image.network(
                          img,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 130,
                              height: 130,
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
                              width: 130,
                              height: 130,
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
                          width: 130,
                          height: 130,
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                ),
                // Featured Badge
                if (listing.isFeatured == true)
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
}
