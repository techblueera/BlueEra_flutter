import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalEmergencyRepo extends BaseService {
  Future<ResponseModel> getByHospital() async {
    final response = await ApiBaseHelper().getHTTP(
      emergencyCareByHospital,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> create({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      emergencyCareBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> update({ required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().patchHTTP(
      emergencyCareById,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
