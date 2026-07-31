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

  /// Selected tab, as a category id. **Null is the leading "All" tab** — every
  /// automotive part, no `categoryId` on the products call.
  ///
  /// Was an index into [level0Categories], which couldn't express "All" (index
  /// 0 meant the first real category) and re-pointed at a different category
  /// whenever the list reordered. An id survives both.
  final RxnString selectedCategoryId = RxnString();

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
    // The two are independent now: the screen opens on "All", which needs no
    // category id, so the product grid no longer waits on the category call to
    // land before it can ask for anything.
    fetchLevel0Categories();
    fetchProductsByCategory();
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
  ///
  /// `?level=0` — the FLAT top-level list, the same request the seller-side
  /// super-category screen makes (`fetchProductsNestedCategory`). Without it
  /// `/categories/nested` returns the whole tree, every level nested under
  /// every root, to build a strip that only ever renders the roots: a payload
  /// many times the size of what is displayed. Drilling into a category is a
  /// separate call when it is needed.
  ///
  /// The cache stays this screen's own (`…AutomotiveDiscoverCategoriesRaw`)
  /// rather than shared with the seller flow — same endpoint, different
  /// lifetime and refresh moment.
  Future<void> fetchLevel0Categories({bool force = false}) async {
    // 1) Cache-first — show tabs from Hive immediately if present.
    final cachedRaw = HiveServices().getAutomotiveDiscoverCategoriesRaw();
    final hasCache = cachedRaw != null && cachedRaw.isNotEmpty;
    if (hasCache) {
      final cached = _parseCategories(cachedRaw);
      if (cached.isNotEmpty) level0Categories.assignAll(cached);
      // 2) …and inside the TTL, stop here. The silent refresh below used to run
      // on EVERY screen open, so the endpoint was hit every time even though
      // the tabs were already painted from Hive and the catalog had not moved.
      // [refreshAll] passes force, so pull-to-refresh still reaches the server.
      if (!force && HiveServices().isAutomotiveDiscoverCategoriesFresh()) {
        return;
      }
    }

    // 3) Network refresh — only show the loader when nothing is on
    // screen yet (cold cache).
    try {
      if (!hasCache) isCategoriesLoading.value = true;
      final ResponseModel res = await _repo
          .productNestedCategoryRepo(queryParams: {ApiKeys.level: 0});
      if (res.isSuccess) {
        final List<dynamic> raw = (res.response?.data is List)
            ? res.response!.data as List
            : const [];
        if (raw.isNotEmpty) {
          await HiveServices().saveAutomotiveDiscoverCategoriesRaw(raw);
          level0Categories.assignAll(_parseCategories(raw));
        }
      }
    } catch (e, s) {
      log('AutomotiveDiscover: fetchLevel0Categories error: $e\n$s');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  /// Switches tab. Null selects "All".
  Future<void> onCategorySelected(String? categoryId) async {
    if (categoryId == selectedCategoryId.value) return;
    selectedCategoryId.value = categoryId;
    await fetchProductsByCategory();
  }

  /// Public, cross-business "products by category" endpoint —
  /// `inventory/public/global-products`, paginated.
  ///
  /// `categoryId` is simply omitted on the "All" tab, which is what makes that
  /// tab every automotive part rather than a fourth thing to special-case.
  Future<void> fetchProductsByCategory({bool isLoadMore = false}) async {
    final categoryId = selectedCategoryId.value;

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
        if (categoryId != null && categoryId.isNotEmpty)
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
  /// selected tab's products from the network. Concurrent — neither depends on
  /// the other's result.
  Future<void> refreshAll() async {
    await Future.wait([
      fetchLevel0Categories(force: true),
      fetchProductsByCategory(),
    ]);
  }
}
