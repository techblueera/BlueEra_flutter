import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalIpdRepo extends BaseService {
  Future<ResponseModel> getByDepartment({required String departmentId}) async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalIpdByDepartment(departmentId),
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> create({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalIpdBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> update({required String id, required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().putHTTP(
      hospitalIpdById(id),
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> delete({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      hospitalIpdById(id),
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
