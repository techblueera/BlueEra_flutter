import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
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
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/model/product_model.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/model/product_snap_search_response.dart';
import 'package:BlueEra/features/me/product/repo/inventory_repo.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
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
  RxList<GetProductData> liveProducts = <GetProductData>[].obs;
  RxList<GetProductData> draftProducts = <GetProductData>[].obs;

  /// ─── Pagination for "Top Selling" own products ───────────────────
  /// Shared between [ProductHomeScreen]'s horizontal preview and the
  /// "View All" screen. On the home screen only the first
  /// [ownProductsPreviewLimit] items are rendered — the rest of the
  /// paginated list lives behind the "View All" action.
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
  int page = 1;
  int limit = 10;
  bool hasMoreData = true;
  bool isLoadingMore = false;

  RxInt businessCardsSelectedIndex = 0.obs;

  RxList<VariantData> searchProductVariantsList = <VariantData>[].obs;
  RxList<UnUsedProduct> searchProductsList = <UnUsedProduct>[].obs;

  final variantSelection = <String, bool>{}.obs;
  final variantSellingPrice = <String, String>{}.obs;
  RxList<VariantData> selectedVariantsList = <VariantData>[].obs;

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
      selectedVariantsList.removeWhere((v) => v.finalVariant.id == id);
    }
    log('id-- $id  selected=${variantSelection[id]}');
  }

  void toggleVariantWithData(VariantData variantData) {
    final id = variantData.finalVariant.id;
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
      selectedVariantsList.removeWhere((v) => v.finalVariant.id == id);
    } else {
      variantSelection[id] = true;
      selectedVariantsList.add(variantData);
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
  RxList<VariantData> suggestedProductList = <VariantData>[].obs;

  // ── Product Nested Category With Inventory ──────────────────────────────────
  Rx<ApiResponse> fetchProductCategoryResponse = ApiResponse.initial('Initial').obs;
  RxBool myProductLoading = true.obs;
  RxList<ProductCategoryWithInventoryModel> productCategoryList = <ProductCategoryWithInventoryModel>[].obs;
  RxBool productNestedCategoryLoading = false.obs;
  RxList<ProductNestedCategoryResponse> productNestedCategoryList = <ProductNestedCategoryResponse>[].obs;

  Future<void> fetchAllProductData({String? visitBusinessId}) async {
    try {
      myProductLoading.value = true;
      await Future.wait([
        fetchProductCategoryWithInventory(visitBusinessId: visitBusinessId),
        fetchProducts(visitBusinessId: visitBusinessId),
      ]);
    } catch (e) {
      log('Error fetching product data: $e');
    } finally {
      myProductLoading.value = false;
    }
  }

  Future<void> fetchProductCategoryWithInventory({
    String? visitBusinessId,
  }) async {
    try {
      fetchProductCategoryResponse.value = ApiResponse.initial('Initial');

      final response = await InventoryRepo().fetchProductCategoryWithInventoryRepo(
        businessId: visitBusinessId ?? businessId,
      );

      if (response.isSuccess) {
        fetchProductCategoryResponse.value = ApiResponse.complete(response);
        final responseData = ProductInventoryByCategoryResponse.fromJson(
          response.response?.data,
        );
        productCategoryList.value = responseData.data ?? [];
        log("Loaded ${productCategoryList.length} product categories");
      } else {
        fetchProductCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchProductCategoryResponse.value = ApiResponse.error('error');
      log("ERROR fetching product categories: $e");
    }
  }

  // ── Product By Category (Paginated) ────────────────────────────────
  final selectedProductCategoryData = Rxn<ProductNestedCategoryResponse>();
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
    bool isLoadMore = false,
    String? visitBusinessId,
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
        'ownerId': visitBusinessId ?? businessId,
        'ownerType': ProviderType.business.title,
        'categoryId': categoryId,
        ApiKeys.page: productByCategoryPage,
        ApiKeys.limit: productByCategoryPageLimit,
      };

      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);

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
  RxList<VariantData> snapSearchProductList = <VariantData>[].obs;
  Rxn<ProductSnapSearchData> productSnapSearchData = Rxn<ProductSnapSearchData>();

  Future<void> addProductImagesBySlot(String title) async {
    if (productSnapSearchImagesMap.values.any((v) => v != null)) {
      commonSnackBar(message: "Please remove the current image before selecting another type.");
      return;
    }

    final List<String>? selectedImages =
        await SelectProductImageDialog.showLogoDialog(Get.context!, title);
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
          await InventoryRepo().fetchProductSnapSearchRepo(params: params);

      if (responseModel.isSuccess) {
        productSnapSearchResponse.value = ApiResponse.complete(responseModel);

        final response = ProductSnapSearchResponseModel.fromJson(
          responseModel.response?.data,
        );
        productSnapSearchData.value = response.data;

        final foundItems = response.data?.foundProducts ?? [];
        final variants = <VariantData>[];
        for (final item in foundItems) {
          variants.addAll(item.variants);
        }
        snapSearchProductList.assignAll(variants);
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

  /// Currently-active `ownerId` for the paginated `allProducts` list. When
  /// the user is visiting another business this becomes the visiting
  /// business's id; on the owner's own product home it stays as the
  /// global `businessId`. Remembered here so load-more requests keep
  /// hitting the same business across `isLoadMore` calls without the
  /// caller having to re-pass it.
  String? _allProductsActiveOwnerId;

  Future<void> fetchProducts({
    bool? isDraftProduct,
    bool isLoadMore = false,
    String? visitBusinessId,
  }) async {
    // Paginated "allProducts" path is only engaged when no draft filter is
    // supplied — the draft/live lists still use the old one-shot behavior.
    final bool paginate = isDraftProduct == null;

    try {
      if (paginate && isLoadMore) {
        // Guard against duplicate/overlapping load-more calls and stop
        // once the server has reported there are no more pages.
        if (!_allProductsHasMore ||
            isAllProductsLoadingMore.value ||
            ownDraftAndPublicProductResponse.value.status == Status.INITIAL) {
          return;
        }
        isAllProductsLoadingMore.value = true;
      } else {
        ownDraftAndPublicProductResponse.value =
            ApiResponse.initial('Initial');
        isLoading.value = true;
        isProductLoading.value = true;
        if (paginate) {
          _allProductsPage = 1;
          _allProductsHasMore = true;
          allProducts.clear();
          // Remember which owner this paginated run is scoped to, so
          // subsequent load-more calls stay on the same business even
          // if the caller forgets to pass `visitBusinessId` again.
          _allProductsActiveOwnerId = visitBusinessId ?? businessId;
        }
      }

      final String effectiveOwnerId = paginate
          ? (_allProductsActiveOwnerId ?? businessId)
          : (visitBusinessId ?? businessId);

      final Map<String, dynamic> queryParams = {
        'ownerId': effectiveOwnerId,
        'ownerType': ProviderType.business.title,
      };

      if (isDraftProduct != null) {
        queryParams['DRAFT'] = isDraftProduct;
      } else {
        queryParams[ApiKeys.page] = _allProductsPage;
        queryParams[ApiKeys.limit] = _allProductsLimit;
      }

      final response = await InventoryRepo()
          .fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);
      if (response.isSuccess) {
        ownDraftAndPublicProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel =
            GetProductModel.fromJson(response.response!.data);
        final List<GetProductData> products = getOwnProductModel.data;

        if (isDraftProduct != null) {
          if (isDraftProduct) {
            draftProducts.clear();
            draftProducts.assignAll(products);
          } else {
            liveProducts.clear();
            liveProducts.assignAll(products);
          }
        } else {
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
        }
      } else {
        print("API failed with status: ${response.statusCode}");
        ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
      ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
    } finally {
      if (paginate && isLoadMore) {
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
        searchProductsList.clear();
        ProductSearchLoading.value = true;
      } else {
        isLoadingMore = true;
        log('loading more -- $isLoadMore');
      }

      Map<String, dynamic> params = {
        ApiKeys.name: keyword,
        ApiKeys.page: page,
        ApiKeys.limit: limit,
      };

      final responseModel = await InventoryRepo().fetchInventoryBasedSearchProductRepo(queryParams: params);

      if (responseModel.isSuccess) {
        searchProductResponse.value = ApiResponse.complete(responseModel);

        final inventoryBasedSearchProductResponse = InventoryBasedSearchProductResponse.fromJson(
          responseModel.response?.data,
        );

        final List<VariantData> newVariants =
        List<VariantData>.from(inventoryBasedSearchProductResponse.data);

        final List<UnUsedProduct> newProducts =
        List<UnUsedProduct>.from(inventoryBasedSearchProductResponse.unUsedProduct);

       // Maintain a map for uniqueness
        final Map<String, VariantData> uniqueById = {
          for (var item in searchProductVariantsList)
            item.finalVariant.id: item, // keep old data
        };

        if (!isLoadMore) {
          // For first load → clear existing
          uniqueById.clear();
        }

        for (final item in newVariants) {
          final id = item.finalVariant.id;

          if (!uniqueById.containsKey(id)) {
            uniqueById[id] = item; // first occurrence only
          }
        }

        searchProductVariantsList.assignAll(uniqueById.values.toList());

        if (!isLoadMore) {
          searchProductsList.assignAll(newProducts);
        } else {
          searchProductsList.addAll(newProducts);
        }

        log('total length-- ${newVariants.length + newProducts.length}');
        if (newVariants.length + newProducts.length < limit) {
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

  List<String> validateSelectedVariants(List<VariantData> allVariants) {
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

  void fillMissingSellingPricesWithDefaults(List<VariantData> allVariants, List<String> missingPriceIds) {
    for (final variantId in missingPriceIds) {
      final variantData = allVariants.firstWhere(
            (v) => v.finalVariant.id == variantId,
        orElse: () => throw Exception("Variant not found: $variantId"),
      );

     updateSellingPrice(variantId, variantData.finalVariant.sellingPrice.toString());

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

      final responseModel = await InventoryRepo().fetchSuggestedProductRepo(queryParams: params);

      if (responseModel.isSuccess) {
        suggestedProductResponse.value = ApiResponse.complete(responseModel);

        final inventoryBasedSearchProductResponse = InventoryBasedSearchProductResponse.fromJson(
          responseModel.response?.data,
        );

        final List<VariantData> newProducts = List<VariantData>.from(inventoryBasedSearchProductResponse.data);

        // Maintain a map for uniqueness
        final Map<String, VariantData> uniqueById = {
          for (var item in suggestedProductList)
            item.finalVariant.id: item, // keep old data
        };

        if (!isLoadMore) {
          // For first load → clear existing
          uniqueById.clear();
        }

        for (final item in newProducts) {
          final id = item.finalVariant.id;

          if (!uniqueById.containsKey(id)) {
            uniqueById[id] = item; // first occurrence only
          }
        }

        suggestedProductList.assignAll(uniqueById.values.toList());

        // if (!isLoadMore) {
        //   suggestedProductList.assignAll(newProducts);
        // } else {
        //   suggestedProductList.addAll(newProducts);
        // }

        log('total length-- ${suggestedProductList.length}');

        if (newProducts.length < limit) {
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
      { required String ownerID,
        required ProviderType providerType,
        required List<VariantData> variants,
      }
      ) async {
    cloneProductVariantLoading.value = true;
    try {
      final clones = _buildSelectedVariantsPayload(variants);

      if (clones.isEmpty) {
        print("No variants selected — skipping API call");
        return;
      }

      // Construct body
      final body = {
        ApiKeys.owner: {
          ApiKeys.id: ownerID,
          ApiKeys.type: providerType.title,
        },
        ApiKeys.clones: clones,
        //  'clones': jsonEncode(clones),
      };

      print("Final Clone Payload: $body");

      final responseModel = await InventoryRepo().cloneProductVariantRepo(params: body);

      if (responseModel.isSuccess) {
        cloneVariantProductResponse.value = ApiResponse.complete(responseModel);
        productDataNeedsRefresh = true;
        if((providerType==ProviderType.business)){
          navigateToInventory();
        }else{
          // await setEarnServiceOptData(true);
          // await setRiderServiceOptData(true);
          if (userProfessionGlobal == BIKE_RIDER) {
            Get.until(
                  (route) =>
              route.settings.name ==
                  RouteHelper.getGigWorkerOptionsScreenRoute(),
            );
          } else {
            Get.until(
                  (route) =>
              route.settings.name ==
                  RouteHelper.getSelfEmployeeScreenRoute(),
            );
          }

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

  void navigateToInventory() {
    Get.until((route) {
      print("🔍 Scanning route → ${route.settings.name}");

      // STOP when this route matches
      if(route.settings.name == RouteHelper.getProductScreenRoute()) return route.settings.name == RouteHelper.getProductScreenRoute();
      else return route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute();
    });
  }

    List<Map<String, dynamic>> _buildSelectedVariantsPayload(
        List<VariantData> allVariants) {
      final payload = <Map<String, dynamic>>[];

      variantSelection.forEach((variantId, isSelected) {
        if (isSelected) {
          final variantData = allVariants.firstWhere(
                (v) => v.finalVariant.id == variantId,
            orElse: () => throw Exception("Variant not found: $variantId"),
          );

          // get selling price from controller OR fallback to default
          final sellingPriceStr = variantSellingPrice[variantId];
          final sellingPrice = double.tryParse(sellingPriceStr ?? '') ??
              variantData.finalVariant.sellingPrice;

          print("----------------------------");
          print("Selected Variant Debug Info");
          print("Variant ID     : $variantId");
          print("Product ID     : ${variantData.productInformation.id}");
          print("Default Price  : ${variantData.finalVariant.sellingPrice}");
          print("Updated Price  : $sellingPrice");
          print("Product Name   : ${variantData.productInformation.name}");
          print("Brand          : ${variantData.productInformation.brand}");
          print("Media Count    : ${variantData.productInformation.media.length}");
          print("----------------------------");

          payload.add({
            "product_id": variantData.productInformation.id,
            "variantId": variantId,
            "sellingPrice": sellingPrice,
          });
        }
      });

      return payload;
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
}
 