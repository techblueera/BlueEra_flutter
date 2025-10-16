import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/map/controller/location_controller.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../repo/personal_profile_repo.dart';

class _ProfileFieldStatus {
  final String title;
  final bool isCompleted;

  _ProfileFieldStatus(this.title, this.isCompleted);
}

class ViewPersonalDetailsController extends GetxController {
  @override
  void onInit() {
    // getAllPostApi();
    // TODO: implement onInit
    super.onInit();
  }

  RxBool shopStatusOpenClose = false.obs;

  Future<void> toggleShopStatus() async {
    shopStatusOpenClose.value = !shopStatusOpenClose.value;
    await callApiForChangeStatus();
  }

  Future<void> toggleShopOnlyStatus({required bool isActive}) async {
    shopStatusOpenClose.value = isActive;
    await callApiForChangeStatus();
  }

  getServiceProviderStatus() async {
    try {
      ResponseModel responseModel =
          await PersonalProfileRepo().getServiceStatusRepo();

      if (responseModel.isSuccess) {
        final statusData = responseModel.response?.data['availabilityStatus']
            .toString()
            .toUpperCase();
        if (statusData == AppConstants.OPEN.toUpperCase()) {
          shopStatusOpenClose.value = true;
          callLocationAPI();
        } else {
          shopStatusOpenClose.value = false;
        }
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.serviceProviderStatus, statusData);
        await getServiceProviderStatusUtils();
      } else {
        shopStatusOpenClose.value = false;
      }
    } catch (e) {
      shopStatusOpenClose.value = false;
    }
  }

  callLocationAPI() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      await MapServiceRepo().mapServiceLocationProviderRepo(queryParams: {
        ApiKeys.userId: userId,
        ApiKeys.lat: position.latitude,
        ApiKeys.lng: position.longitude,
      });
    }
  }

  callApiForChangeStatus() async {
    try {
      changeShopStatusResponse.value = ApiResponse.initial("Initial");

      ResponseModel responseModel =
          await PersonalProfileRepo().setServiceStatusRepo(bodyReq: {
        ApiKeys.userId: userId,
        ApiKeys.status: shopStatusOpenClose.value ? "OPEN" : "CLOSED"
      });

      if (responseModel.isSuccess) {
        final statusData = responseModel
            .response?.data['provider']['availabilityStatus']
            .toString()
            .toUpperCase();
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.serviceProviderStatus, statusData);
        await getServiceProviderStatusUtils();
        if (statusData == AppConstants.OPEN.toUpperCase()) {
          callLocationAPI();

          // Get.put(LocationServiceProviderController()); // initialize controller
        }
        changeShopStatusResponse.value = ApiResponse.complete(responseModel);
      }
    } catch (e) {
      changeShopStatusResponse.value = ApiResponse.error('error');
    }
  }

  final RxInt postsCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxInt followersCount = 0.obs;
  Rx<ApiResponse> changeShopStatusResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> viewPersonalResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFollowerViewCountResponse =
      ApiResponse.initial('Initial').obs;
  Rx<PersonalProfileDetailsModel> personalProfileDetails =
      PersonalProfileDetailsModel().obs;
  RxBool isSocialEdit = false.obs, isSelfVideo = false.obs;
  RxString isYoutubeEdit = "".obs;
  RxString youtube = ''.obs;
  RxString twitter = ''.obs;
  RxString linkedin = ''.obs;
  RxString instagram = ''.obs;
  RxString website = ''.obs;
  Rx<ApiResponse> postsResponse = ApiResponse.initial('Initial').obs;
  Rx<PostResponse?> postRes = Rx(null);

  SortBy selectedFilter = SortBy.Latest;

  Rx<File?> selectedVideo = Rx<File?>(null);

  // RxBool isLoading = false.obs;
  RxString introVideoUrl = ''.obs;

  RxList<Projects>? projectsList = <Projects>[].obs;
  RxList<Experiences>? experiencesList = <Experiences>[].obs;

  // RxList<Projects>? projectsList=<Projects>[].obs;
  RxString overView = ''.obs;
  RxBool isMyProfileShow = false.obs;
  RxBool isChannelCreated = false.obs;

  Rxn<AvailabilityModel> availabilityDetails = Rxn<AvailabilityModel>();

  List<_ProfileFieldStatus> fields = [];
  RxDouble myProfileCompletionPercent = 0.0.obs;

  Future<void> viewPersonalProfile() async {
    final personalController = Get.put(PersonalCreateProfileController());

    try {
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

        ///SET MY PROFILE DATA
        final user = personalProfileDetails.value.user;
        if (user != null) {
          fields = [
            _ProfileFieldStatus(
                'Profile video', user.introVideo?.isNotEmpty ?? false),
            _ProfileFieldStatus('Bio', user.bio?.isNotEmpty ?? false),
            _ProfileFieldStatus(
                'Designation', user.designation?.isNotEmpty ?? false),
            _ProfileFieldStatus(
                'Phone number', user.contactNo?.isNotEmpty ?? false),
            _ProfileFieldStatus(
                'Organization', user.currentOrganisation?.isNotEmpty ?? false),
            _ProfileFieldStatus('Email (Unverified)', false),
          ];

          final int totalFields = fields.length;
          final int completedFields = fields.where((e) => e.isCompleted).length;
          final double percent =
              totalFields > 0 ? completedFields / totalFields : 0.0;

          myProfileCompletionPercent.value = percent;
        }

        ///SET SOCIAL DATA LINK...
        setSocialLink(data);
        personalController.imagePath?.value =
            personalProfileDetails.value.user?.profileImage ?? "";

        ///SET SKILL...
        personalController.skillsList.clear();
        personalController.skillsList
            .addAll(personalProfileDetails.value.user?.skills ?? []);

        ///SET OVERVIEW
        overView.value = personalProfileDetails.value.user?.objective ?? "";

        ///SET PROJECT...
        projectsList?.clear();
        projectsList?.addAll(personalProfileDetails.value.user?.projects ?? []);

        ///SET PROJECT...
        experiencesList?.clear();
        experiencesList
            ?.addAll(personalProfileDetails.value.user?.experiences ?? []);
        Get.find<AuthController>().imgPath.value =
            personalProfileDetails.value.user?.profileImage ?? "";
        // await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.userProfile, personalProfileDetails.value.user?.profileImage??"");
        await SharedPreferenceUtils.userLoggedInIndivisualGuest(
          businesId: "",
          loginUserId_: "${personalProfileDetails.value.user?.id}",
          contactNo: "${personalProfileDetails.value.user?.contactNo}",
          getUserName: "${personalProfileDetails.value.user?.name}",
          profileImage: "${personalProfileDetails.value.user?.profileImage}",
          designation: "${personalProfileDetails.value.user?.profession}",
          userNameAt: "${personalProfileDetails.value.user?.username}",
        );
        await getUserLoginData();
        if (personalProfileDetails.value.user?.profession?.toUpperCase() ==
            "SELF_EMPLOYED") {
          await getServiceProviderStatusUtils();
          if (serviceProviderStatusGlobal.isNotEmpty) {
            if (serviceProviderStatusGlobal.toUpperCase() ==
                AppConstants.OPEN.toUpperCase()) {
              shopStatusOpenClose.value = true;
            } else {
              shopStatusOpenClose.value = false;
            }
          } else {
            getServiceProviderStatus();
          }
        }
        viewPersonalResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewPersonalResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> viewPersonalProfiles(String number) async {
    final personalController = Get.find<PersonalCreateProfileController>();

    // try {
    viewPersonalResponse.value = ApiResponse.initial("Initial");

    // await getUserLoginBusinessId();
    ResponseModel responseModel =
        await PersonalProfileRepo().viewParticularPersonalProfiles(number);

    // await PersonalProfileRepo().getUserWithFollowersAndPostsCount();
    // ResponseModel response = await UserRepo().getUserById(userId: userId);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      personalProfileDetails.value = PersonalProfileDetailsModel.fromJson(data);

      ///SET SOCIAL DATA LINK...
      setSocialLink(data);

      ///SET SKILL...
      personalController.skillsList.clear();
      personalController.skillsList
          .addAll(personalProfileDetails.value.user?.skills ?? []);

      ///SET OVERVIEW
      overView.value = personalProfileDetails.value.user?.objective ?? "";

      ///SET PROJECT...
      projectsList?.clear();
      projectsList?.addAll(personalProfileDetails.value.user?.projects ?? []);

      ///SET PROJECT...
      experiencesList?.clear();
      experiencesList
          ?.addAll(personalProfileDetails.value.user?.experiences ?? []);
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
    final introVideoController = Get.isRegistered<IntroductionVideoController>()
        ? Get.find<IntroductionVideoController>()
        : Get.put(IntroductionVideoController());

    // logs("personalProfileDetails.value.user?.introVideo=== 1 ${ personalProfileDetails.value.user?.introVideo }");
    introVideoController.videoUrl.value =
        personalProfileDetails.value.user?.introVideo ?? "";
    // logs("personalProfileDetails.value.user?.introVideo=== 2 ${   introVideoController.videoUrl.value }");

    if (introVideoController.videoUrl.value.isNotEmpty) {
      await introVideoController.initializeVideoPlayerFromNetwork(
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
          getFollowerViewCountResponse.value =
              ApiResponse.complete(responseModel);

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

  Future<void> getAllPostApi(String id) async {
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: 1,
      ApiKeys.limit: 10,
      ApiKeys.filter: "latest",
    };

    // if (query == null) {
    queryParams[ApiKeys.refresh] = refresh;
    // }
    queryParams[ApiKeys.authorId] = id;
    try {
      ResponseModel response =
          await FeedRepo().getAllOtherPosts(queryParams: queryParams);
      if (response.isSuccess) {
        postsResponse.value = ApiResponse.complete(response);
        postRes.value = PostResponse.fromJson(response.response?.data);
        update();
      } else {
        postsResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      postsResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
