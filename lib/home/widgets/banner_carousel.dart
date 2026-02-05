import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/home/home_service.dart';
import '../../home/models/banner_model.dart';
import '../../api/auth/auth_config.dart';
import '../../category/product_details_screen.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  String? _error;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await HomeService.fetchBanners();
      if (mounted) {
        setState(() {
          _banners = banners.where((b) => b.isActive).toList();
          _banners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          _isLoading = false;
        });

        // Start auto-play if there are multiple banners
        if (_banners.length > 1) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _banners.isEmpty) {
        timer.cancel();
        return;
      }

      final nextPage = (_currentPage + 1) % _banners.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${AuthConfig.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
        ),
      );
    }

    if (_error != null || _banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onPanDown: (_) => _stopAutoPlay(),
      onPanEnd: (_) => _startAutoPlay(),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildBannerItem(_banners[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_banners.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? const Color(0xFF1DAF52)
                        : const Color(0xFFD9D9D9),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(BannerModel banner) {
    return GestureDetector(
      onTap: () {
        if (banner.listingId != null && banner.listingId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(listingId: banner.listingId!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(_getFullImageUrl(banner.imageUrl)),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // Handle image load error silently
            },
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
            ),
          ),
          child: banner.listingTitle != null && banner.listingTitle!.isNotEmpty
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      banner.listingTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
