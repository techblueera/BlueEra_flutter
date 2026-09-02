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
        showProgress: true,
        params: reqBody,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///CREATE SCHOOL/UNIVERSITY DETAILS...
  ///
  /// `showProgress: false` — a side effect of account creation, run while the
  /// Submit button already shows its own spinner. See the note on
  /// `OtherRepo.createOtherBusinessProfileRepo`.
  Future<ResponseModel> createSchoolRepo({required dynamic reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiCreateSchool,
        params: {ApiKeys.aiOutput: reqBody},
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getSchoolAboutUsRepo({String? schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${schoolAboutUs}/${schoolID ?? schoolIDGlobal}",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getSearchSchoolRepo(
      {required Map<String, dynamic> reqParm}) async {
    // education-service/schools?page=1&limit=10&search=computer%20science
    final response = await ApiBaseHelper().getHTTP("education-service/schools",
        params: reqParm, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  // Future<ResponseModel> getSearchFoodRepo({required Map<String, dynamic> reqParm}) async {
  Future<ResponseModel> getSearchFoodRepo({required String reqParm}) async {
    final response = await ApiBaseHelper()
        .getHTTP("food-service/api/home/category-page/${reqParm}",
            // params: reqParm,
            showProgress: false,
            onError: (error) {},
            onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getSchoolBranchRepo({required String schoolID}) async {
    final response = await ApiBaseHelper().getHTTP("${schoolContact}/$schoolID",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> createSchoolManagementRepo(
      {required String aboutUsID,
      required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${schoolAboutUsUpdate}$aboutUsID/management",
        onError: (error) {},
        params: reqBODY,
        onSuccess: (data) {});
    return response;
  }

  ///UPDATE SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> updateSchoolManagementAboutUsRepo(
      {required String aboutUsID,
      required int managementIndex,
      required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${schoolAboutUsUpdate}$aboutUsID/management/$managementIndex",
        onError: (error) {},
        params: reqBODY,
        onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> updateSchoolAboutUsRepo(
      {required String aboutUsID,
      required Map<String, dynamic> reqBODY}) async {
    if (aboutUsID.isNotEmpty) {
      final response = await ApiBaseHelper().putHTTP(
          "${schoolAboutUsUpdate}$aboutUsID",
          onError: (error) {},
          params: reqBODY,
          onSuccess: (data) {});
      return response;
    } else {
      final response = await ApiBaseHelper().postHTTP(
          "${schoolAboutUsUpdate}$aboutUsID",
          onError: (error) {},
          params: reqBODY,
          onSuccess: (data) {});
      return response;
    }
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
      {required dynamic reqParm,
      required String contactID,
      required String branchId}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${schoolContactUpdate}/$contactID/departments/$branchId",
        onError: (error) {},
        params: reqParm,
        onSuccess: (data) {});
    return response;
  }

  ///ADD  SCHOOL BRNACH DEPARTMENT REPO....
  Future<ResponseModel> addBranchDepartmentRepo(
      {required dynamic reqParm, required String branchId}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${schoolContactUpdate}/$branchId/departments",
        onError: (error) {},
        params: reqParm,
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL BY USER ID REPO....
  Future<ResponseModel> getSchoolByUserIDRepo({String? userID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${schoolUser}/${userID ?? userId}",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL CONTACT REPO....
  /// `showProgress: false` — the School "Me" screen's own load
  /// (`SchoolHomeScreenV2.initState` + pull-to-refresh), which already reports
  /// its own progress.
  Future<ResponseModel> getSchoolByIDRepo({String? schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${schoolUserID}${schoolID ?? schoolIDGlobal}",
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
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
    final response = await ApiBaseHelper().putHTTP(
        "${educationCourses}/$courseId",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
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

  ///CREATE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> createSchoolBranchContactRepo(
      {required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${educationServiceContact}",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> deleteSchoolBranchDeptRepo(
      {required String contactID, required String deptID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationServiceContact}/$contactID/departments/$deptID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE SCHOOL Branch REPO....
  Future<ResponseModel> deleteSchoolBranchRepo(
      {required String contactID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationServiceContact}/$contactID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///PUT SCHOOL Branch Info REPO....
  Future<ResponseModel> updateSchoolBranchRepo(
      {required String branchID, required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${educationServiceContact}/$branchID",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL CONTACT REPO....
  Future<ResponseModel> getEducationServiceAcademicsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${educationServiceAcademics}/school/$schoolIDGlobal",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///ADD SCHOOL NOTICE REPO....
  Future<ResponseModel> addEducationServiceAcademicsRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${educationServiceAcademics}",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///EDIT SCHOOL NOTICE REPO....
  Future<ResponseModel> editEducationServiceAcademicsRepo(
      {required Map<String, dynamic> reqBODY, required String noticeID}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${educationServiceAcademics}/$noticeID",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE SCHOOL NOTICE REPO....
  Future<ResponseModel> deleteEducationServiceAcademicsRepo(
      {required String noticeID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationServiceAcademics}/$noticeID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///CREATE STUDENT CORNER REPO....
  Future<ResponseModel> createStudentCornerRepo() async {
    final response = await ApiBaseHelper().postHTTP(
        "${educationServiceStudentCorner}",
        params: {ApiKeys.schoolId: schoolIDGlobal},
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET STUDENT CORNER LIST REPO....
  Future<ResponseModel> getStudentCornerRepo() async {
    final response = await ApiBaseHelper().getHTTP(
        "${educationServiceStudentCorner}/school/$schoolIDGlobal",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///ADD STUDENT CORNER SPECIFIC DETAILS REPO....
  Future<ResponseModel> postStudentCornerRepo(
      {required String studentCornerId,
      required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${educationServiceStudentCorner}/$studentCornerId/items",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///DELETE STUDENT CORNER SPECIFIC DETAILS REPO....
  Future<ResponseModel> deleteStudentCornerRepo(
      {required String studentCornerId,
      required String studentCornerType,
      required int cornerIndex}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationServiceStudentCorner}/$studentCornerId/$studentCornerType/$cornerIndex",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///UPDATE STUDENT CORNER SPECIFIC DETAILS REPO....
  Future<ResponseModel> updateStudentCornerRepo(
      {required String studentCornerId,
      required String studentCornerType,
      required int cornerIndex,
      required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${educationServiceStudentCorner}/$studentCornerId/$studentCornerType/$cornerIndex",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///educationServiceFaculty  REPO....
  Future<ResponseModel> addFacultyRepo(
      {required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().postHTTP(
        "${educationServiceFaculty}",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///educationServiceFaculty  REPO....
  Future<ResponseModel> editFacultyRepo(
      {required Map<String, dynamic> reqParm,
      required String facultyId}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${educationServiceFaculty}/$facultyId",
        params: reqParm,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET ALL Faculty  REPO....
  Future<ResponseModel> getAllFacultyRepo(
      {required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().getHTTP("${educationServiceFaculty}",
        params: reqParm, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///DELETE FACULTY DETAILS REPO....
  Future<ResponseModel> deleteFacultyRepo({
    required String facultyId,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${educationServiceFaculty}/$facultyId",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET CAMPUS CATEGORIES REPO....
  Future<ResponseModel> campusLifeCategoriesRepo() async {
    final response = await ApiBaseHelper().getHTTP("${campusLifeCategories}",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE CAMPUS REPO....
  Future<ResponseModel> createCampusLifeRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP("${campusLife}",
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET CAMPUS LIFE REPO....
  Future<ResponseModel> getAllCampusLifeRepo({String? schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${campusLife}/school/${schoolID ?? schoolIDGlobal}",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  // ///GET CAMPUS CATEGORY LIFE REPO....
  // Future<ResponseModel> getCampusCategoryLifeRepo({
  //   required String campusId,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP("${campusLife}/${campusId}",
  //       onError: (error) {}, onSuccess: (data) {});
  //   return response;
  // }

  ///UPDATE CAMPUS CATEGORY LIFE REPO....
  Future<ResponseModel> updateCampusCategoryLifeRepo(
      {required String campusId, required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().putHTTP("${campusLife}/${campusId}",
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///DELETE CAMPUS CATEGORY LIFE REPO....
  Future<ResponseModel> deleteCampusCategoryLifeRepo({
    required String entriesId,
    required String imageId,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${campusLife}/${entriesId}/images/$imageId",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///PUT  COURSE....
  Future<ResponseModel> updateSchoolInfoRepo({
    required Map<String, dynamic> reqBODY,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
        "${schoolUserID}$schoolIDGlobal",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL COURSES REPO....
  Future<ResponseModel> getSchoolCoursesRepo({required String schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${educationCourses}/school/$schoolID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL ACADEMICS REPO....
  Future<ResponseModel> getSchoolAcademicsRepo(
      {required String schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${educationServiceAcademics}/school/$schoolID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL OPTIONS (boards & mediums of instruction) REPO....
  ///
  ///Public endpoint — returns dropdown suggestions for the school
  ///quick-info form. See lib/docs/SCHOOL_OPTIONS_UI_INTEGRATION.md.
  Future<ResponseModel> getSchoolOptionsRepo() async {
    final response = await ApiBaseHelper().getHTTP(schoolOptions,
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL OPTIONS FOR A SPECIFIC CATEGORY REPO....
  ///
  ///Public endpoint — returns the ordered `fields` descriptor list for
  ///the given category (School Education, College/University, Sports &
  ///Hobby, Professional Learn, Skill Training, Coaching/Institute).
  ///Used as the authoritative source of *what to render* in the Quick
  ///Info form; the per-listing endpoint carries only the saved values.
  ///Doc §4.
  Future<ResponseModel> getSchoolOptionsByCategoryRepo(
      {required String category}) async {
    final response = await ApiBaseHelper().getHTTP(
      schoolOptions,
      params: {'category': category},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET SCHOOL QUICK INFO REPO....
  Future<ResponseModel> getSchoolQuickInfoRepo({String? schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "$schoolUserID${schoolID ?? schoolIDGlobal}/quick-info",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///UPDATE SCHOOL QUICK INFO REPO....
  Future<ResponseModel> updateSchoolQuickInfoRepo(
      {String? schoolID, required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().putHTTP(
        "$schoolUserID${schoolID ?? schoolIDGlobal}/quick-info",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET SCHOOL TIMINGS REPO....
  Future<ResponseModel> getSchoolTimingsRepo({String? schoolID}) async {
    final response = await ApiBaseHelper().getHTTP(
        "$schoolUserID${schoolID ?? schoolIDGlobal}/timings",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///UPDATE SCHOOL TIMINGS REPO....
  Future<ResponseModel> updateSchoolTimingsRepo(
      {String? schoolID, required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().putHTTP(
        "$schoolUserID${schoolID ?? schoolIDGlobal}/timings",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
}
