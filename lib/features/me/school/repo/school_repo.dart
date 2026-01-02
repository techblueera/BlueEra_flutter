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

  ///UPDATE SCHOOL CONTACT REPO....
  Future<ResponseModel> updateSchoolContactRepo(
      {required dynamic reqParm, required String contactID}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${schoolContactUpdate}/$contactID",
        onError: (error) {},
        params: reqParm,
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getSchoolByUserIDRepo() async {
    final response = await ApiBaseHelper().getHTTP("${schoolUser}/$userId",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getSchoolNoticesRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${schoolNotices}/$schoolIDGlobal",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///ADD SCHOOL NOTICE REPO....
  Future<ResponseModel> addSchoolNoticesRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP("${schoolNoticesAddDelete}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///EDIT SCHOOL NOTICE REPO....
  Future<ResponseModel> editSchoolNoticesRepo(
      {required Map<String, dynamic> reqBODY, required String noticeID}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${schoolNoticesAddDelete}/$noticeID",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE SCHOOL NOTICE REPO....
  Future<ResponseModel> deleteSchoolNoticesRepo(
      {required String noticeID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${schoolNoticesAddDelete}/$noticeID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///CREATE DEPARTMENT...
  Future<ResponseModel> addSchoolDepartmentRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP("${educationDepartments}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///UPDATE DEPARTMENT...
  Future<ResponseModel> updateSchoolDepartmentRepo(
      {required Map<String, dynamic> reqBODY, required String deptId}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${educationDepartments}/${deptId}",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET DEPARTMENT REPO....
  Future<ResponseModel> getSchoolDepartmentRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().getHTTP("${educationDepartments}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///DELETE SCHOOL DEPARTMENT REPO....
  Future<ResponseModel> deleteSchoolDepartmentRepo(
      {required String departmentID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationDepartments}/$departmentID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  ///GET ALL COURSE....
  Future<ResponseModel> getSchoolCourseRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().getHTTP("${educationCourses}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///ADD  COURSE....
  Future<ResponseModel> addSchoolCourseRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP("${educationCourses}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///PUT  COURSE....
  Future<ResponseModel> updateSchoolCourseRepo(
      {required Map<String, dynamic> reqBODY, required String courseId}) async {
    final response = await ApiBaseHelper().putHTTP("${educationCourses}/$courseId",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  ///DELETE SCHOOL Course REPO....
  Future<ResponseModel> deleteSchoolCourseRepo(
      {required String courseId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationCourses}/$courseId",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
}
