import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:get/get.dart';

class PropertyDiscoverCategory {
  final String label;
  final String listingType;
  final String propertyType;
  final String image;
  final bool isSale;

  const PropertyDiscoverCategory({
    required this.label,
    required this.listingType,
    required this.propertyType,
    required this.image,
    required this.isSale,
  });
}

class PropertyDiscoverController extends GetxController {
  final PropertyRepo _repo = PropertyRepo();

  final properties = <PropertyModel>[].obs;
  final mapProperties = <PropertyModel>[].obs;
  final isMapLoading = false.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final selectedCategoryIndex = 0.obs;

  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;

  List<PropertyDiscoverCategory> categories = [];

  // ── Sort (reserved for future API support) ──

  // ── Common filters ──
  final city = ''.obs;
  final minPrice = ''.obs;
  final maxPrice = ''.obs;

  // ── HouseAndApartment filters ──
  final filterBhk = ''.obs;
  final filterBathrooms = ''.obs;
  final filterFacing = ''.obs;
  final filterCarParking = ''.obs;

  // ── ShopAndOffices filters ──
  final filterFurnishing = ''.obs;

  // ── PGAndGuestHouse filters ──
  final filterSubType = ''.obs;
  final filterMealsIncluded = ''.obs;

  // ── NewProjectsAndProperties filters ──
  final filterProjectStatus = ''.obs;
  final filterTypeOfProperty = ''.obs;

  String get currentPropertyType =>
      categories[selectedCategoryIndex.value].propertyType;

  String get _listingType =>
      categories[selectedCategoryIndex.value].listingType;

  void initWithCategories(
      List<PropertyDiscoverCategory> cats, int initialIndex) {
    categories = cats;
    selectedCategoryIndex.value = initialIndex;
    fetchProperties();
  }

  void selectCategory(int index) {
    if (index == selectedCategoryIndex.value) return;
    selectedCategoryIndex.value = index;
    _clearTypeFilters();
    _resetAndFetch();
  }

  void applyAllFilters({
    required String cityVal,
    required String min,
    required String max,
    String bhk = '',
    String bathrooms = '',
    String facing = '',
    String carParking = '',
    String furnishing = '',
    String subType = '',
    String mealsIncluded = '',
    String projectStatus = '',
    String typeOfProperty = '',
  }) {
    city.value = cityVal;
    minPrice.value = min;
    maxPrice.value = max;
    filterBhk.value = bhk;
    filterBathrooms.value = bathrooms;
    filterFacing.value = facing;
    filterCarParking.value = carParking;
    filterFurnishing.value = furnishing;
    filterSubType.value = subType;
    filterMealsIncluded.value = mealsIncluded;
    filterProjectStatus.value = projectStatus;
    filterTypeOfProperty.value = typeOfProperty;
    _resetAndFetch();
  }

  void clearFilters() {
    city.value = '';
    minPrice.value = '';
    maxPrice.value = '';
    _clearTypeFilters();
    _resetAndFetch();
  }

  void _clearTypeFilters() {
    filterBhk.value = '';
    filterBathrooms.value = '';
    filterFacing.value = '';
    filterCarParking.value = '';
    filterFurnishing.value = '';
    filterSubType.value = '';
    filterMealsIncluded.value = '';
    filterProjectStatus.value = '';
    filterTypeOfProperty.value = '';
  }

  int get activeFilterCount {
    int count = 0;
    if (city.value.isNotEmpty) count++;
    if (minPrice.value.isNotEmpty || maxPrice.value.isNotEmpty) count++;
    if (filterBhk.value.isNotEmpty) count++;
    if (filterBathrooms.value.isNotEmpty) count++;
    if (filterFacing.value.isNotEmpty) count++;
    if (filterCarParking.value.isNotEmpty) count++;
    if (filterFurnishing.value.isNotEmpty) count++;
    if (filterSubType.value.isNotEmpty) count++;
    if (filterMealsIncluded.value.isNotEmpty) count++;
    if (filterProjectStatus.value.isNotEmpty) count++;
    if (filterTypeOfProperty.value.isNotEmpty) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  void _resetAndFetch() {
    _page = 1;
    _hasMore = true;
    properties.clear();
    fetchProperties();
  }

  Future<void> fetchProperties({bool isLoadMore = false}) async {
    if (isLoadMore && !_hasMore) return;
    if (isLoadMore && isLoadingMore.value) return;
    if (!isLoadMore && isLoading.value) return;

    if (isLoadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final params = <String, dynamic>{
        'listingType': _listingType,
        'propertyType': currentPropertyType,
        'page': _page,
        'limit': _limit,
      };

      if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
        params['lat'] = LocationService.lat;
        params['lng'] = LocationService.lng;
        params['radius'] = 1500;
      }

      // Common filters
      if (city.value.isNotEmpty) params['city'] = city.value;
      if (minPrice.value.isNotEmpty) {
        params['minPrice'] = int.tryParse(minPrice.value) ?? 0;
      }
      if (maxPrice.value.isNotEmpty) {
        params['maxPrice'] = int.tryParse(maxPrice.value) ?? 0;
      }

      // Type-specific filters
      if (filterBhk.value.isNotEmpty) params['bhk'] = filterBhk.value;
      if (filterBathrooms.value.isNotEmpty) {
        params['bathrooms'] = filterBathrooms.value;
      }
      if (filterFacing.value.isNotEmpty) params['facing'] = filterFacing.value;
      if (filterCarParking.value.isNotEmpty) {
        params['carParking'] = filterCarParking.value;
      }
      if (filterFurnishing.value.isNotEmpty) {
        params['furnishing'] = filterFurnishing.value;
      }
      if (filterSubType.value.isNotEmpty) {
        params['subType'] = filterSubType.value;
      }
      if (filterMealsIncluded.value.isNotEmpty) {
        params['mealsIncluded'] = filterMealsIncluded.value;
      }
      if (filterProjectStatus.value.isNotEmpty) {
        params['projectStatus'] = filterProjectStatus.value;
      }
      if (filterTypeOfProperty.value.isNotEmpty) {
        params['typeOfProperty'] = filterTypeOfProperty.value;
      }

      final response = await _repo.discoverProperties(params);

      if (response.isSuccess && response.data != null) {
        if (response.data is List) {
          final list = (response.data as List)
              .map((e) =>
                  PropertyModel.fromJson(e as Map<String, dynamic>))
              .toList();

          if (isLoadMore) {
            properties.addAll(list);
          } else {
            properties.value = list;
          }

          _hasMore = list.length >= _limit;
          if (list.isNotEmpty) _page++;
        } else {
          if (!isLoadMore) properties.clear();
          _hasMore = false;
        }
      } else {
        if (!isLoadMore) properties.clear();
        _hasMore = false;
      }
    } catch (_) {
      if (!isLoadMore) properties.clear();
      _hasMore = false;
    }

    isLoading.value = false;
    isLoadingMore.value = false;
  }

  Future<void> refresh() async {
    _resetAndFetch();
  }

  Future<void> fetchAllForMap() async {
    isMapLoading.value = true;
    try {
      final params = <String, dynamic>{
        'listingType': _listingType,
        'propertyType': currentPropertyType,
        'limit': 200,
      };
      if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
        params['lat'] = LocationService.lat;
        params['lng'] = LocationService.lng;
        params['radius'] = 1500;
      }
      final response = await _repo.discoverProperties(params);
      if (response.isSuccess && response.data is List) {
        mapProperties.value = (response.data as List)
            .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    isMapLoading.value = false;
  }
}
