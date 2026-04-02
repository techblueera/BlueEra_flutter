
class CategoryInventoryModel {
  final String id;
  final String name;
  final String description;
  final int productCount;
  final String imageUrl;
  final String status; // 'Active' or 'Draft'
  final DateTime createdAt;

  CategoryInventoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
  });
} 