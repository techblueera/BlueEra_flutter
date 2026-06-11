import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
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
import 'package:BlueEra/features/me/product/model/categoryinventory_model.dart';
// `show` keeps `Variant` / `ProductFeature` from this module out of the
// namespace — they conflict with the same names from
// `product_catalog_response.dart` below.
import 'package:BlueEra/features/me/product/model/get_product_model.dart'
    show GetProductData, GetProductModel;
import 'package:BlueEra/features/me/product/model/product_catalog_response.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/model/product_model.dart';
import 'package:BlueEra/features/me/product/model/product_snap_search_response.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/me/product/view/admin/product_variant_dialog.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController {
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
  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  RxList<CategoryInventoryModel> categories = <CategoryInventoryModel>[].obs;
  RxList<CategoryInventoryModel> filteredCategories = <CategoryInventoryModel>[].obs;

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

  RxList<SelectedVariant> searchProductVariantsList = <SelectedVariant>[].obs;

  final variantSelection = <String, bool>{}.obs;
  final variantSellingPrice = <String, String>{}.obs;
  RxList<SelectedVariant> selectedVariantsList = <SelectedVariant>[].obs;

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

  void toggleVariantWithData(SelectedVariant selected) {
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
  RxList<SelectedVariant> suggestedProductList = <SelectedVariant>[].obs;

  // ── Product Nested Category With Inventory ──────────────────────────────────
  Rx<ApiResponse> fetchProductCategoryResponse = ApiResponse.initial('Initial').obs;
  RxBool myProductLoading = true.obs;
  RxList<ProductCategoryWithInventoryModel> productNestedCategoryList = <ProductCategoryWithInventoryModel>[].obs;
  RxBool productNestedCategoryLoading = false.obs;

  Future<void> fetchAllProductData({String? visitUserId}) async {
    try {
      myProductLoading.value = true;
      await Future.wait([
        fetchProductCategoryWithInventory(visitUserId: visitUserId),
        fetchBusinessProducts(visitUserId: visitUserId),
      ]);
    } catch (e) {
      log('Error fetching product data: $e');
    } finally {
      myProductLoading.value = false;
    }
  }

  Future<void> fetchProductCategoryWithInventory({
    String? visitUserId,
  }) async {
    try {
      fetchProductCategoryResponse.value = ApiResponse.initial('Initial');

      ResponseModel response;
      if(visitUserId!=null){
        response = await ProductRepo().fetchPublicProductCategoryWithInventoryRepo(visitUserId: visitUserId);
      }else{
        response = await ProductRepo().fetchProductCategoryWithInventoryRepo();
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
        productNestedCategoryList.value = rawList
            .whereType<Map>()
            .map((e) => ProductCategoryWithInventoryModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
        log("Loaded ${productNestedCategoryList.length} product categories");
      } else {
        fetchProductCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchProductCategoryResponse.value = ApiResponse.error('error');
      log("ERROR fetching product categories: $e");
    }
  }

  // ── Product By Category (Paginated) ────────────────────────────────
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

      final response = await ProductRepo().fetchProductsRepo(queryParams: queryParams);

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

  // ── Product Snap Search ──────────────────────────────────────────────
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
  RxList<SelectedVariant> snapSearchProductList = <SelectedVariant>[].obs;
  Rxn<ProductSnapSearchData> productSnapSearchData = Rxn<ProductSnapSearchData>();

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
          await ProductRepo().fetchProductSnapSearchRepo(params: params);

      if (responseModel.isSuccess) {
        productSnapSearchResponse.value = ApiResponse.complete(responseModel);

        final response = ProductSnapSearchResponseModel.fromJson(
          responseModel.response?.data,
        );
        productSnapSearchData.value = response.data;

        final foundItems = response.data?.foundProducts ?? [];
        final rows = <SelectedVariant>[];
        for (final item in foundItems) {
          final product = item.product;
          if (product == null) continue;
          for (final v in product.variants) {
            rows.add(SelectedVariant(product: product, variant: v));
          }
        }
        snapSearchProductList.assignAll(rows);
      } else {
        productSnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      productSnapSearchResponse.value = ApiResponse.error('error');
      log("Product Snap Search Error: $s");
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

  Future<void> fetchBusinessProducts({
    String? visitUserId,
    bool? isDiscountedProducts,
    bool isLoadMore = false,
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
        ownDraftAndPublicProductResponse.value = ApiResponse.initial('Initial');
        isLoading.value = true;
        isProductLoading.value = true;
        _allProductsPage = 1;
        _allProductsHasMore = true;
        allProducts.clear();
      }

      final Map<String, dynamic> queryParams = {
        ApiKeys.ownerType: ProviderType.business.title,
      };
      if(visitUserId!=null) queryParams[ApiKeys.businessId] = visitUserId;
      if(isDiscountedProducts!=null) queryParams[ApiKeys.isDiscounted] = isDiscountedProducts;
      queryParams[ApiKeys.page] = _allProductsPage;
      queryParams[ApiKeys.limit] = _allProductsLimit;

      final response = await ProductRepo()
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
        ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
      ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
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
        ApiKeys.searchTerm: keyword,
        ApiKeys.page: page,
        ApiKeys.limit: limit,
      };

      final responseModel = await ProductRepo().fetchSearchProductViaCategoryRepo(queryParams: params);

      if (responseModel.isSuccess) {
        searchProductResponse.value = ApiResponse.complete(responseModel);

        final parsed = ProductCatalogResponse.fromJson(
          responseModel.response?.data,
        );

        final newRows = flattenProducts(parsed.data);

        // Maintain a map for uniqueness (by variant id).
        final Map<String, SelectedVariant> uniqueById = {
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

  List<String> validateSelectedVariants(List<SelectedVariant> allVariants) {
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
      List<SelectedVariant> allVariants, List<String> missingPriceIds) {
    for (final variantId in missingPriceIds) {
      final row = allVariants.firstWhere(
        (v) => v.id == variantId,
        orElse: () => throw Exception("Variant not found: $variantId"),
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

      final responseModel = await ProductRepo().fetchSuggestedProductRepo(queryParams: params);

      if (responseModel.isSuccess) {
        suggestedProductResponse.value = ApiResponse.complete(responseModel);

        final parsed = ProductCatalogResponse.fromJson(
          responseModel.response?.data,
        );

        final newRows = flattenProducts(parsed.data);

        // Maintain a map for uniqueness (by variant id).
        final Map<String, SelectedVariant> uniqueById = {
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
        required List<SelectedVariant> variants,
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

      final responseModel = await ProductRepo().cloneProductVariantRepo(
          params: payload);

      if (responseModel.isSuccess) {
        cloneVariantProductResponse.value = ApiResponse.complete(responseModel);
        productDataNeedsRefresh = true;
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
        return ProductVariantDialog(
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

      final response = await ProductRepo().createNewProductVariantRepo(
        productId: productId,
        params: data,
      );

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      productDataNeedsRefresh = true;
      commonSnackBar(message: 'Variant added successfully');
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
        List<SelectedVariant> allVariants, ProviderType providerType) {
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

  String _resolveVariantQuantity(Variant variant) {
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

  /// Updates a single inventory variant's selling price / mrp / active flag by
  /// its inventory id, via the product-service inventory endpoint. Refreshes
  /// the in-memory [allProducts] so the card reflects the change immediately.
  Future<bool> updateProductVariantPrice({
    required String inventoryId,
    required num sellingPrice,
    required num mrp,
    required bool varientIsActive,
  }) async {
    try {
      final res = await ProductRepo().updateInventoryVariantRepo(
        inventoryId: inventoryId,
        params: {
          'sellingPrice': sellingPrice,
          'mrp': mrp,
          'varientIsActive': varientIsActive,
        },
      );
      if (!res.isSuccess) return false;
      for (final p in allProducts) {
        for (final v in p.product.sellerClassification?.variants ?? const []) {
          if (v.inventoryId == inventoryId || v.id == inventoryId) {
            v.sellingPrice = sellingPrice;
            v.mrp = mrp;
            v.variantIsActive = varientIsActive;
          }
        }
      }
      allProducts.refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
 