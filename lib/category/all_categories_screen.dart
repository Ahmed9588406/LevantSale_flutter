import 'package:flutter/material.dart';
import 'subcategories_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'title': 'للعقارات',
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
        'subcategories': [
          'شقق للبيع',
          'شقق للإيجار',
          'فلل للبيع',
          'فلل للإيجار',
          'عقارات مصيفية للبيع',
          'عقارات مصيفية للإيجار',
          'عقارات تجارية للإيجار',
          'مباني وأراضي',
        ]
      },
      {
        'title': 'للسيارات',
        'image': 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=400',
        'subcategories': []
      },
      {
        'title': 'أجهزة الكترونية',
        'image': 'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?w=400',
        'subcategories': []
      },
      {
        'title': 'للخدمة',
        'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
        'subcategories': []
      },
      {
        'title': 'هوايات',
        'image': 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=400',
        'subcategories': []
      },
      {
        'title': 'للخدمة',
        'image': 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
        'subcategories': []
      },
      {
        'title': 'موضة',
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400',
        'subcategories': []
      },
      {
        'title': 'للخدمة',
        'image': 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
        'subcategories': []
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'الفئات',
            style: TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'دور على موبايلات، عقارات، سيارات...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ),
            ),
            // Categories Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final subcategories = (category['subcategories'] as List)
                      .map((e) => e.toString())
                      .toList();
                  return _buildCategoryCard(
                    context,
                    category['title'] as String,
                    category['image'] as String,
                    subcategories,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String image,
    List<String> subcategories,
  ) {
    return GestureDetector(
      onTap: () {
        if (subcategories.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoriesScreen(
                categoryTitle: title,
                subcategories: subcategories,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1DAF52),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2B2B2A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
