import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class HospitalContactUsRepo extends BaseService {

  ///CREATE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> createSchoolBranchContactRepo(
      {required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${hospitalContact}",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> deleteSchoolBranchDeptRepo(
      {required String contactID, required String deptID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${hospitalDepartmentContact}$contactID/departments/$deptID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE SCHOOL Branch REPO....
  Future<ResponseModel> deleteSchoolBranchRepo(
      {required String contactID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${hospitalContact}/$contactID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///PUT SCHOOL Branch Info REPO....
  Future<ResponseModel> updateSchoolBranchRepo(
      {required String branchID, required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${hospitalContact}/$branchID",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getSchoolContactRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${hospitalContact}/hospital/$hospitalIDGlobal",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  ///ADD  SCHOOL BRNACH DEPARTMENT REPO....
  Future<ResponseModel> addBranchDepartmentRepo(
      {required dynamic reqParm, required String branchId}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${hospitalContact}/$branchId/departments",
        onError: (error) {},
        params: reqParm,
        onSuccess: (data) {});
    return response;
  }

  ///UPDATE SCHOOL CONTACT REPO....
  Future<ResponseModel> updateSchoolContactRepo(
      {required dynamic reqParm,
        required String contactID,
        required String branchId}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${hospitalContact}/$contactID/departments/$branchId",
        onError: (error) {},
        params: reqParm,
        onSuccess: (data) {});
    return response;
  }
}