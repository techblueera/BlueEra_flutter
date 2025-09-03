import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MapServiceRepo extends BaseService{

  ///View Channel details...
  Future<ResponseModel> fetchAllHomeServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      servicesByLatLng,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///View Channel details...
  Future<ResponseModel> fetchAllFoodServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      foodServicesByLatLng,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}