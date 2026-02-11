import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class LabProfileRepo extends BaseService {

  Future<ResponseModel> getProfile() async {
    return await ApiBaseHelper().getHTTP("$labProfiles/$labIDGlobal");
  }

  Future<ResponseModel> postDescription(Map<String, dynamic> data) async {
    return await ApiBaseHelper().postHTTP(labProfiles, params: data);
  }

  Future<ResponseModel> putDescription(Map<String, dynamic> data) async {
    return await ApiBaseHelper().putHTTP("${labProfiles}/$labIDGlobal", params: data);
  }
}
