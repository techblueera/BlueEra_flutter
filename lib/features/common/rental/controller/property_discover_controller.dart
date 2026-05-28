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

/// One applied filter, rendered as a removable chip in the filter strip.
/// [key] is the stable id passed back to [PropertyDiscoverController.removeFilter].
class AppliedFilter {
  final String key;
  final String label;
  const AppliedFilter({required this.key, required this.label});
}

/// Sort options surfaced in the discover screen's sort sheet. Applied
/// client-side over the currently-loaded [PropertyDiscoverController.properties]
/// list — backend doesn't accept a sort param yet, so the order is
/// reapplied after each page load so newly-appended items slot in
/// correctly instead of always landing at the bottom.
enum PropertySortBy {
  none,
  priceLowToHigh,
  distanceNearToFar,
  ratingHighToLow,
}

extension PropertySortByLabel on PropertySortBy {
  /// Long label used inside the sort bottom sheet.
  String get label {
    switch (this) {
      case PropertySortBy.none:
        return 'Default';
      case PropertySortBy.priceLowToHigh:
        return 'Price: Low to High';
      case PropertySortBy.distanceNearToFar:
        return 'Distance: Near to Far';
      case PropertySortBy.ratingHighToLow:
        return 'Rating: High to Low';
    }
  }

  /// Compact label used on the inline sort chip in the filter strip.
  String get chipLabel {
    switch (this) {
      case PropertySortBy.none:
        return 'Sort';
      case PropertySortBy.priceLowToHigh:
        return 'Price ↑';
      case PropertySortBy.distanceNearToFar:
        return 'Distance ↑';
      case PropertySortBy.ratingHighToLow:
        return 'Rating ↓';
    }
  }
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

  // ── Sort (client-side; reapplied after every page fetch) ──
  final Rx<PropertySortBy> sortBy = PropertySortBy.none.obs;

  void setSort(PropertySortBy value) {
    if (sortBy.value == value) return;
    sortBy.value = value;
    _applySort();
  }

  /// Sorts [properties] in place per the current [sortBy]. Called after
  /// each fetch so newly-loaded pages don't always land at the bottom
  /// of a sorted list.
  void _applySort() {
    if (sortBy.value == PropertySortBy.none || properties.isEmpty) return;
    final sorted = properties.toList();
    switch (sortBy.value) {
      case PropertySortBy.priceLowToHigh:
        sorted.sort((a, b) {
          final ap = a.priceRange?.min ?? a.price;
          final bp = b.priceRange?.min ?? b.price;
          return ap.compareTo(bp);
        });
        break;
      case PropertySortBy.distanceNearToFar:
        sorted.sort(
            (a, b) => _sortDistanceFor(a).compareTo(_sortDistanceFor(b)));
        break;
      case PropertySortBy.ratingHighToLow:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case PropertySortBy.none:
        return;
    }
    properties.assignAll(sorted);
  }

  /// Squared-degree distance from the user's current location to [p].
  /// Squared (not sqrt'd) because we only need ordering, not real km —
  /// keeps it cheap. Properties with no coordinates or no known user
  /// location sink to the bottom via [double.infinity].
  double _sortDistanceFor(PropertyModel p) {
    final userLat = LocationService.lat;
    final userLng = LocationService.lng;
    if (userLat == 0.0 && userLng == 0.0) return double.infinity;
    final coords = p.location?.coordinates ?? const <double>[];
    if (coords.length < 2) return double.infinity;
    final dLat = coords[1] - userLat;
    final dLng = coords[0] - userLng;
    return (dLat * dLat) + (dLng * dLng);
  }

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

  /// Active filters as displayable chips. Price min/max collapse into a
  /// single "5000 - 50000" entry so the strip stays compact.
  List<AppliedFilter> get activeFilters {
    final list = <AppliedFilter>[];
    if (city.value.isNotEmpty) {
      list.add(AppliedFilter(key: 'city', label: city.value));
    }
    if (minPrice.value.isNotEmpty || maxPrice.value.isNotEmpty) {
      final min = minPrice.value;
      final max = maxPrice.value;
      final String range;
      if (min.isNotEmpty && max.isNotEmpty) {
        range = '₹$min - ₹$max';
      } else if (min.isNotEmpty) {
        range = 'Min ₹$min';
      } else {
        range = 'Max ₹$max';
      }
      list.add(AppliedFilter(key: 'price', label: range));
    }
    if (filterBhk.value.isNotEmpty) {
      list.add(AppliedFilter(key: 'bhk', label: '${filterBhk.value} BHK'));
    }
    if (filterBathrooms.value.isNotEmpty) {
      list.add(AppliedFilter(
          key: 'bathrooms', label: '${filterBathrooms.value} Bath'));
    }
    if (filterFacing.value.isNotEmpty) {
      list.add(AppliedFilter(key: 'facing', label: filterFacing.value));
    }
    if (filterCarParking.value.isNotEmpty) {
      list.add(AppliedFilter(
          key: 'carParking', label: '${filterCarParking.value} Parking'));
    }
    if (filterFurnishing.value.isNotEmpty) {
      list.add(
          AppliedFilter(key: 'furnishing', label: filterFurnishing.value));
    }
    if (filterSubType.value.isNotEmpty) {
      list.add(AppliedFilter(key: 'subType', label: filterSubType.value));
    }
    if (filterMealsIncluded.value.isNotEmpty) {
      list.add(AppliedFilter(
          key: 'mealsIncluded',
          label: filterMealsIncluded.value == 'Yes Included'
              ? 'Meals Included'
              : 'No Meals'));
    }
    if (filterProjectStatus.value.isNotEmpty) {
      list.add(AppliedFilter(
          key: 'projectStatus', label: filterProjectStatus.value));
    }
    if (filterTypeOfProperty.value.isNotEmpty) {
      list.add(AppliedFilter(
          key: 'typeOfProperty', label: filterTypeOfProperty.value));
    }
    return list;
  }

  /// Removes the filter identified by [key] (as returned in
  /// [activeFilters]) and refetches. Unknown keys are a no-op so the
  /// caller doesn't have to defensive-check.
  void removeFilter(String key) {
    switch (key) {
      case 'city':
        city.value = '';
        break;
      case 'price':
        minPrice.value = '';
        maxPrice.value = '';
        break;
      case 'bhk':
        filterBhk.value = '';
        break;
      case 'bathrooms':
        filterBathrooms.value = '';
        break;
      case 'facing':
        filterFacing.value = '';
        break;
      case 'carParking':
        filterCarParking.value = '';
        break;
      case 'furnishing':
        filterFurnishing.value = '';
        break;
      case 'subType':
        filterSubType.value = '';
        break;
      case 'mealsIncluded':
        filterMealsIncluded.value = '';
        break;
      case 'projectStatus':
        filterProjectStatus.value = '';
        break;
      case 'typeOfProperty':
        filterTypeOfProperty.value = '';
        break;
      default:
        return;
    }
    _resetAndFetch();
  }

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
          // Reapply current sort so paged-in items don't always stick
          // to the bottom of a sorted list. No-op when sortBy is none.
          _applySort();

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
