import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/ad_model.dart';
import 'models/statistics_model.dart';
import 'widgets/statistics_section.dart';
import 'widgets/ads_list_section.dart';
import '../verification/verification_step_one_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  // Sample data - replace with actual data from your backend
  final StatisticsModel statistics = StatisticsModel(
    totalViews: 1024.00,
    totalAds: 1024,
    featuredAds: 1024,
    potentialCustomers: 1024,
  );

  final List<AdModel> ads = [
    AdModel(
      id: '1',
      title: 'موبايل سامسونج - في موبايلات',
      category: 'في موبايلات',
      imageUrl: 'https://via.placeholder.com/150',
      daysRemaining: 31,
      views: 2026,
      potentialCustomers: 2026,
      status: AdStatus.active,
    ),
    AdModel(
      id: '2',
      title: 'عجلة - في الدراجات',
      category: 'في الدراجات',
      imageUrl: 'https://via.placeholder.com/150',
      daysRemaining: 31,
      views: 2026,
      potentialCustomers: 2026,
      status: AdStatus.pending,
      statusLabel: 'إعلان معلق',
    ),
    AdModel(
      id: '3',
      title: 'فيلا - في العقارات',
      category: 'في العقارات',
      imageUrl: 'https://via.placeholder.com/150',
      daysRemaining: 31,
      views: 2026,
      potentialCustomers: 2026,
      status: AdStatus.waitingForApproval,
      statusLabel: 'في انتظار الرد',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            StatisticsSection(statistics: statistics),
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
    );
  }

  void _handleRepost(AdModel ad) {
    // Implement repost logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'إعادة نشر: ${ad.title}',
          style: GoogleFonts.cairo(),
        ),
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
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم تأكيد البيع',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9B8E),
            ),
            child: Text(
              'تأكيد',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
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
                // Navigate to edit screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تعديل: ${ad.title}',
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'حذف الإعلان',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حذف الإعلان',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
