import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/food_item_model.dart';

class AddFoodResponseModel {
  final bool success;
  final FoodItemModel? data;
  final List<String> uploadUrls;

  const AddFoodResponseModel({
    this.success = false,
    this.data,
    this.uploadUrls = const [],
  });

  factory AddFoodResponseModel.fromJson(Map<String, dynamic> json) {
    return AddFoodResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? FoodItemModel.fromJson(
        json['data'],
        FoodCategoryType.fromKey(json['data']['categoryKey']),
      )
          : null,
      uploadUrls: List<String>.from(json['uploadUrls'] ?? []),
    );
  }
}