import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class TiffinRepo extends BaseService{

  Future<ResponseModel> fetchAllMeals() async {
    print('call3');
    final response = await ApiBaseHelper().getHTTP(
      tiffinsByUserId,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Consumer: fetch a specific store's tiffins by its owner [userId]
  /// (`earn-service/tiffins/user/{userId}`).
  Future<ResponseModel> fetchTiffinsByUser({required String userId}) async {
    return ApiBaseHelper().getHTTP(
      tiffinsByUser(userId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  Future<ResponseModel> createMeal({required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().postHTTP(
      tiffins,
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateMeal({required String id, required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().patchHTTP(
      '$tiffins/$id',
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> toggleGoLive({required String id, required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().patchHTTP(
      '$tiffins/$id',
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addCenterName({required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().postHTTP(
      tiffinsCenters,
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateCenterName({required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().patchHTTP(
      tiffinsCenters,
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Consumer: fetch all tiffins (all users, filtered by query params)
  Future<ResponseModel> fetchAllTiffins({Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      tiffins,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}