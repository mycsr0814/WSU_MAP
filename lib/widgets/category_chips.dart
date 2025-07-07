import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['카페', '식당', '편의점', '자판기'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryChip(category);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    IconData icon;
    switch (category) {
      case 'ㄴㅇㄴㄴㅇㄴㅇㄴ':
        icon = Icons.local_cafe;
        break;
      case '식당':
        icon = Icons.restaurant;
        break;
      case '편의점':
        icon = Icons.store;
        break;
      case '자판기':
        icon = Icons.local_drink;
        break;
      default:
        icon = Icons.category;
    }

    return InkWell(
      onTap: () => onCategorySelected(category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.indigo.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}