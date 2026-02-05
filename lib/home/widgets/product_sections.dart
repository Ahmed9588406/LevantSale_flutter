import 'package:flutter/material.dart';
import 'package:leventsale/api/home/home_service.dart';
import 'package:leventsale/category/product_details_screen.dart';
import 'package:leventsale/services/favorites_service.dart';
import 'package:leventsale/services/toast_service.dart';

class ProductSections extends StatefulWidget {
  const ProductSections({super.key});

  @override
  State<ProductSections> createState() => _ProductSectionsState();
}

class _ProductSectionsState extends State<ProductSections> {
  late Future<List<Listing>> _future;
  Set<String> _favoriteIds = {};
  Set<String> _loadingIds = {}; // Track which items are loading

  @override
  void initState() {
    super.initState();
    _future = _fetchListingsAndInitFavorites();
  }

  /// Fetch listings and initialize favorite state from the listing's `favorite` field
  Future<List<Listing>> _fetchListingsAndInitFavorites() async {
    final listings = await HomeService.fetchListings();

    // Initialize favorites from the listing data (API returns favorite status per listing)
    final Set<String> favIds = {};
    for (final listing in listings) {
      if (listing.favorite) {
        favIds.add(listing.id);
      }
    }

    if (mounted) {
      setState(() {
        _favoriteIds = favIds;
      });
    }

    return listings;
  }

  Future<void> _toggleFavorite(String listingId) async {
    if (_loadingIds.contains(listingId)) return;

    setState(() {
      _loadingIds.add(listingId);
    });

    final isFavorite = _favoriteIds.contains(listingId);
    final result = await FavoritesService.toggleFavorite(listingId, isFavorite);

    if (mounted) {
      setState(() {
        _loadingIds.remove(listingId);
        if (result.success) {
          if (result.isFavorite == true) {
            _favoriteIds.add(listingId);
          } else {
            _favoriteIds.remove(listingId);
          }
        }
      });

      // Show toast
      if (result.success) {
        if (result.isFavorite == true) {
          AppToast.showFavoriteAdded(context);
        } else {
          AppToast.showFavoriteRemoved(context);
        }
      } else {
        if (result.errorCode == 'NOT_LOGGED_IN') {
          AppToast.showLoginRequired(context);
        } else {
          AppToast.showError(context, result.message);
        }
      }
    }
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

  String _firstImageUrl(List<String> urls) {
    if (urls.isEmpty) return '';
    final first = urls.first;
    if (first.startsWith('http')) return first;
    if (first.startsWith('/')) return '${HomeService.baseUrl}$first';
    return first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Listing>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: const [
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('لا توجد إعلانات متاحة حالياً')),
          );
        }

        // Group by categoryId
        final Map<String, List<Listing>> byCategory = {};
        final Map<String, String> categoryNames = {};
        for (final l in listings) {
          byCategory.putIfAbsent(l.categoryId, () => <Listing>[]).add(l);
          categoryNames[l.categoryId] = l.categoryName;
        }

        final sections = byCategory.entries
            .map(
              (e) => _CategorySectionData(
                id: e.key,
                title: categoryNames[e.key] ?? '',
                products: e.value,
              ),
            )
            .where((s) => s.products.isNotEmpty)
            .toList();

        if (sections.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _header(
                  context,
                  section.title,
                  onViewMore: () {
                    // Navigate to categories page (placeholder)
                    // TODO: hook to specific category page when available
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _gridFor(section.products),
              ),
              const SizedBox(height: 28),
            ],
          ],
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    String title, {
    VoidCallback? onViewMore,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2B2B2A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: onViewMore,
          child: const Text(
            'عرض المزيد',
            style: TextStyle(
              color: Color(0xFF1DAF52),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _gridFor(List<Listing> products) {
    final display = products.take(10).toList();
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: display.length,
        itemBuilder: (context, index) {
          final p = display[index];
          final img = _firstImageUrl(p.imageUrls);
          final price = '${p.price.toStringAsFixed(0)} ${p.currency.symbol}';
          final time = _formatTimeAgo(p.createdAt);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(listingId: p.id),
                ),
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(left: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with favorite button
                  Stack(
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          image: img.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(img),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: const Color(0xFFF2F2F2),
                        ),
                      ),
                      // Favorite button
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(p.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _loadingIds.contains(p.id)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFE91E63),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _favoriteIds.contains(p.id)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: _favoriteIds.contains(p.id)
                                        ? const Color(0xFFE91E63)
                                        : const Color(0xFF757575),
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Details
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            color: Color(0xFF1DAF52),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2B2B2A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 11,
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
}

class _CategorySectionData {
  final String id;
  final String title;
  final List<Listing> products;
  _CategorySectionData({
    required this.id,
    required this.title,
    required this.products,
  });
}
