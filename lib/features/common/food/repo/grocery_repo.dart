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

  Future<ResponseModel> userSearchGroceryCategoryRepo({Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      userSearchGroceryCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create New Grocery Product Variant
  Future<ResponseModel> createNewGroceryProductVariantRepo({ required String productId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createNewProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FETCH My GROCERIES SERVICES....
  Future<ResponseModel> fetchMyGroceryProductsRepo({Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      myGroceryProducts,
      showProgress: false,
      params: queryParam,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Add Grocery Product to inventory
  Future<ResponseModel> addGroceryProductVariantRepo({List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addGroceryProductVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

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