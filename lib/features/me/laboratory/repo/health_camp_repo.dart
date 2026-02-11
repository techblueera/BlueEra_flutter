import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HealthCampRepo extends BaseService {

  Future<ResponseModel> getHealthCamps() async {
    return await ApiBaseHelper().getHTTP(labHealthCamps);
  }

  Future<ResponseModel> createHealthCamp(Map<String, dynamic> data) async {
    return await ApiBaseHelper().postHTTP(labHealthCamps, params: data);
  }

  Future<ResponseModel> updateHealthCamp(String id, Map<String, dynamic> data) async {
    return await ApiBaseHelper().putHTTP("$labHealthCamps/$id", params: data);
  }

  Future<ResponseModel> deleteHealthCamp(String id) async {
    return await ApiBaseHelper().deleteHTTP("$labHealthCamps/$id");
  }
}
