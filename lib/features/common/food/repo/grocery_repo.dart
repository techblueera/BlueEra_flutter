import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class GroceryRepo extends BaseService {

  Future<ResponseModel> searchGroceryCategoryRepo({Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      searchGroceryCategory,
      params:queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> groceryCategoryOfChildrenRepo({required String key}) async {
    final response = await ApiBaseHelper().getHTTP(
      GroceryCategoryOfChildren(key),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  Future<ResponseModel> addGroceryProductVariantRepo({ required String productId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addGroceryProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ///FETCH SINGLE FOOD SERVICES....
  // Future<ResponseModel> fetchSingleFoodDataApi({required String serviceId}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     businessServicesById(serviceId),
  //     showProgress: false,
  //     onError: (error) {},
  //     onSuccess: (data) {},
  //   );
  //   return response;
  // }
  //
  // ///DELETE FOOD SERVICES....
  // Future<ResponseModel> deleteFoodServiceRepo({required String serviceId}) async {
  //   final response = await ApiBaseHelper().deleteHTTP(
  //     businessServicesById(serviceId),
  //     showProgress: false,
  //     onError: (error) {},
  //     onSuccess: (data) {},
  //   );
  //   return response;
  // }

}