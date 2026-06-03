import 'dart:developer';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/Discover/model/earn_profile_home_foods_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/tiffin_repo.dart';
import 'package:get/get.dart';

/// Backs the consumer "home made food store details" screen. The profile
/// details themselves are passed in from the listing screen — this only
/// fetches the store's home made food items (Bakery / Sweets / Namkeen /
/// Pickles) for the given earn profile [profileId], grouped by category.
class HomeMadeFoodStoreDetailsController extends GetxController {
  final EarnProfileRepo _repo = EarnProfileRepo();
  final TiffinRepo _tiffinRepo = TiffinRepo();

  /// The earn profile id whose food items we list.
  final String profileId;

  HomeMadeFoodStoreDetailsController({required this.profileId});

  final RxBool isFoodLoading = false.obs;

  /// Items grouped per food category, mirroring the owner-side controller.
  final Map<FoodCategoryType, RxList<FoodItemModel>> categoryData = {
    for (final type in FoodCategoryType.values) type: <FoodItemModel>[].obs,
  };

  /// This store's tiffins (shown only when allocated). Fetched via
  /// [TiffinRepo.fetchAllMeals].
  final RxList<TiffinMealModel> tiffins = <TiffinMealModel>[].obs;
  final RxBool isTiffinLoading = false.obs;

  /// True once a fetch has completed and no items were found.
  bool get hasNoFood => categoryData.values.every((list) => list.isEmpty);

  /// Categories that actually have at least one item — drives the tabs.
  List<FoodCategoryType> get availableCategories => FoodCategoryType.values
      .where((t) => (categoryData[t]?.isNotEmpty ?? false))
      .toList();

  @override
  void onInit() {
    super.onInit();
    fetchFoodItems();
    fetchTiffins();
  }

  /// Fetch this store's tiffins. Only meals that actually have data are kept,
  /// so the Tiffin section is shown only when the store has allocated tiffins.
  Future<void> fetchTiffins() async {
    try {
      isTiffinLoading.value = true;
      final response = await _tiffinRepo.fetchAllMeals();
      if (!response.isSuccess || response.response?.data == null) return;

      final parsed = TiffinResponseModel.fromJson(response.response!.data);
      if (!parsed.success) return;

      tiffins.assignAll(parsed.data.where((m) => m.hasData));
    } catch (e, s) {
      log('Error fetching store tiffins: $e\n$s');
    } finally {
      isTiffinLoading.value = false;
    }
  }

  Future<void> fetchFoodItems() async {
    try {
      isFoodLoading.value = true;

      final response = await _repo.fetchEarnProfileHomeFoods(id: profileId);
      if (!response.isSuccess || response.response?.data == null) return;

      final parsed =
          EarnProfileHomeFoodsResponse.fromJson(response.response!.data);
      if (!parsed.success) return;

      for (final type in FoodCategoryType.values) {
        categoryData[type]?.clear();
      }
      for (final item in parsed.foods) {
        categoryData[item.categoryType]?.add(item);
      }
    } catch (e, s) {
      log('Error fetching store home made food: $e\n$s');
    } finally {
      isFoodLoading.value = false;
    }
  }
}
