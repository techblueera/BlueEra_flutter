import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class AutomotiveProductRepo extends BaseService {
  /// `GET automotive-service/api/inventory/product-variant-ids?businessId=` —
  /// the catalogue-variant ids this shop already stocks.
  ///
  /// Backs the "already added" state on the pre-publish selection screens; see
  /// [AutomotiveProductController.fetchStockedVariantIdsIfNeeded]. Automotive
  /// mirror of [FoodRepo.getInventoryProductVariantIdsRepo].
  ///
  /// `showProgress: false`: this decorates a screen the merchant is already
  /// reading, so it must not put a blocking overlay over it.
  Future<ResponseModel> getInventoryProductVariantIdsRepo({
    required String businessId,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveInventoryProductVariantIds,
      params: {ApiKeys.businessId: businessId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  /// Generate Ai AutomotiveProduct...
  Future<ResponseModel> generateAiProductContentRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      generateAiContent,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Own AutomotiveProducts...
  Future<ResponseModel> fetchProductsRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveAllProducts,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Public, cross-business products for a category — backs the consumer
  /// category-discover screen.
  /// `GET automotive-service/api/inventory/public/global-products`.
  Future<ResponseModel> fetchGlobalProductsRepo(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveGlobalProducts,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update a single inventory record (one variant) — PUT price/mrp etc.
  /// `PUT product-service/api/inventory/{id}`, where `id` is the variant's
  /// own inventory id.
  Future<ResponseModel> updateInventoryVariantRepo({
    required String inventoryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      automotiveUpdateProductInventory(inventoryId),
      params: params,
      showProgress: false,
    );
  }

  /// Delete a single inventory variant by its inventory id.
  /// `DELETE automotive-service/api/inventory/{inventoryId}` — same path as the
  /// update endpoint, DELETE verb.
  Future<ResponseModel> deleteInventoryVariantRepo({
    required String inventoryId,
  }) async {
    return ApiBaseHelper().deleteHTTP(
      automotiveUpdateProductInventory(inventoryId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Invert the manual out-of-stock flag on one or more inventory records.
  /// `PATCH automotive-service/api/inventory/stock/flip-out-of-stock`.
  ///
  /// No value is sent — the server flips each id independently and reports the
  /// resulting value per item, which is why the caller must read the new state
  /// off the response rather than assuming `!previous`. Two devices flipping
  /// the same row would otherwise disagree with the server until a refetch.
  ///
  /// Pass ONE of [inventoryId] / [inventoryIds]; `inventoryIds` wins if both
  /// are given. Duplicate ids collapse server-side (an id sent twice flips
  /// once, not back to where it started).
  ///
  /// This writes the flag only — batch quantity is untouched, so flipping a
  /// zero-quantity item back to "in stock" does not make it sellable.
  Future<ResponseModel> flipOutOfStockRepo({
    String? inventoryId,
    List<String>? inventoryIds,
  }) async {
    assert(inventoryId != null || (inventoryIds?.isNotEmpty ?? false),
        'Supply inventoryId or a non-empty inventoryIds');
    return ApiBaseHelper().patchHTTP(
      automotiveFlipOutOfStock,
      params: (inventoryIds != null && inventoryIds.isNotEmpty)
          ? {'inventoryIds': inventoryIds}
          : {'inventoryId': inventoryId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Place a product order. `POST product-service/api/orders`.
  Future<ResponseModel> placeProductOrderRepo({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      automotivePlaceProductOrder,
      params: params,
      showProgress: false,
    );
  }

  ///Fetch InventoryBasedSearchProduct...
  Future<ResponseModel> fetchSearchProductViaCategoryRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveSearchProductViaCategory,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// AutomotiveProduct Snap Search...
  Future<ResponseModel> fetchProductSnapSearchRepo({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      automotiveProductSnapSearch,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create a brand-new variant on an existing product. Mirrors
  /// grocery's `createNewGroceryProductVariantRepo` — same payload
  /// shape, only the service URL changes (grocery-service →
  /// product-service).
  Future<ResponseModel> createNewProductVariantRepo({
    required String productId,
    Map<String, dynamic>? params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      automotiveCreateProductNewVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Clone AutomotiveProduct AutomotiveVariant...
  /// Now hits the product-service inventory endpoint (mirrors grocery's
  /// `grocery-service/api/inventory`). The body is a flat
  /// `List<Map<String, dynamic>>` — same shape grocery's
  /// `addGroceryProductVariantRepo` posts — built by
  /// `AutomotiveInventoryController._buildInventoryPayload`.
  Future<ResponseModel> cloneProductVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      automotiveAddProductVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch Suggested AutomotiveProducts...
  Future<ResponseModel> fetchSuggestedProductRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      storesByCategory,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Fetch full business profile
  Future<dynamic> getBusinessProfileFullRepo(String id) async {
    return await ApiBaseHelper().getHTTP(
      "automotive_products-service/api/business-profile/$id/full",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  ///UPDATE PRODUCT BUSINESS....
  Future<ResponseModel> updateProductBusinessProfileRepo(
      {required Map<String, dynamic> reqBODY,}) async {
    final response = await ApiBaseHelper().putHTTP(
        automotiveProductBusinessProfile,
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// GENERATED AI PRODUCT DETAILS...
  Future<ResponseModel> aiGenerateProductFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(
        generateProductBusiness, params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE BUSINESS.......
  Future<ResponseModel> createProductBusinessProfileRepo(
      {required dynamic reqBODY,}) async {
    final response = await ApiBaseHelper().postHTTP(
        automotiveProductBusinessProfile,
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// Fetch AutomotiveProduct AutomotiveCategory With Inventory
  Future<ResponseModel> fetchProductCategoryWithInventoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveProductInventoryByCategory,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch AutomotiveProduct AutomotiveCategory With Inventory
  Future<ResponseModel> fetchPublicProductCategoryWithInventoryRepo({required String visitUserId}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveProductPublicInventoryByCategory,
      params: {
        ApiKeys.businessId: visitUserId
      },
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  ///GET BUSINESS PROFILE REPO....
  Future<ResponseModel> getBusinessProfileRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        automotiveProductBusinessProfile,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// Place bulk product self-pickup order
  Future<ResponseModel> placeBulkProductOrderApi(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      automotivePlaceProductOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Mark product self-pickup order as ready (seller side)
  Future<ResponseModel> markProductOrderReadyRepo(
      {required String orderId}) async {
    final response = await ApiBaseHelper().putHTTP(
      productOrderReady(orderId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add AutomotiveProduct...
  Future<ResponseModel> addProduct({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      products,
      params: params,
      showProgress: false,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get AutomotiveProduct...
  Future<ResponseModel> getProduct({required String channelId}) async {
    String channelProduct = channelProducts(channelId);
    final response = await ApiBaseHelper().getHTTP(
      channelProduct,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Single AutomotiveProduct ...
  Future<ResponseModel> getSingleProductDetails({required String productId}) async {
    String channelProductDetails = product(productId);
    final response = await ApiBaseHelper().getHTTP(
      channelProductDetails,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///update AutomotiveProduct Details...
  Future<ResponseModel> updateProductDetails({required String productId, required Map<String, dynamic> params}) async {
    String channelProductDetails = product(productId);
    final response = await ApiBaseHelper().putHTTP(
      channelProductDetails,
      showProgress: false,
      isMultipart: true,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Delete AutomotiveProduct...
  Future<ResponseModel> deleteProduct({required String productId}) async {
    String channelProductDetails = product(productId);
    final response = await ApiBaseHelper().deleteHTTP(
      channelProductDetails,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Create AutomotiveProduct (multipart)
  Future<ResponseModel> createProductViaAiApi({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      automotiveCreateProductAdmin,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add AutomotiveProduct To Inventory...
  /// Body is a raw JSON array of inventory entries (one per variant).
  Future<ResponseModel> addProductToInventoryApi({required dynamic params}) async {
    final response = await ApiBaseHelper().postHTTP(
      automotiveAddProductToInventory,
      params: params,
      isArrayReq: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> searchCategoryOfProduct({
    required Map<String, dynamic> queryParams
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveSearchProductCategory,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create variants on a product. Body is `{ variantData: [...] }`;
  /// `productId` lives in the URL only.
  Future<ResponseModel> addUpdateProductVariantApi({
    required Map<String, dynamic> params,
    required String productId,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      automotiveAddUpdateProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Own AutomotiveProducts...
  Future<ResponseModel> fetchSingleProductApi({required String productId}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveGetProductById(productId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch the Google Custom Search keys (api key + cx) for product image
  /// search. `GET product-service/api/products/fe/ai-keys`.
  Future<ResponseModel> getProductAiKeysRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveProductAiKeys,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> productNestedCategoryRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveProductNestedCategory,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Products grouped by root category — one section per root category, each
  /// with a capped product list — for the "Quick Upload" rails.
  Future<ResponseModel> fetchProductsByRootCategoryRepo(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveProductsByRootCategory,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch categories for a group (e.g. `homeMadeProduct`).
  Future<ResponseModel> productCategoriesByGroupRepo(
      {required String group}) async {
    final response = await ApiBaseHelper().getHTTP(
      automotiveProductCategoriesByGroup(group),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}