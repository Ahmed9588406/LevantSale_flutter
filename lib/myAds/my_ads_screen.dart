import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/ad_model.dart';
import 'models/statistics_model.dart';
import 'widgets/statistics_section.dart';
import 'widgets/ads_list_section.dart';
import '../verification/verification_step_one_screen.dart';
import '../profile/profile_service.dart';
import '../category/product_details_screen.dart';
import '../profile/profile_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _listings = [];
  StatisticsModel _statistics = StatisticsModel(
    totalViews: 0,
    totalAds: 0,
    featuredAds: 0,
    potentialCustomers: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchAllAds();
  }

  Future<void> _fetchAllAds() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statuses = ['PENDING', 'ACTIVE', 'REJECTED', 'EXPIRED', 'INACTIVE'];
      final List<Map<String, dynamic>> all = [];
      for (final s in statuses) {
        final list = await ProfileService.fetchUserListingsByStatus(s);
        all.addAll(list);
      }

      // Calculate statistics
      int totalViews = 0;
      int totalLeads = 0;
      int featuredCount = 0;

      for (final listing in all) {
        totalViews +=
            int.tryParse((listing['viewCount'] ?? '0').toString()) ?? 0;
        totalLeads +=
            int.tryParse((listing['leadCount'] ?? '0').toString()) ?? 0;
        if ((listing['isFeatured'] ?? false) == true) {
          featuredCount++;
        }
      }

      if (!mounted) return;
      setState(() {
        _listings = all;
        _statistics = StatisticsModel(
          totalViews: totalViews.toDouble(),
          totalAds: all.length,
          featuredAds: featuredCount,
          potentialCustomers: totalLeads,
        );
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الإعلانات';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteListing(String id) async {
    final ok = await ProfileService.deleteListing(id);
    if (ok) {
      await _fetchAllAds();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف الإعلان بنجاح', style: GoogleFonts.cairo()),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف الإعلان', style: GoogleFonts.cairo())),
      );
    }
  }

  List<AdModel> _convertToAdModels() {
    return _listings.map((listing) {
      final status = (listing['status'] ?? '').toString().toUpperCase();
      final expiryDate = DateTime.tryParse(
        (listing['expiryDate'] ?? '').toString(),
      );

      AdStatus adStatus;
      String? statusLabel;

      switch (status) {
        case 'ACTIVE':
          adStatus = AdStatus.active;
          break;
        case 'PENDING':
          adStatus = AdStatus.pending;
          statusLabel = 'إعلان معلق';
          break;
        case 'REJECTED':
        case 'EXPIRED':
        case 'INACTIVE':
          adStatus = AdStatus.waitingForApproval;
          statusLabel = 'في انتظار الرد';
          break;
        default:
          adStatus = AdStatus.active;
      }

      // Get image URL
      final imgs = listing['imageUrls'];
      String imageUrl = 'https://via.placeholder.com/150';
      if (imgs is List && imgs.isNotEmpty) {
        final img = imgs[0].toString();
        final base = ProfileService.baseUrl;
        if (img.startsWith('http')) {
          imageUrl = img;
        } else if (img.startsWith('/uploads')) {
          imageUrl = '$base$img';
        } else if (img.isNotEmpty) {
          imageUrl = img.startsWith('/') ? '$base$img' : '$base/$img';
        }
      }

      return AdModel(
        id: (listing['id'] ?? '').toString(),
        title:
            '${listing['title'] ?? ''} - في ${listing['categoryName'] ?? ''}',
        category: 'في ${listing['categoryName'] ?? ''}',
        imageUrl: imageUrl,
        daysRemaining: expiryDate?.day ?? 31,
        views: int.tryParse((listing['viewCount'] ?? '0').toString()) ?? 0,
        potentialCustomers:
            int.tryParse((listing['leadCount'] ?? '0').toString()) ?? 0,
        status: adStatus,
        statusLabel: statusLabel,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'إعلاناتي',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A9B8E)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'إعلاناتي',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.cairo(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchAllAds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9B8E),
                ),
                child: Text('حاول مرة أخرى', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      );
    }

    final ads = _convertToAdModels();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'إعلاناتي',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllAds,
        color: const Color(0xFF4A9B8E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              StatisticsSection(statistics: _statistics),
              const SizedBox(height: 24),
              AdsListSection(
                ads: ads,
                onRepost: _handleRepost,
                onSold: _handleSold,
                onMenu: _handleMenu,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRepost(AdModel ad) {
    // Navigate to feature request screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFeatureRequestScreen(initialListingId: ad.id),
      ),
    );
  }

  void _handleSold(AdModel ad) {
    // Implement sold logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد البيع',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل تريد تأكيد بيع هذا المنتج؟',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteListing(ad.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9B8E),
            ),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleMenu(AdModel ad) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // Navigate to product details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(listingId: ad.id),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'تعديل',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF757575),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Verification option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // Navigate to verification screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerificationStepOneScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'التحقق',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF757575),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Delete option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // Show delete confirmation
                _showDeleteConfirmation(ad);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'مسح',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.delete_outline,
                      color: Color(0xFF757575),
                      size: 24,
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

  void _showDeleteConfirmation(AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الإعلان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الإعلان؟',
          style: GoogleFonts.cairo(fontSize: 15),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: const Color(0xFF757575),
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteListing(ad.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
