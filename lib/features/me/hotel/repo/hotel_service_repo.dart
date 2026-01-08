import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HotelServiceRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getHotelServiceCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP("${hotelBulkCatalogStatus}",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET AI HOTEL SERVICE DETAILS...
  Future<ResponseModel> aiHotelFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(fetchHotelFromAi,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE HOTEL SERVICE DETAILS...
  Future<ResponseModel> createHotelServiceRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(createHotelService,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///UPDATE HOTEL Bulk SERVICE DETAILS...
  Future<ResponseModel> updateHotelServiceRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().patchHTTP(hotelBulkStatus,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

}
