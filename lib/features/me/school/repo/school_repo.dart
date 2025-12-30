import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SchoolRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> aiInstitutionFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiInstitutionFetchDetails,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> createSchoolRepo({required dynamic reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiCreateSchool,
        params: {ApiKeys.aiOutput: reqBody},
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
}
