import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ProductRepo extends BaseService{

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
      createProductViaAi,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add Product To Inventory...
  Future<ResponseModel> addProductToInventoryApi({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addProductToInventory,
      params: params,
      isMultipart: true,
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

  Future<ResponseModel> addUpdateProductVariantApi({
    required Map<String, dynamic> params,
    required String productId,

  }) async {
    final response = await ApiBaseHelper().patchHTTP(
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

}