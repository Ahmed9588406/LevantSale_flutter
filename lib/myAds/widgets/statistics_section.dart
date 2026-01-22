import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/statistics_model.dart';

class StatisticsSection extends StatelessWidget {
  final StatisticsModel statistics;

  const StatisticsSection({super.key, required this.statistics});

  // Helper to load SVG with a fallback icon if loading fails.
  static Widget _svgIcon(
    String assetPath, {
    required Color color,
    double width = 26,
    double height = 26,
    IconData fallback = Icons.image_outlined,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      // Show a simple Icon if the SVG can't be rendered
      placeholderBuilder: (context) =>
          Icon(fallback, size: width, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'تحليلات:',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A9B8E),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // First row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCard(
                    icon: _svgIcon(
                      'icons/view.svg',
                      color: const Color(0xFF4A9B8E),
                      width: 28,
                      height: 28,
                      fallback: Icons.visibility_outlined,
                    ),
                    title: 'المشاهدات',
                    value: statistics.totalViews.toStringAsFixed(2),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: _svgIcon(
                      'icons/allads.svg',
                      color: const Color(0xFF4A9B8E),
                      width: 28,
                      height: 28,
                      fallback: Icons.list_alt,
                    ),
                    title: 'كل الإعلانات',
                    value: statistics.totalAds.toString() + '.00',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCard(
                    icon: _svgIcon(
                      'icons/person.svg',
                      color: const Color(0xFF4A9B8E),
                      width: 28,
                      height: 28,
                      fallback: Icons.person_outline,
                    ),
                    title: 'العملاء المحتملين',
                    value: statistics.potentialCustomers.toString() + '.00',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: _svgIcon(
                      'icons/star.svg',
                      color: const Color(0xFF4A9B8E),
                      width: 28,
                      height: 28,
                      fallback: Icons.star_outline,
                    ),
                    title: 'الإعلانات المميزة',
                    value: statistics.featuredAds.toString() + '.00',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Small local card that reliably loads and colors SVG icons (with fallback)
class _StatCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String value;

  const _StatCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: icon,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF4A9B8E),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: const Color(0xFF8B95A5),
                      fontWeight: FontWeight.bold,
                      height: 1.2,
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
}
