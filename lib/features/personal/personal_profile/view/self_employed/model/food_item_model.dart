import 'package:BlueEra/core/constants/app_enum.dart';

class FoodItemModel {
  final String? id;

  /// Owning user (kitchen) id. Populated by the consumer listing API so the
  /// discover screen can resolve the item's store. Null on the owner side.
  final String? userId;
  final FoodCategoryType categoryType;
  final String foodName;
  final String? imagePath;
  final List<String> images;
  final String mrpPrice;
  final String sellingPrice;
  final String foodType;
  final String cookingMethod;
  final bool isLive;
  final String? createdAt;
  final double? lat;
  final double? lng;

  const FoodItemModel({
    this.id,
    this.userId,
    required this.categoryType,
    this.foodName = '',
    this.imagePath,
    this.images = const [],
    this.mrpPrice = '',
    this.sellingPrice = '',
    this.foodType = '',
    this.cookingMethod = '',
    this.isLive = false,
    this.createdAt,
    this.lat,
    this.lng,
  });

  bool get hasData => id != null;

  String? get imageUrl => images.isNotEmpty ? images.first : null;

  String get discount {

    final mrp = double.tryParse(mrpPrice) ?? 0;
    final selling = double.tryParse(sellingPrice) ?? 0;
    if (mrp <= 0 || selling <= 0 || selling >= mrp) return '';
    return '${((mrp - selling) / mrp * 100).toStringAsFixed(0)}% OFF';
  }

  factory FoodItemModel.fromJson(
      Map<String, dynamic> json, FoodCategoryType type) {
    return FoodItemModel(
      id: json['_id'],
      userId: json['userId']?.toString(),
      categoryType: type,
      foodName: json['foodName'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      mrpPrice: json['mrp'] ?? '',
      sellingPrice: json['sellingPrice'] ?? '',
      foodType: json['foodType'] ?? '',
      cookingMethod: json['cookingMethod'] ?? '',
      isLive: json['isActive'] ?? false,
      createdAt: json['createdAt'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'foodName': foodName,
        'foodKey': categoryType.name,
        'mrp': mrpPrice,
        'sellingPrice': sellingPrice,
        'foodType': foodType,
        'images': images,
        'cookingMethod': cookingMethod,
        'isActive': isLive,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  FoodItemModel copyWith({
    String? id,
    String? itemName,
    String? imagePath,
    List<String>? images,
    String? mrpPrice,
    String? sellingPrice,
    String? selectedFoodType,
    String? selectedCookingMethod,
    bool? isLive,
    double? lat,
    double? lng,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      categoryType: categoryType,
      foodName: itemName ?? this.foodName,
      imagePath: imagePath ?? this.imagePath,
      images: images ?? this.images,
      mrpPrice: mrpPrice ?? this.mrpPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      foodType: selectedFoodType ?? this.foodType,
      cookingMethod:
          selectedCookingMethod ?? this.cookingMethod,
      isLive: isLive ?? this.isLive,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
