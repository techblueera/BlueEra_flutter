import 'package:BlueEra/core/constants/app_enum.dart';

class TiffinMealModel {
  final String? id;
  final MealType mealType;
  final String tiffinName;
  final String? imagePath;
  final String? imageUrl;
  final String mrpPrice;
  final String sellingPrice;
  final String selectedFoodType;
  final String selectedCookingMethod;
  final String selectedStartTime;
  final String selectedEndTime;
  final bool isLive;

  const TiffinMealModel({
    this.id,
    required this.mealType,
    this.tiffinName = '',
    this.imagePath,
    this.imageUrl,
    this.mrpPrice = '',
    this.sellingPrice = '',
    this.selectedFoodType = '',
    this.selectedCookingMethod = '',
    this.selectedStartTime = '',
    this.selectedEndTime = '',
    this.isLive = false,
  });

  bool get hasData => id != null; // ✅ only true after API create/fetch

  factory TiffinMealModel.fromJson(Map<String, dynamic> json, MealType type) {
    return TiffinMealModel(
      id: json['id'],
      mealType: type,
      tiffinName: json['tiffin_name'] ?? '',
      imageUrl: json['image_url'],
      mrpPrice: json['mrp_price'] ?? '',
      sellingPrice: json['selling_price'] ?? '',
      selectedFoodType: json['food_type'] ?? '',
      selectedCookingMethod: json['cooking_method'] ?? '',
      selectedStartTime: json['start_time'] ?? '',
      selectedEndTime: json['end_time'] ?? '',
      isLive: json['is_live'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'tiffin_name': tiffinName,
        'mrp_price': mrpPrice,
        'selling_price': sellingPrice,
        'food_type': selectedFoodType,
        'cooking_method': selectedCookingMethod,
        'start_time': selectedStartTime,
        'end_time': selectedEndTime,
        'is_live': isLive,
        'meal_type': mealType.name,
      };

  TiffinMealModel copyWith({
    String? id,
    String? tiffinName,
    String? imagePath,
    String? imageUrl,
    String? mrpPrice,
    String? sellingPrice,
    String? selectedFoodType,
    String? selectedCookingMethod,
    String? selectedStartTime,
    String? selectedEndTime,
    bool? isLive,
  }) {
    return TiffinMealModel(
      id: id ?? this.id,
      mealType: mealType,
      tiffinName: tiffinName ?? this.tiffinName,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      mrpPrice: mrpPrice ?? this.mrpPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      selectedFoodType: selectedFoodType ?? this.selectedFoodType,
      selectedCookingMethod:
          selectedCookingMethod ?? this.selectedCookingMethod,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      isLive: isLive ?? this.isLive,
    );
  }
}
