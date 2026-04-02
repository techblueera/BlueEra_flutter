import 'dart:ui';

class ProductModel {
  final String id;
  final String name;
  final double currentPrice;
  final double originalPrice;
  final int discountPercentage;
  final String? imageUrl;
  final String status;
  final String stockStatus; // 'In stock' or 'Out of stock'
  final List<String> sizes;
  final List<Color> colors;
  final int selectedSizeIndex;
  final int selectedColorIndex;
  final List<String>? multipleImageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.originalPrice,
    required this.discountPercentage,
    required this.status,
    required this.stockStatus,
    required this.sizes,
    required this.colors,
    this.selectedSizeIndex = 0,
    this.selectedColorIndex = 0,
    this.imageUrl,
    this.multipleImageUrl,
  });
}
