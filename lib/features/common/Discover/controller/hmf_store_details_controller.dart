import 'dart:developer';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/Discover/model/earn_profile_home_foods_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/tiffin_repo.dart';
import 'package:get/get.dart';

/// Backs the consumer "home made food store details" screen. Everything is
/// keyed off the store owner's [userId] — the backend resolves the store by
/// userId for both the home-foods (profile + items) and tiffins calls.
class HmfStoreDetailsController extends GetxController {
  final EarnProfileRepo _repo = EarnProfileRepo();
  final TiffinRepo _tiffinRepo = TiffinRepo();

  /// Store owner user id — drives both the home-foods and tiffins calls.
  final String userId;

  HmfStoreDetailsController({required this.userId});

  /// Store profile — populated from the home-foods response. Null until the
  /// first fetch resolves; the screen gates its whole UI on this.
  final Rxn<EarnProfileModel> store = Rxn<EarnProfileModel>();

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
      final response = await _tiffinRepo.fetchTiffinsByUser(userId: userId);
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

  /// Loads this store's home-made-food items AND the store profile — both come
  /// back in the one home-foods response. Exposed for the screen's Retry.
  Future<void> fetchFoodItems() async {
    try {
      isFoodLoading.value = true;

      // home-foods returns the store profile AND its food items together;
      // backend resolves the store by userId.
      final response = await _repo.fetchEarnProfileHomeFoods(id: userId);
      if (!response.isSuccess || response.response?.data == null) return;

      final parsed =
          EarnProfileHomeFoodsResponse.fromJson(response.response!.data);
      if (!parsed.success) return;

      // The profile travels inside the same payload — no separate call needed.
      if (parsed.profile != null) store.value = parsed.profile;

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
