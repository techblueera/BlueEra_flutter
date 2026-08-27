import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/me/manufacturer/model/manufacturer_category_inventory_model.dart';
// `show` keeps `ManufacturerVariant` / `ManufacturerProductFeature` from this module out of the
// namespace — they conflict with the same names from
// `product_catalog_response.dart` below.
import 'package:BlueEra/features/me/product/model/get_product_model.dart'
    show GetProductData, GetProductModel, Variant;
import 'package:BlueEra/features/me/manufacturer/model/manufacturer_product_catalog_response.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/manufacturer/model/manufacturer_product_model.dart';
import 'package:BlueEra/features/me/manufacturer/model/manufacturer_product_snap_search_response.dart';
import 'package:BlueEra/features/me/manufacturer/repo/manufacturer_product_repo.dart';
import 'package:BlueEra/features/me/manufacturer/service/manufacturer_local_store.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_variant_dialog.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerInventoryController extends GetxController {
  Rx<ApiResponse> ownDraftAndPublicProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> searchProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cloneVariantProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteProductVariantResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> suggestedProductResponse = ApiResponse.initial('Initial').obs;

  final TextEditingController searchController = TextEditingController();
  
  bool productDataNeedsRefresh = false;
  RxBool isLoading = false.obs;
  RxBool isProductLoading = false.obs;
  RxString selectedFilter = AppStrings.draft.obs;
  RxList<ManufacturerProductModel> products = <ManufacturerProductModel>[].obs;
  RxList<ManufacturerProductModel> filteredProducts = <ManufacturerProductModel>[].obs;
  RxList<ManufacturerCategoryInventoryModel> categories = <ManufacturerCategoryInventoryModel>[].obs;
  RxList<ManufacturerCategoryInventoryModel> filteredCategories = <ManufacturerCategoryInventoryModel>[].obs;

  RxBool isMenuOpen = false.obs;

  final List<String> productTab = [
    AppStrings.all,
    AppStrings.live,
    AppStrings.draft,
    AppStrings.outOfStock
  ];
  RxInt selectedProductIndex = 0.obs;

  RxList<GetProductData> allProducts = <GetProductData>[].obs;

  RxBool isAllProductsLoadingMore = false.obs;
  int _allProductsPage = 1;
  bool _allProductsHasMore = true;
  static const int _allProductsLimit = 20;
  static const int ownProductsPreviewLimit = 20;

  bool get allProductsHasMore => _allProductsHasMore;

  // final RxList<ProductItem> selectedProducts = <ProductItem>[].obs;
  final int maxSelectionLimit = 10;
  final RxBool showErrorBanner = false.obs;

  /// Search debounce timer
  Timer? _searchDebounce;
  final RxString searchProduct = ''.obs;
  final RxBool ProductSearchLoading = false.obs;

  final RxBool cloneProductVariantLoading = false.obs;

  /// Loading flag for [createNewProductVariantApi] — mirrors grocery's
  /// `isCreateNewGroceryProductNewVariantLoading`.
  final RxBool isCreateNewProductVariantLoading = false.obs;
  int page = 1;
  int limit = 10;
  bool hasMoreData = true;
  bool isLoadingMore = false;

  RxInt businessCardsSelectedIndex = 0.obs;

  RxList<ManufacturerSelectedVariant> searchProductVariantsList = <ManufacturerSelectedVariant>[].obs;

  final variantSelection = <String, bool>{}.obs;
  final variantSellingPrice = <String, String>{}.obs;
  RxList<ManufacturerSelectedVariant> selectedVariantsList = <ManufacturerSelectedVariant>[].obs;

  final viewProfileController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  final viewIndividualProfileController = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  bool isVariantSelected(String id) => variantSelection[id] ?? false;
  String? getUpdatedPrice(String id) => variantSellingPrice[id];
  bool hasAnySelected() {
    return variantSelection.values.any((isSelected) => isSelected);
  }

  void toggleVariant(String id) {
    final currentlySelected = variantSelection.entries
        .where((e) => e.value == true)
        .length;

    final isSelected = variantSelection[id] ?? false;

    if (!isSelected && currentlySelected >= maxSelectionLimit) {
      log("Cannot select more than 10 variants");
      showErrorBanner.value = true;
      return;
    }

    showErrorBanner.value = false;
    variantSelection[id] = !isSelected;

    if (!isSelected) {
      // was not selected, now selected — will be added via toggleVariantWithData
    } else {
      selectedVariantsList.removeWhere((v) => v.id == id);
    }
    log('id-- $id  selected=${variantSelection[id]}');
  }

  void toggleVariantWithData(ManufacturerSelectedVariant selected) {
    final id = selected.id;
    final isSelected = variantSelection[id] ?? false;

    final currentlySelected = variantSelection.entries
        .where((e) => e.value == true)
        .length;

    if (!isSelected && currentlySelected >= maxSelectionLimit) {
      log("Cannot select more than 10 variants");
      showErrorBanner.value = true;
      return;
    }

    showErrorBanner.value = false;

    if (isSelected) {
      variantSelection[id] = false;
      selectedVariantsList.removeWhere((v) => v.id == id);
    } else {
      variantSelection[id] = true;
      selectedVariantsList.add(selected);
    }
  }

  void updateSellingPrice(String id, String value) {
    variantSellingPrice[id] = value;
    refresh();
  }


  int suggestedProductPage = 1;
  RxBool isSuggestedProductFirstLoading = false.obs;
  RxBool isSuggestedProductLoadingLoadingMore = false.obs;
  bool suggestedProductHasMoreData = true;
  RxList<ManufacturerSelectedVariant> suggestedProductList = <ManufacturerSelectedVariant>[].obs;

  // ── ManufacturerProduct Nested Category With Inventory ──────────────────────────────────
  Rx<ApiResponse> fetchProductCategoryResponse = ApiResponse.initial('Initial').obs;
  RxBool myProductLoading = true.obs;
  RxList<ProductCategoryWithInventoryModel> productNestedCategoryList = <ProductCategoryWithInventoryModel>[].obs;
  RxBool productNestedCategoryLoading = false.obs;

  /// Freshness guard for [fetchAllProductData], keyed per store so visiting
  /// another manufacturer's catalog never reuses this one's data.
  final FetchCache _allProductCache = FetchCache();

  /// Load category + products only when not already loaded & fresh for this
  /// store. Use on tab open / screen (re)entry; call [fetchAllProductData] to
  /// force (pull-to-refresh, post-publish). Mirrors the product and automotive
  /// controllers.
  /// Three layers, cheapest first:
  /// 1. [_allProductCache] — same store, fetched < 5 min ago, still in memory.
  /// 2. [ManufacturerLocalStore] — the saved snapshot. **If there is one, that
  ///    is the answer and no request is made.**
  /// 3. The network — only when nothing is saved.
  ///
  /// The snapshot is not a head start on a request; it replaces the request.
  /// What keeps it honest is that every write the merchant makes (publish,
  /// price edit, delete, stock toggle) runs [markInventoryChanged], which
  /// refetches and rewrites it — so the only way to be looking at stale stock
  /// is for it to have changed somewhere other than this device, and
  /// pull-to-refresh on the tab is the escape hatch for that.
  Future<void> fetchAllProductDataIfNeeded({String? visitBusinessId}) async {
    final sig = 'allProduct|${visitBusinessId ?? 'self'}';
    final hasData =
        productNestedCategoryList.isNotEmpty || allProducts.isNotEmpty;
    if (_allProductCache.isFresh(sig, hasData: hasData)) return;

    if (await _hydrateProductDataFromCache(visitBusinessId)) {
      // Stamped so a tab switch doesn't go back to disk either.
      _allProductCache.mark(sig);
      return;
    }
    await fetchAllProductData(visitBusinessId: visitBusinessId);
  }

  Future<void> fetchAllProductData({
    String? visitBusinessId,
    bool silent = false,
  }) async {
    try {
      if (!silent) myProductLoading.value = true;
      await Future.wait([
        fetchProductCategoryWithInventory(
            visitBusinessId: visitBusinessId, silent: silent),
        fetchBusinessProducts(visitBusinessId: visitBusinessId, silent: silent),
      ]);
      // Stamp freshness only once BOTH lists actually loaded.
      //
      // Categories alone used to be enough, and that is what stranded the tab:
      // `hasData` on the guard is an OR across the two lists, so a run where
      // the categories landed and the top-selling request did not stamped the
      // guard anyway — and every later entry then took the early return and
      // never retried the half that failed, leaving its shimmer running.
      //
      // COMPLETE means the REQUEST succeeded, not that rows came back, so an
      // empty catalogue still stamps and still gets its 5-minute reuse.
      if (fetchProductCategoryResponse.value.status == Status.COMPLETE &&
          ownDraftAndPublicProductResponse.value.status == Status.COMPLETE) {
        _allProductCache.mark('allProduct|${visitBusinessId ?? 'self'}');
      }
    } catch (e) {
      log('Error fetching product data: $e');
    } finally {
      if (!silent) myProductLoading.value = false;
    }
  }

  /// Paints the Products tab from the last saved snapshot.
  ///
  /// Returns true only when something was actually restored — false sends the
  /// caller to the network. Deliberately tolerant: a snapshot that fails to
  /// parse (a model changed shape since it was written) counts as a miss, so a
  /// bad cache degrades into a normal fetch rather than an error the user sees.
  ///
  /// Both lists must restore for this to report success. Restoring one and
  /// declaring victory would leave the other permanently empty, since a `true`
  /// return means no request is made.
  Future<bool> _hydrateProductDataFromCache(String? visitBusinessId) async {
    // Owner scope only. A visitor browsing someone else's store has no way to
    // invalidate a snapshot — they can't publish, edit or restock anything — so
    // a cache-first read with no revalidation would freeze that store's shelf
    // on their device indefinitely. Their fetches stay live (in-memory guard
    // only), exactly as before.
    if (visitBusinessId != null || userId.isEmpty) return false;

    List<ProductCategoryWithInventoryModel>? categories;
    List<GetProductData>? topSelling;
    try {
      final entry = await ManufacturerLocalStore.readCategories(userId,
          otherStore: false);
      if (entry != null && !entry.isEmpty) {
        categories = _parseProductCategories(entry.items);
      }
    } catch (e) {
      log('manufacturer: category cache hydrate failed — $e');
    }
    try {
      final entry = await ManufacturerLocalStore.readTopSelling(userId,
          otherStore: false);
      if (entry != null && !entry.isEmpty) {
        topSelling = GetProductModel.fromJson({'data': entry.items}).data;
      }
    } catch (e) {
      log('manufacturer: top-selling cache hydrate failed — $e');
    }

    // Half a snapshot is not a snapshot: publish nothing unless both sides
    // restored, or the missing list would stay empty with no request coming.
    if (categories == null ||
        categories.isEmpty ||
        topSelling == null ||
        topSelling.isEmpty) {
      return false;
    }

    productNestedCategoryList.value = categories;
    fetchProductCategoryResponse.value = ApiResponse.complete();

    allProducts.value = topSelling;
    // The snapshot only ever holds page 1, so "load more" resumes at page 2 —
    // and a short page means the server had nothing after it.
    _allProductsPage = 2;
    _allProductsHasMore = topSelling.length >= _allProductsLimit;
    ownDraftAndPublicProductResponse.value = ApiResponse.complete();
    return true;
  }

  /// Called after any inventory write (publish / clone / add variant / edit
  /// price / delete / stock toggle) that the merchant just made.
  ///
  /// The sheets already patch their own models in place, so the screen is
  /// correct the moment the call returns. What this fixes is everything the
  /// patch cannot reach: the 5-minute freshness guard that would otherwise
  /// short-circuit the next tab entry, and the disk snapshot, which must never
  /// outlive the change that invalidated it.
  ///
  /// The snapshot is **deleted** and then rebuilt from a refetch rather than
  /// edited in place — editing it would mean re-implementing every mutation
  /// against a second data shape. Deleting first is also what makes the race
  /// safe: the merchant can be back on the tab before the refetch resolves, and
  /// with the old snapshot still on disk that re-entry would hydrate the
  /// pre-mutation list and stamp it fresh.
  void markInventoryChanged() {
    productDataNeedsRefresh = true;
    _allProductCache.invalidate();
    allProducts.refresh();
    productNestedCategoryList.refresh();

    if (userId.isEmpty) return;
    // Fire-and-forget: the caller is a sheet closing on a completed write, or a
    // publish popping back, and nothing on screen is waiting for this.
    unawaited(ManufacturerLocalStore.clearStore(userId).then(
      (_) => fetchAllProductData(silent: true),
    ));
  }

  /// Rebuilds the category-with-inventory rows from raw API JSON — the one
  /// parser for both a live response and the saved snapshot.
  List<ProductCategoryWithInventoryModel> _parseProductCategories(
          List<dynamic> rawList) =>
      rawList
          .whereType<Map>()
          .map((e) => ProductCategoryWithInventoryModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();

  /// [silent] keeps the currently rendered list on screen while the call runs —
  /// used when the tab was hydrated from disk, or refreshed after a write, so
  /// the content never flashes back to a skeleton it has already moved past.
  Future<void> fetchProductCategoryWithInventory({
    String? visitBusinessId,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        fetchProductCategoryResponse.value = ApiResponse.initial('Initial');
      }

      ResponseModel response;
      if(visitBusinessId!=null){
        response = await ManufacturerProductRepo().fetchPublicProductCategoryWithInventoryRepo();
      }else{
        response = await ManufacturerProductRepo().fetchProductCategoryWithInventoryRepo();
      }

      if (response.isSuccess) {
        fetchProductCategoryResponse.value = ApiResponse.complete(response);
        // API returns either a flat list of categories or a legacy
        // `{data: [...]}` envelope. Handle both so old/new shapes work.
        final raw = response.response?.data;
        final List<dynamic> rawList = raw is List
            ? raw
            : (raw is Map && raw['data'] is List
                ? List<dynamic>.from(raw['data'] as List)
                : const <dynamic>[]);
        productNestedCategoryList.value = _parseProductCategories(rawList);

        // Persist the raw payload, not the parsed models: the next open rebuilds
        // them with this same `fromJson`, so there is one parser to keep right.
        // Owner scope only — see [_hydrateProductDataFromCache].
        if (visitBusinessId == null && userId.isNotEmpty) {
          unawaited(ManufacturerLocalStore.writeCategories(
            userId,
            otherStore: false,
            items: rawList,
          ));
        }

        log("Loaded ${productNestedCategoryList.length} product categories");
      } else {
        // A failed SILENT refresh must not replace what the user is reading
        // with an error — the hydrated list stays, and the guard was already
        // left un-stamped so the next entry retries. The exception is a status
        // that never resolved; see [_resolveCategoryFailure].
        _resolveCategoryFailure(silent: silent);
      }
    } catch (e) {
      _resolveCategoryFailure(silent: silent);
      log("ERROR fetching product categories: $e");
    }
  }

  /// Records a failed category fetch.
  ///
  /// A silent refresh normally leaves the status alone — that is the point of
  /// `silent`: keep the rendered rows and their COMPLETE state while
  /// replacements are fetched, so the tab doesn't blink. **But a status that
  /// has never resolved is not worth protecting.** The Products tab renders
  /// its shimmer on `Status.INITIAL`, so a silent failure over an unresolved
  /// status left that shimmer running with nothing scheduled to stop it. Same
  /// failure mode the food tab was fixed for; see
  /// `FoodMainScreen._fetchProductsTab`.
  void _resolveCategoryFailure({required bool silent}) {
    final unresolved =
        fetchProductCategoryResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      fetchProductCategoryResponse.value = ApiResponse.error('error');
    }
  }

  /// Top-selling counterpart of [_resolveCategoryFailure].
  void _resolveBusinessProductsFailure({required bool silent}) {
    final unresolved =
        ownDraftAndPublicProductResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
    }
  }

  // ── ManufacturerProduct By Category (Paginated) ────────────────────────────────
  final selectedProductCategoryData =
      Rxn<ProductCategoryWithInventoryModel>();
  RxList<GetProductData> productsByCategoryList = <GetProductData>[].obs;
  RxBool isProductByCategoryFirstLoading = false.obs;
  RxBool isProductByCategoryLoadingMore = false.obs;
  int productByCategoryPage = 1;
  bool productByCategoryHasMore = true;
  int productByCategoryPageLimit = 20;
  RxBool isProductSearchOpen = false.obs;
  RxInt selectedProductHorizontalTabIndex = 0.obs;

  Future<void> fetchProductsByCategory({
    required String categoryId,
    String? visitBusinessId,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isProductByCategoryLoadingMore.value || !productByCategoryHasMore) return;
      isProductByCategoryLoadingMore.value = true;
    } else {
      isProductByCategoryFirstLoading.value = true;
      productByCategoryPage = 1;
      productByCategoryHasMore = true;
    }

    try {
      Map<String, dynamic> queryParams = {
        'ownerType': ProviderType.business.title,
        'businessId': visitBusinessId ?? userId,
        'categoryId': categoryId,
        ApiKeys.page: productByCategoryPage,
        ApiKeys.limit: productByCategoryPageLimit,
      };

      final response = await ManufacturerProductRepo().fetchProductsRepo(queryParams: queryParams);

      if (response.isSuccess) {
        final getOwnProductModel = GetProductModel.fromJson(response.response!.data);
        final List<GetProductData> newItems = getOwnProductModel.data;

        if (!isLoadMore) {
          productsByCategoryList.clear();
        }

        if (newItems.isNotEmpty) {
          productsByCategoryList.addAll(newItems);
          productByCategoryPage++;
        }

        productByCategoryHasMore = newItems.length >= productByCategoryPageLimit;

        log("Loaded ${newItems.length} items | Total: ${productsByCategoryList.length}");
      }
    } catch (e, s) {
      log('Error fetching products by category: $e\n$s');
    } finally {
      if (isLoadMore) {
        isProductByCategoryLoadingMore.value = false;
      } else {
        isProductByCategoryFirstLoading.value = false;
      }
    }
  }

  // ── ManufacturerProduct Snap Search ──────────────────────────────────────────────
  final List<Map<String, String>> productSnapSearchConfig = [
    {
      'title': 'Upload Photo',
      'icon': AppIconAssets.cameraAddOutlineIcon,
      'image': AppImageAssets.groceryImageFirst,
    },
    {
      'title': 'Search Manually',
      'icon': AppIconAssets.search,
      'image': AppImageAssets.groceryImageSecond,
    },
  ];

  final RxMap<String, File?> productSnapSearchImagesMap = <String, File?>{}.obs;
  Rx<ApiResponse> productSnapSearchResponse = ApiResponse.initial('Initial').obs;
  RxList<ManufacturerSelectedVariant> snapSearchProductList = <ManufacturerSelectedVariant>[].obs;
  Rxn<ManufacturerProductSnapSearchData> productSnapSearchData = Rxn<ManufacturerProductSnapSearchData>();

  Future<void> addProductImagesBySlot(String title) async {
    if (productSnapSearchImagesMap.values.any((v) => v != null)) {
      commonSnackBar(message: "Please remove the current image before selecting another type.");
      return;
    }

    final List<String>? selectedImages =
        await PhotoPickerService.pickMultiplePhotos(Get.context!, title);
    if (selectedImages == null || selectedImages.isEmpty) return;

    productSnapSearchImagesMap[title] = File(selectedImages.first);
    fetchProductSnapSearchApi();
  }

  void removeProductImageBySlot(String title) {
    productSnapSearchImagesMap[title] = null;
    productSnapSearchImagesMap.refresh();
    snapSearchProductList.clear();
    productSnapSearchData.value = null;
    productSnapSearchResponse.value = ApiResponse.initial('Initial');
  }

  Future<void> fetchProductSnapSearchApi() async {
    final List<File> activeImages = productSnapSearchImagesMap.values
        .where((file) => file != null)
        .cast<File>()
        .toList();

    if (activeImages.isEmpty) {
      commonSnackBar(message: "Please upload at least 1 photo");
      return;
    }

    try {
      productSnapSearchResponse.value = ApiResponse.loading('Loading');
      snapSearchProductList.clear();
      productSnapSearchData.value = null;

      List<dio.MultipartFile> imageByPart = [];
      for (final image in activeImages) {
        final fileName = image.path.split('/').last;
        imageByPart.add(
          await dio.MultipartFile.fromFile(image.path, filename: fileName),
        );
      }

      Map<String, dynamic> params = {
        ApiKeys.images: imageByPart,
      };

      final responseModel =
          await ManufacturerProductRepo().fetchProductSnapSearchRepo(params: params);

      if (responseModel.isSuccess) {
        productSnapSearchResponse.value = ApiResponse.complete(responseModel);

        final response = ManufacturerProductSnapSearchResponseModel.fromJson(
          responseModel.response?.data,
        );
        productSnapSearchData.value = response.data;

        final foundItems = response.data?.foundProducts ?? [];
        final rows = <ManufacturerSelectedVariant>[];
        for (final item in foundItems) {
          final product = item.product;
          if (product == null) continue;
          for (final v in product.variants) {
            rows.add(ManufacturerSelectedVariant(product: product, variant: v));
          }
        }
        snapSearchProductList.assignAll(rows);
      } else {
        productSnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      productSnapSearchResponse.value = ApiResponse.error('error');
      log("ManufacturerProduct Snap Search Error: $s");
    }
  }

  // final suggestedProductVariantSelection = <String, bool>{}.obs;
  // final suggestedProductVariantSellingPrice = <String, String>{}.obs;

  // bool isSuggestedProductVariantSelected(String id) => suggestedProductVariantSelection[id] ?? false;
  // String? getSuggestedProductUpdatedPrice(String id) => suggestedProductVariantSellingPrice[id];
  // bool hasAnySelectedSuggestedProduct() {
  //   return suggestedProductVariantSelection.values.any((isSelected) => isSelected);
  // }
  //
  // void toggleSuggestedProductVariant(String id) {
  //   final currentlySelected = suggestedProductVariantSelection.entries
  //       .where((e) => e.value == true)
  //       .length;
  //
  //   final isSelected = suggestedProductVariantSelection[id] ?? false;
  //
  //   if (!isSelected && currentlySelected >= maxSelectionLimit) {
  //     log("Cannot select more than 10 variants");
  //     commonSnackBar(message: AppStrings.cannotSelectMoreThanTenVariants);
  //     return;
  //   }
  //
  //   suggestedProductVariantSelection[id] = !isSelected;
  //   log('id-- $id  selected=${suggestedProductVariantSelection[id]}');
  // }
  //
  // void updateSuggestedProductSellingPrice(String id, String value) {
  //   suggestedProductVariantSellingPrice[id] = value;
  //   refresh();
  // }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(Get.context!).unfocus();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// [silent] keeps the rendered list on screen while the call runs (hydrated
  /// from disk, or refreshed after a write) instead of blinking back to a
  /// skeleton — see [fetchProductCategoryWithInventory].
  Future<void> fetchBusinessProducts({
    String? visitBusinessId,
    bool? isDiscountedProducts,
    bool isLoadMore = false,
    bool silent = false,
  }) async {

    try {
      if (isLoadMore) {
        // Guard against duplicate/overlapping load-more calls and stop
        // once the server has reported there are no more pages.
        if (!_allProductsHasMore ||
            isAllProductsLoadingMore.value ||
            ownDraftAndPublicProductResponse.value.status == Status.INITIAL) {
          return;
        }
        isAllProductsLoadingMore.value = true;
      } else {
        // Paging always restarts, but a silent refresh keeps the rendered rows
        // until the replacements arrive — clearing here is what would make the
        // list blink on every hydrate and after every write.
        _allProductsPage = 1;
        _allProductsHasMore = true;
        if (!silent) {
          ownDraftAndPublicProductResponse.value =
              ApiResponse.initial('Initial');
          isLoading.value = true;
          isProductLoading.value = true;
          allProducts.clear();
        }
      }

      final Map<String, dynamic> queryParams = {
        ApiKeys.ownerType: ProviderType.business.title,
      };
      if(visitBusinessId!=null) queryParams[ApiKeys.businessId] = visitBusinessId;
      if(isDiscountedProducts!=null) queryParams[ApiKeys.isDiscounted] = isDiscountedProducts;
      queryParams[ApiKeys.page] = _allProductsPage;
      queryParams[ApiKeys.limit] = _allProductsLimit;

      final response = await ManufacturerProductRepo()
          .fetchProductsRepo(queryParams: queryParams);
      if (response.isSuccess) {
        ownDraftAndPublicProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel =
            GetProductModel.fromJson(response.response!.data);
        final List<GetProductData> products = getOwnProductModel.data;

        if (isLoadMore) {
            allProducts.addAll(products);
        } else {
            allProducts.assignAll(products);
            // Page 1 of the UNFILTERED owner list only — that is exactly what
            // the tab renders. The `isDiscountedProducts` variant writes into
            // this same list from the "view all top selling" screen, and
            // caching that filtered payload would replay it as the merchant's
            // whole catalogue on the next open.
            if (visitBusinessId == null &&
                isDiscountedProducts == null &&
                userId.isNotEmpty) {
              final raw = response.response?.data;
              final rawItems = (raw is Map && raw['data'] is List)
                  ? raw['data'] as List
                  : const [];
              unawaited(ManufacturerLocalStore.writeTopSelling(
                userId,
                otherStore: false,
                items: rawItems,
              ));
            }
          }
          if (products.isNotEmpty) {
            _allProductsPage++;
          }
          // Backend returned fewer than a full page → no more pages.
          if (products.length < _allProductsLimit) {
            _allProductsHasMore = false;
          }

      } else {
        print("API failed with status: ${response.statusCode}");
        _resolveBusinessProductsFailure(silent: silent);
      }
    } catch (e, s) {
      print("stack trace: $s");
      _resolveBusinessProductsFailure(silent: silent);
    } finally {
      if (isLoadMore) {
        isAllProductsLoadingMore.value = false;
      } else {
        isLoading.value = false;
        isProductLoading.value = false;
      }
    }
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    // searchResults.clear();
    searchProduct.value = '';
  }

  /// Search method
  void onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      variantSelection.clear();
      variantSellingPrice.clear();
      showErrorBanner.value = false;
      if (query.trim().isEmpty) {
        clearSearch();
      } else {
        fetchListOfSearchProductApi(query.trim());
      }
    });
  }

  Future<void> fetchListOfSearchProductApi(String keyword, {bool isLoadMore = false}) async {
    if(keyword.length < 3) return;

    searchProduct.value = keyword;

    if (isLoadingMore) return;

    try {
      if (!isLoadMore) {
        page = 1;
        hasMoreData = true;
        searchProductVariantsList.clear();
        ProductSearchLoading.value = true;
      } else {
        isLoadingMore = true;
        log('loading more -- $isLoadMore');
      }

      Map<String, dynamic> params = {
        ApiKeys.key: keyword,
        ApiKeys.page: page,
        ApiKeys.limit: limit,
      };

      final responseModel = await ManufacturerProductRepo().fetchSearchProductViaCategoryRepo(queryParams: params);

      if (responseModel.isSuccess) {
        searchProductResponse.value = ApiResponse.complete(responseModel);

        final parsed = ManufacturerProductCatalogResponse.fromJson(
          responseModel.response?.data,
        );

        final newRows = flattenProducts(parsed.data);

        // Maintain a map for uniqueness (by variant id).
        final Map<String, ManufacturerSelectedVariant> uniqueById = {
          for (final item in searchProductVariantsList) item.id: item,
        };

        if (!isLoadMore) {
          // For first load → clear existing
          uniqueById.clear();
        }

        for (final item in newRows) {
          if (!uniqueById.containsKey(item.id)) {
            uniqueById[item.id] = item; // first occurrence only
          }
        }

        searchProductVariantsList.assignAll(uniqueById.values.toList());

        log('total length-- ${newRows.length}');
        if (newRows.length < limit) {
          hasMoreData = false;
        } else {
          page++;
        }

        refresh();

      } else {
        searchProductResponse.value = ApiResponse.error('error');
      }

    } catch (e, s) {
      print("stack trace: $s");
      searchProductResponse.value = ApiResponse.error('error');
    }finally{
      if (isLoadMore) {
        isLoadingMore = false;
      } else {
        ProductSearchLoading.value = false;
      }
    }
  }

  List<String> validateSelectedVariants(List<ManufacturerSelectedVariant> allVariants) {
    final missingPriceIds = <String>[];

    for (final entry in variantSelection.entries) {
      if (entry.value) {
        final variantId = entry.key;
        final sellingPriceStr = variantSellingPrice[variantId];
        if (sellingPriceStr == null || sellingPriceStr.trim().isEmpty) {
          missingPriceIds.add(variantId);
        }
      }
    }
    return missingPriceIds;
  }

  void fillMissingSellingPricesWithDefaults(
      List<ManufacturerSelectedVariant> allVariants, List<String> missingPriceIds) {
    for (final variantId in missingPriceIds) {
      final row = allVariants.firstWhere(
        (v) => v.id == variantId,
        orElse: () => throw Exception("ManufacturerVariant not found: $variantId"),
      );
      updateSellingPrice(variantId, row.variant.sellingPrice.toString());
    }
  }

  /// Fetch suggested product of similar stores
  Future<void> fetchListOfSuggestedProductApi({bool isLoadMore = false}) async {

    try {

      if(isSuggestedProductLoadingLoadingMore.isTrue) return;

      if (!isLoadMore) {
        suggestedProductPage = 1;
        suggestedProductHasMoreData = true;
        isSuggestedProductFirstLoading.value = true;
        suggestedProductList.clear();
      } else {
        isSuggestedProductLoadingLoadingMore.value = true;
        log('loading more -- $isLoadMore');
      }

      double? businessLat;
      double? businessLng;
      String? categoryId;
      if(isIndividualUser()){
        var user = viewIndividualProfileController.personalProfileDetails.value.user;
         businessLat = user?.userLocation?.lat ?? LocationService.lat;
         businessLng = user?.userLocation?.lon ?? LocationService.lng;
         // categoryId = user.categoryDetails?.id
         //    ?? user.subCategoryDetails?.id ?? '';
      }
      else{
         var businessProfileDetails = viewProfileController.businessProfileDetails.value?.data;
         businessLat = businessProfileDetails?.businessLocation?.lat ?? LocationService.lat;
         businessLng = businessProfileDetails?.businessLocation?.lon ?? LocationService.lng ;
         categoryId = businessProfileDetails?.categoryOfBusiness ?? businessProfileDetails?.subCategoryOfBusiness;
         print('categoryId: $categoryId');
      }

      Map<String, dynamic> params = {
        ApiKeys.lat: businessLat,
        ApiKeys.lng: businessLng,
        ApiKeys.radius: kmRadius1500,
        ApiKeys.category_id: categoryId,
        ApiKeys.page: suggestedProductPage,
        ApiKeys.limit: 20,
      };

      final responseModel = await ManufacturerProductRepo().fetchSuggestedProductRepo(queryParams: params);

      if (responseModel.isSuccess) {
        suggestedProductResponse.value = ApiResponse.complete(responseModel);

        final parsed = ManufacturerProductCatalogResponse.fromJson(
          responseModel.response?.data,
        );

        final newRows = flattenProducts(parsed.data);

        // Maintain a map for uniqueness (by variant id).
        final Map<String, ManufacturerSelectedVariant> uniqueById = {
          for (final item in suggestedProductList) item.id: item,
        };

        if (!isLoadMore) {
          // For first load → clear existing
          uniqueById.clear();
        }

        for (final item in newRows) {
          if (!uniqueById.containsKey(item.id)) {
            uniqueById[item.id] = item; // first occurrence only
          }
        }

        suggestedProductList.assignAll(uniqueById.values.toList());

        log('total length-- ${suggestedProductList.length}');

        if (newRows.length < limit) {
          suggestedProductHasMoreData = false;
        } else {
          suggestedProductPage++;
        }

      } else {
        suggestedProductResponse.value = ApiResponse.error('error');
      }

    } catch (e, s) {
      print("stack trace: $s");
      suggestedProductResponse.value = ApiResponse.error('error');
    } finally{
      if (isLoadMore) {
        isSuggestedProductLoadingLoadingMore.value = false;
      } else {
        isSuggestedProductFirstLoading.value = false;
      }
    }
  }

  Future<void> cloneProductVariantApi(
      {
        required ProviderType providerType,
        required List<ManufacturerSelectedVariant> variants,
      }
      ) async {
    cloneProductVariantLoading.value = true;
    try {
      // Payload mirrors grocery's `buildInventoryPayload` — a flat List
      // of `{productVariant, pincode, cityName, batches[]}` items. The
      // only addition for product is an `ownerType` field per row so
      // the backend can route business vs. rider/self-employed clones.
      final payload = _buildInventoryPayload(variants, providerType);

      if (payload.isEmpty) {
        print("No variants selected — skipping API call");
        return;
      }

      print("Final Clone Payload: $payload");

      final responseModel = await ManufacturerProductRepo().cloneProductVariantRepo(
          params: payload);

      if (responseModel.isSuccess) {
        cloneVariantProductResponse.value = ApiResponse.complete(responseModel);
        if (providerType == ProviderType.business) {
          // Publishing must also delete the saved snapshot, or a re-entry would
          // paint the pre-publish catalogue straight off disk.
          markInventoryChanged();
        } else {
          // Self-employed / rider publish. It doesn't feed the business
          // Products tab, so there is no snapshot to drop and no owner list
          // worth refetching — just the flag the screens read on return.
          productDataNeedsRefresh = true;
        }
        if((providerType==ProviderType.business)){
          navigateToProductSection();
        }else{
          Get.until(
                (route) =>
            route.settings.name ==
                RouteHelper.getEarnServiceDashboardViewRoute(),
          );

          // if (userProfessionGlobal == BIKE_RIDER) {
          //   Get.until(
          //         (route) =>
          //     route.settings.name ==
          //         RouteHelper.getGigWorkerOptionsScreenRoute(),
          //   );
          // } else {
          //   Get.until(
          //         (route) =>
          //     route.settings.name ==
          //         RouteHelper.getSelfEmployeeScreenRoute(),
          //   );
          // }

        }

      } else {
        cloneVariantProductResponse.value = ApiResponse.error('error');
      }

    } catch (e, s) {
      print("stack trace: $s");
      searchProductResponse.value = ApiResponse.error('error');
    }finally{
      cloneProductVariantLoading.value = false;
    }
  }

  /// Open the "Add more variant" dialog for a product. Mirrors
  /// grocery's [GroceryController.openAddVariantDialog] flow — same
  /// quantity / unit / mrp / sellingPrice form, same submit-handler
  /// shape — only the downstream API and product id differ.
  void openAddVariantDialog({
    required BuildContext context,
    required String productId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isCreateNewProductVariantLoading.value,
      builder: (_) {
        return ManufacturerProductVariantDialog(
          title: AppStrings.productAddMoreVariant.tr,
          onSubmit: (quantity, unit, mrp, sellingPrice) {
            createNewProductVariantApi(
              productId: productId,
              quantity: quantity.trim(),
              unit: unit.trim(),
              mrp: mrp.trim(),
              sellingPrice: sellingPrice.trim(),
            );
          },
        );
      },
    );
  }

  /// Create a brand-new variant on an existing product. Mirrors
  /// grocery's [GroceryController.createNewGroceryProductNewVariant]
  /// — identical payload shape, only the service URL differs
  /// (grocery-service → product-service). On success we close the
  /// dialog and surface a snackbar; the caller is responsible for
  /// refreshing any list view that needs the new variant.
  Future<void> createNewProductVariantApi({
    required String productId,
    required String quantity,
    required String unit,
    required String mrp,
    required String sellingPrice,
  }) async {
    try {
      isCreateNewProductVariantLoading.value = true;
      final Map<String, dynamic> data = {
        ApiKeys.variantData: jsonEncode({
          ApiKeys.quantity: "$quantity $unit",
          ApiKeys.pricing: [
            {
              ApiKeys.mrp: int.tryParse(mrp),
              ApiKeys.sellingPrice: int.tryParse(sellingPrice),
            }
          ],
        }),
      };

      final response = await ManufacturerProductRepo().createNewProductVariantRepo(
        productId: productId,
        params: data,
      );

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      markInventoryChanged();
      commonSnackBar(message: 'ManufacturerVariant added successfully');
      Get.back();
    } catch (e, s) {
      log('createNewProductVariantApi error: $e\n$s');
    } finally {
      isCreateNewProductVariantLoading.value = false;
    }
  }

  void navigateToProductSection() {
    Get.until((route) {
      print("🔍 Scanning route → ${route.settings.name}");

      // STOP when this route matches
      if(route.settings.name == RouteHelper.getProductScreenRoute()) return route.settings.name == RouteHelper.getProductScreenRoute();
      else return route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute();
    });
  }

    /// Builds the publish payload in the same shape grocery uses
    /// (`buildInventoryPayload` in GroceryController) — a flat list of
    /// `{productVariant, pincode, cityName, batches[]}` items — with one
    /// additional `ownerType` field per row so the backend can route
    /// business vs. rider/self-employed clones.
    List<Map<String, dynamic>> _buildInventoryPayload(
        List<ManufacturerSelectedVariant> allVariants, ProviderType providerType) {
      final payload = <Map<String, dynamic>>[];

      final businessData = viewProfileController.businessProfileDetails.value?.data;
      String city = (businessData?.cityStatePincode != null &&
              businessData!.cityStatePincode!.isNotEmpty)
          ? businessData.cityStatePincode!
          : LocationService.userCurrentAddress.value.city;
      String postalCode;
      if (businessData?.pincode == null || businessData?.pincode == 0) {
        postalCode = LocationService.userCurrentAddress.value.postalCode;
      } else {
        postalCode = businessData!.pincode.toString();
      }

      if (postalCode.isEmpty || postalCode == "0") {
        commonSnackBar(message: AppStrings.groceryEnableGpsOrPincode.tr);
      }

      variantSelection.forEach((variantId, isSelected) {
        if (!isSelected) return;

        final row =
            allVariants.firstWhereOrNull((v) => v.id == variantId);
        if (row == null) return;

        final variant = row.variant;

        // User-entered price → fallback to API default selling price.
        final sellingPriceStr = variantSellingPrice[variantId];
        final sellingPrice =
            double.tryParse(sellingPriceStr ?? '') ?? variant.sellingPrice;

        payload.add({
          "ownerType": providerType.title,
          "productVariant": variantId,
          "pincode": postalCode,
          "cityName": city,
          "batches": [
            {
              "quantity": _resolveVariantQuantity(variant),
              "mrp": variant.mrp,
              "sellingPrice": sellingPrice,
            }
          ],
        });
      });

      return payload;
    }

  String _resolveVariantQuantity(ManufacturerVariant variant) {
    final raw = variant.quantity.trim();
    if (raw.isNotEmpty) return raw;

    final parts = variant.attributes.entries.map((entry) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (key == 'color' && value is Map<String, dynamic>) {
        return (value['color_name'] ?? '').toString();
      }
      if (value == null) return '';
      return value.toString();
    }).where((s) => s.isNotEmpty);

    final derived = parts.join(' • ');
    return derived.isNotEmpty ? derived : 'default';
  }

  void dismissErrorBanner() {
    showErrorBanner.value = false;
  }


  RxBool isDeleteProductVariantLoading = false.obs;

  void deleteProduct() {
    try {
      isDeleteProductVariantLoading.value = true;

      // final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsApi(queryParams: queryParams);
      // if (response.isSuccess) {
      //   deleteProductVariantResponse.value = ApiResponse.complete(response);
      //   // final getOwnProductModel = GetProductModel.fromJson(response.response!.data);
      //   // List<GetProductData> products = getOwnProductModel.data;
      //   //
      //   // if(isDraftProduct!=null){
      //   //   if(isDraftProduct){
      //   //     draftProducts.clear();
      //   //     draftProducts.assignAll(products);
      //   //   }else{
      //   //     liveProducts.clear();
      //   //     liveProducts.assignAll(products);
      //   //   }
      //   // }else{
      //   //   allProducts.clear();
      //   //   allProducts.assignAll(products);
      //   // }
      // } else {
      //   print("API failed with status: ${response.statusCode}");
      //   deleteProductVariantResponse.value = ApiResponse.error('error');
      // }
    } catch (e, s) {
      print("stack trace: $s");
    } finally {
      isDeleteProductVariantLoading.value = false;
      deleteProductVariantResponse.value = ApiResponse.error('error');
    }
  }

  /// Deletes a single inventory variant by its inventory id, then drops it from
  /// the in-memory [allProducts] (removing the product entirely once it has no
  /// variants left) so the grid updates immediately. Returns `true` on success.
  Future<bool> deleteInventoryVariant({required String inventoryId}) async {
    if (inventoryId.isEmpty) return false;
    try {
      final res = await ManufacturerProductRepo()
          .deleteInventoryVariantRepo(inventoryId: inventoryId);
      if (!res.isSuccess) return false;

      // Purge from every displayed list (the grid renders from
      // [productsByCategoryList]; [allProducts] backs other strips) and refresh
      // so the bound Obx rebuilds without the deleted item.
      for (final list in [allProducts, productsByCategoryList]) {
        for (final p in list.toList()) {
          final variants = p.product.sellerClassification?.variants;
          variants?.removeWhere(
              (v) => v.inventoryId == inventoryId || v.id == inventoryId);
          if (variants == null || variants.isEmpty) {
            list.remove(p);
          }
        }
        list.refresh();
      }
      // The in-place purge fixes what is on screen; this drops the saved
      // snapshot so the deleted variant can't come back from disk on the next
      // open. See [markInventoryChanged].
      markInventoryChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates a single inventory variant's selling price / mrp / active flag by
  /// its inventory id. Body is the flat updated fields. Mirrors the product
  /// service's price-edit flow.
  Future<bool> updateProductVariantPrice({
    required String inventoryId,
    required num sellingPrice,
    required num mrp,
    required bool varientIsActive,
  }) async {
    try {
      final res = await ManufacturerProductRepo().updateInventoryVariantRepo(
        inventoryId: inventoryId,
        params: {
          'sellingPrice': sellingPrice,
          'mrp': mrp,
          'varientIsActive': varientIsActive,
        },
      );
      if (!res.isSuccess) return false;
      // Reflect the change in-memory so the card and a re-opened edit sheet
      // show the new values immediately (avoids a stale/cached refetch).
      for (final p in allProducts) {
        for (final v
            in p.product.sellerClassification?.variants ?? const <Variant>[]) {
          if (v.inventoryId == inventoryId || v.id == inventoryId) {
            v.sellingPrice = sellingPrice;
            v.mrp = mrp;
            v.variantIsActive = varientIsActive;
          }
        }
      }
      allProducts.refresh();
      // Same reason as [deleteInventoryVariant]: the patched price must not be
      // undone by a stale snapshot on the next open.
      markInventoryChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Flips the manual out-of-stock flag on one variant's inventory record via
  /// `PATCH /inventory/stock/toggle-out-of-stock`, then mirrors it into the
  /// in-memory lists so the sheet and the cards behind it update without a
  /// refetch. Returns `true` on success.
  ///
  /// Quantity is untouched — this is the merchant's manual "don't sell this
  /// right now" switch (damaged goods, supplier gap), not a stock adjustment.
  ///
  /// Returns the resulting `isOutOfStock`, or `null` when the write failed.
  /// This endpoint SETS rather than flips, so on success the value is exactly
  /// what was asked for — but the nullable-value contract is what the sheet
  /// expects, since automotive's flip endpoint can only report its result.
  Future<bool?> toggleVariantOutOfStock({
    required String inventoryId,
    required bool isOutOfStock,
  }) async {
    if (inventoryId.isEmpty) return null;
    try {
      final res = await ManufacturerProductRepo().toggleOutOfStockRepo(
        inventoryIds: [inventoryId],
        isOutOfStock: isOutOfStock,
      );
      if (!res.isSuccess) return null;

      // Both lists render variants (the category grid reads
      // [productsByCategoryList], [allProducts] backs the rails) and they hold
      // separate objects for the same variant — mirror into both, same as
      // [deleteInventoryVariant].
      for (final list in [allProducts, productsByCategoryList]) {
        for (final p in list) {
          for (final v
              in p.product.sellerClassification?.variants ?? const <Variant>[]) {
            if (v.inventoryId == inventoryId || v.id == inventoryId) {
              v.stock = !isOutOfStock;
            }
          }
        }
        list.refresh();
      }
      // Same reason as [deleteInventoryVariant].
      markInventoryChanged();
      return isOutOfStock;
    } catch (_) {
      return null;
    }
  }
}
 