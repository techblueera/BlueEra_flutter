import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/children_of_grocery_category_response.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/model/grocery_product_model.dart';
import 'package:BlueEra/features/common/food/repo/grocery_repo.dart';
import 'package:get/get.dart';

class UserGroceryController extends GetxController{
  Rx<ApiResponse> groceryCategoryOfChildrenResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> userGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;

  RxList<VariantsData> selectedGroceriesVariants = <VariantsData>[].obs;

  Rx<CollapsibleGridModel> selectedGroceryData = CollapsibleGridModel(
      icon: "chips.png",
      label: "Chips &\nNamkeens",
      tagId: CHIPS_NAMKEEN
  ).obs;
  RxBool isInitialLoading = false.obs;

  RxInt selectedTabIndex = 0.obs;
  String get currentTabKey =>
      selectedTabIndex.value == 0                    // “All” tab
          ? selectedGroceryData.value.tagId                    // top-level key
          : arrChildrenOfGroceryCategory[selectedTabIndex.value - 1].key ?? '';

  void addGroceryVariants(VariantsData v){
    selectedGroceriesVariants.add(v);
  }

  void removeGroceryVariants(int index){
    selectedGroceriesVariants.removeAt(index);
  }

  double get totalSelectedVariantsSellingPrice {
    return selectedGroceriesVariants.fold<double>(
      0.0,
          (sum, variant) {
       // final groceryController = getOrPut(() => GroceryController());

        // final price = groceryController.getPriceDetails(variant.pricing);

        // final minSellingPrice = _minPriceFromRange(price.sellingRange);

        // return sum + minSellingPrice;
        return sum + (variant.pricing?[0].sellingPrice??0.0);
      },
    );
  }

  // double _minPriceFromRange(String range) {
  //   // Examples:
  //   // "₹100" → 100
  //   // "₹90 - ₹120" → 90
  //
  //   final clean = range.replaceAll('₹', '').trim();
  //
  //   if (clean.contains('-')) {
  //     return double.tryParse(clean.split('-').first.trim()) ?? 0.0;
  //   }
  //
  //   return double.tryParse(clean) ?? 0.0;
  // }

  Future<void>  fetchUserGrocery() async {
    try {
      isInitialLoading.value = true;
      await Future.wait([
        fetchChildrenOfGroceryCategory(),
        fetchUserGroceries(),
      ]);
    } catch (e) {
    } finally {
      isInitialLoading.value = false;
    }
  }

  RxBool isGroceryCategoryOfChildrenLoading = false.obs;
  RxList<ChildrenOfGroceryCategoryResponse> arrChildrenOfGroceryCategory =
      <ChildrenOfGroceryCategoryResponse>[].obs;

  Future<void> fetchChildrenOfGroceryCategory() async {
    try {

      isGroceryCategoryOfChildrenLoading.value = true;
      final response =
      await GroceryRepo().groceryCategoryOfChildrenRepo(key: currentTabKey);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      arrChildrenOfGroceryCategory.value =
          ChildrenOfGroceryCategoryResponse.fromJsonList(jsonData);
      groceryCategoryOfChildrenResponse.value = ApiResponse.complete(response);
      update();
    } catch (e) {
      groceryCategoryOfChildrenResponse.value = ApiResponse.error('error');
      update();
    } finally {
      isGroceryCategoryOfChildrenLoading.value = false;
    }
  }

  RxBool isUserGroceryLoading = false.obs;
  RxList<GroceryProductData> arrUserGrocery = <GroceryProductData>[].obs;
  RxBool isUserGroceryLoadingMore = false.obs;
  int userGroceryPage = 1;
  bool userGroceryHasMore = true;
  int pageLimit = 20;

  Future<void> fetchUserGroceries({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isUserGroceryLoadingMore.value = true;
      } else {
        arrUserGrocery.clear();
        isUserGroceryLoading.value = true;
        userGroceryPage = 1;
        userGroceryHasMore = true;
      }

      String postalCode = LocationService.userCurrentAddress[5];
      if(postalCode.isEmpty) return;

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.pincode: postalCode,
        ApiKeys.key: currentTabKey,
        ApiKeys.page: userGroceryPage,
        ApiKeys.limit: pageLimit
      };

      final response = await GroceryRepo()
          .userSearchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      userGroceryCategoryResponse.value = ApiResponse.complete(response);

      final groceryProductModel = GroceryProductModel.fromJson(response.response?.data);
      List<GroceryProductData> newItems = groceryProductModel.data ?? [];

      if (newItems.isNotEmpty) {
        if (isLoadMore) {
          arrUserGrocery.addAll(newItems);
        } else {
          arrUserGrocery.assignAll(newItems);
        }

        userGroceryPage++;
      } else {
        userGroceryHasMore = false;
      }

      log('total grocery-- ${arrUserGrocery.length}');
      update();
    } catch (e, s) {
      userGroceryCategoryResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isUserGroceryLoadingMore.value = false;
      } else {
        isUserGroceryLoading.value = false;
      }
    }
  }

}