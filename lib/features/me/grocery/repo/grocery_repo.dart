import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class GroceryRepo extends BaseService {
  /// Update a single inventory record (one variant) — price/mrp etc.
  /// `PUT grocery-service/api/inventory/{inventoryId}`.
  Future<ResponseModel> updateInventoryVariantRepo({
    required String inventoryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      updateGroceryInventory(inventoryId),
      params: params,
      showProgress: false,
    );
  }

  /// Delete a single inventory variant by its inventory id.
  /// `DELETE grocery-service/api/inventory/{inventoryId}` — same path as the
  /// update endpoint, DELETE verb.
  Future<ResponseModel> deleteInventoryVariantRepo({
    required String inventoryId,
  }) async {
    return ApiBaseHelper().deleteHTTP(
      updateGroceryInventory(inventoryId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  Future<ResponseModel> searchGroceryCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      searchGroceryViaCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> groceryCategoryOfChildrenRepo(
      {required String key}) async {
    final response = await ApiBaseHelper().getHTTP(
      GroceryCategoryOfChildren(key),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> groceryCategoryOfChildWithInventoryRepo(
      {required String key}) async {
    final response = await ApiBaseHelper().getHTTP(
      GroceryCategoryOfChildrenWithInventory(key),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> userSearchGroceryCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      userSearchGroceryCategory,
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
      createNewProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FETCH GROCERIES PRODUCTS (SELF AND OTHER)....
  Future<ResponseModel> fetchGroceryProductsRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      groceryProducts,
      showProgress: false,
      params: queryParam,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FETCH GLOBAL GROCERIES PRODUCTS ....
  Future<ResponseModel> fetchGlobalGroceryProductsRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      globalGroceryProducts,
      showProgress: false,
      params: queryParam,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Add Grocery Product to product
  Future<ResponseModel> addGroceryProductVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addGroceryProductVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch My grocery Category
  Future<ResponseModel> fetchGroceryCategoryWithInventoryRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
      groceryCategoryWithInventory,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  /// Fetch Other grocery Category
  Future<ResponseModel> fetchPublicGroceryCategoryWithInventoryRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
      publicGroceryCategoryWithInventory,
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
      groceryOrder,
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
      updateGroceryOrder(orderId),
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



  /// ACCEPT GROCERY ACCEPT ORDER...
  Future<ResponseModel> createGroceryAcceptOrderServiceRepo(
      {required String? rideOrderId,
      required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${groceryServiceOrder(rideOrderId ?? " ")}",
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
      "${ridersGroceryOrders}${rideOrderId}/businesses/$businessId/items/$itemId/pickup",
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
      myGroceryOrders,
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
      groceryOrderItemAvailability,
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
      groceryOrderAvailableItem,
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
      groceryOrderUpdatePaymentStatus,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> fetchGroceryNestedCategoryWithInventoryRepo(
      {required Map<String, dynamic> queryParams}
      ) async {
    final response = await ApiBaseHelper().getHTTP(
      groceryNestedCategoryWithInventory,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> fetchGroceryNestedCategoryRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      groceryNestedCategory,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GROCERY BUSINESS PRODUCTS (SELF)...
  Future<ResponseModel> fetchGroceryBusinessProductsRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      groceryBusinessProducts,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GROCERY BUSINESS PRODUCTS (Other)...
  Future<ResponseModel> fetchPublicGroceryBusinessProductsRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      publicGroceryBusinessProducts,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GROCERY SNAP SEARCh...
  Future<ResponseModel> fetchGrocerySnapSearchRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      grocerySnapSearch,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Add Grocery Product to product
  Future<ResponseModel> missingGroceryProductRequestsRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      missingGroceryProductRequests,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  /// Mark Self-Pickup Order as Ready
  Future<ResponseModel> markSelfPickupOrderReadyRepo(
      {required String orderId}) async {
    final response = await ApiBaseHelper().putHTTP(
      selfPickupOrderReady(orderId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> placeBulkGroceryOrderApi(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      placeBulkGroceryOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GROCERY SNAP SEARCH WITH INVENTORY ...
  Future<ResponseModel> fetchGrocerySnapSearchWithInventoryRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      grocerySnapSearchWithInventory,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
