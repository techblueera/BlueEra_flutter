import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectedFoodItem {
  final CategoryFoodProductData product;
  final List<FoodVariants> selectedVariants;

  SelectedFoodItem({required this.product, required this.selectedVariants});
}

class FoodCustomerController extends GetxController{
  var selectedCategoryId = ''.obs;
  var selectedSubCategoryId = ''.obs;
  RxList<GroceryNestedCategoryModel> subCategoryTabs = <GroceryNestedCategoryModel>[].obs;

  // Variant related var and methods
  RxMap<String, SelectedFoodItem> selectedVariantsMap = <String, SelectedFoodItem>{}.obs;

  int get totalVariantsCount => selectedVariantsMap.values
      .fold(0, (sum, item) => sum + item.selectedVariants.length);

// Check if a specific variant is selected for a product
  bool isVariantSelected(String pId, String variantId) {
    return selectedVariantsMap[pId]?.selectedVariants.any((v) => v.id == variantId) ?? false;
  }

  void clearControllerFields() {
    // 1. Reset Category Selection
    selectedCategoryId.value = '';
    selectedSubCategoryId.value = '';
    subCategoryTabs.clear();

    // 2. Clear Cart / Selected Variants
    selectedVariantsMap.clear();

    // 3. Reset Pagination & Product Lists
    categoryCustomerFoodProductDataList.clear();
    foodCatProductsWithInvPage = 1;
    foodCatProductsWithInvHasMore = true;

    // 4. Reset Loading States (Safety)
    isFoodCatProductsWithInvLoading.value = false;
    isFoodCatProductsWithInvLoadingMore.value = false;

    debugPrint("FoodCustomerController Data Cleared");
  }

  /// Customer Products By Category
  RxList<CategoryFoodProductData> categoryCustomerFoodProductDataList = <CategoryFoodProductData>[].obs;
  RxBool isFoodCatProductsWithInvLoading = false.obs;
  RxBool isFoodCatProductsWithInvLoadingMore = false.obs;
  int foodCatProductsWithInvPage = 1;
  bool foodCatProductsWithInvHasMore = true;

  Future<void> getCustomerFoodProductByCategoryIdApi(
      {
        required Map<String, String> categoryIdParams,
        String? visitBusinessId,
        bool isLoadMore = false
      }) async {
    try {
      if (isLoadMore) {
        isFoodCatProductsWithInvLoadingMore.value = true;
      } else {
        isFoodCatProductsWithInvLoading.value = true;
        categoryCustomerFoodProductDataList.clear();
        foodCatProductsWithInvPage = 1;
        foodCatProductsWithInvHasMore = true;
      }

      String postalCode = LocationService.userCurrentAddress.value.postalCode;

      Map<String, dynamic> queryParams = {
        ApiKeys.page: foodCatProductsWithInvPage,
        ApiKeys.limit: 20
      };
      if(visitBusinessId==null) {
        queryParams[ApiKeys.pincode] = postalCode;
        queryParams[ApiKeys.radius] = kmRadius5000;
      }else{
        queryParams[ApiKeys.businessId] = visitBusinessId;
      }
      queryParams.addAll(categoryIdParams);

      ResponseModel response =
      await FoodRepo().getUserFoodProductsCategoryIdRepo(
        queryParam: queryParams,
      );
      if (response.isSuccess) {
        var foodProductResponseModel = FoodProductResponseModel.fromJson(response.response?.data);

        List<CategoryFoodProductData> newItems = (foodProductResponseModel.data ?? [])
            .where((item) => item.productDetails != null) // Filter out nulls for safety
            .map((item) => item.productDetails!)         // Extract the internal productDetails
            .toList();

        if (newItems.isNotEmpty) {
          if (isLoadMore) {
            categoryCustomerFoodProductDataList.addAll(newItems);
          } else {
            categoryCustomerFoodProductDataList.assignAll(newItems);
          }

          foodCatProductsWithInvPage++;
        } else {
          foodCatProductsWithInvHasMore = false;
        }
        debugPrint('total food products-- ${categoryCustomerFoodProductDataList.length}');

      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      debugPrint('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isFoodCatProductsWithInvLoadingMore.value = false;
      } else {
        isFoodCatProductsWithInvLoading.value = false;
      }
    }
  }




}