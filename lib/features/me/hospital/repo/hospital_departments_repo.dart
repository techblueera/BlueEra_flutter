import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalDepartmentsRepo extends BaseService {
  Future<ResponseModel> getDepartmentsByHospital() async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalDepartmentsByHospital,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> createDepartment({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalDepartmentsBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateDepartment({required String id, required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().putHTTP(
      hospitalDepartmentById(id),
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> deleteDepartment({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      hospitalDepartmentById(id),
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
