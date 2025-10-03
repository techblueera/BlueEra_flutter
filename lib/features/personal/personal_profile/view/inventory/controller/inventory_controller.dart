import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/categoryinventory_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_own_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController {
  Rx<ApiResponse> ownDraftAndPublicProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> searchProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cloneVariantProductResponse = ApiResponse.initial('Initial').obs;

  final TextEditingController searchController = TextEditingController();
  
  RxBool isLoading = false.obs;
  RxString selectedFilter = 'Draft'.obs;
  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  RxList<CategoryInventoryModel> categories = <CategoryInventoryModel>[].obs;
  RxList<CategoryInventoryModel> filteredCategories = <CategoryInventoryModel>[].obs;

  RxBool isMenuOpen = false.obs;

  final List<String> productTab = ["All", "Live", 'Draft', 'Out Of Stock'];
  RxInt selectedProductIndex = 0.obs;

  RxList<OwnProductData> allProducts = <OwnProductData>[].obs;
  RxList<OwnProductData> liveProducts = <OwnProductData>[].obs;
  RxList<OwnProductData> draftProducts = <OwnProductData>[].obs;

  // final RxList<ProductItem> selectedProducts = <ProductItem>[].obs;
  final int maxSelectionLimit = 10;
  final RxBool showErrorBanner = false.obs;

  /// Search debounce timer
  Timer? _searchDebounce;
  final RxString searchProduct = ''.obs;
  final RxBool ProductSearchLoading = false.obs;

  final RxBool cloneProductVariantLoading = false.obs;

  RxList<VariantData> searchProductVariantsList = <VariantData>[].obs;
  RxList<UnUsedProduct> searchProductsList = <UnUsedProduct>[].obs;

  final variantSelection = <String, bool>{}.obs;
  final variantSellingPrice = <String, String>{}.obs;

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
      log("⚠️ Cannot select more than 10 variants");
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

  @override
  void onInit() {
    super.onInit();
    // loadProducts();
    loadCategories();
    searchController.addListener(_filterData);
    // Ensure search field doesn't auto-focus
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
    RxList<OwnProductData> targetList;

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

    log('forceRefresh-- $forceRefresh');
    log('isEmpty-- ${targetList.isEmpty}');
    if (forceRefresh || targetList.isEmpty) {
      switch (selectedProductIndex.value) {
        case 0:
          loadProducts();
          break;
        case 1:
          loadProducts(isDraftProduct: false);
          break;
        case 2:
          loadProducts(isDraftProduct: true);
          break;
      }
    }
  }

  Future<void> loadProducts({bool? isDraftProduct}) async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {
        ApiKeys.businessId: businessId,
      };

      if(isDraftProduct!=null){
        params['DRAFT'] = isDraftProduct;
      }

      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsApi(params: params);
      if (response.isSuccess) {
        ownDraftAndPublicProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel = GetOwnProductModel.fromJson(response.response!.data);
        List<OwnProductData> products = getOwnProductModel.data;

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
    } finally {
      isLoading.value = false;
      ownDraftAndPublicProductResponse.value = ApiResponse.error('error');
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

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isEmpty) {
        clearSearch();
      } else {
        fetchListOfSearchProductApi(query.trim());
      }
    });
  }

  Future<void> fetchListOfSearchProductApi(String keyword) async {

    if(keyword.length < 3) return;

    try {
      searchProduct.value = keyword;
      ProductSearchLoading.value = true;

      Map<String, dynamic> params = { ApiKeys.name: keyword };

      final responseModel = await InventoryRepo().fetchInventoryBasedSearchProductApi(queryParams: params);

      if (responseModel.isSuccess) {
        searchProductResponse.value = ApiResponse.complete(responseModel);

        // Parse the API response
        final inventoryBasedSearchProductResponse = InventoryBasedSearchProductResponse.fromJson(
          responseModel.response?.data,
        );

        /// search variants
        searchProductVariantsList.clear();
        searchProductVariantsList.addAll(inventoryBasedSearchProductResponse.data);
        print("Total variants products: ${searchProductVariantsList.length}");

        /// search products
        searchProductsList.clear();
        searchProductsList.assignAll(inventoryBasedSearchProductResponse.unUsedProduct);
        print("Total products without variants: ${searchProductsList.length}");

        refresh();

      } else {
        searchProductResponse.value = ApiResponse.error('error');
      }

    } catch (e, s) {
      print("stack trace: $s");
      searchProductResponse.value = ApiResponse.error('error');
    }finally{
      ProductSearchLoading.value = false;
    }
  }

  bool validateSelectedVariants(List<VariantData> allVariants) {
    for (final entry in variantSelection.entries) {
      if (entry.value) {
        final variantId = entry.key;
        final sellingPriceStr = variantSellingPrice[variantId];

        if (sellingPriceStr == null || sellingPriceStr.trim().isEmpty) {
          // no price filled
          return false;
        }
      }
    }
    return true;
  }

  Future<void> cloneProductVariantApi() async {

    cloneProductVariantLoading.value = true;
    try {
      final params = buildSelectedVariantsPayload(
        searchProductVariantsList,
      );

      print("Final Payload: $params");

      final responseModel = await InventoryRepo().cloneProductVariantApi(params: params);

      if (responseModel.isSuccess) {
        cloneVariantProductResponse.value = ApiResponse.complete(responseModel);
         Get.until(
          (route) =>
                route.settings.name ==
                    RouteHelper.getInventoryScreenRoute(),
            );
        // Parse the API response
        // final inventoryBasedSearchProductResponse = InventoryBasedSearchProductResponse.fromJson(
        //   responseModel.response?.data,
        // );


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

  List<Map<String, dynamic>> buildSelectedVariantsPayload(
      List<VariantData> allVariants) {
    final payload = <Map<String, dynamic>>[];

    variantSelection.forEach((variantId, isSelected) {
      if (isSelected) {
        // find this variant in the full variant list
        final variantData = allVariants.firstWhere(
              (v) => v.finalVariant.id == variantId,
          orElse: () => throw Exception("Variant not found: $variantId"),
        );

        // get selling price from controller OR fallback to default
        final sellingPriceStr = variantSellingPrice[variantId];
        final sellingPrice = double.tryParse(sellingPriceStr ?? '') ??
            variantData.finalVariant.sellingPrice;

        payload.add({
          "productId": variantData.productInformation.id,
          "variantId": variantId,
          "sellingPrice": sellingPrice,
        });
      }
    });

    return payload;
  }


  void loadCategories() {
    // Simulate API call for categories
    Future.delayed(const Duration(seconds: 1), () {
      categories.value = [
        CategoryInventoryModel(
          id: '1',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 15,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        CategoryInventoryModel(
          id: '2',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 12,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active', createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        CategoryInventoryModel(
          id: '3',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 8,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CategoryInventoryModel(
          id: '4',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        CategoryInventoryModel(
          id: '5',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 18,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      filteredCategories.value = categories;
    });
  }

  void _filterData() {
    final searchQuery = searchController.text.toLowerCase();
    
    if (searchQuery.isEmpty) {
      // Show all items when no search query
      filteredProducts.value = products;
      filteredCategories.value = categories;
    } else {
      // Filter by search query only
      filteredProducts.value = products.where((product) => 
        product.name.toLowerCase().contains(searchQuery)
      ).toList();
      filteredCategories.value = categories.where((category) => 
        category.name.toLowerCase().contains(searchQuery)
      ).toList();
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    // Only apply status filter if no search query is active
    if (searchController.text.isEmpty) {
      if (filter == 'Draft') {
        filteredProducts.value = products.where((product) => product.status == 'Draft').toList();
        filteredCategories.value = categories.where((category) => category.status == 'Draft').toList();
      } else {
        // Show all items for other filters
        filteredProducts.value = products;
        filteredCategories.value = categories;
      }
    }
    // If there's a search query, let _filterData handle it
  }

  // void toggleProductSelection(ProductItem product) {
  //   if (product.isSelected) {
  //     // Deselect product
  //     product.isSelected = false;
  //     product.showSellingPrice = false;
  //     product.sellingPrice = '';
  //     selectedProducts.remove(product);
  //     showErrorBanner.value = false;
  //   } else {
  //     // Try to select product
  //     if (selectedProducts.length >= maxSelectionLimit) {
  //       showErrorBanner.value = true;
  //       return;
  //     }
  //
  //     product.isSelected = true;
  //     product.showSellingPrice = true;
  //     selectedProducts.add(product);
  //     showErrorBanner.value = false;
  //   }
  //
  //   // Update the lists
  //   final index = allProducts.indexWhere((p) => p.id == product.id);
  //   if (index != -1) {
  //     allProducts[index] = product;
  //   }
  //
  //   final filteredIndex = filteredProducts.indexWhere((p) => p.id == product.id);
  //   if (filteredIndex != -1) {
  //     filteredProducts[filteredIndex] = product;
  //   }
  //
  //   update();
  // }

  // void updateSellingPrice(ProductItem product, String price) {
  //   product.sellingPrice = price;
  //
  //   // Update the lists
  //   final index = allProducts.indexWhere((p) => p.id == product.id);
  //   if (index != -1) {
  //     allProducts[index] = product;
  //   }
  //
  //   final filteredIndex = filteredProducts.indexWhere((p) => p.id == product.id);
  //   if (filteredIndex != -1) {
  //     filteredProducts[filteredIndex] = product;
  //   }
  //
  //   update();
  // }


  void postProduct() {
    // if (selectedProducts.isEmpty) {
    //   // Show error or validation
    //   return;
    // }

    isLoading.value = true;

    // TODO: Implement post product functionality
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;
      Get.back();
    });
  }

  void dismissErrorBanner() {
    showErrorBanner.value = false;
  }

  void copyListing(String productId) {
    // Implement copy listing functionality

  }

  void addVariant(String productId) {
    // Implement add variant functionality

  }

  void showVariant(String productId) {
    // Implement show variant functionality

  }

  void addProduct() {
    // Navigate to add product screen

  }

  void addCategory() {
    // Navigate to add category screen

  }

  void addToCart(String productId) {
    // Implement add to cart functionality
   commonSnackBar(message: "product added successfully to cart.");
  }

  void handleProductOption(String option, String productId) {
    switch (option) {
      case 'Edit':
        commonSnackBar(message: "Product Edited.");
        break;
      case 'Unpublish':
        commonSnackBar(message: "Product Unpublished.");
        break;
      case 'Copy Listing':
        // copyListing(productId);
        break;
        case 'Out of Stock':
        // copyListing(productId);
        break;
      case 'Delete':
        // Implement delete functionality
        commonSnackBar(message: "Product Deleted.");
        break;
    }
  }

  void handleCategoryOption(String option, String categoryId) {
    switch (option) {
      case 'Edit':
        // Implement edit functionality
        commonSnackBar(message: "Edit Category.");
        break;
      case 'Unpublish':
        // Implement unpublish functionality
        commonSnackBar(message: "Unpublish Category.");
        break;
      case 'Copy Listing':
        copyListing(categoryId);
        break;
      case 'Delete':
        // Implement delete functionality
        commonSnackBar(message: "Category Deleted.");
        break;
    }
  }
}
 