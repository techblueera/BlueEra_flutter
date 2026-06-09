import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ManufacturerProductRepo extends BaseService {

  /// Generate Ai ManufacturerProduct...
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

  /// Update an inventory variant (price / mrp / active) — PUT
  /// `product-service/api/inventory/{id}`. Mirrors the product service.
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

  /// ManufacturerProduct Snap Search...
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

  ///Clone ManufacturerProduct ManufacturerVariant...
  /// Now hits the product-service inventory endpoint (mirrors grocery's
  /// `grocery-service/api/inventory`). The body is a flat
  /// `List<Map<String, dynamic>>` — same shape grocery's
  /// `addGroceryProductVariantRepo` posts — built by
  /// `ManufacturerInventoryController._buildInventoryPayload`.
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

  /// Fetch ManufacturerProduct Category With Inventory
  Future<ResponseModel> fetchProductCategoryWithInventoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      productInventoryByCategory,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch ManufacturerProduct Category With Inventory
  Future<ResponseModel> fetchPublicProductCategoryWithInventoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      productPublicInventoryByCategory,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  /// Place bulk product self-pickup order
  Future<ResponseModel> placeBulkProductOrderApi(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      placeProductOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Create ManufacturerProduct (multipart) — uses the new admin create
  // endpoint, mirroring the product service.
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

  ///Add ManufacturerProduct To Inventory...
  /// Body is a raw JSON array of inventory entries (one per variant) — same
  /// shape the product service posts.
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
  /// `productId` lives in the URL only. POST (mirrors the product service).
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


}