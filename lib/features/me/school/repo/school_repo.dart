import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

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

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getSchoolAboutUsRepo({required String schoolID}) async {
    final response = await ApiBaseHelper().getHTTP("${schoolAboutUs}/$schoolID",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getSchoolBranchRepo({required String schoolID}) async {
    final response = await ApiBaseHelper().getHTTP("${schoolContact}/$schoolID",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///UPDATE SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> updateSchoolAboutUsRepo(
      {required String aboutUsID,
      required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${schoolAboutUsUpdate}$aboutUsID",
        onError: (error) {},
        params: reqBODY,
        onSuccess: (data) {});
    return response;
  }

  ///UPLOAD INTRO VIDEO INIT...
  Future<ResponseModel?> uploadEducationDocRepo(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      educationUploadInit,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getSchoolContactRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${schoolContact}/$schoolIDGlobal",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getSchoolByUserIDRepo() async {
    final response = await ApiBaseHelper().getHTTP("${schoolUser}/$userId",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
