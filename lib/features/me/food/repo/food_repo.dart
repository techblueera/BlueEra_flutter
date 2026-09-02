import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FoodRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getFoodAiGenerateRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP("${foodAiGenerate}",
        params: reqBody, showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET FOOD CATEGORY...
  Future<ResponseModel> getFoodNestedCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP("${categoryTree}",
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET CHILDREN OF A FOOD CATEGORY BY KEY (e.g. RESTAURANT_SPECIAL)...
  Future<ResponseModel> getFoodCategoryChildrenByKeyRepo(String key) async {
    final response = await ApiBaseHelper().getHTTP(
        foodCategoryChildrenByKey(key),
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> createFoodCategoryRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      foodProduct,
      params: params,
      isMultipart: false,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateFoodVariantRepo(
      {required Map<String, dynamic> params, required String foodID}) async {
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

  Future<ResponseModel> addFoodVariantRepo(
      {required Map<String, dynamic> params, required String foodID}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${foodProduct}/${foodID}/variants",
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addKitchenInventoryRepo({
    required dynamic params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      kitchenInventory,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Bulk-flip the manual out-of-stock flag on one or more kitchen-inventory
  /// records. `PATCH food-service/api/kitchen-inventory/stock/flip-out-of-stock`.
  ///
  /// Touches `isOutOfStock` only — batch quantity is not changed.
  ///
  /// No value is sent: the endpoint INVERTS each id rather than setting it (see
  /// [foodFlipOutOfStock]). Callers that need to know the resulting state read
  /// it back off the response, or rely on having asked for the inverse of what
  /// they were already showing.
  Future<ResponseModel> flipOutOfStockRepo({
    required List<String> inventoryIds,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      foodFlipOutOfStock,
      params: {'inventoryIds': inventoryIds},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update one kitchen-inventory record (a published variant) by its id.
  /// `PUT food-service/api/kitchen-inventory/{inventoryId}`.
  ///
  /// **PUT, not PATCH** — the server answers PATCH with `Cannot PATCH
  /// /api/kitchen-inventory/{id}`; that route is registered for PUT only,
  /// unlike `stock/flip-out-of-stock`, which is a PATCH.
  ///
  /// **Prices live under `price`, and the block is REPLACED.** Verified against
  /// the live service:
  ///
  ///   * a top-level `{"baseSellingPrice": 84, "mrp": 85}` returns
  ///     `success: true` and changes NOTHING — those keys are silently ignored;
  ///   * `{"price": {"mrp": 85, "sellingPrice": 84}}` does apply — and reset
  ///     `packingCharges` from 20 to 0, because the omitted keys of the
  ///     subdocument fall back to their defaults.
  ///
  /// So a price edit MUST send the whole `price` block, `currency` and
  /// `packingCharges` included. [getKitchenInventoryByIdRepo] is how the caller
  /// gets the values it is not editing.
  Future<ResponseModel> updateKitchenInventoryVariantRepo({
    required String inventoryId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      kitchenInventoryById(inventoryId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// One kitchen-inventory record in full.
  /// `GET food-service/api/kitchen-inventory/{inventoryId}`.
  ///
  /// Read before a price write, so the fields the edit does not touch can be
  /// sent back unchanged — see [updateKitchenInventoryVariantRepo].
  Future<ResponseModel> getKitchenInventoryByIdRepo({
    required String inventoryId,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      kitchenInventoryById(inventoryId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// The productVariant ids already stocked by this restaurant.
  /// `GET food-service/api/kitchen-inventory/product-variant-ids?businessId=`.
  ///
  /// Read before the pre-publish selection screens render, so a variant the
  /// merchant already has cannot be picked and published twice.
  Future<ResponseModel> getInventoryProductVariantIdsRepo({
    required String businessId,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      foodInventoryProductVariantIds,
      params: {ApiKeys.businessId: businessId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  /// Delete a single kitchen-inventory entry (a product variant) by its id.
  /// `DELETE food-service/api/kitchen-inventory/{inventoryId}`.
  Future<ResponseModel> deleteKitchenInventoryRepo({
    required String inventoryId,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
      kitchenInventoryById(inventoryId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Food products grouped by root category — one section per root category,
  /// each with a capped product list — for the "Quick Upload" rails.
  Future<ResponseModel> getFoodProductsByRootCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      foodProductsByRootCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Cross-category food product showcase (paginated) for the category menu
  /// screen's "Suggested Products" section.
  Future<ResponseModel> getFoodCategoryShowcaseRepo(
      {required Map<String, dynamic> queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      foodCategoryShowcase,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getFoodByCategoryIdRepo(
      {required Map<String, dynamic> queryPatrams}) async {
    final response = await ApiBaseHelper().getHTTP(
      foodServiceProduct,
      params: queryPatrams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getHomeFoodByIdRepo(
      {required String businessProfile}) async {
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
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Fetch property photos
  /// `showProgress: false` — a gallery read that fills a tab, not an action the
  /// user is waiting on.
  Future<ResponseModel> getFoodServicePhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      homeFoodGallery,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteFoodServicePhotosRepo(
      {required String imgID, required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$homeFoodGallery/$imgID",
      params: reqBody,
      showProgress: false,
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
  Future<ResponseModel> fetchSingleFoodProductDetailsRepo(
      {required String foodID}) async {
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

  Future<ResponseModel> createHomeMadeFood(
      {required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().postHTTP(
      homeFood,
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateHomeMadeFood(
      {required String id, required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().putHTTP(
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
  Future<ResponseModel> fetchAllHomeFoodItems(
      {Map<String, dynamic>? queryParams}) async {
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
