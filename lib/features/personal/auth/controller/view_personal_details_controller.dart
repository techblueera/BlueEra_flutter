import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../repo/personal_profile_repo.dart';

class ViewPersonalDetailsController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  final RxInt postsCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxInt followersCount = 0.obs;
  Rx<ApiResponse> viewPersonalResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFollowerViewCountResponse = ApiResponse.initial('Initial').obs;
  Rx<PersonalProfileDetailsModel> personalProfileDetails =
      PersonalProfileDetailsModel().obs;
  RxBool isSocialEdit = false.obs, isSelfVideo = false.obs;
RxString isYoutubeEdit="".obs;
  RxString youtube = ''.obs;
  RxString twitter = ''.obs;
  RxString linkedin = ''.obs;
  RxString instagram = ''.obs;
  RxString website = ''.obs;

  SortBy selectedFilter = SortBy.Latest;

  Rx<File?> selectedVideo = Rx<File?>(null);

  // RxBool isLoading = false.obs;
  RxString introVideoUrl = ''.obs;

  RxList<Projects>? projectsList=<Projects>[].obs;
  RxList<Experiences>? experiencesList=<Experiences>[].obs;
  // RxList<Projects>? projectsList=<Projects>[].obs;
  RxString overView=''.obs;

  Future<void> viewPersonalProfile() async {
    final personalController= Get.put(PersonalCreateProfileController());

    // try {
      viewPersonalResponse.value = ApiResponse.initial("Initial");

      // await getUserLoginBusinessId();
      ResponseModel responseModel =
          await PersonalProfileRepo().viewParticularPersonalProfile();

          // await PersonalProfileRepo().getUserWithFollowersAndPostsCount();
      // ResponseModel response = await UserRepo().getUserById(userId: userId);

      if (responseModel.isSuccess) {

        final data = responseModel.response?.data;
        personalProfileDetails.value =
            PersonalProfileDetailsModel.fromJson(data);

        ///SET SOCIAL DATA LINK...
        setSocialLink(data);
        personalController.imagePath?.value =
            personalProfileDetails.value.user?.profileImage ??
                "";
        ///SET SKILL...
        personalController.skillsList.clear();
        personalController
            .skillsList
            .addAll(personalProfileDetails.value.user?.skills ?? []);
       ///SET OVERVIEW
        overView.value=personalProfileDetails.value.user?.objective??"";
        ///SET PROJECT...
        projectsList?.clear();
        projectsList?.addAll(personalProfileDetails.value.user?.projects??[]);
        ///SET PROJECT...
        experiencesList?.clear();
        experiencesList?.addAll(personalProfileDetails.value.user?.experiences??[]);
        Get.find<AuthController>().imgPath.value=personalProfileDetails.value.user?.profileImage??"";
        await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.userProfile, personalProfileDetails.value.user?.profileImage??"");

        // followersCount.value = personalProfileDetails.value.followersCount??0  ;
        // followingCount.value =personalProfileDetails.value.followingCount??0  ;
        // postsCount.value = personalProfileDetails.value.totalPosts??0  ;
        viewPersonalResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    // } catch (e) {
    //   viewPersonalResponse.value = ApiResponse.error('error');
    // }
  }
Future<void> viewPersonalProfiles( String number) async {
    final personalController= Get.find<PersonalCreateProfileController>();

    // try {
      viewPersonalResponse.value = ApiResponse.initial("Initial");

      // await getUserLoginBusinessId();
      ResponseModel responseModel =
          await PersonalProfileRepo().viewParticularPersonalProfiles(number);
          
          // await PersonalProfileRepo().getUserWithFollowersAndPostsCount();
      // ResponseModel response = await UserRepo().getUserById(userId: userId);

      if (responseModel.isSuccess) {

        final data = responseModel.response?.data;
        personalProfileDetails.value =
            PersonalProfileDetailsModel.fromJson(data);

        ///SET SOCIAL DATA LINK...
        setSocialLink(data);

        ///SET SKILL...
        personalController.skillsList.clear();
        personalController
            .skillsList
            .addAll(personalProfileDetails.value.user?.skills ?? []);
       ///SET OVERVIEW
        overView.value=personalProfileDetails.value.user?.objective??"";
        ///SET PROJECT...
        projectsList?.clear();
        projectsList?.addAll(personalProfileDetails.value.user?.projects??[]);
        ///SET PROJECT...
        experiencesList?.clear();
        experiencesList?.addAll(personalProfileDetails.value.user?.experiences??[]);
        // followersCount.value = personalProfileDetails.value.followersCount??0  ;
        // followingCount.value =personalProfileDetails.value.followingCount??0  ;
        // postsCount.value = personalProfileDetails.value.totalPosts??0  ;
        viewPersonalResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    // } catch (e) {
    //   viewPersonalResponse.value = ApiResponse.error('error');
    // }
  }
  ///SET SOCIAL LINK DATA
  setSocialLink(data) async {
    youtube.value = data['user']['social_links']['youtube'] ?? '';
    twitter.value = data['user']['social_links']['twitter'] ?? '';
    linkedin.value = data['user']['social_links']['linkedin'] ?? '';
    instagram.value = data['user']['social_links']['instagram'] ?? '';
    website.value = data['user']['social_links']['website'] ?? '';
    final introVideoController= Get.find<IntroductionVideoController>();

    // logs("personalProfileDetails.value.user?.introVideo=== 1 ${ personalProfileDetails.value.user?.introVideo }");
    introVideoController.videoUrl.value =
        personalProfileDetails.value.user?.introVideo ?? "";
    // logs("personalProfileDetails.value.user?.introVideo=== 2 ${   introVideoController.videoUrl.value }");

    if (introVideoController.videoUrl.value.isNotEmpty) {
    await  introVideoController.initializeVideoPlayerFromNetwork(
          introVideoController.videoUrl.value);

    } else {
      introVideoController.hasUploadedVideo.value = false;
    }
  }

  Future<void> UserFollowersAndPostsCount(String? userId) async {
    try {
      ResponseModel responseModel =
          await PersonalProfileRepo().getUserWithFollowersAndPostsCount(userId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        if (data != null) {
          followersCount.value = data['followersCount'] ?? 0;
          followingCount.value = data['followingCount'] ?? 0;
          postsCount.value = data['totalPosts'] ?? 0;
          getFollowerViewCountResponse.value = ApiResponse.complete(responseModel);

          // if (data['user'] != null) {
          //   personalProfileDetails.value =
          //       PersonalProfileDetailsModel.fromJson(data);
          // }
        }
      } else {
        getFollowerViewCountResponse.value = ApiResponse.error();

        // commonSnackBar(
        //     message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getFollowerViewCountResponse.value = ApiResponse.error();

      print('Error fetching counts: $e');
      // commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {}
  }
}
