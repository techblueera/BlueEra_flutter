import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/personal_identity_model.dart';
import 'package:BlueEra/core/api/model/social_event_model.dart';
import 'package:BlueEra/core/api/model/social_vision_mission_model.dart';
import 'package:BlueEra/core/api/model/social_activity_res_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/social/model/social_profile_res_model.dart';

class SocialProfileRepo extends BaseService {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  Future<SocialProfileResModel> getSocialProfile() async {
    final response = await _apiBaseHelper.getHTTP(socialProfile);
    if (response.response != null && response.response!.data != null) {
      return SocialProfileResModel.fromJson(response.response!.data);
    }
    return SocialProfileResModel(success: false);
  }

  Future<PersonalIdentityModel> getPersonalIdentity() async {
    final response = await _apiBaseHelper.getHTTP(personalIdentity);
    if (response.response != null && response.response!.data != null) {
      return PersonalIdentityModel.fromJson(response.response!.data);
    }
    return PersonalIdentityModel(success: false);
  }

  Future<PersonalIdentityModel> updatePersonalIdentity(
      Map<String, dynamic> body) async {
    final response =
        await _apiBaseHelper.postHTTP(personalIdentity, params: body);
    if (response.response != null && response.response!.data != null) {
      return PersonalIdentityModel.fromJson(response.response!.data);
    }
    return PersonalIdentityModel(success: false);
  }

  Future<SocialEventModel> getEvents() async {
    final response = await _apiBaseHelper.getHTTP(events);
    if (response.response != null && response.response!.data != null) {
      return SocialEventModel.fromJson(response.response!.data);
    }
    return SocialEventModel(success: false);
  }

  Future<SocialEventModel> createEvent(Map<String, dynamic> body) async {
    final response = await _apiBaseHelper.postHTTP(events, params: body);
    if (response.response != null && response.response!.data != null) {
      return SocialEventModel.fromJson(response.response!.data);
    }
    return SocialEventModel(success: false);
  }

  Future<SocialEventModel> updateEvent(
      String id, Map<String, dynamic> body) async {
    final response = await _apiBaseHelper.putHTTP("$events/$id", params: body);
    if (response.response != null && response.response!.data != null) {
      return SocialEventModel.fromJson(response.response!.data);
    }
    return SocialEventModel(success: false);
  }

  Future<SocialEventModel> deleteEvent(String id) async {
    final response = await _apiBaseHelper.deleteHTTP("$events/$id");
    if (response.response != null && response.response!.data != null) {
      return SocialEventModel.fromJson(response.response!.data);
    }
    return SocialEventModel(success: false);
  }

  Future<SocialVisionMissionModel> getMissionVision() async {
    final response = await _apiBaseHelper.getHTTP(missionVision);
    if (response.response != null && response.response!.data != null) {
      return SocialVisionMissionModel.fromJson(response.response!.data);
    }
    return SocialVisionMissionModel(success: false);
  }

  Future<SocialVisionMissionModel> createMissionVision(
      Map<String, dynamic> body) async {
    final response = await _apiBaseHelper.postHTTP(missionVision, params: body);
    if (response.response != null && response.response!.data != null) {
      return SocialVisionMissionModel.fromJson(response.response!.data);
    }
    return SocialVisionMissionModel(success: false);
  }

  Future<SocialActivityResModel> getSocialActivities() async {
    final response = await _apiBaseHelper.getHTTP(socialActivities);
    if (response.response != null && response.response!.data != null) {
      return SocialActivityResModel.fromJson(response.response!.data);
    }
    return SocialActivityResModel(success: false);
  }

  Future<SocialActivityResModel> createSocialActivity(
      Map<String, dynamic> body) async {
    final response =
        await _apiBaseHelper.postHTTP(socialActivities, params: body);
    if (response.response != null && response.response!.data != null) {
      return SocialActivityResModel.fromJson(response.response!.data);
    }
    return SocialActivityResModel(success: false);
  }

  Future<SocialActivityResModel> updateSocialActivity(
      String id, Map<String, dynamic> body) async {
    final response =
        await _apiBaseHelper.putHTTP("$socialActivities/$id", params: body);
    if (response.response != null && response.response!.data != null) {
      return SocialActivityResModel.fromJson(response.response!.data);
    }
    return SocialActivityResModel(success: false);
  }

  Future<SocialActivityResModel> deleteSocialActivity(String id) async {
    final response = await _apiBaseHelper.deleteHTTP("$socialActivities/$id");
    if (response.response != null && response.response!.data != null) {
      return SocialActivityResModel.fromJson(response.response!.data);
    }
    return SocialActivityResModel(success: false);
  }

  ///CREATE DEPARTMENT...
  Future<ResponseModel> addSchoolDepartmentRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP("${socialActivityFeed}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///UPDATE DEPARTMENT...
  Future<ResponseModel> updateSchoolDepartmentRepo(
      {required Map<String, dynamic> reqBODY, required String deptId}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${socialActivityFeed}/${deptId}",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///GET DEPARTMENT REPO....
  Future<ResponseModel> getSchoolDepartmentRepo(
      {required Map<String, dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().getHTTP("${socialActivityFeed}",
        params: reqBODY, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///DELETE SCHOOL DEPARTMENT REPO....
  Future<ResponseModel> deleteSchoolDepartmentRepo(
      {required String departmentID}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        "${socialActivityFeed}/$departmentID",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  Future<dynamic> addSocialCertificateRepo(
      {required Map<String, dynamic> bodyREQ}) async {
    return await ApiBaseHelper().postHTTP(
      socialAchievements,
      params: bodyREQ,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateSocialCertificateRepo(
      {required String id, required Map<String, dynamic> bodyREQ}) async {
    return await ApiBaseHelper().putHTTP(
      "$socialAchievements/$id",
      params: bodyREQ,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getSocialCertificateRepo() async {
    return await ApiBaseHelper().getHTTP(
      "$socialAchievements",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteSocialCertificateRepo({
    required String id,
  }) async {
    return await ApiBaseHelper().deleteHTTP(
      "$socialAchievements/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }


  // POST: Create a new contact
  Future<ResponseModel> addSocialContactRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      socialContact,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getSocialContactByIdRepo(
      ) async {
    final response = await ApiBaseHelper().getHTTP(
      "${socialContact}/$userId",
      onError: (error) {},
      showProgress: true,
      onSuccess: (data) {},
    );
    return response;
  }

}
