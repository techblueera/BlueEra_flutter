import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/model/personal_identity_model.dart';
import 'package:BlueEra/core/api/model/social_event_model.dart';
import 'package:BlueEra/core/api/model/social_vision_mission_model.dart';

class SocialProfileRepo extends BaseService {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  Future<PersonalIdentityModel> getPersonalIdentity() async {
    final response = await _apiBaseHelper.getHTTP(personalIdentity);
    if (response.response != null && response.response!.data != null) {
      return PersonalIdentityModel.fromJson(response.response!.data);
    }
    return PersonalIdentityModel(success: false);
  }

  Future<PersonalIdentityModel> updatePersonalIdentity(
      Map<String, dynamic> body) async {
    final response = await _apiBaseHelper.postHTTP(personalIdentity, params: body);
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

  Future<SocialEventModel> updateEvent(String id, Map<String, dynamic> body) async {
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

  Future<SocialVisionMissionModel> createMissionVision(Map<String, dynamic> body) async {
    final response = await _apiBaseHelper.postHTTP(missionVision, params: body);
    if (response.response != null && response.response!.data != null) {
      return SocialVisionMissionModel.fromJson(response.response!.data);
    }
    return SocialVisionMissionModel(success: false);
  }
}
