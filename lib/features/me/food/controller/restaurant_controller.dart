import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:get/get.dart';

class RestaurantController extends GetxController {
  bool foodDataNeedsRefresh = false;

  Rx<ApiResponse> foodHomeDataResponse = ApiResponse.initial('Initial').obs;

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
  RxList<CategoryFoodProductData> discountFoodItems =
      <CategoryFoodProductData>[].obs;
  RxBool isDiscountProductsLoading = false.obs;
  RxBool isDiscountProductsLoadingMore = false.obs;
  int _discountProductsPage = 1;
  bool _discountProductsHasMore = true;
  static const int _discountProductsLimit = 20;

  bool get discountProductsHasMore => _discountProductsHasMore;

  /// Freshness guard for the store's home data, keyed per business so a
  /// re-entry for the same restaurant skips the network call.
  final FetchCache _homeCache = FetchCache();

  /// Load home + discount data only when it isn't already loaded & fresh for
  /// this [businessId]. Use on screen (re)entry; call [fetchHomeData] /
  /// [fetchDiscountFoodProducts] directly for explicit refreshes.
  /// AWAITS both fetches. Callers that only want them fired (the tab
  /// dispatcher) simply don't await this — but the ones that need to READ the
  /// result afterwards (the go-live catalogue gate, the app-open kickstart)
  /// cannot work unless awaiting this actually means the data has landed. It
  /// used to fire both and return immediately, so those callers always saw an
  /// unresolved response and treated an empty menu as "not loaded".
  Future<void> fetchHomeAndDiscountIfNeeded({required String businessId}) async {
    if (_homeCache.isFresh('foodHome|$businessId',
        hasData: restaurantData.value != null)) {
      return;
    }
    await Future.wait([
      fetchHomeData(businessId: businessId),
      fetchDiscountFoodProducts(businessId: businessId),
    ]);
  }

  /// Returns a Future so callers CAN await the menu; existing call sites that
  /// fire and forget are unaffected.
  Future<void> fetchHomeData({required String businessId}) async {
    try {
      foodHomeDataResponse.value = ApiResponse.initial('Initial');

      // call repo
      ResponseModel responseModel =
          await FoodRepo().getHomeFoodByIdRepo(businessProfile: businessId);

      if (responseModel.isSuccess) {
        restaurantData.value =
            FoodHomeResModel.fromJson(responseModel.response?.data).data;
        foodMenuNestedCategory.value = restaurantData.value?.foodMenu ?? [];
        restaurantSpecials.value =
            restaurantData.value?.restaurantSpecials ?? [];

        foodHomeDataResponse.value = ApiResponse.complete(responseModel);
        _homeCache.mark('foodHome|$businessId');
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
              businessId: businessId, queryParams: queryParams);

      if (response.isSuccess) {
        var foodProductResponseModel =
            FoodProductResponseModel.fromJson(response.response?.data);

        // Same outer-`inventoryId` → variant copy used by the category
        // listing flow. Discount API embeds the id at the variant
        // level so the `??=` is usually a no-op here, but doing the
        // propagation defensively keeps the two flows in sync.
        List<CategoryFoodProductData> newItems =
            (foodProductResponseModel.data ?? [])
                .where((item) => item.productDetails != null)
                .map((item) {
                  final pd = item.productDetails!;
                  final outerInv = item.inventoryId;
                  if (outerInv != null && outerInv.isNotEmpty) {
                    for (final v in pd.variants ?? const <FoodVariants>[]) {
                      v.inventoryId ??= outerInv;
                    }
                  }
                  return pd;
                })
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
      commonSnackBar(message: AppStrings.foodSelectValidLocation.tr);
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
                AppStrings.foodBranchDetailsAdded.tr);
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
