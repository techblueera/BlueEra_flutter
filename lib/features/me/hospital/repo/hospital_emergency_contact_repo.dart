import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalEmergencyContactRepo extends BaseService {
  Future<ResponseModel> getByHospital() async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalEmergencyContactByHospital,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> saveOrUpdate({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalEmergencyContactBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
