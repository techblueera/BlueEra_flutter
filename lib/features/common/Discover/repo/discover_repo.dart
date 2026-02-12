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
  Future<ResponseModel> getBookingRidersApi({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getBookingRiders,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }  Future<ResponseModel> makeTransportBookOrderApi({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      makeTransportBookOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  /// GET EARN SERVICES
  Future<ResponseModel> fetchProfessionalConsServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      professionalSearch,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

