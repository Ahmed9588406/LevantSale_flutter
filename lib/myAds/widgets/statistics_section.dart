import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/statistics_model.dart';

class StatisticsSection extends StatelessWidget {
  final StatisticsModel statistics;

  const StatisticsSection({super.key, required this.statistics});

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
                    iconPath: 'assets/icons/view.svg',
                    fallbackIcon: Icons.visibility_outlined,
                    title: 'المشاهدات',
                    value: statistics.totalViews.toStringAsFixed(2),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    iconPath: 'assets/icons/view.svg',
                    fallbackIcon: Icons.list_alt_rounded,
                    title: 'كل الإعلانات',
                    value: '${statistics.totalAds}.00',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCard(
                    iconPath: 'assets/icons/person.svg',
                    fallbackIcon: Icons.people_outline_rounded,
                    title: 'العملاء المحتملين',
                    value: '${statistics.potentialCustomers}.00',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    iconPath: 'assets/icons/star.svg',
                    fallbackIcon: Icons.star_outline_rounded,
                    title: 'الإعلانات المميزة',
                    value: '${statistics.featuredAds}.00',
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

class _StatCard extends StatelessWidget {
  final String? iconPath;
  final IconData? fallbackIcon;
  final String title;
  final String value;

  const _StatCard({
    this.iconPath,
    this.fallbackIcon,
    required this.title,
    required this.value,
  });

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
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF4A9B8E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: iconPath != null
                    ? SvgPicture.asset(
                        iconPath!,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF4A9B8E),
                          BlendMode.srcIn,
                        ),
                        placeholderBuilder: (context) => Icon(
                          fallbackIcon ?? Icons.image_outlined,
                          size: 18,
                          color: const Color(0xFF4A9B8E),
                        ),
                      )
                    : Icon(
                        fallbackIcon ?? Icons.image_outlined,
                        size: 18,
                        color: const Color(0xFF4A9B8E),
                      ),
              ),
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
