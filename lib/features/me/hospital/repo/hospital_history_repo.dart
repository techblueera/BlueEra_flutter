import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalHistoryRepo extends BaseService {
  Future<ResponseModel> get() async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalHistoryGet,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> create({required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalHistoryBase,
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> update({required String id, required Map<String, dynamic> body}) async {
    final response = await ApiBaseHelper().putHTTP(
      hospitalHistoryById(id),
      params: body,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
