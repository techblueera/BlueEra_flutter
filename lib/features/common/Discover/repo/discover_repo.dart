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

  /// GET: Get Hotel Stay
  Future<ResponseModel> fetchHotelSearchRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      hotelSearch,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET: Filter businesses by category. Used by the education / school
  /// listing screens to fetch college-, university-, school-type providers
  /// (e.g. `category=COLLEGE_UNIVERSITY`). Backed by:
  /// `GET user-service/business/filter?category=...&page=...&limit=...`
  Future<ResponseModel> fetchBusinessFilterRepo({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      'user-service/business/filter',
      // 'user-service/business/filter?typeOfBusiness=Siksha&category=SPORTS_HOBBY',
      // 'user-service/business/filter?typeOfBusiness=Siksha',

      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}

