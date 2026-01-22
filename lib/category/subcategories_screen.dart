import 'package:flutter/material.dart';
import 'subcategory_items_screen.dart';

class SubcategoriesScreen extends StatelessWidget {
  final String categoryTitle;
  final List<String> subcategories;

  const SubcategoriesScreen({
    Key? key,
    required this.categoryTitle,
    required this.subcategories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            categoryTitle,
            style: const TextStyle(
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
            // Subcategories List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  return _buildSubcategoryItem(context, subcategories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFF2B2B2A),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF9E9E9E),
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoryItemsScreen(
                subcategoryTitle: title,
              ),
            ),
          );
        },
      ),
    );
  }
}
