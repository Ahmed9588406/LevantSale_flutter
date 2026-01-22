import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ad_model.dart';
import 'ad_card.dart';

class AdsListSection extends StatelessWidget {
  final List<AdModel> ads;
  final Function(AdModel) onRepost;
  final Function(AdModel) onSold;
  final Function(AdModel) onMenu;

  const AdsListSection({
    super.key,
    required this.ads,
    required this.onRepost,
    required this.onSold,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'إعلاناتي:',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A9B8E),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return AdCard(
              ad: ad,
              onRepost: () => onRepost(ad),
              onSold: () => onSold(ad),
              onMenu: () => onMenu(ad),
            );
          },
        ),
      ],
    );
  }
}
