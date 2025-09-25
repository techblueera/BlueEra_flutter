import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';


class ListingFormRepo extends BaseService{

 Future<ResponseModel> getToplevelCategories() async {
    final response = await ApiBaseHelper().getHTTP(
      toplevelcategoriesApi,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getSubcategories(String categoryId) async {
    final path = "/inventory-service/product/categories/$categoryId/subcategories";
    final response = await ApiBaseHelper().getHTTP(
      path,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Add Product (multipart)
  Future<ResponseModel> addProduct(Map<String, dynamic> params) async {
    const String path = "/inventory-service/product/addProduct";
    final response = await ApiBaseHelper().postHTTP(
      path,
      params: params,
      isMultipart: true,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Init upload for media (presigned URL)
  Future<ResponseModel> initMediaUpload({
    required String fileName,
    required String fileType,
  }) async {
    final String path = "/inventory-service/upload/init?fileName=$fileName&fileType=$fileType";
    final response = await ApiBaseHelper().getHTTP(
      path,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // getSubchildORRootCategroy
  Future<ResponseModel> getSubchildORRootCategroy({
    required Map<String, dynamic> queryParams
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      subchildORRootCategroy,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

 // Create Product (multipart)
 Future<ResponseModel> createProductApi({required Map<String, dynamic> params}) async {
   final response = await ApiBaseHelper().postHTTP(
     createProduct,
     params: params,
     isMultipart: true,
     showProgress: true,
     onError: (error) {},
     onSuccess: (data) {},
   );
   return response;
 }

 // updateProductFeatureApi
 Future<ResponseModel> updateProductFeatureApi({required Map<String, dynamic> params, required String productId}) async {
   final response = await ApiBaseHelper().putHTTP(
     updateProductFeature(productId),
     params: params,
     showProgress: true,
     onError: (error) {},
     onSuccess: (data) {},
   );
   return response;
 }

 // updatePriceAndWarrantyApi
 Future<ResponseModel> updatePriceAndWarrantyApi(
     {required Map<String, dynamic> params, required String productId}) async {
   final response = await ApiBaseHelper().putHTTP(
     updatePriceAndWarranty(productId),
     params: params,
     showProgress: true,
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

 // Create Product (multipart)
 Future<ResponseModel> createProductViaAiApi({required Map<String, dynamic> params}) async {
   final response = await ApiBaseHelper().postHTTP(
     createProductViaAi,
     params: params,
     isMultipart: true,
     showProgress: true,
     onError: (error) {},
     onSuccess: (data) {},
   );
   return response;
 }


}