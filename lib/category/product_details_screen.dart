import 'package:flutter/material.dart';
import 'package:levantsale/api/home/home_service.dart';
import 'package:levantsale/services/favorites_service.dart';
import 'package:levantsale/services/toast_service.dart';
import 'package:levantsale/messages/chat_screen.dart';
import 'package:levantsale/messages/chat_service.dart';
import 'package:levantsale/messages/models/message_model.dart';
import 'package:levantsale/messages/models/chat_models.dart';
import 'widgets/seller_info_section.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String? listingId;
  final Map<String, dynamic>? initialProduct;

  const ProductDetailsScreen({Key? key, this.listingId, this.initialProduct})
    : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Listing? _listing;
  bool _loading = false;
  String? _error;
  List<Listing> _related = [];
  final PageController _pageController = PageController();
  int _currentImage = 0;

  // Favorites state
  Set<String> _favoriteIds = {};
  bool _favoriteLoading = false;

  // Attribute icons map (attributeName -> iconUrl)
  Map<String, String> _attributeIcons = {};

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null && widget.listingId!.isNotEmpty) {
      _fetchData(widget.listingId!);
      _checkFavoriteStatus(widget.listingId!);
    }
  }

  Future<void> _checkFavoriteStatus(String listingId) async {
    final isFav = await FavoritesService.checkFavoriteStatus(listingId);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(listingId);
        } else {
          _favoriteIds.remove(listingId);
        }
      });
    }
  }

  Future<void> _toggleFavorite(String listingId) async {
    if (_favoriteLoading) return;

    // Optimistically update UI first
    final wasFavorite = _favoriteIds.contains(listingId);

    setState(() {
      _favoriteLoading = true;
      // Optimistically toggle
      if (wasFavorite) {
        _favoriteIds.remove(listingId);
      } else {
        _favoriteIds.add(listingId);
      }
    });

    // Call API
    final result = await FavoritesService.toggleFavorite(
      listingId,
      wasFavorite,
    );

    if (mounted) {
      setState(() {
        _favoriteLoading = false;
      });

      // If API call failed, revert the optimistic update
      if (!result.success) {
        setState(() {
          if (wasFavorite) {
            _favoriteIds.add(listingId);
          } else {
            _favoriteIds.remove(listingId);
          }
        });

        // Show error
        if (result.errorCode == 'NOT_LOGGED_IN') {
          AppToast.showLoginRequired(context);
        } else {
          AppToast.showError(context, result.message);
        }
      } else {
        // Success - ensure state matches API response
        if (result.isFavorite == true) {
          setState(() {
            _favoriteIds.add(listingId);
          });
          AppToast.showFavoriteAdded(context);
        } else if (result.isFavorite == false) {
          setState(() {
            _favoriteIds.remove(listingId);
          });
          AppToast.showFavoriteRemoved(context);
        }
      }
    }
  }

  Future<void> _fetchData(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      print('[ProductDetails] Fetching listing $id...');
      final l = await HomeService.fetchListingById(id);
      print('[ProductDetails] Got listing: ${l.title}');

      // Fetch category attributes to get icons
      await _fetchAttributeIcons(l.categoryId);

      final related = await HomeService.fetchSimilarListings(
        categoryId: l.categoryId,
        excludeId: id,
        limit: 5,
      );
      print('[ProductDetails] Got ${related.length} related listings');

      // Fetch all favorite IDs from server
      print('[ProductDetails] Fetching favorite IDs...');
      final favoriteIds = await FavoritesService.fetchFavoriteIds();
      print(
        '[ProductDetails] Got ${favoriteIds.length} favorite IDs: $favoriteIds',
      );

      setState(() {
        _listing = l;
        _related = related;
        _favoriteIds = favoriteIds;
      });
      print(
        '[ProductDetails] State updated. Is $id favorited? ${_favoriteIds.contains(id)}',
      );
    } catch (e) {
      print('[ProductDetails] Error: $e');
      setState(() {
        _error = 'فشل تحميل البيانات';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchAttributeIcons(String categoryId) async {
    try {
      print(
        '[ProductDetails] Fetching attribute icons for category $categoryId...',
      );
      final response = await HomeService.fetchCategoryAttributes(categoryId);

      if (response != null && response is List) {
        final Map<String, String> icons = {};
        for (var attr in response) {
          if (attr is Map<String, dynamic>) {
            final name = attr['name'] as String?;
            final iconUrl = attr['iconUrl'] as String?;

            if (name != null && iconUrl != null && iconUrl.isNotEmpty) {
              // Build full icon URL
              icons[name] = '${HomeService.baseUrl}$iconUrl';
              print('[ProductDetails] Found icon for "$name": $iconUrl');
            }
          }
        }

        setState(() {
          _attributeIcons = icons;
        });
        print('[ProductDetails] Loaded ${icons.length} attribute icons');
      }
    } catch (e) {
      print('[ProductDetails] Error fetching attribute icons: $e');
      // Don't fail the whole screen if icons fail to load
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '${HomeService.baseUrl}$url';
    return url;
  }

  String _formatMemberSince(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return '';
    }
  }

  List<String> _images() {
    if (_listing != null && _listing!.imageUrls.isNotEmpty) {
      return _listing!.imageUrls.map(_resolveUrl).toList();
    }
    final img = widget.initialProduct?['image']?.toString();
    if (img != null && img.isNotEmpty) return [img];
    return ['https://via.placeholder.com/1200x800?text=No+Image'];
  }

  String _priceText() {
    if (_listing != null) {
      final price = _listing!.price.toStringAsFixed(0);
      final symbol = _listing!.currency.symbol;
      return '$price $symbol';
    }
    final p = widget.initialProduct?['price']?.toString() ?? '';
    return p.isNotEmpty ? p : '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openImageViewer(int initialIndex) {
    final imgs = _images();
    if (imgs.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _ImageGalleryScreen(images: imgs, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildDots() {
    final imgs = _images();
    if (imgs.length <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(imgs.length, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _currentImage
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null && _listing == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _openImageViewer(_currentImage),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _images().length,
                                onPageChanged: (i) =>
                                    setState(() => _currentImage = i),
                                itemBuilder: (context, index) {
                                  final url = _images()[index];
                                  return Image.network(
                                    url,
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Center(child: _buildDots()),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Featured Badge
                      if (_listing?.isFeatured == true)
                        Positioned(
                          top: 40,
                          left: 70,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'مميــــز',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                      // Back Button
                      Positioned(
                        top: 40,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 40,
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: _favoriteLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    _favoriteIds.contains(widget.listingId)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color:
                                        _favoriteIds.contains(widget.listingId)
                                        ? const Color(0xFFE91E63)
                                        : Colors.white,
                                  ),
                                  onPressed: () {
                                    if (widget.listingId != null) {
                                      _toggleFavorite(widget.listingId!);
                                    }
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price
                        Text(
                          _priceText(),
                          style: const TextStyle(
                            color: Color(0xFF1DAF52),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          _listing?.title ?? '',
                          style: const TextStyle(
                            color: Color(0xFF2B2B2A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          _listing?.description ?? '',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Property Details
                        ...(((_listing?.attributes?.isNotEmpty) ?? false)
                            ? _listing!.attributes!
                                  .map(
                                    (a) => _buildDetailRow(
                                      a.attributeName,
                                      a.displayValue, // Uses unit if available
                                    ),
                                  )
                                  .expand(
                                    (w) => [w, const SizedBox(height: 12)],
                                  )
                                  .toList()
                            : [
                                _buildDetailRow(
                                  'الحالة',
                                  _listing?.condition ?? '',
                                ),
                              ]),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openChat,
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFFFFB800),
                                  size: 20,
                                ),
                                label: const Text(
                                  'محادثة',
                                  style: TextStyle(
                                    color: Color(0xFFFFB800),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFF8E1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showPhoneModal(context);
                                },
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFFAB47BC),
                                  size: 20,
                                ),
                                label: const Text(
                                  'مكالمة',
                                  style: TextStyle(
                                    color: Color(0xFFAB47BC),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3E5F5),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Seller Info Section (New inline section)
                        if (_listing != null)
                          SellerInfoSection(
                            sellerId: _listing!.userId ?? '',
                            sellerName: _listing!.userName ?? 'بائع',
                            memberSince: _formatMemberSince(
                              _listing!.createdAt,
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Related Ads Section
                        const Text(
                          'إعلانات ذات صلة :',
                          style: TextStyle(
                            color: Color(0xFF2B2B2A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Related Ads List
                        SizedBox(
                          height: 260, // Increased to match home screen
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            itemCount: _related.length,
                            itemBuilder: (context, index) {
                              return _buildRelatedAdCard(_related[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneModal(BuildContext context) {
    final phoneNumber = _listing?.userPhone ?? 'غير متوفر';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'رقم الهاتف',
                  style: TextStyle(
                    color: Color(0xFF1DAF52),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: Color(0xFF2B2B2A),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DAF52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openChat() async {
    if (_listing == null) {
      AppToast.showError(context, 'لا يمكن فتح المحادثة الآن');
      return;
    }

    // Check if user is logged in
    final currentUserId = await ChatService.getCurrentUserId();
    if (currentUserId == null) {
      AppToast.showLoginRequired(context);
      return;
    }

    // Get seller user ID
    final sellerUserId = _listing!.userId;
    if (sellerUserId == null || sellerUserId.isEmpty) {
      AppToast.showError(context, 'معلومات البائع غير متوفرة');
      return;
    }

    // Check if trying to chat with yourself
    if (sellerUserId == currentUserId) {
      AppToast.showError(context, 'لا يمكنك محادثة نفسك');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      ),
    );

    try {
      // Get or create conversation with the seller
      final conversationApi = await ChatService.getOrCreateConversation(
        sellerUserId,
      );

      if (conversationApi == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          AppToast.showError(context, 'فشل في إنشاء المحادثة');
        }
        return;
      }

      // Create ChatConversation from API response
      final conversation = ChatConversation.fromApi(conversationApi);

      // Create ChatAdData from the listing
      final adData = ChatAdData(
        id: _listing!.id,
        title: _listing!.title,
        price: _listing!.price.toStringAsFixed(0),
        currency: _listing!.currency.symbol,
        imageUrl: _listing!.imageUrls.isNotEmpty
            ? _resolveUrl(_listing!.imageUrls.first)
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Navigate to chat screen with product details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(conversation: conversation, adData: adData),
          ),
        );
      }
    } catch (e) {
      print('[ProductDetails] Error opening chat: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        AppToast.showError(context, 'حدث خطأ أثناء فتح المحادثة');
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    // Get icon URL for this attribute
    final iconUrl = _attributeIcons[label];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Show icon if available
            if (iconUrl != null) ...[
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Image.network(
                  iconUrl,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Hide icon if it fails to load
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2B2B2A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }

  Widget _buildRelatedAdCard(Listing item) {
    final img = item.imageUrls.isNotEmpty
        ? _resolveUrl(item.imageUrls.first)
        : 'https://via.placeholder.com/400x300?text=No+Image';
    final price = '${item.price.toStringAsFixed(0)} ${item.currency.symbol}';
    final time = _formatTimeAgo(item.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(listingId: item.id),
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
                    image: DecorationImage(
                      image: NetworkImage(img),
                      fit: BoxFit.cover,
                    ),
                    color: const Color(0xFFF2F2F2),
                  ),
                ),
                // Featured Badge
                if (item.isFeatured == true)
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
                        'مميــــز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Favorite button (top-left corner like home screen)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(item.id),
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
                      child: _favoriteLoading
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
                              _favoriteIds.contains(item.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _favoriteIds.contains(item.id)
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xFF1DAF52),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (item.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 35),
                            child: Image.asset(
                              'assets/verified.png',
                              width: 70,
                              height: 70,
                            ),
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
}

class _ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _ImageGalleryScreen({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final url = widget.images[i];
              return Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
