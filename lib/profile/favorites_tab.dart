import 'package:flutter/material.dart';
import '../api/home/home_service.dart';
import '../services/favorites_service.dart';
import '../services/toast_service.dart';
import '../category/product_details_screen.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  bool _loading = true;
  String? _error;
  List<Listing> _favorites = [];
  Set<String> _favoriteIds = {};
  Set<String> _loadingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final favorites = await FavoritesService.fetchFavoriteListings(
        page: 0,
        size: 100,
      );

      if (mounted) {
        setState(() {
          _favorites = favorites;
          _favoriteIds = favorites.map((e) => e.id).toSet();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل المفضلة';
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String listingId) async {
    if (_loadingIds.contains(listingId)) return;

    setState(() {
      _loadingIds.add(listingId);
    });

    final wasFavorite = _favoriteIds.contains(listingId);
    final result = await FavoritesService.toggleFavorite(
      listingId,
      wasFavorite,
    );

    if (mounted) {
      setState(() {
        _loadingIds.remove(listingId);
      });

      if (result.success) {
        // Remove from list if unfavorited
        if (result.isFavorite == false) {
          setState(() {
            _favorites.removeWhere((e) => e.id == listingId);
            _favoriteIds.remove(listingId);
          });
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

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '${HomeService.baseUrl}$url';
    return url;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
              ),
              child: const Text('حاول مرة أخرى'),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد إعلانات مفضلة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ابدأ بإضافة إعلانات إلى المفضلة',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFavorites,
      color: const Color(0xFF1DAF52),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final listing = _favorites[index];
          return _buildFavoriteCard(listing);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Listing listing) {
    final img = listing.imageUrls.isNotEmpty
        ? _resolveUrl(listing.imageUrls.first)
        : '';
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
        ).then((_) => _fetchFavorites()); // Refresh when coming back
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                image: img.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(img),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: const Color(0xFFF2F2F2),
              ),
              child: Stack(
                children: [
                  // Featured badge
                  if (listing.isFeatured == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(6),
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
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFF1DAF52),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Remove from favorites button
                        GestureDetector(
                          onTap: () => _toggleFavorite(listing.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: _loadingIds.contains(listing.id)
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
                                : const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFE91E63),
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.categoryName,
                        style: const TextStyle(
                          color: Color(0xFF1DAF52),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}
