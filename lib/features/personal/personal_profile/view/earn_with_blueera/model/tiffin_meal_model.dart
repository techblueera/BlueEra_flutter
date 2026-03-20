import 'package:BlueEra/core/constants/app_enum.dart';

class TiffinResponseModel {
  final bool success;
  final List<TiffinMealModel> data;
  final String centerName;

  const TiffinResponseModel({
    this.success = false,
    this.data = const [],
    this.centerName = '',
  });

  factory TiffinResponseModel.fromJson(Map<String, dynamic> json) {
    return TiffinResponseModel(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((item) => TiffinMealModel.fromJson(item))
          .toList(),
      centerName: json['centerName'] ?? '',
    );
  }
}

class TiffinMealModel {
  final String? id;
  final MealType mealType;
  final String tiffinName;
  final String? imagePath;
  final List<String> images;
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
    this.images = const [],
    this.mrpPrice = '',
    this.sellingPrice = '',
    this.selectedFoodType = '',
    this.selectedCookingMethod = '',
    this.selectedStartTime = '',
    this.selectedEndTime = '',
    this.isLive = false,
  });

  bool get hasData => id != null;

  String? get imageUrl =>
      images.isNotEmpty ? images.first : null; // ✅ first image for display

  // ✅ fromJson mapped to API response
  factory TiffinMealModel.fromJson(Map<String, dynamic> json) {
    return TiffinMealModel(
      id: json['_id'],
      mealType: MealType.fromKey(json['tiffinKey']),
      tiffinName: json['tiffinName'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      mrpPrice: json['mrp'] ?? '',
      sellingPrice: json['sellingPrice'] ?? '',
      selectedFoodType: json['foodType'] ?? '',
      selectedCookingMethod: json['cookingMethod'] ?? '',
      selectedStartTime: json['tiffinTiming']?['start'] ?? '',
      selectedEndTime: json['tiffinTiming']?['end'] ?? '',
      isLive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'tiffinName': tiffinName,
        'mrp': mrpPrice,
        'sellingPrice': sellingPrice,
        'foodType': selectedFoodType,
        'cookingMethod': selectedCookingMethod,
        'tiffinTiming': {
          'start': selectedStartTime,
          'end': selectedEndTime,
        },
        'isActive': isLive,
        'tiffinKey': mealType.name,
      };

  TiffinMealModel copyWith({
    String? id,
    String? tiffinName,
    String? imagePath,
    List<String>? images,
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
      images: images ?? this.images,
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
