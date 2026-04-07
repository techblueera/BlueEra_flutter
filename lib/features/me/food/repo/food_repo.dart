import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FoodRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getFoodAiGenerateRepo({required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${foodAiGenerate}",
        params: reqBody,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET FOOD CATEGORY...
  Future<ResponseModel> getFoodNestedCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${categoryTree}",
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> createFoodCategoryRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      foodProduct,
      params: params,
      isMultipart: false,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateFoodVariantRepo({required Map<String, dynamic> params,required String foodID}) async {
    final response = await ApiBaseHelper().putHTTP(
      "${foodProduct}/${foodID}",
      params: params,
      isMultipart: false,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addFoodVariantRepo({required Map<String, dynamic> params,required String foodID}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${foodProduct}/${foodID}/variants",
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addKitchenInventoryRepo({required dynamic params,}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${kitchenInventory}",
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getFoodByCategoryIdRepo({required Map<String, dynamic> queryPatrams}) async {
    final response = await ApiBaseHelper().getHTTP(
      foodServiceProduct,
      params: queryPatrams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getHomeFoodByIdRepo({required String businessProfile}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${home}$businessProfile",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Paginated discount food products for the Offer Dish (Discount) section.
  Future<ResponseModel> getDiscountFoodProductsRepo({
    required String businessId,
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      discountFoodProducts(businessId),
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create a new contact
  Future<ResponseModel> addFoodContactRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      homeFoodContactUs,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // POST: Upload/Add a new photo
  Future<ResponseModel> addFoodServicePhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      homeFoodGallery,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // GET: Fetch property photos
  Future<ResponseModel> getFoodServicePhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      homeFoodGallery,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteFoodServicePhotosRepo({required String imgID,required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$homeFoodGallery/$imgID",
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// FOOD SNAP SEARCH...
  Future<ResponseModel> fetchFoodSnapSearchRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      foodSnapSearch,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  ///  SINGLE FOOD PRODUCT DETAILS...
  Future<ResponseModel> fetchSingleFoodProductDetailsRepo({required String foodID}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${foodProduct}/${foodID}",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET My FOOD Inventory With Product...
  Future<ResponseModel> getMyFoodProductByCategoryIdRepo({
    required Map<String, dynamic> queryParam,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      kitchenInventory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET My FOOD Inventory With Product...
  Future<ResponseModel> getUserFoodProductsCategoryIdRepo({
    required Map<String, dynamic> queryParam,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      foodCustomerSearch,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> fetchAllHomeMadeFoodItems() async {
    final response = await ApiBaseHelper().getHTTP(
      homeFoodByUserId,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> createHomeMadeFood({required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().postHTTP(
      homeFood,
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateHomeMadeFood({required String id, required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().patchHTTP(
      '$homeFood/$id',
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Place bulk food self-pickup order
  Future<ResponseModel> placeBulkFoodOrderApi(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      placeBulkFoodOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Mark food self-pickup order as ready (restaurant side)
  Future<ResponseModel> markFoodOrderReadyRepo(
      {required String orderId}) async {
    final response = await ApiBaseHelper().putHTTP(
      foodOrderReady(orderId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Consumer: fetch all home-made food items (all users, filtered by query params)
  Future<ResponseModel> fetchAllHomeFoodItems({Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      homeFood,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}

