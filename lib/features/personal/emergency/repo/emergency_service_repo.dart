import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class EmergencyServiceRepo extends BaseService {
  Future<ResponseModel> getEmergencyProfile() async {
    return await ApiBaseHelper().getHTTP(
        emergencyProfile,
        showProgress: false,
    );
  }

  Future<ResponseModel> submitBasicInfo({required Map<String, dynamic> body}) async {
    final res = await ApiBaseHelper().postHTTP(
      emergencyBasicInfo,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return res;
  }

  Future<ResponseModel> submitEmergencyContact({required Map<String, dynamic> body}) async {
    final res = await ApiBaseHelper().postHTTP(
      emergencyContacts,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return res;
  }

  Future<ResponseModel> submitPrivacyAlerts({required Map<String, dynamic> body}) async {
    final res = await ApiBaseHelper().postHTTP(
      emergencyPrivacyAlerts,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return res;
  }
}
