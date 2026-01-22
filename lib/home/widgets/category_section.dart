import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../../category/all_categories_screen.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryModel(
        title: 'العقارات',
        icon: Icons.home_outlined,
        image: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
      ),
      CategoryModel(
        title: 'الموضة',
        icon: Icons.checkroom_outlined,
        image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400',
      ),
      CategoryModel(
        title: 'سيارات',
        icon: Icons.directions_car_outlined,
        image: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=400',
      ),
      CategoryModel(
        title: 'موبايلات',
        icon: Icons.phone_android_outlined,
        image: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
      ),
    ];

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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(categories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
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
              border: Border.all(
                color: const Color(0xFF1DAF52),
                width: 2,
              ),
              image: DecorationImage(
                image: NetworkImage(category.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.title,
            style: const TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
