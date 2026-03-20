import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class TiffinRepo extends BaseService{

  Future<ResponseModel> fetchAllMeals() async {
    final response = await ApiBaseHelper().getHTTP(
      addAccountApi,
      showProgress: false,
      params: {},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> createMeal({required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().postHTTP(
      addAccountApi,
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateMeal({required String id, required Map<String, dynamic> data}) async {
    final response = await ApiBaseHelper().putHTTP(
      '$addAccountApi/$id',
      showProgress: false,
      params: data,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> toggleGoLive({required String id, required bool isLive}) async {
    final response = await ApiBaseHelper().patchHTTP(
      '$addAccountApi/$id',
      showProgress: false,
      params: {'is_live': isLive},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}