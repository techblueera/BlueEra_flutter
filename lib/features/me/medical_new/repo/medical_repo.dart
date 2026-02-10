import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class MedicalRepo extends BaseService {

  Future<ResponseModel> searchGroceryCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      searchMedicalCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> userSearchGroceryCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      userSearchMedicalCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create New Grocery Product Variant
  Future<ResponseModel> createNewGroceryProductVariantRepo(
      {required String productId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createNewMedicalProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FETCH My GROCERIES SERVICES....
  Future<ResponseModel> fetchMyGroceryProductsRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      myMedicalProducts,
      showProgress: false,
      params: queryParam,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Add Grocery Product to inventory
  Future<ResponseModel> addGroceryProductVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addMedicalProductVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch My grocery Category
  Future<ResponseModel> fetchGroceryCategoryWithVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalCategoryWithVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Grocery Order Request
  Future<ResponseModel> groceryOrderRepo({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Grocery Order update Request
  Future<ResponseModel> updateGroceryOrderRepo(
      {Map<String, dynamic>? params, required String orderId}) async {
    final response = await ApiBaseHelper().putHTTP(
      updateMedicalOrder(orderId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch Near By Riders
  Future<ResponseModel> fetchNearByRidersRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getNearByRiderApi,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Order Request To Rider
  Future<ResponseModel> orderReqToRiderRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      sendOrderReqToRider,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET ALL GROCERY ORDER...
  Future<ResponseModel> groceryOrderServiceRepo(
      {required String? orderID,
        required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalServiceOrder(orderID ?? " "),
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ACCEPT GROCERY ACCEPT ORDER...
  Future<ResponseModel> createGroceryAcceptOrderServiceRepo(
      {required String? rideOrderId,
        required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalServiceOrder(rideOrderId ?? " "),
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  /// ACCEPT GROCERY ACCEPT ORDER...
  Future<ResponseModel> submitGroceryAcceptOrderServiceRepo(
      {required String? rideOrderId,required String? itemId,
        required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().patchHTTP(
      "${ridersMedicalOrders}${rideOrderId}/businesses/$businessId/items/$itemId/pickup",
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// FETCH MY GROCERY ORDERS...
  Future<ResponseModel> fetchGroceryOrdersRepo(
      {required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().getHTTP(
      myMedicalOrders,
      showProgress: false,
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GROCERY ITEM AVAILABILITY...
  Future<ResponseModel> groceryOrderItemAvailabilityRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalOrderAvailableItem,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GROCERY AVAILABLE ITEMS...
  Future<ResponseModel> groceryOrderAvailableItemRepo(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalOrderAvailableItem,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> submitGroceryOrderToRiderRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalOrderUpdatePaymentStatus,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> fetchGroceryNestedCategoryRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalNestedCategory,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }



}
