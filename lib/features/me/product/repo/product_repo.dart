import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ProductRepo extends BaseService {

  /// Generate Ai Product...
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

  ///Get Own Products...
  Future<ResponseModel> fetchProductsRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      allProducts,
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
      updateProductInventory(inventoryId),
      params: params,
      showProgress: false,
    );
  }

  /// Place a product order. `POST product-service/api/orders`.
  Future<ResponseModel> placeProductOrderRepo({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      placeProductOrder,
      params: params,
      showProgress: false,
    );
  }

  ///Fetch InventoryBasedSearchProduct...
  Future<ResponseModel> fetchSearchProductViaCategoryRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      searchProductViaCategory,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Product Snap Search...
  Future<ResponseModel> fetchProductSnapSearchRepo({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      productSnapSearch,
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
      createProductNewVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Clone Product Variant...
  /// Now hits the product-service inventory endpoint (mirrors grocery's
  /// `grocery-service/api/inventory`). The body is a flat
  /// `List<Map<String, dynamic>>` — same shape grocery's
  /// `addGroceryProductVariantRepo` posts — built by
  /// `InventoryController._buildInventoryPayload`.
  Future<ResponseModel> cloneProductVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addProductVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch Suggested Products...
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
      "product-service/api/business-profile/$id/full",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  ///UPDATE PRODUCT BUSINESS....
  Future<ResponseModel> updateProductBusinessProfileRepo(
      {required Map<String, dynamic> reqBODY,}) async {
    final response = await ApiBaseHelper().putHTTP(
        productBusinessProfile,
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
        productBusinessProfile,
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// Fetch Product Category With Inventory
  Future<ResponseModel> fetchProductCategoryWithInventoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      productInventoryByCategory,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch Product Category With Inventory
  Future<ResponseModel> fetchPublicProductCategoryWithInventoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      productPublicInventoryByCategory,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  ///GET BUSINESS PROFILE REPO....
  Future<ResponseModel> getBusinessProfileRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        productBusinessProfile,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// Place bulk product self-pickup order
  Future<ResponseModel> placeBulkProductOrderApi(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      placeBulkProductOrder,
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

  ///Add Product...
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

  ///Get Product...
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

  ///Get Single Product ...
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

  ///update Product Details...
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

  ///Delete Product...
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

  // Create Product (multipart)
  Future<ResponseModel> createProductViaAiApi({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createProductAdmin,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add Product To Inventory...
  /// Body is a raw JSON array of inventory entries (one per variant).
  Future<ResponseModel> addProductToInventoryApi({required dynamic params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addProductToInventory,
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
      searchProductCategory,
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
      addUpdateProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Own Products...
  Future<ResponseModel> fetchSingleProductApi({required String productId}) async {
    final response = await ApiBaseHelper().getHTTP(
      getProductById(productId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> productNestedCategoryRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      productNestedCategory,
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
      productCategoriesByGroup(group),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}