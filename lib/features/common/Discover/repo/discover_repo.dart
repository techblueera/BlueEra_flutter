import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class DiscoverRepo extends BaseService {

  /// GET EARN SERVICES
  Future<ResponseModel> fetchSelfWorkServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      servicesByLatLng,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET RENTAL SERVICES
  Future<ResponseModel> getRentalService({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      rentalService,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}

