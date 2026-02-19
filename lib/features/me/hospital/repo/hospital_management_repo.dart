import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalManagementRepo extends BaseService {
  Future<ResponseModel> getByHospital({required String hospitalId}) async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalManagementByHospital,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> create({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalManagementBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> update({required String id, required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().putHTTP(
      hospitalManagementById(id),
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> delete({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      hospitalManagementById(id),
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
