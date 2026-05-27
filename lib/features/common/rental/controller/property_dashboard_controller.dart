import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:get/get.dart';

class PropertyDashboardController extends GetxController {
  final PropertyRepo _repo = PropertyRepo();

  final isStatsLoading = true.obs;
  final isLoading = false.obs;
  final properties = <PropertyModel>[].obs;

  final selectedTab = 0.obs; // 0 = Sell, 1 = Rent
  final selectedCategoryIndex = 0.obs;

  final sellCount = 0.obs;
  final rentCount = 0.obs;

  final sellCategories = <_Category>[].obs;
  final rentCategories = <_Category>[].obs;

  String get _activeListingType => selectedTab.value == 0 ? 'Sell' : 'Rent';

  List<_Category> get _activeCategories =>
      selectedTab.value == 0 ? sellCategories : rentCategories;

  static final _allTypes = [
    ('HouseAndApartment', 'Houses &\nApartments', AppImageAssets.propertyHouseSell),
    ('NewProjectsAndProperties', 'New Projects\n& Properties', AppImageAssets.propertyNewProjectSell),
    ('ShopAndOffices', 'Shops &\nOffices', AppImageAssets.propertyShopOfficeSell),
    ('LandAndPlots', 'Lands &\nPlots', AppImageAssets.propertyLandPlotSell),
    ('PGAndGuestHouse', 'PG &\nGuest House', AppImageAssets.propertyHouseRent),
  ];

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  Future<void> fetchStats() async {
    isStatsLoading.value = true;
    try {
      final response = await _repo.getPropertyStats();
      if (response.isSuccess && response.data != null) {
        _parseStats(response.data);
      }
    } catch (_) {}
    isStatsLoading.value = false;

    if (_activeCategories.isNotEmpty) {
      fetchProperties();
    }
  }

  void _parseStats(Map<String, dynamic> data) {
    final sell = data['Sell'];
    final rent = data['Rent'];

    if (sell != null) {
      sellCount.value = sell['count'] ?? 0;
      sellCategories.value = _extractCategories(sell);
    }
    if (rent != null) {
      rentCount.value = rent['count'] ?? 0;
      rentCategories.value = _extractCategories(rent);
    }
  }

  List<_Category> _extractCategories(Map<String, dynamic> section) {
    final result = <_Category>[];
    for (final t in _allTypes) {
      final cat = section[t.$1];
      if (cat != null && cat['available'] == true && (cat['count'] ?? 0) > 0) {
        result.add(_Category(key: t.$1, label: t.$2, image: t.$3));
      }
    }
    return result;
  }

  void switchTab(int tab) {
    if (tab == selectedTab.value) return;
    selectedTab.value = tab;
    selectedCategoryIndex.value = 0;
    properties.clear();
    if (_activeCategories.isNotEmpty) {
      fetchProperties();
    }
  }

  void selectCategory(int index) {
    if (index == selectedCategoryIndex.value) return;
    selectedCategoryIndex.value = index;
    fetchProperties();
  }

  Future<void> fetchProperties() async {
    final cats = _activeCategories;
    if (cats.isEmpty) return;

    final idx = selectedCategoryIndex.value.clamp(0, cats.length - 1);
    final cat = cats[idx];

    isLoading.value = true;
    try {
      final response = await _repo.getFilteredProperties(
        _activeListingType,
        cat.key,
      );
      if (response.isSuccess && response.data != null) {
        if (response.data is List) {
          properties.value = (response.data as List)
              .map((e) =>
                  PropertyModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          properties.clear();
        }
      } else {
        properties.clear();
      }
    } catch (_) {
      properties.clear();
    }
    isLoading.value = false;
  }

  Future<void> refresh() async {
    await fetchStats();
  }
}

class _Category {
  final String key;
  final String label;
  final String image;

  _Category({required this.key, required this.label, required this.image});
}
