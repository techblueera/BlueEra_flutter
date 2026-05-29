import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/rental/controller/property_filter_registry.dart';
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

  // ── Free-text / range filters (don't fit the chip registry shape) ──
  final city = ''.obs;
  final minPrice = ''.obs;
  final maxPrice = ''.obs;

  // ── Chip-style filters keyed by registry id ──
  // All per-type filters live here. Source of truth: see
  // [propertyFilterRegistry] in property_filter_registry.dart.
  final RxMap<FilterId, String> _filterValues = <FilterId, String>{}.obs;

  /// Read-only snapshot of the currently-applied chip filters. Useful for
  /// hydrating the filter sheet's local working copy.
  Map<FilterId, String> get currentFilterValues =>
      Map<FilterId, String>.unmodifiable(_filterValues);

  String get currentPropertyType =>
      categories[selectedCategoryIndex.value].propertyType;

  String get currentListingType =>
      categories[selectedCategoryIndex.value].listingType;

  /// Filters defined in [propertyFilterRegistry] that are visible under
  /// the current property-type + listing-type combo. The bottom sheet
  /// renders one chip selector per entry.
  List<FilterDef> get visibleFilterDefs => propertyFilterRegistry
      .where((d) => d.showsFor(currentPropertyType, currentListingType))
      .toList();

  void initWithCategories(
      List<PropertyDiscoverCategory> cats, int initialIndex) {
    categories = cats;
    selectedCategoryIndex.value = initialIndex;
    fetchProperties();
  }

  void selectCategory(int index) {
    if (index == selectedCategoryIndex.value) return;
    selectedCategoryIndex.value = index;
    // Drop only the filters that no longer apply under the new
    // category — common ones (listedBy, rating, etc.) persist so the
    // user doesn't have to re-pick them after switching tabs.
    _filterValues.removeWhere((id, _) {
      final def = filterDefById(id);
      if (def == null) return true;
      return !def.showsFor(currentPropertyType, currentListingType);
    });
    _resetAndFetch();
  }

  /// Replaces the entire filter set in one shot. Called by the bottom
  /// sheet's Apply button.
  void applyAllFilters({
    required String cityVal,
    required String min,
    required String max,
    required Map<FilterId, String> filters,
  }) {
    city.value = cityVal;
    minPrice.value = min;
    maxPrice.value = max;
    _filterValues
      ..clear()
      ..addAll(filters);
    _resetAndFetch();
  }

  void clearFilters() {
    city.value = '';
    minPrice.value = '';
    maxPrice.value = '';
    _filterValues.clear();
    _resetAndFetch();
  }

  int get activeFilterCount {
    int count = 0;
    if (city.value.isNotEmpty) count++;
    if (minPrice.value.isNotEmpty || maxPrice.value.isNotEmpty) count++;
    count += _filterValues.length;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  /// Active filters as displayable chips. Price min/max collapse into a
  /// single "₹5000 - ₹50000" entry so the strip stays compact.
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
    for (final entry in _filterValues.entries) {
      list.add(AppliedFilter(
        key: entry.key.name,
        label: chipLabelFor(entry.key, entry.value),
      ));
    }
    return list;
  }

  /// Removes the filter identified by [key] (as returned in
  /// [activeFilters]) and refetches. Unknown keys are a no-op so the
  /// caller doesn't have to defensive-check.
  void removeFilter(String key) {
    if (key == 'city') {
      city.value = '';
    } else if (key == 'price') {
      minPrice.value = '';
      maxPrice.value = '';
    } else {
      FilterId? matched;
      for (final id in FilterId.values) {
        if (id.name == key) {
          matched = id;
          break;
        }
      }
      if (matched == null) return;
      _filterValues.remove(matched);
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
      final params = _buildBaseParams()
        ..addAll({
          'page': _page,
          'limit': _limit,
        });

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

  /// Builds the common request body (category, location, city/price,
  /// and every active chip filter) used by both [fetchProperties] and
  /// [fetchAllForMap]. Centralising it means a new registry filter
  /// instantly works for the map view too.
  Map<String, dynamic> _buildBaseParams() {
    final params = <String, dynamic>{
      'listingType': currentListingType,
      'propertyType': currentPropertyType,
    };

    if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
      params['lat'] = LocationService.lat;
      params['lng'] = LocationService.lng;
      params['radius'] = 1500;
    }

    if (city.value.isNotEmpty) params['city'] = city.value;
    if (minPrice.value.isNotEmpty) {
      params['minPrice'] = int.tryParse(minPrice.value) ?? 0;
    }
    if (maxPrice.value.isNotEmpty) {
      params['maxPrice'] = int.tryParse(maxPrice.value) ?? 0;
    }

    for (final entry in _filterValues.entries) {
      final def = filterDefById(entry.key);
      if (def == null || entry.value.isEmpty) continue;
      // minRating is the one filter whose UI value ("4+") differs
      // from the numeric value the backend wants. Strip the "+" and
      // send a number.
      if (def.id == FilterId.minRating) {
        final n = double.tryParse(entry.value.replaceAll('+', ''));
        if (n != null) params[def.apiKey] = n;
      } else {
        params[def.apiKey] = entry.value;
      }
    }

    return params;
  }

  Future<void> refresh() async {
    _resetAndFetch();
  }

  Future<void> fetchAllForMap() async {
    isMapLoading.value = true;
    try {
      final params = _buildBaseParams()..['limit'] = 200;
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
