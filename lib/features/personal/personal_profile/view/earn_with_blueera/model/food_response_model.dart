import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/food_item_model.dart';

class FoodResponseModel {
  final bool success;
  final List<FoodItemModel> data;

  const FoodResponseModel({
    this.success = false,
    this.data = const [],
  });

  factory FoodResponseModel.fromJson(Map<String, dynamic> json) {
    return FoodResponseModel(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((item) => FoodItemModel.fromJson(
                item,
                FoodCategoryType.fromKey(item['foodKey']),
              ))
          .toList(),
    );
  }
}
