import 'dart:developer';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/Discover/model/consumer_tiffin_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/tiffin_repo.dart';
import 'package:get/get.dart';

/// Backs the consumer "Home Made Food" category screen ([HomeMadeFoodScreen]).
///
/// Category index 0 is the **Tiffin** tab (paginated tiffins across all
/// stores, filtered by meal slot). Indices 1-4 map to the home-made food
/// categories (Bakery / Sweets / Namkeen / Pickles), each a paginated list
/// filtered by `foodKey`.
class HomeMadeFoodConsumerController extends GetxController {
  final TiffinRepo _tiffinRepo = TiffinRepo();
  final FoodRepo _foodRepo = FoodRepo();

  static const int _pageLimit = 20;

  // Screen categories: [Tiffin, Bakery, Sweets, Namkeen, Pickles].
  // Index 0 is tiffin; the rest map (index - 1) onto this list.
  static const List<FoodCategoryType> _foodCategoryByIndex = [
    FoodCategoryType.bakery,
    FoodCategoryType.sweets,
    FoodCategoryType.namkeens,
    FoodCategoryType.pickles,
  ];

  // Tiffin filter tabs: [Break-Fast, Morning Tiffin / Lunch, Evening / Dinner].
  static const List<MealType> _mealTypeByFilter = [
    MealType.breakfast,
    MealType.morningTiffin,
    MealType.eveningDinner,
  ];

  final RxInt selectedCategoryIndex = 0.obs;
  final RxInt selectedFilterIndex = 0.obs;

  // ── Tiffin state ──
  final RxList<ConsumerTiffinItem> tiffinList = <ConsumerTiffinItem>[].obs;
  final RxBool isTiffinFirstLoading = false.obs;
  final RxBool isTiffinLoadingMore = false.obs;
  int _tiffinPage = 1;
  int _tiffinTotalPages = 1;

  bool get _tiffinHasMore => _tiffinPage < _tiffinTotalPages;

  // ── Home food state ──
  final RxList<FoodItemModel> homeFoodList = <FoodItemModel>[].obs;
  final RxBool isHomeFoodFirstLoading = false.obs;
  final RxBool isHomeFoodLoadingMore = false.obs;
  int _homeFoodPage = 1;
  bool _homeFoodHasMore = false;

  FoodCategoryType get _currentFoodCategory =>
      _foodCategoryByIndex[selectedCategoryIndex.value - 1];

  // ── Category / filter switching ──

  void onCategoryChanged(int index) {
    if (index == selectedCategoryIndex.value) return;
    selectedCategoryIndex.value = index;
    if (index == 0) {
      if (tiffinList.isEmpty) fetchAllTiffins();
    } else {
      _fetchHomeFood(reset: true);
    }
  }

  void onTiffinFilterChanged(int index) {
    if (index == selectedFilterIndex.value) return;
    selectedFilterIndex.value = index;
    fetchAllTiffins();
  }

  // ── Tiffins ──

  /// Initial (reset) load of tiffins for the selected meal filter.
  Future<void> fetchAllTiffins() async {
    _tiffinPage = 1;
    _tiffinTotalPages = 1;
    await _loadTiffins(reset: true);
  }

  void onTiffinScrollEnd() {
    if (isTiffinLoadingMore.value ||
        isTiffinFirstLoading.value ||
        !_tiffinHasMore) {
      return;
    }
    _tiffinPage++;
    _loadTiffins(reset: false);
  }

  Future<void> _loadTiffins({required bool reset}) async {
    try {
      if (reset) {
        isTiffinFirstLoading.value = true;
      } else {
        isTiffinLoadingMore.value = true;
      }

      final response = await _tiffinRepo.fetchAllTiffins(queryParams: {
        'page': _tiffinPage,
        'limit': _pageLimit,
        'tiffinKey': _mealTypeByFilter[selectedFilterIndex.value].name,
      });

      if (!response.isSuccess || response.response?.data == null) return;

      final parsed =
          ConsumerTiffinResponseModel.fromJson(response.response!.data);
      _tiffinTotalPages = parsed.pagination?.totalPages ?? _tiffinPage;

      if (reset) {
        tiffinList.assignAll(parsed.items);
      } else {
        tiffinList.addAll(parsed.items);
      }
    } catch (e, s) {
      log('Error fetching consumer tiffins: $e\n$s');
      if (!reset) _tiffinPage--; // roll back failed page bump
    } finally {
      isTiffinFirstLoading.value = false;
      isTiffinLoadingMore.value = false;
    }
  }

  // ── Home made food (Bakery / Sweets / Namkeen / Pickles) ──

  void onHomeFoodScrollEnd() {
    if (isHomeFoodLoadingMore.value ||
        isHomeFoodFirstLoading.value ||
        !_homeFoodHasMore) {
      return;
    }
    _homeFoodPage++;
    _fetchHomeFood(reset: false);
  }

  Future<void> _fetchHomeFood({required bool reset}) async {
    try {
      if (reset) {
        _homeFoodPage = 1;
        _homeFoodHasMore = false;
        isHomeFoodFirstLoading.value = true;
      } else {
        isHomeFoodLoadingMore.value = true;
      }

      final response = await _foodRepo.fetchAllHomeFoodItems(queryParams: {
        'page': _homeFoodPage,
        'limit': _pageLimit,
        'foodKey': _currentFoodCategory.name,
      });

      if (!response.isSuccess || response.response?.data == null) return;

      final parsed = FoodResponseModel.fromJson(response.response!.data);
      // FoodResponseModel carries no pagination block — infer "has more"
      // from a full page.
      _homeFoodHasMore = parsed.data.length >= _pageLimit;

      if (reset) {
        homeFoodList.assignAll(parsed.data);
      } else {
        homeFoodList.addAll(parsed.data);
      }
    } catch (e, s) {
      log('Error fetching consumer home made food: $e\n$s');
      if (!reset) _homeFoodPage--; // roll back failed page bump
    } finally {
      isHomeFoodFirstLoading.value = false;
      isHomeFoodLoadingMore.value = false;
    }
  }
}
