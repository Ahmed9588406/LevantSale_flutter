import 'package:flutter/material.dart';
import 'package:leventsale/api/home/home_service.dart';
import '../../category/all_categories_screen.dart';
import '../../category/category_listings_screen.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الفئات الشائعة',
                style: TextStyle(
                  color: Color(0xFF2B2B2A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllCategoriesScreen(),
                    ),
                  );
                },
                child: const Text(
                  'الكل',
                  style: TextStyle(
                    color: Color(0xFF1DAF52),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: FutureBuilder<List<ApiCategory>>(
            future: HomeService.fetchCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'حدث خطأ أثناء تحميل الفئات',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              } else {
                final cats = snapshot.data ?? [];
                if (cats.isEmpty) {
                  return const Center(child: Text('لا توجد فئات متاحة حالياً'));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(context, cats[index]);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, ApiCategory category) {
    final raw = category.iconUrl ?? category.imageUrl;
    String? imageUrl;
    if (raw != null && raw.isNotEmpty) {
      imageUrl = raw.startsWith('http') ? raw : '${HomeService.baseUrl}$raw';
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryListingsScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1DAF52), width: 2),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF2B2B2A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
