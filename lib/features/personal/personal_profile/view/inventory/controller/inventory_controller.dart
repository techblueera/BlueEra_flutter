import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
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
      isLoading.value = true;

      Map<String, dynamic> queryParams = {
        // ApiKeys.businessId: businessId,
        'ownerId': businessId,
        'ownerType': ProductServiceProviderType.business.title,
      };

      if(isDraftProduct!=null){
        queryParams['DRAFT'] = isDraftProduct;
      }

      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsApi(queryParams: queryParams);
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

      final responseModel = await InventoryRepo().fetchInventoryBasedSearchProductApi(queryParams: params);

      if (responseModel.isSuccess) {
        searchProductResponse.value = ApiResponse.complete(responseModel);

        final inventoryBasedSearchProductResponse = InventoryBasedSearchProductResponse.fromJson(
          responseModel.response?.data,
        );

        final newVariants = inventoryBasedSearchProductResponse.data;
        final newProducts = inventoryBasedSearchProductResponse.unUsedProduct;

        if (!isLoadMore) {
          searchProductVariantsList.assignAll(newVariants);
          searchProductsList.assignAll(newProducts);
        }else {
          searchProductVariantsList.addAll(newVariants);
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


  void fillMissingSellingPricesWithDefaults(
      List<VariantData> allVariants, List<String> missingPriceIds) {
    for (final variantId in missingPriceIds) {
      final variantData = allVariants.firstWhere(
            (v) => v.finalVariant.id == variantId,
        orElse: () => throw Exception("Variant not found: $variantId"),
      );

     updateSellingPrice(variantId, variantData.finalVariant.sellingPrice.toString());

    }

    // refresh();

  }

  Future<void> cloneProductVariantApi() async {
    cloneProductVariantLoading.value = true;
    try {
      final clones = _buildSelectedVariantsPayload(searchProductVariantsList);

      if (clones.isEmpty) {
        print("No variants selected — skipping API call");
        return;
      }

      // Construct body
      final body = {
        ApiKeys.owner: {
          ApiKeys.id: businessId,
          ApiKeys.type: ProductServiceProviderType.business.title,
        },
        ApiKeys.clones: clones,
        //  'clones': jsonEncode(clones),
      };

      print("Final Clone Payload: $body");

      final responseModel = await InventoryRepo().cloneProductVariantApi(params: body);

      if (responseModel.isSuccess) {
        cloneVariantProductResponse.value = ApiResponse.complete(responseModel);
         Get.until(
          (route) =>
                route.settings.name ==
                    RouteHelper.getInventoryScreenRoute(),
            );

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

          payload.add({
            "product_id": variantData.productInformation.id,
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

  RxBool isDeleteProductVariantLoading = false.obs;

  void deleteProduct() {
    try {
      isDeleteProductVariantLoading.value = true;

      Map<String, dynamic> queryParams = {
        'ownerId': businessId,
        'ownerType': ProductServiceProviderType.business.title,
      };

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
 