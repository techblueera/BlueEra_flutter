import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

import '../../../../../../core/api/apiService/base_service.dart';


final String getUserByIdUrl = "user-service/user/getUserById";

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

}