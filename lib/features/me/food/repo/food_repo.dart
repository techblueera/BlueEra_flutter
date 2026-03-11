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
    final response = await ApiBaseHelper().getHTTP(
        "${categoryTree}",
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
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
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addKitchenInventoryRepo({required dynamic params,}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${otherKitchenInventory}",
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getFoodByCategoryIdRepo({required String catID}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${foodServiceProduct}category=$catID",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getHomeFoodByIdRepo({required String businessProfile}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${homeFood}$businessProfile",
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
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // GET: Fetch property photos
  Future<ResponseModel> getFoodServicePhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      homeFoodGallery,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteFoodServicePhotosRepo({required String imgID,required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$homeFoodGallery/$imgID/images",
      params: reqBody,
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

}
