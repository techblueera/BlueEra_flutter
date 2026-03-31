import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
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

  RxBool isRiderServiceUser = false.obs;
  RxString isEarnServiceOpt = ''.obs;
  RxString userProfileType = userProfileTypeGlobal.obs;

  Future<void> viewPersonalProfile() async {
    final personalController = Get.put(PersonalCreateProfileController());

    try {
      // viewPersonalResponse.value = ApiResponse.initial("Initial");

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
            // _ProfileFieldStatus(
            //   id: 4,
            //   title: AppStrings.phoneNumber,
            //   isCompleted: user.contactNo?.isNotEmpty ?? false,
            // ),
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
        }

        ///SET SOCIAL DATA LINK...
        setSocialLink(data);
        personalController.imagePath?.value =
            user?.profileImage ?? "";
        personalController.coverImagePath?.value =
            user?.coverPicture ?? "";

        ///SET SKILL...
        personalController.skillsList.clear();
        personalController.skillsList
            .addAll(user?.skills ?? []);

        ///SET OVERVIEW
        overView.value = user?.objective ?? "";

        Get.find<AuthController>().imgPath.value =
            user?.profileImage ?? "";
        // await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.userProfile, user?.profileImage??"");
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
        log("userProfileTypeGlobal after api: ${userProfileType.value}");
        // print("Hash 1: ${userProfileType.hashCode}");

        /// Check Earn services
        isRiderServiceUser.value =
            personalProfileDetails.value.isRiderServiceUser ?? false;
        isEarnServiceOpt.value =
            personalProfileDetails.value.isEarnServiceUser.toString();
        await setRiderServiceOptData(isRiderServiceUser.value);
        // await setEarnServiceOptData(isEarnServiceUser.value);
        // await getRiderServiceOptData();
        // await getEarnServiceOptData();

        /// need to verify (for checking is service exists or not)
        if (user?.profession?.toUpperCase() == SELF_EMPLOYED ||
            user?.profession?.toUpperCase() == GIG_WORKER
        ) {
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
    } catch (e, s) {
      log('stack trace -- $s');
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

  // String checkIsEranServiceAlreadyCreated(){
  //   return earnServiceCreatedStatusGlobal;
  // }

  ///GET STATUS OF EARN SERVICE...
  // Future<void> getEarnServiceStatus() async {
  //   try {
  //     if(earnServiceCreatedStatusGlobal == "true"){
  //       return;
  //     }
  //
  //     ResponseModel responseModel =
  //         await EarnServiceRepo().getEarnServiceExistsStatusRepo();
  //
  //     if (responseModel.isSuccess) {
  //       final statusData = responseModel.response?.data['exists'] != null
  //           ? responseModel.response!.data['exists'].toString()
  //           : 'false';
  //       await SharedPreferenceUtils.setSecureValue(
  //           SharedPreferenceUtils.earnServiceCreatedStatusKey, statusData);
  //       await getEarnServiceCreatedStatusUtils();
  //     } else {
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     update();
  //   }
  // }

  void partiallyForceToCreateService() {
    final viewProfileController = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

    Get.find<AuthController>().individualOnboardingSkillWorkList.any(
      (service) => service.tagId == userProfessionGlobal,
    );

    if (viewProfileController.personalProfileDetails.value.isProfileCreated ==
        false) {
      Navigator.push(Get.context!,
          MaterialPageRoute(builder: (context) => CreateProfileScreen()));
    } else {

      if (userProfessionGlobal == BIKE_RIDER) {
        Get.toNamed(RouteHelper.getEarnServiceAvailableOptionsScreenRoute());
      } else {
        Get.toNamed(
            RouteHelper.getEarnServiceScreenRoute());
      }

      // Get.toNamed(
      //   RouteHelper.getAddServicesScreenRoute(),
      //   arguments: {
      //     ApiKeys.providerType: ProductServiceProviderType.user,
      //     ApiKeys.isFromEarnWithBlueEraService: true,
      //     ApiKeys.designation: userProfessionGlobal,
      //     ApiKeys.serviceSubType: isSelfService ? EarnWithBlueEraServiceTypes.selfWork : EarnWithBlueEraServiceTypes.homeService,
      //   },
      // );
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
        commonSnackBar(message:'Action Tapped on ${item.title}');
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
