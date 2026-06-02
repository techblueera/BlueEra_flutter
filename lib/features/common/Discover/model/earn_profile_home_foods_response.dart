import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';

/// Response for `GET earn-service/earn-profiles/{id}/home-foods`.
///
/// Unlike the list endpoint, `data` here is a SINGLE object: the full store
/// profile plus a nested `homeMadeFoods` array of that store's food items.
/// ```json
/// { "success": true, "data": { ...profile, "homeMadeFoodsCount": 1,
///     "homeMadeFoods": [ { ...foodItem } ] } }
/// ```
class EarnProfileHomeFoodsResponse {
  final bool success;
  final EarnProfileModel? profile;
  final int foodsCount;
  final List<FoodItemModel> foods;

  const EarnProfileHomeFoodsResponse({
    this.success = false,
    this.profile,
    this.foodsCount = 0,
    this.foods = const [],
  });

  factory EarnProfileHomeFoodsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return EarnProfileHomeFoodsResponse(success: json['success'] ?? false);
    }

    final rawFoods = data['homeMadeFoods'];
    final foods = rawFoods is List
        ? rawFoods
            .whereType<Map<String, dynamic>>()
            .map((e) => FoodItemModel.fromJson(
                  e,
                  FoodCategoryType.fromKey(e['foodKey']),
                ))
            .toList()
        : <FoodItemModel>[];

    return EarnProfileHomeFoodsResponse(
      success: json['success'] ?? false,
      profile: EarnProfileModel.fromJson(data),
      foodsCount: (data['homeMadeFoodsCount'] as num?)?.toInt() ?? foods.length,
      foods: foods,
    );
  }
}
