import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class PersonalProfileRepo extends BaseService {
  Future<ResponseModel> viewParticularPersonalProfile() async {
    final response = await ApiBaseHelper().getHTTP(getUser,
        showProgress: false, onError: (error) {}, onSuccess: (data) {});

    return response;
  }
 Future<ResponseModel> viewParticularPersonalProfiles(String no) async {
    final response = await ApiBaseHelper().getHTTP(getotherUsers(no),
        showProgress: false, onError: (error) {}, onSuccess: (data) {});

    return response;
  }
  ///UPDATE USER PROFILE....
  Future<ResponseModel> updateUser({
    required Map<String, dynamic> formData,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$updateIndividualAccountUser$userId",
      // "$updateUserProfile/$userId",
      params: formData,
      isMultipart: true,
      onError: (error) {
        print("Update user failed: $error");
      },
      onSuccess: (res) {
        print("User updated: ${res.data}");
      },
    );

    return response;
  }

  Future<ResponseModel> getUserWithFollowersAndPostsCount(String? userId) async {
    print('userIdnow:$userId');
    final response = await ApiBaseHelper().getHTTP(
      "$FollowersAndPostsCount/$userId",
      showProgress: false,
      onError: (error) {
        print("Get user counts failed: $error");
      },
      onSuccess: (data) {
        print("User counts fetched: ${data}");
      },
    );

    return response;
  }
  ///UPLOAD INTRO VIDEO INIT...
  Future<ResponseModel?> uploadIntroVideoInit({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      userUploadInit,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> uploadIntroVideo({required String videoLink}) async {
    final Map<String, dynamic> payload = {
      ApiKeys.videoLink:videoLink,
    };

    return await ApiBaseHelper().postHTTP(
      uploadLiveVideo,
      params: payload,
      isMultipart: false,
    );
  }

  Future<ResponseModel> deleteIntroVideoRepo() async {
    return await ApiBaseHelper().deleteHTTP(
      deleteIntroVideo,
    );
  }

  Future<ResponseModel> deleteProjectRepo({required String? projectID}) async {
    return await ApiBaseHelper().deleteHTTP(
      "${user_project}$projectID",
    );
  }

  Future<ResponseModel> deleteExperienceRepo(
      {required String? experienceID}) async {
    return await ApiBaseHelper().deleteHTTP(
      "${user_experience}$experienceID",
    );
  }
}
