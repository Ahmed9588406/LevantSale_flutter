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
              // Main scrollable content
              CustomScrollView(
                slivers: [
                  // Search bar (stays at top, not in scroll)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Search bar with inline results
                        const SearchBarWidget(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Banner carousel
                  const SliverToBoxAdapter(child: BannerCarousel()),

                  // Categories section
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: CategorySection(),
                    ),
                  ),

                  // Product sections
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: ProductSections(),
                    ),
                  ),

                  // Bottom padding for nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
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
