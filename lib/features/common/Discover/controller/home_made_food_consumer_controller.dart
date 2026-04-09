import 'dart:developer';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/model/consumer_tiffin_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/tiffin_repo.dart';
import 'package:get/get.dart';

class HomeMadeFoodConsumerController extends GetxController {
  final _tiffinRepo = TiffinRepo();
  final _foodRepo = FoodRepo();

  static const int _pageLimit = 20;
  static const int _distance = 5000;

  // ── Selected Category (sidebar) ──
  RxInt selectedCategoryIndex = 0.obs;

  // ── Selected Filter (tiffin sub-tabs) ──
  RxInt selectedFilterIndex = 0.obs;

  // ── Tiffin Data ──
  RxBool isTiffinFirstLoading = false.obs;
  RxBool isTiffinLoadingMore = false.obs;
  RxList<ConsumerTiffinItem> tiffinList = <ConsumerTiffinItem>[].obs;
  int _tiffinPage = 1;
  bool _tiffinHasMore = true;

  // ── Home Food Data ──
  RxBool isHomeFoodFirstLoading = false.obs;
  RxBool isHomeFoodLoadingMore = false.obs;
  RxList<FoodItemModel> homeFoodList = <FoodItemModel>[].obs;
  int _homeFoodPage = 1;
  bool _homeFoodHasMore = true;

  // ── Location params ──
  Map<String, dynamic> get _locationParams => {
        'lat': LocationService.lat != 0.0 ? LocationService.lat : 0.0,
        'long': LocationService.lng != 0.0 ? LocationService.lng : 0.0,
        'distance': _distance,
      };

  // ── Tiffin key for current filter tab ──
  // 0=Break-Fast, 1=Morning Tiffin / Lunch, 2=Evening Tiffin / Dinner
  static const List<MealType> _filterMealTypes = [
    MealType.breakfast,
    MealType.morningTiffin,
    MealType.eveningDinner,
  ];

  String get _currentTiffinKey =>
      _filterMealTypes[selectedFilterIndex.value].name;

  // ── Food category key for current sidebar category ──
  // Sidebar: 0=Tiffin, 1=Bakery, 2=Sweets, 3=Namkeen, 4=Pickles
  static const List<FoodCategoryType> _foodCategoryTypes = [
    FoodCategoryType.bakery,
    FoodCategoryType.sweets,
    FoodCategoryType.namkeens,
    FoodCategoryType.pickles,
  ];

  // ── Public API ──

  /// Called on init & when tiffin filter tab changes
  Future<void> fetchAllTiffins({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isTiffinLoadingMore.value || !_tiffinHasMore) return;
      isTiffinLoadingMore.value = true;
    } else {
      isTiffinFirstLoading.value = true;
      tiffinList.clear();
      _tiffinPage = 1;
      _tiffinHasMore = true;
    }

    try {
      final queryParams = <String, dynamic>{
        'tiffinKey': _currentTiffinKey,
        'page': _tiffinPage,
        'limit': _pageLimit,
        ..._locationParams,
      };

      final response =
          await _tiffinRepo.fetchAllTiffins(queryParams: queryParams);

      if (response.isSuccess && response.response?.data != null) {
        final parsed =
            ConsumerTiffinResponseModel.fromJson(response.response!.data);
          final newItems = parsed.items;
          if (isLoadMore) {
            tiffinList.addAll(newItems);
          } else {
            tiffinList.assignAll(newItems);
          }
          final pagination = parsed.pagination;
          _tiffinHasMore = pagination != null
              ? pagination.page < pagination.totalPages
              : newItems.length >= _pageLimit;
          _tiffinPage++;
        log('tiffin list -- ${tiffinList.length}');
      }
    } catch (e) {
      log('Error fetching consumer tiffins: $e');
    } finally {
      isTiffinFirstLoading.value = false;
      isTiffinLoadingMore.value = false;
    }
  }

  /// Called when a food category is selected or needs more data
  Future<void> fetchAllHomeFood({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isHomeFoodLoadingMore.value || !_homeFoodHasMore) return;
      isHomeFoodLoadingMore.value = true;
    } else {
      isHomeFoodFirstLoading.value = true;
      homeFoodList.clear();
      _homeFoodPage = 1;
      _homeFoodHasMore = true;
    }

    try {
      // sidebar index 1 = bakery(0), 2 = sweets(1), 3 = namkeen(2), 4 = pickles(3)
      final foodCatIndex = selectedCategoryIndex.value - 1;
      final foodKey = _foodCategoryTypes[foodCatIndex].name;

      final queryParams = <String, dynamic>{
        'foodKey': foodKey,
        'page': _homeFoodPage,
        'limit': _pageLimit,
        ..._locationParams,
      };

      final response =
          await _foodRepo.fetchAllHomeFoodItems(queryParams: queryParams);

      if (response.isSuccess && response.response?.data != null) {
        final parsed = FoodResponseModel.fromJson(response.response!.data);
        if (parsed.success) {
          final newItems = parsed.data;
          if (isLoadMore) {
            homeFoodList.addAll(newItems);
          } else {
            homeFoodList.assignAll(newItems);
          }
          _homeFoodHasMore = newItems.length >= _pageLimit;
          _homeFoodPage++;
        }
      }
    } catch (e) {
      log('Error fetching consumer home food: $e');
    } finally {
      isHomeFoodFirstLoading.value = false;
      isHomeFoodLoadingMore.value = false;
    }
  }

  /// Called when sidebar category changes
  void onCategoryChanged(int index) {
    selectedCategoryIndex.value = index;
    selectedFilterIndex.value = 0;

    if (index == 0) {
      // Tiffin category — fetch with default tab (breakfast)
      fetchAllTiffins();
    } else {
      // Food categories (bakery, sweets, namkeen, pickles)
      fetchAllHomeFood();
    }
  }

  /// Called when tiffin sub-tab changes
  void onTiffinFilterChanged(int index) {
    selectedFilterIndex.value = index;
    fetchAllTiffins();
  }

  // ── Scroll pagination helpers ──
  void onTiffinScrollEnd() => fetchAllTiffins(isLoadMore: true);
  void onHomeFoodScrollEnd() => fetchAllHomeFood(isLoadMore: true);
}
