import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class InventoryRepo extends BaseService {

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
  Future<ResponseModel> fetchOwnDraftedAndPublicProductsRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getOwnDraftedAndPublicProducts,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update product inventory variant — PATCH only price/mrp etc.
  Future<ResponseModel> updateInventoryVariantRepo({
    required String inventoryId,
    required String variantId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().patchHTTP(
      updateProductInventoryVariant(inventoryId, variantId),
      params: params,
      showProgress: true,
    );
  }

  ///Fetch InventoryBasedSearchProduct...
  Future<ResponseModel> fetchInventoryBasedSearchProductRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getInventoryBasedSearchProduct,
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

  ///Clone Product Variant...
  Future<ResponseModel> cloneProductVariantRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      cloneProductInventory,
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
  Future<ResponseModel> fetchProductCategoryWithInventoryRepo({required String businessId}) async {
    final response = await ApiBaseHelper().getHTTP(
      productInventoryByCategory(businessId),
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
}