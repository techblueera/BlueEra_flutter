import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalVisionMissionRepo extends BaseService {
  Future<ResponseModel> getByHospital() async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalVisionMissionByHospital,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> create({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalVisionMissionBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> update({required String id, required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().putHTTP(
      hospitalVisionMissionById(id),
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
