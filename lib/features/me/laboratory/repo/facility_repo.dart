import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class FacilityRepo extends BaseService {

  Future<ResponseModel> getFacilitiesByUser() async {
    return await ApiBaseHelper().getHTTP("$labFacilities/user/$userId");
  }

  Future<ResponseModel> createOrUpdateFacilities(Map<String, dynamic> data) async {
    return await ApiBaseHelper().postHTTP(labFacilities, params: data);
  }
}
