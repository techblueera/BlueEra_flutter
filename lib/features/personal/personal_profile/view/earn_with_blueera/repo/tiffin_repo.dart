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
}