import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/food/model/food_category_res_model.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
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
  RxList<Children> subCategoryTabs = <Children>[].obs;

  // Variant related var and methods
  RxMap<String, SelectedFoodItem> selectedVariantsMap = <String, SelectedFoodItem>{}.obs;

  int get totalVariantsCount => selectedVariantsMap.values
      .fold(0, (sum, item) => sum + item.selectedVariants.length);

// Check if a specific variant is selected for a product
  bool isVariantSelected(String pId, String variantId) {
    return selectedVariantsMap[pId]?.selectedVariants.any((v) => v.id == variantId) ?? false;
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
        ApiKeys.pincode: postalCode,
        ApiKeys.radius: kmRadius5000,
        ApiKeys.page: foodCatProductsWithInvPage,
        ApiKeys.limit: 20
      };

      queryParams.addAll(categoryIdParams);

      ResponseModel response =
      await FoodRepo().getUserFoodProductsCategoryIdRepo(
        queryParam: queryParams,
      );
      if (response.isSuccess) {
        var myFoodProductResponseModel = FoodProductResponseModel.fromJson(response.response?.data);

        List<CategoryFoodProductData> newItems = (myFoodProductResponseModel.data ?? [])
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