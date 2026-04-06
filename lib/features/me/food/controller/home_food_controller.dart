import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:get/get.dart';

class RestaurantController extends GetxController {
  bool foodDataNeedsRefresh = false;

  Rx<ApiResponse> foodHomeDataResponse =
      ApiResponse.initial('Initial').obs;

  // Observables
  var isLoading = true.obs;
  var restaurantData = Rxn<FoodData>();
  var foodMenuNestedCategory = <GroceryNestedCategoryModel>[].obs;
  var allFoodItems = <Items>[].obs;
  var restaurantSpecials = <RestaurantSpecial>[].obs;

  /// ─── Discount Products (paginated) ───
  /// Dedicated list for the "Offer Dish (Discount)" horizontal section.
  /// Fed by the `food-service/api/discountProducts` endpoint and paginated
  /// independently of the home API.
  RxList<CategoryFoodProductData> discountFoodItems = <CategoryFoodProductData>[].obs;
  RxBool isDiscountProductsLoading = false.obs;
  RxBool isDiscountProductsLoadingMore = false.obs;
  int _discountProductsPage = 1;
  bool _discountProductsHasMore = true;
  static const int _discountProductsLimit = 20;

  bool get discountProductsHasMore => _discountProductsHasMore;

  void fetchHomeData({required String businessId}) async {
    try {
      foodHomeDataResponse.value = ApiResponse.initial('Initial');

      // call repo
      ResponseModel responseModel = await FoodRepo()
          .getHomeFoodByIdRepo(businessProfile: businessId);

      if (responseModel.isSuccess) {
        restaurantData.value =
            FoodHomeResModel.fromJson(responseModel.response?.data).data;
        foodMenuNestedCategory.value = restaurantData.value?.foodMenu ?? [];
        restaurantSpecials.value = restaurantData.value?.restaurantSpecials ?? [];

        foodHomeDataResponse.value = ApiResponse.complete(responseModel);

      } else {
        foodHomeDataResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      foodHomeDataResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }

  /// Fetch paginated discount food products.
  ///
  /// Pass [isLoadMore] = true to append the next page. When called with
  /// [isLoadMore] = false (default) the list, page counter and
  /// `hasMore` flag are all reset first — use this for initial load /
  /// pull-to-refresh.
  Future<void> fetchDiscountFoodProducts({
    required String businessId,
    bool isLoadMore = false,
  }) async {
    try {
      if (isLoadMore) {
        if (!_discountProductsHasMore ||
            isDiscountProductsLoadingMore.value ||
            isDiscountProductsLoading.value) {
          return;
        }
        isDiscountProductsLoadingMore.value = true;
      } else {
        isDiscountProductsLoading.value = true;
        discountFoodItems.clear();
        _discountProductsPage = 1;
        _discountProductsHasMore = true;
      }

      final Map<String, dynamic> queryParams = {
        ApiKeys.page: _discountProductsPage,
        ApiKeys.limit: _discountProductsLimit,
      };

      final ResponseModel response = await FoodRepo()
          .getDiscountFoodProductsRepo(
          businessId: businessId,
          queryParams: queryParams
      );

      if (response.isSuccess) {
        var foodProductResponseModel = FoodProductResponseModel.fromJson(response.response?.data);

        List<CategoryFoodProductData> newItems = (foodProductResponseModel.data ?? [])
            .where((item) => item.productDetails != null) // Filter out nulls for safety
            .map((item) => item.productDetails!)         // Extract the internal productDetails
            .toList();

        if (newItems.isNotEmpty) {
          if (isLoadMore) {
            discountFoodItems.addAll(newItems);
          } else {
            discountFoodItems.assignAll(newItems);
          }
          _discountProductsPage++;
          // If the server returned fewer than the page size, we've reached
          // the end — no point asking for another page.
          if (newItems.length < _discountProductsLimit) {
            _discountProductsHasMore = false;
          }
        } else {
          _discountProductsHasMore = false;
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('fetchDiscountFoodProducts error: $e\n$s');
    } finally {
      if (isLoadMore) {
        isDiscountProductsLoadingMore.value = false;
      } else {
        isDiscountProductsLoading.value = false;
      }
    }
  }

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) {
    // Basic validation logic
    bool isValid = branchName.isNotEmpty &&
        website.isURL &&
        address.isNotEmpty &&
        department.isNotEmpty &&
        email.isEmail &&
        phone.length >= 10;

    isFormValid.value = isValid;
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(
          message: "Please select a valid location from the search.");
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "name": branchName,
        "pageLink": website,
        "department": department,
        "email": email,
        "phone": phone,
        "location": {
          "name": address,
          "type": "Point",
          "coordinates": [selectedLat, selectedLng]
        },
      };

      ResponseModel response =
          await FoodRepo().addFoodContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details added successfully");
        Get.back();
        fetchHomeData(businessId: businessId);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      print("Request Body: $body");
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
}
