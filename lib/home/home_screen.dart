import 'package:flutter/material.dart';
import '../home/widgets/search_bar_widget.dart';
import '../home/widgets/banner_carousel.dart';
import '../home/widgets/category_section.dart';
import '../home/widgets/bottom_nav_bar.dart';
import '../home/widgets/product_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Search bar and notification
                    const SearchBarWidget(),

                    const SizedBox(height: 16),

                    // Banner carousel
                    const BannerCarousel(),

                    const SizedBox(height: 24),

                    // Categories section
                    const CategorySection(),

                    const SizedBox(height: 24),

                    // Product sections (grouped by category) from API
                    const ProductSections(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // Bottom navigation bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomBottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
