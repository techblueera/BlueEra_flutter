import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_nested_category_response.dart';
import 'package:BlueEra/features/me/automotive_products/repo/automotive_product_repo.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:get/get.dart';

/// Consumer-side controller for the automotive category-discover screen.
///
/// Mirrors the HMF discover flow: it loads the level-0 (top-level) nested
/// categories for the sticky tabs, then — on tab select — fetches the
/// public cross-business products for that category via the
/// `inventory/public/global-products` endpoint (paginated).
class AutomotiveDiscoverController extends GetxController {
  final _repo = AutomotiveProductRepo();

  /// Optional business filter — reserved for future use. The global-products
  /// endpoint is cross-business, so it is not sent as a query param today.
  final String? businessId;

  AutomotiveDiscoverController({this.businessId});

  // ── Category tabs (level 0 of the nested category tree) ──
  final RxList<AutomotiveProductNestedCategoryResponse> level0Categories =
      <AutomotiveProductNestedCategoryResponse>[].obs;
  final RxBool isCategoriesLoading = false.obs;
  final RxInt selectedCategoryIndex = 0.obs;

  // ── Products for the selected category (paginated) ──
  final RxList<GetProductData> products = <GetProductData>[].obs;
  final RxBool isProductsFirstLoading = false.obs;
  final RxBool isProductsLoadingMore = false.obs;
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 20;

  @override
  void onInit() {
    super.onInit();
    fetchLevel0Categories();
  }

  String? get _selectedCategoryId {
    final i = selectedCategoryIndex.value;
    if (i < 0 || i >= level0Categories.length) return null;
    return level0Categories[i].sId;
  }

  List<AutomotiveProductNestedCategoryResponse> _parseCategories(
          List<dynamic> raw) =>
      raw
          .whereType<Map>()
          .map((e) => AutomotiveProductNestedCategoryResponse.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();

  /// Loads the level-0 category tabs cache-first: render the locally cached
  /// list instantly (no spinner / no API wait), then silently refresh from
  /// the network and re-cache. The nested-category API only fires once the
  /// cached data is stale or absent on this device.
  Future<void> fetchLevel0Categories() async {
    // 1) Cache-first — show tabs from Hive immediately if present.
    final cachedRaw = HiveServices().getAutomotiveDiscoverCategoriesRaw();
    final hasCache = cachedRaw != null && cachedRaw.isNotEmpty;
    if (hasCache) {
      final cached = _parseCategories(cachedRaw);
      if (cached.isNotEmpty) {
        level0Categories.assignAll(cached);
        selectedCategoryIndex.value = 0;
        // Fire the first category's products off the cached tabs.
        await fetchProductsByCategory();
      }
    }

    // 2) Silent network refresh — only show the loader when nothing is on
    // screen yet (cold cache).
    try {
      if (!hasCache) isCategoriesLoading.value = true;
      final ResponseModel res = await _repo.productNestedCategoryRepo();
      if (res.isSuccess) {
        final List<dynamic> raw = (res.response?.data is List)
            ? res.response!.data as List
            : const [];
        if (raw.isNotEmpty) {
          await HiveServices().saveAutomotiveDiscoverCategoriesRaw(raw);
          final parsed = _parseCategories(raw);
          level0Categories.assignAll(parsed);
          // Only (re)select + (re)fetch products if we didn't already render
          // from cache above — avoids a redundant product fetch on warm start.
          if (!hasCache && level0Categories.isNotEmpty) {
            selectedCategoryIndex.value = 0;
            await fetchProductsByCategory();
          }
        }
      }
    } catch (e, s) {
      log('AutomotiveDiscover: fetchLevel0Categories error: $e\n$s');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> onCategorySelected(int index) async {
    if (index == selectedCategoryIndex.value) return;
    selectedCategoryIndex.value = index;
    await fetchProductsByCategory();
  }

  /// Public, cross-business "products by category" endpoint —
  /// `inventory/public/global-products` filtered by `categoryId`, paginated.
  Future<void> fetchProductsByCategory({bool isLoadMore = false}) async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) return;

    if (isLoadMore) {
      if (isProductsLoadingMore.value || !_hasMore) return;
      isProductsLoadingMore.value = true;
    } else {
      isProductsFirstLoading.value = true;
      _page = 1;
      _hasMore = true;
    }

    try {
      final queryParams = <String, dynamic>{
        'categoryId': categoryId,
        ApiKeys.page: _page,
        ApiKeys.limit: _limit,
      };
      final ResponseModel res =
          await _repo.fetchGlobalProductsRepo(queryParams: queryParams);
      if (res.isSuccess) {
        final model = GetProductModel.fromJson(res.response!.data);
        final List<GetProductData> newItems = model.data;
        if (!isLoadMore) products.clear();
        if (newItems.isNotEmpty) {
          products.addAll(newItems);
          _page++;
        }
        _hasMore = newItems.length >= _limit;
        log('AutomotiveDiscover: loaded ${newItems.length} | total ${products.length}');
      }
    } catch (e, s) {
      log('AutomotiveDiscover: fetchProductsByCategory error: $e\n$s');
    } finally {
      if (isLoadMore) {
        isProductsLoadingMore.value = false;
      } else {
        isProductsFirstLoading.value = false;
      }
    }
  }

  void onScrollEnd() => fetchProductsByCategory(isLoadMore: true);

  /// Explicit pull-to-refresh: re-fetch the category tabs and the currently
  /// selected category's products from the network.
  Future<void> refreshAll() async {
    await fetchLevel0Categories();
    await fetchProductsByCategory();
  }
}
