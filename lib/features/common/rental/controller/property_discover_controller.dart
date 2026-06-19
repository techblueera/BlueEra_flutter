import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
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
  relevance,
  newestFirst,
  priceLowToHigh,
  priceHighToLow,
  pricePerSqftLowToHigh,
  pricePerSqftHighToLow,
}

extension PropertySortByLabel on PropertySortBy {
  /// Long label used inside the sort bottom sheet.
  String get label {
    switch (this) {
      case PropertySortBy.relevance:
        return 'Relevance';
      case PropertySortBy.newestFirst:
        return 'Newest first';
      case PropertySortBy.priceLowToHigh:
        return 'Price Low to High';
      case PropertySortBy.priceHighToLow:
        return 'Price High to Low';
      case PropertySortBy.pricePerSqftLowToHigh:
        return 'Price / sq.ft. : Low to High';
      case PropertySortBy.pricePerSqftHighToLow:
        return 'Price / sq.ft. : High to Low';
    }
  }

  /// Compact label used on the inline sort chip in the filter strip.
  String get chipLabel {
    switch (this) {
      case PropertySortBy.relevance:
        return 'Sort';
      case PropertySortBy.newestFirst:
        return 'Newest';
      case PropertySortBy.priceLowToHigh:
        return 'Price ↑';
      case PropertySortBy.priceHighToLow:
        return 'Price ↓';
      case PropertySortBy.pricePerSqftLowToHigh:
        return '₹/sqft ↑';
      case PropertySortBy.pricePerSqftHighToLow:
        return '₹/sqft ↓';
    }
  }
}

class PropertyDiscoverController extends GetxController {
  final PropertyRepo _repo = PropertyRepo();
  final FetchCache _propertyCache = FetchCache();

  final properties = <PropertyModel>[].obs;
  final mapProperties = <PropertyModel>[].obs;
  final isMapLoading = false.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final selectedCategoryIndex = 0.obs;

  /// Total number of matching properties as reported by the backend
  /// (drives the "N RESULTS" header + the sheet CTA). Falls back to the
  /// number of currently-loaded items until/unless the API sends a
  /// total — see [_readTotalCount].
  final totalCount = 0.obs;

  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;

  List<PropertyDiscoverCategory> categories = [];

  // ── Sort (client-side; reapplied after every page fetch) ──
  final Rx<PropertySortBy> sortBy = PropertySortBy.relevance.obs;

  void setSort(PropertySortBy value) {
    if (sortBy.value == value) return;
    sortBy.value = value;
    _applySort();
  }

  /// Sorts [properties] in place per the current [sortBy]. Called after
  /// each fetch so newly-loaded pages don't always land at the bottom
  /// of a sorted list.
  void _applySort() {
    if (sortBy.value == PropertySortBy.relevance || properties.isEmpty) return;
    final sorted = properties.toList();
    switch (sortBy.value) {
      case PropertySortBy.newestFirst:
        // createdAt is an ISO-8601 string, so a descending lexical sort
        // is also chronologically newest-first. Missing timestamps sink
        // to the bottom.
        sorted.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
      case PropertySortBy.priceLowToHigh:
        sorted.sort((a, b) => _priceFor(a).compareTo(_priceFor(b)));
        break;
      case PropertySortBy.priceHighToLow:
        sorted.sort((a, b) => _priceFor(b).compareTo(_priceFor(a)));
        break;
      case PropertySortBy.pricePerSqftLowToHigh:
        sorted.sort((a, b) => _pricePerSqft(a).compareTo(_pricePerSqft(b)));
        break;
      case PropertySortBy.pricePerSqftHighToLow:
        sorted.sort((a, b) => _pricePerSqft(b).compareTo(_pricePerSqft(a)));
        break;
      case PropertySortBy.relevance:
        return;
    }
    properties.assignAll(sorted);
  }

  /// Numeric price for sorting. priceRange.min / price are strings on the
  /// wire; unparseable values fall back to 0 (sort to the cheap end).
  double _priceFor(PropertyModel p) =>
      num.tryParse(p.priceRange?.min ?? p.price)?.toDouble() ?? 0;

  /// Best-effort numeric area (sq.ft.) pulled from whichever sub-model is
  /// present. The area fields are free-text ("1200 sq.ft.", "1,200"), so
  /// we grab the leading number. Returns 0 when no area is known.
  double _areaFor(PropertyModel p) {
    final raw = p.houseAndApartment?.areaDetails ??
        p.shopAndOffices?.superBuiltupArea ??
        p.newProjectsAndProperties?.area ??
        p.landAndPlots?.plotAreaDetails?.totalArea;
    if (raw == null || raw.isEmpty) return 0;
    final match = RegExp(r'[\d.]+').firstMatch(raw.replaceAll(',', ''));
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }

  /// Price per sq.ft. Properties with an unknown area yield 0 so they
  /// cluster predictably at one end rather than corrupting the order.
  double _pricePerSqft(PropertyModel p) {
    final area = _areaFor(p);
    if (area <= 0) return 0;
    return _priceFor(p) / area;
  }

  // ── Free-text / range filters (don't fit the chip registry shape) ──
  final city = ''.obs;
  final minPrice = ''.obs;
  final maxPrice = ''.obs;

  // ── Chip-style filters keyed by registry id ──
  // All per-type filters live here. Multi-select: each filter maps to
  // the list of chosen option values. Source of truth: see
  // [propertyFilterRegistry] in property_filter_registry.dart.
  final RxMap<FilterId, List<String>> _filterValues =
      <FilterId, List<String>>{}.obs;

  /// Deep-copied snapshot of the currently-applied chip filters. Used to
  /// hydrate the filter sheet's local working copy without letting its
  /// edits mutate the live state until Apply.
  Map<FilterId, List<String>> get currentFilterValues => {
        for (final e in _filterValues.entries)
          e.key: List<String>.from(e.value),
      };

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
    final sig = 'property|$initialIndex';
    if (_propertyCache.isFresh(sig, hasData: properties.isNotEmpty)) return;
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
    required Map<FilterId, List<String>> filters,
  }) {
    city.value = cityVal;
    minPrice.value = min;
    maxPrice.value = max;
    _filterValues
      ..clear()
      ..addAll({
        for (final e in filters.entries)
          if (e.value.isNotEmpty) e.key: List<String>.from(e.value),
      });
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
    // Count each selected option (multi-select) so the badge reflects
    // the total number of picks, like 99acres.
    for (final v in _filterValues.values) {
      count += v.length;
    }
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
      if (entry.value.isEmpty) continue;
      list.add(AppliedFilter(
        key: entry.key.name,
        label: entry.value.map((v) => chipLabelFor(entry.key, v)).join(', '),
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
            _propertyCache.mark('property|${selectedCategoryIndex.value}');
          }
          // Reapply current sort so paged-in items don't always stick
          // to the bottom of a sorted list. No-op when sortBy is none.
          _applySort();

          // Total comes from a sibling field on the response; until the
          // backend sends one we fall back to the loaded count.
          totalCount.value = _readTotalCount(response) ?? properties.length;

          _hasMore = list.length >= _limit;
          if (list.isNotEmpty) _page++;
        } else {
          if (!isLoadMore) properties.clear();
          totalCount.value = 0;
          _hasMore = false;
        }
      } else {
        if (!isLoadMore) properties.clear();
        totalCount.value = 0;
        _hasMore = false;
      }
    } catch (_) {
      if (!isLoadMore) properties.clear();
      totalCount.value = 0;
      _hasMore = false;
    }

    isLoading.value = false;
    isLoadingMore.value = false;
  }

  /// Pulls the total result count out of the response. The backend
  /// hasn't settled on a field name yet, so we probe the common ones
  /// (top-level and nested under `pagination` / `meta`). Returns null
  /// when none are present, letting the caller fall back to the loaded
  /// count. Update the key list here once the API is finalised.
  int? _readTotalCount(ResponseModel response) {
    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    const keys = ['total', 'totalCount', 'totalRecords', 'totalItems', 'count'];
    for (final k in keys) {
      final n = asInt(response.getExtraData(k));
      if (n != null) return n;
    }
    for (final container in ['pagination', 'meta']) {
      final m = response.getExtraData(container);
      if (m is Map) {
        for (final k in keys) {
          final n = asInt(m[k]);
          if (n != null) return n;
        }
      }
    }
    return null;
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
      // send a single number (lowest selected threshold is the most
      // permissive, so pick the min).
      if (def.id == FilterId.minRating) {
        final nums = entry.value
            .map((v) => double.tryParse(v.replaceAll('+', '')))
            .whereType<double>();
        if (nums.isNotEmpty) {
          params[def.apiKey] = nums.reduce((a, b) => a < b ? a : b);
        }
      } else {
        // Multi-select values are sent comma-joined (e.g. "1,2,3").
        params[def.apiKey] = entry.value.join(',');
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
