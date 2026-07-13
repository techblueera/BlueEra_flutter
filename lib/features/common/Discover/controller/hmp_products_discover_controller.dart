import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:get/get.dart';

/// Consumer-side controller for the **v2 home-made-product** category-discover
/// screen.
///
/// Categories come from the home-made-product **group** API
/// ([ProductController.fetchHomeMadeProductCategories] →
/// `categories/group/homeMadeProduct`). On tab select it fetches the
/// user-owned products for that category via `ProductRepo.fetchProductsRepo`
/// (`ownerType = User`, `categoryId`, paginated).
class HmpProductsDiscoverController extends GetxController {
  final _productRepo = ProductRepo();

  // Reused only for its (cached) home-made-product category list — so we don't
  // refetch categories that another screen already loaded this session.
  final ProductController _categoryCtrl = getOrPut(() => ProductController());

  // ── Category tabs (home-made-product group categories) ──
  final RxList<CollapsibleGridModel> categories = <CollapsibleGridModel>[].obs;
  final RxBool isCategoriesLoading = false.obs;
  final RxInt selectedCategoryIndex = 0.obs;

  // ── Products for the selected category (paginated) ──
  final RxList<GetProductData> products = <GetProductData>[].obs;
  final RxBool isProductsFirstLoading = false.obs;
  final RxBool isProductsLoadingMore = false.obs;
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _ensureCategories();
    if (categories.isNotEmpty) {
      selectedCategoryIndex.value = 0;
      await fetchProductsByCategory();
    }
  }

  /// Cache-first categories: if [ProductController.homeMadeProductCategoryList]
  /// is already populated (loaded earlier this session), reuse it directly
  /// without hitting the API; otherwise fetch once.
  Future<void> _ensureCategories() async {
    if (_categoryCtrl.homeMadeProductCategoryList.isNotEmpty) {
      categories.assignAll(_categoryCtrl.homeMadeProductCategoryList);
      return;
    }
    isCategoriesLoading.value = true;
    try {
      await _categoryCtrl.fetchHomeMadeProductCategories();
      categories.assignAll(_categoryCtrl.homeMadeProductCategoryList);
    } catch (e, s) {
      log('HmpProductsDiscover: fetch categories error: $e\n$s');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  /// The selected category's id (`slugId` carries the category `_id`).
  String? get _selectedCategoryId {
    final i = selectedCategoryIndex.value;
    if (i < 0 || i >= categories.length) return null;
    return categories[i].slugId;
  }

  Future<void> onCategorySelected(int index) async {
    if (index == selectedCategoryIndex.value) return;
    selectedCategoryIndex.value = index;
    await fetchProductsByCategory();
  }

  /// `fetchProductsRepo` filtered by the active category. providerType/owner is
  /// **User** (home-made-product sellers), paginated; `businessId` is NOT sent.
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
        ApiKeys.ownerType: ProviderType.user.title,
        ApiKeys.categoryId: categoryId,
        ApiKeys.page: _page,
        ApiKeys.limit: _limit,
      };
      final res =
          await _productRepo.fetchGlobalProductsRepo(queryParams: queryParams);
      if (res.isSuccess) {
        final model = GetProductModel.fromJson(res.response?.data);
        final newItems = model.data;
        if (!isLoadMore) products.clear();
        if (newItems.isNotEmpty) {
          products.addAll(newItems);
          _page++;
        }
        _hasMore = newItems.length >= _limit;
        log('HmpProductsDiscover: loaded ${newItems.length} | total ${products.length}');
      }
    } catch (e, s) {
      log('HmpProductsDiscover: fetchProductsByCategory error: $e\n$s');
    } finally {
      if (isLoadMore) {
        isProductsLoadingMore.value = false;
      } else {
        isProductsFirstLoading.value = false;
      }
    }
  }

  void onScrollEnd() => fetchProductsByCategory(isLoadMore: true);
}
