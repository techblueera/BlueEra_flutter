import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/categoryinventory_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController {
  Rx<ApiResponse> ownDraftAndPublicProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> searchProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cloneVariantProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteProductVariantResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> suggestedProductResponse = ApiResponse.initial('Initial').obs;

  final TextEditingController searchController = TextEditingController();
  
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

  final viewProfileController = getOrPut(() => ViewBusinessDetailsController());
  final viewIndividualProfileController = getOrPut(() => ViewPersonalDetailsController());

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
    log('id-- $id  selected=${variantSelection[id]}');
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

  void callApi({bool forceRefresh = false}) {
    RxList<GetProductData> targetList;

    switch (selectedProductIndex.value) {
      case 0:
        targetList = allProducts;
        break;
      case 1:
        targetList = liveProducts;
        break;
      case 2:
        targetList = draftProducts;
        break;
      default:
        targetList = allProducts;
    }

    if (forceRefresh || targetList.isEmpty) {
      switch (selectedProductIndex.value) {
        case 0:
          fetchProducts();
          break;
        case 1:
          fetchProducts(isDraftProduct: false);
          break;
        case 2:
          fetchProducts(isDraftProduct: true);
          break;
      }
    }
  }

  Future<void> fetchProducts({bool? isDraftProduct}) async {
    try {
      ownDraftAndPublicProductResponse.value = ApiResponse.initial('Initial');

      isLoading.value = true;
      isProductLoading.value = true;

      Map<String, dynamic> queryParams = {
        // ApiKeys.businessId: businessId,
        'ownerId': businessId,
        'ownerType': ProviderType.business.title,
      };

      if(isDraftProduct!=null){
        queryParams['DRAFT'] = isDraftProduct;
      }

      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);
      if (response.isSuccess) {
        ownDraftAndPublicProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel = GetProductModel.fromJson(response.response!.data);
        List<GetProductData> products = getOwnProductModel.data;

        if(isDraftProduct!=null){
          if(isDraftProduct){
            draftProducts.clear();
            draftProducts.assignAll(products);
          }else{
            liveProducts.clear();
            liveProducts.assignAll(products);
          }
        }else{
          allProducts.clear();
          allProducts.assignAll(products);
        }
      } else {
        print("API failed with status: ${response.statusCode}");
        ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
      ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
    } finally {
      isLoading.value = false;
      isProductLoading.value = false;
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
         businessLat = viewIndividualProfileController.personalProfileDetails.value.user?.userLocation?.lat ?? LocationService.lat;
         businessLng = viewIndividualProfileController.personalProfileDetails.value.user?.userLocation?.lon ?? LocationService.lng;
         // categoryId = viewIndividualProfileController.personalProfileDetails.value.user.c
         //    ?? viewIndivi dualProfileController.businessProfileDetails?.data?.subCategoryDetails?.id ?? '';
      }
      else{
         businessLat = viewProfileController.businessProfileDetails?.data?.businessLocation?.lat ?? LocationService.lat;
         businessLng = viewProfileController.businessProfileDetails?.data?.businessLocation?.lon ?? LocationService.lng ;
         categoryId = viewProfileController.businessProfileDetails?.data?.categoryDetails?.id
            ?? viewProfileController.businessProfileDetails?.data?.subCategoryDetails?.id ?? '';

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
       required bool cloneProductVariantFromSearch
      }
      ) async {
    cloneProductVariantLoading.value = true;
    try {
      final clones;
      if(cloneProductVariantFromSearch){
        clones = _buildSelectedVariantsPayload(searchProductVariantsList);
      }else{
        clones = _buildSelectedVariantsPayload(suggestedProductList);
      }

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
        if((providerType==ProviderType.business)){
          navigateToInventory();
        }else{
          await setEarnServiceOptData(true);
          Get.until(
                (route) =>
            route.settings.name ==
                RouteHelper.getEarnServiceAvailableOptionsScreenRoute(),
          );
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
      if(route.settings.name == RouteHelper.getInventoryScreenRoute()) return route.settings.name == RouteHelper.getInventoryScreenRoute();
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
 