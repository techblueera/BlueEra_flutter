import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/individual_user_response_model.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../chat/auth/service/location_update_service.dart';
import '../../personal_profile/view/widget/ai_suggestion_field.dart';
import '../../personal_profile/view/widget/introduction_video_widget.dart';
import '../../personal_profile/view/widget/update_personal_profession_dialog.dart';
import '../repo/personal_profile_repo.dart';

class _ProfileFieldStatus {
  final int id; // unique identifier
  final String title;
  final bool isCompleted;

  const _ProfileFieldStatus({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

class ViewPersonalDetailsController extends GetxController {
  bool updateBtnLoading = false;

  @override
  void onInit() {
    // getAllPostApi();
    // TODO: implement onInit
    super.onInit();
  }

  // ViewPersonalDetailsController() {
  //   print("🕵️‍♂️ Someone created a new instance!");
  //   print(StackTrace.current); // This prints the file & line number
  // }

  RxBool shopStatusOpenClose = false.obs;
  RxBool isShopStatusUpdating = false.obs;
  final LiveLocationService locationService = LiveLocationService();

  Future<void> toggleShopStatus() async {
    shopStatusOpenClose.value = !shopStatusOpenClose.value;
    if (shopStatusOpenClose.value) {
      locationService.start();
    } else {
      locationService.stop();
    }
    await callApiForChangeStatus();
  }

  Future<void> toggleShopOnlyStatus({required bool isActive}) async {
    shopStatusOpenClose.value = isActive;
    await callApiForChangeStatus();
  }

  void getServiceProviderStatus() async {
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
      isShopStatusUpdating.value = true;
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
    } finally {
      isShopStatusUpdating.value = false;
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
  RxString verifiedEmail = ''.obs;
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

  // RxList<Projects>? projectsList = <Projects>[].obs;
  // RxList<Experiences>? experiencesList = <Experiences>[].obs;

  // RxList<Projects>? projectsList=<Projects>[].obs;
  RxString overView = ''.obs;
  RxBool isMyProfileShow = false.obs;
  RxBool isChannelCreated = false.obs;

  // Rxn<AvailabilityModel> availabilityDetails = Rxn<AvailabilityModel>();

  List<_ProfileFieldStatus> fields = [];
  RxDouble myProfileCompletionPercent = 0.0.obs;

  RxString userProfileType = userProfileTypeGlobal.obs;
  Rxn<String> earnProfileType = Rxn<String>();

  Future<void> viewPersonalProfile() async {
    // Skip when logged out: stale screens / in-flight asyncs / Obx rebuilds
    // can re-enter this after token + userId globals were cleared, which
    // would otherwise hit /user/get?contact_no= with an invalidated token.
    if (!isLoggedIn()) return;

    final personalController = Get.put(PersonalCreateProfileController());

    // 1. Hydrate from cache immediately so the UI isn't blank while
    //    the silent network refresh below is in flight. The repo call
    //    runs without a global progress dialog.
    final cacheKey = userId;
    final cached = await PersonalProfileCache.read(cacheKey);
    if (cached != null) {
      _applyPersonalProfileData(cached, personalController,
          persistPrefs: false);
    }

    try {
      // 2. Silently refresh from the server.
      ResponseModel responseModel =
          await PersonalProfileRepo().viewParticularPersonalProfile();

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        // final upgraded = IndividualUserResponseModel.fromJson(data ?? {});
        // await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, upgraded.token);
        // await getUserAuthToken();
        if (data is Map<String, dynamic>) {
          await _applyPersonalProfileData(data, personalController,
              persistPrefs: true);
          final freshKey = userId;
          await PersonalProfileCache.write(freshKey, data);

          /// The server lost this device's push token (null/empty). Restore
          /// a fresh FCM token and rebind it on the backend so notifications
          /// keep working.
          await _restoreDeviceTokenIfMissing(data);
        }
        viewPersonalResponse.value = ApiResponse.complete(responseModel);
      } else {
        if (cached == null) {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e, s) {
      log('stack trace -- $s');
      viewPersonalResponse.value = ApiResponse.error('error');
    }
  }

  /// When the fetched profile's `device_token` is null/empty, the backend
  /// has no push token for this device. Regenerate the FCM token via
  /// [AppNotificationHandler.getFcmToken] and PATCH it back to
  /// `/user/me/device-token` so push delivery is restored.
  Future<void> _restoreDeviceTokenIfMissing(Map<String, dynamic> data) async {
    try {
      final user = data['user'];
      final serverToken =
          (user is Map) ? user['device_token']?.toString() : null;
      if (serverToken != null && serverToken.isNotEmpty) return;

      // Fetch the live FCM token and reconcile it into secure storage
      // (picks up a rotated token, not just an empty cache).
      await AppNotificationHandler.getFcmToken();
      final fcmToken = (await SharedPreferenceUtils.getSecureValue(
              SharedPreferenceUtils.notificationDeviceToken))
          ?.toString();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await PersonalProfileRepo().updateDeviceTokenRepo(deviceToken: fcmToken);
    } catch (e, s) {
      log('restore device token failed -- $e\n$s');
    }
  }

  /// Applies a personal-profile JSON map to all the reactive fields and
  /// optionally writes shared-preference snapshots / runs the side-effect
  /// helpers. `persistPrefs` is `true` only for fresh API responses — for
  /// cached data we skip prefs and the service-status fetch so we never
  /// overwrite newer values with stale ones.
  Future<void> _applyPersonalProfileData(
    Map<String, dynamic> data,
    PersonalCreateProfileController personalController, {
    required bool persistPrefs,
  }) async {
    personalProfileDetails.value =
        PersonalProfileDetailsModel.fromJson(data);

    ///SET MY PROFILE DATA
    final user = personalProfileDetails.value.user;
    if (user != null) {
      fields = [
        _ProfileFieldStatus(
          id: 1,
          title: AppStrings.profileVideo,
          isCompleted: user.introVideo?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 2,
          title: AppStrings.bio,
          isCompleted: user.bio?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 3,
          title: AppStrings.designation,
          isCompleted: user.designation?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 4,
          title: AppStrings.education,
          isCompleted: user.highestEducation?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 5,
          title: (user.emailVerified == true)
              ? AppStrings.emailVerified
              : AppStrings.emailUnverified,
          isCompleted: user.emailVerified ?? false,
        ),
      ];

      final int totalFields = fields.length;
      final int completedFields = fields.where((e) => e.isCompleted).length;
      final double percent =
          totalFields > 0 ? completedFields / totalFields : 0.0;

      myProfileCompletionPercent.value = percent;
    }

    if (user?.emailVerified ?? false) {
      verifiedEmail.value = user?.email ?? "";
    } else {
      verifiedEmail.value = "";
    }

    ///SET SOCIAL DATA LINK...
    setSocialLink(data);
    personalController.imagePath?.value = user?.profileImage ?? "";
    personalController.coverImagePath?.value = user?.coverPicture ?? "";

    ///SET SKILL...
    personalController.skillsList.clear();
    personalController.skillsList.addAll(user?.skills ?? []);

    ///SET OVERVIEW
    overView.value = user?.objective ?? "";

    /// SYNC GENDER, DOB AND PROFESSION TO CONTROLLER
    personalController.selectedGender.value =
        GenderTypeExtension.fromString(user?.gender ?? "male");
    personalController.selectedDay?.value = user?.dateOfBirth?.date ?? 0;
    personalController.selectedMonth?.value = user?.dateOfBirth?.month ?? 0;
    personalController.selectedYear?.value = user?.dateOfBirth?.year ?? 0;
    personalController.selectedProfession.value = user?.profession ?? "";

    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().imgPath.value = user?.profileImage ?? "";
    }

    /// Check Earn services
    earnProfileType.value = personalProfileDetails.value.earnProfileType;
    debugPrint(
        '=== earnProfileType: "${earnProfileType.value}", raw: "${personalProfileDetails.value.earnProfileType}" ===');

    /// Seed the location fallback from the personal profile so nearby APIs
    /// still work when device GPS is off.
    LocationService.setProfileLocation(
      personalProfileDetails.value.user?.userLocation?.lat,
      personalProfileDetails.value.user?.userLocation?.lon,
    );

    if (!persistPrefs) return;

    await SharedPreferenceUtils.userLoggedInIndividualGuest(
      businesId: "",
      loginUserId_: "${user?.id}",
      contactNo: "${user?.contactNo}",
      getUserName: "${user?.name}",
      profileImage: "${user?.profileImage}",
      profileType: "${user?.profileType}",
      profession: "${user?.profession}",
      designation: "${user?.designation}",
      userNameAt: "${user?.username}",
    );
    await getUserLoginData();
    userProfileType.value = userProfileTypeGlobal;
    debugPrint("userProfileTypeGlobal after api: ${userProfileType.value}");

    /// need to verify (for checking is service exists or not)
    if (user?.profession?.toUpperCase() == SELF_EMPLOYED ||
        user?.profession?.toUpperCase() == GIG_WORKER) {
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
  }


  ///SET SOCIAL LINK DATA
  setSocialLink(data) async {
    youtube.value = data['user']['social_links']['youtube'] ?? '';
    twitter.value = data['user']['social_links']['twitter'] ?? '';
    linkedin.value = data['user']['social_links']['linkedin'] ?? '';
    instagram.value = data['user']['social_links']['instagram'] ?? '';
    website.value = data['user']['social_links']['website'] ?? '';
    final introVideoController = getOrPut(() => IntroductionVideoController());


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
    if (!isLoggedIn()) return;
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

  RxString isUserServiceExistsKey = 'false'.obs;

  ///GET STATUS OF USER EXISTENCE...
  Future<String> getUserServiceExistenceStatus() async {
    try {
      ResponseModel responseModel =
          await AuthRepo().getServiceExistenceStatusRepo();

      if (responseModel.isSuccess) {
        String isUserServiceExits =
            responseModel.response?.data['exists'].toString() ?? 'false';
        return isUserServiceExits;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return 'false';
      }
    } catch (e) {
      update();
      return 'false';
    }
  }

  void onFieldTap(_ProfileFieldStatus item) {
    switch (item.id) {
      case 1:
        showIntroductionVideoDialog();
        break;
      case 2:
        showBioUpdateDialog();
        break;
      case 3:
        showProfessionUpdateDialog();
        break;
      case 4:
        showEducationUpdateDialog();
        break;
      case 5:
        if (!item.isCompleted) {
          showEmailVerificationDialog();
        } else {
          commonSnackBar(message: AppStrings.emailAlreadyVerified);
        }
        break;
      default:
        commonSnackBar(message: 'Action Tapped on ${item.title}');
    }
  }

  void showEmailVerificationDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(
      text: personalProfileDetails.value.user?.email ?? '',
    );

    showDialog(
      context: Get.context!,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.verifyYourEmail,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),

                  /// Email Field
                  CommonTextField(
                    title: AppStrings.email,
                    hintText: AppStrings.enterEmailAddress,
                    textEditController: emailController,
                    validationType: ValidationTypeEnum.email,
                    validator: ValidationMethod.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  /// Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: CustomText(AppStrings.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          title: AppStrings.getVerify,
                          height: SizeConfig.size40,
                          bgColor: AppColors.primaryColor,
                          radius: 10.0,
                          onTap: () {
                            if (formKey.currentState?.validate() ?? false) {
                              final email = emailController.text.trim();
                              Navigator.pop(context); // Close dialog
                              final emailVerificationController =
                                  Get.isRegistered<
                                          EmailVerificationController>()
                                      ? Get.find<EmailVerificationController>()
                                      : Get.put(EmailVerificationController());

                              emailVerificationController.verifyEmail(email);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showBioUpdateDialog() {
    final formKey = GlobalKey<FormState>();
    final personalCreateProfileController =
        Get.put(PersonalCreateProfileController());
    final ViewPersonalDetailsController viewPersonalDetailsController =
        Get.find<ViewPersonalDetailsController>();
    final TextEditingController bioController = TextEditingController();
    bioController.text =
        viewPersonalDetailsController.personalProfileDetails.value.user?.bio ??
            '';

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Update Bio",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),
                  AiSuggestionField(
                    title: "About Me / Bio",
                    apiType: "bio",
                    textController: bioController,
                    bodyRequest: {
                      ApiKeys.profession: viewPersonalDetailsController
                          .personalProfileDetails.value.user?.profession,
                      ApiKeys.designation: viewPersonalDetailsController
                          .personalProfileDetails.value.user?.designation,
                      ApiKeys.date_of_birth_Obj: {
                        ApiKeys.year:
                            personalCreateProfileController.selectedYear?.value,
                        ApiKeys.month: personalCreateProfileController
                            .selectedMonth?.value,
                        ApiKeys.date:
                            personalCreateProfileController.selectedDay?.value,
                      },
                      ApiKeys.gender: personalCreateProfileController
                          .selectedGender.value?.name,
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const CustomText("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          title: "Save",
                          height: SizeConfig.size40,
                          bgColor: AppColors.primaryColor,
                          radius: 10.0,
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              personalCreateProfileController
                                  .updateUserProfileDetails(
                                params: {
                                  ApiKeys.bio: bioController.text.trim(),
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showEducationUpdateDialog() {
    final formKey = GlobalKey<FormState>();
    final personalCreateProfileController =
        Get.put(PersonalCreateProfileController());
    final viewPersonalDetailsController =
        Get.find<ViewPersonalDetailsController>();

    final TextEditingController educationController = TextEditingController();

    educationController.text = viewPersonalDetailsController
            .personalProfileDetails.value.user?.highestEducation ??
        '';

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Update Education",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    title: AppStrings.highestEducation,
                    hintText: "eg. 12th, B.A, M.A, PhD",
                    textEditController: educationController,
                    maxLength: 16,
                    onChange: (val) {},
                    validator: (value) {
                      if (value!.trim().length < 2) {
                        return AppStrings.educationMinLength.tr;
                      } else if (value.trim().length > 16) {
                        return AppStrings.educationMaxLength.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const CustomText("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          title: "Save",
                          height: SizeConfig.size40,
                          bgColor: AppColors.primaryColor,
                          radius: 10.0,
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              personalCreateProfileController
                                  .updateUserProfileDetails(
                                params: {
                                  ApiKeys.highest_education:
                                      educationController.text.trim(),
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showIntroductionVideoDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500, // prevents overflow
              minHeight: 200,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          AppStrings.uploadIntroductionVideo,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const IntroductionVideoWidget(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showProfessionUpdateDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: UpdatePersonalProfessionDialog(),
        );
      },
    );
  }
}

//
