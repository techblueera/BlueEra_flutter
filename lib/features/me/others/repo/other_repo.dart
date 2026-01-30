import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class OtherRepo extends BaseService {
  Future<dynamic> createAboutOrganisationRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      createAboutOrganisation,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getAboutOrganisationRepo() async {
    return await ApiBaseHelper().getHTTP(
      createAboutOrganisation,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateAboutOrganisationRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$createAboutOrganisation/$id",
      params:body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteAboutOrganisationRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$createAboutOrganisation/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // Management APIs
  Future<dynamic> createManagementRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      management,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getManagementRepo() async {
    return await ApiBaseHelper().getHTTP(
      management,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateManagementRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$management/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteManagementRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$management/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // Staff APIs
  Future<dynamic> createStaffRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      staff,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getStaffRepo() async {
    return await ApiBaseHelper().getHTTP(
      staff,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateStaffRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$staff/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteStaffRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$staff/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // Blogs APIs
  Future<dynamic> createBlogsRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      otherBlogs,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getBlogsRepo() async {
    return await ApiBaseHelper().getHTTP(
      otherBlogs,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateBlogsRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$otherBlogs/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteBlogsRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$otherBlogs/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }


  // News APIs
  Future<dynamic> createNewsRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      otherNews,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getNewsRepo() async {
    return await ApiBaseHelper().getHTTP(
      otherNews,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateNewsRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$otherNews/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteNewsRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$otherNews/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }


  // Downloads APIs
  Future<dynamic> createDownloadsRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      otherDownloads,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getDownloadsRepo() async {
    return await ApiBaseHelper().getHTTP(
      otherDownloads,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateDownloadsRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$otherDownloads/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteDownloadsRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$otherDownloads/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // OtherTNC APIs
  Future<dynamic> createOtherTNCRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      otherTNC,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getOtherTNCRepo() async {
    return await ApiBaseHelper().getHTTP(
      otherTNC,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateOtherTNCRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$otherTNC/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteOtherTNCRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$otherTNC/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }


  // Timings APIs
  Future<dynamic> createTimingRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      otherTimings,
      params: {body},
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getTimingRepo() async {
    return await ApiBaseHelper().getHTTP(
      otherTimings,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateTimingRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      otherTimings,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }


  // GET: Fetch property photos
  Future<ResponseModel> getOtherServicePhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      otherGallery,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Fetch full business profile
  Future<dynamic> getBusinessProfileFullRepo(String id) async {
    return await ApiBaseHelper().getHTTP(
      "other-service/business-profile/$id/full",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // POST: Upload/Add a new photo
  Future<ResponseModel> addOtherServicePhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      otherGallery,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteOtherServicePhotosRepo({required String imgID,required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$otherGallery/$imgID/images",
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  ///CREATE BUSINESS.......
  Future<ResponseModel> createOtherBusinessProfileRepo(
      {required dynamic reqBODY,}) async {
    final response = await ApiBaseHelper().postHTTP(
        otherBusinessProfile,
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

 ///PUT  COURSE....
  Future<ResponseModel> updateOtherBusinessProfileRepo(
      {required Map<String, dynamic> reqBODY,}) async {
    final response = await ApiBaseHelper().putHTTP(
        otherBusinessProfile,
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> aiGenerateOtherServiceFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(generateOtherService,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  ///GET HOTEL CONTACT REPO....
  Future<ResponseModel> getBusinessProfileRepo() async {
    final response = await ApiBaseHelper().getHTTP(otherBusinessProfile,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }


  ///CREATE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> createOtherBranchContactRepo(
      {required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${otherContactUsService}",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }


  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getOtherServiceContactRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${otherContactUsService}/business-profile/$otherServiceIDGlobal",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }


  ///ADD  SCHOOL BRNACH DEPARTMENT REPO....
  Future<ResponseModel> addBranchDepartmentRepo(
      {required dynamic reqParm, required String branchId}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${otherContactUsService}/$branchId/departments",
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
        "${otherContactUsService}/$contactID/departments/$branchId",
        onError: (error) {},
        params: reqParm,
        onSuccess: (data) {});
    return response;
  }
  ///DELETE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> deleteSchoolBranchDeptRepo(
      {required String contactID, required String deptID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${otherContactUsService}/$contactID/departments/$deptID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  ///DELETE SCHOOL Branch REPO....
  Future<ResponseModel> deleteSchoolBranchRepo(
      {required String contactID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${otherContactUsService}/$contactID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  ///PUT SCHOOL Branch Info REPO....
  Future<ResponseModel> updateSchoolBranchRepo(
      {required String branchID, required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${otherContactUsService}/$branchID",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }


}
