
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FoodAiRepo extends BaseService {

  Future<ResponseModel> aiFoodGenerateRepo({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      aiFoodGenerateContent,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addFoodService({Map<String, dynamic>? queryParam}) async {

    final response = await ApiBaseHelper().postHTTP(
      businessServices,
      params:queryParam,
      isMultipart: false,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FETCH SINGLE FOOD SERVICES....
  Future<ResponseModel> fetchSingleFoodDataApi({required String serviceId}) async {
    final response = await ApiBaseHelper().getHTTP(
      businessServicesById(serviceId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///DELETE FOOD SERVICES....
  Future<ResponseModel> deleteFoodServiceRepo({required String serviceId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      businessServicesById(serviceId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  ///FETCH SINGLE FOOD SERVICES....
  Future<ResponseModel> getFoodCategoryDataApi({required String categoryName}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${categoryTree}?type=$categoryName",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}