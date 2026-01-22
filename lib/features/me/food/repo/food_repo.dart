import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FoodRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getFoodAiGenerateRepo({required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP("${foodAiGenerate}",
        params: reqBody,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET FOOD CATEGORY...
  Future<ResponseModel> getFoodCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP("${categoryTree}",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> createFoodCategoryRepo({required Map<String, dynamic> params}) async {
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

  Future<ResponseModel> updateFoodVariantRepo({required Map<String, dynamic> params,required String foodID}) async {
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

  Future<ResponseModel> addFoodVariantRepo({required Map<String, dynamic> params,required String foodID}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${foodProduct}/${foodID}/variants",
      params: params,
      isMultipart: false,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getFoodByCategoryIdRepo({required String catID}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${foodServiceProduct}category=$catID",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
