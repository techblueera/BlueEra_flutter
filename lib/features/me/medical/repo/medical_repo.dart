
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MedicalRepo extends BaseService {
  Future<ResponseModel> fetchMedicalCategoryData(String endPoint) async {
    final response = await ApiBaseHelper().getHTTP(
        getMedicalCategoryApi(endPoint),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> fetchMedicalAdminProduct(String endPoint) async {
    final response = await ApiBaseHelper().getHTTP(
        getMedicalAdminProduct(endPoint),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> enableHotelServiceStatusApi(String categoryId,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().patchHTTP(
        enableHotelServiceStatus(categoryId),
        params: params,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getHospitalFromAi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        fetchHospitalFromAi,
        params: params,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }

}
